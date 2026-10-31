#!/usr/bin/env bash
# /usr/local/sbin/backup-stv.sh  (CT 108 srv-backup-stv)
# Backup pull del VPS gestionale STV -> repository restic sul QNAP.
# Lato VPS ogni componente passa da /usr/local/sbin/stv-backup-gate (comando forzato, sola lettura).
# Un componente che fallisce non blocca gli altri; l'esito finale e' "fail" se almeno uno fallisce.
set -uo pipefail
umask 077

# shellcheck source=/dev/null
source /etc/backup-stv.conf
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE
export RESTIC_CACHE_DIR=/var/cache/restic

SSH_BASE=(ssh -i "$SSH_KEY" -p "$VPS_PORT" -o BatchMode=yes -o StrictHostKeyChecking=yes
          -o ConnectTimeout=30 -o ServerAliveInterval=30 -o ServerAliveCountMax=6
          "${VPS_USER}@${VPS_HOST}")
FAILED=()

log() { echo "[$(date '+%F %T')] $*"; }

notify() { # $1 = ok|fail  $2 = messaggio
  [[ -n "${HA_WEBHOOK_URL:-}" ]] || return 0
  curl -fsS -m 15 -X POST -H 'Content-Type: application/json' \
    -d "{\"status\":\"$1\",\"host\":\"$(hostname)\",\"msg\":\"$2\"}" \
    "$HA_WEBHOOK_URL" >/dev/null || true
}

exec 9>/run/backup-stv.lock
flock -n 9 || { log "Backup gia' in esecuzione, esco"; exit 1; }

if [[ ! -f "$BACKUP_ROOT/.stv-backup-target" ]]; then
  log "Sentinel $BACKUP_ROOT/.stv-backup-target assente: NFS non montato?"
  notify fail "backup-stv: NFS non montato"
  exit 1
fi

# Componente in streaming: il gate restituisce un .gz, qui lo decomprimiamo prima di restic
# cosi' la deduplica funziona tra un giorno e l'altro. pipefail fa fallire restic se ssh fallisce.
stream() { # $1 = parola chiave gate  $2 = nome file nello snapshot (senza "/")
  log "Componente $1"
  local cmd
  printf -v cmd '%q ' "${SSH_BASE[@]}" "$1"
  if restic backup --host stv-vps --tag "$1" --stdin-filename "$2" \
       --stdin-from-command -- bash -o pipefail -c "${cmd} | gunzip -c"; then
    log "Componente $1: OK"
  else
    log "Componente $1: FALLITO"
    FAILED+=("$1")
  fi
}

stream db       stv-db-mysql-all-databases.sql
stream code     stv-code-containers.tar
stream pec      stv-pec-docker-send.tar
stream hostcfg  stv-hostcfg.tar

# Archivio documentale: rsync incrementale verso lo staging (il gate lo instrada su rrsync -ro)
log "Componente docs (rsync)"
mkdir -p "$STAGING"
printf -v RSH '%q ' ssh -i "$SSH_KEY" -p "$VPS_PORT" -o BatchMode=yes -o StrictHostKeyChecking=yes \
  -o ConnectTimeout=30 -o ServerAliveInterval=30 -o ServerAliveCountMax=6
if rsync -rltH --delete --partial --max-delete="$MAX_DELETE" -e "$RSH" \
     "${VPS_USER}@${VPS_HOST}:./" "$STAGING/" \
   && restic backup --host stv-vps --tag docs "$STAGING"; then
  log "Componente docs: OK"
else
  log "Componente docs: FALLITO"
  FAILED+=(docs)
fi

# Immagini complete una volta a settimana o su richiesta: FORCE_IMAGES=1
if [[ "$(date +%u)" == "$IMAGES_WEEKDAY" || "${FORCE_IMAGES:-0}" == 1 ]]; then
  stream images-lxc    stv-image-lxc-export.tar
  stream images-docker stv-image-pec-mailer.tar
fi

log "Retention e prune"
if ! restic forget --host stv-vps \
       --keep-daily "$KEEP_DAILY" --keep-weekly "$KEEP_WEEKLY" --keep-monthly "$KEEP_MONTHLY" \
       --prune; then
  FAILED+=(prune)
fi

if (( ${#FAILED[@]} )); then
  log "Backup terminato con errori: ${FAILED[*]}"
  notify fail "backup-stv: falliti ${FAILED[*]}"
  exit 1
fi
log "Backup completato"
notify ok "backup-stv completato"
