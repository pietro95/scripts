# scripts

Script prodotti per il progetto di messa in sicurezza del VPS del gestionale di Studio Tecnico Verro. Nessun segreto nel repository: password, chiavi e token restano fuori (sul server in `/etc/backup-stv.conf`, root 600).

Ogni file è la copia di quanto è in produzione al momento del commit; lo sha256 è indicato qui sotto e va riverificato prima di sovrascrivere un file sul server.

| Percorso nel repo | Destinazione | Note | sha256 |
|---|---|---|---|
| `backup-stv/vps/stv-backup-gate` | VPS `/usr/local/sbin/stv-backup-gate` (root:root 755) | v3.1, 31/10/2026. Comando forzato della chiave `stv-backup`: `db`, `code`, `pec`, `hostcfg`, `docs` (rsync), `images-lxc`, `images-docker`. Container attuali: `php74`, `nginx-server` | `c32375c34da0db1cbcbcaf39b7e4554ec33daa569a8da34904815092a0b428af` |
| `backup-stv/ct108/backup-stv.sh` | CT108 `/usr/local/sbin/backup-stv.sh` (root:root 700) | Backup pull con restic; legge `/etc/backup-stv.conf` (non nel repo) | `43626d4b8f3090306ce567393d3fa272255bb290a8d1f2a63bebfdb9618d6bed` |
| `vps-firewall/cf-origin.nft` + `stv-cf-origin.service` | VPS `/etc/stv-cf/` e `/etc/systemd/system/` | 80/443 verso i container solo da IP Cloudflare (CF2 fase B, 29/10/2026). I range Cloudflare sono statici | — |
| `vps-firewall/stv-v6.nft` + `stv-v6-fw.service` | VPS `/etc/stv-cf/` e `/etc/systemd/system/` | A14, firewall IPv6 dell'host (29/10/2026) | — |

Non ancora nel repo: unit systemd `backup-stv*.service|timer` di CT108, `cf-origin-monitor.nft` (fase A, sostituita).

Il registro delle modifiche e delle verifiche è nel Project "Gestionale StudioTecnicoVerro" (`claude/change-log.md`, `claude/registro-verifiche.md`).
