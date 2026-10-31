# Registro backup — 31/10/2026 (guasto del run notturno 30→31/10 e correzione)

Solo fatti verificati con output di comando, più findings aperti. Nessun segreto. Le modifiche eseguite sono in `claude/change-log.md` (righe del 31/10). Dove questo file diverge da `registro-verifiche.md` sul backup (copertura `webalpine`, `images-lxc`, nomi dei file in restic), prevale questo.
Accesso: connettore MCP SSH, alias `stv-vps` e `stv-ct108`, dal nuovo Mac di Pietro (alias e `known_hosts` reimportati da OneDrive).

## Fatti verificati

| Data | Fatto | Fonte / comando | Esito |
| --- | --- | --- | --- |
| 2026-10-31 | **Causa del fallimento notturno:** il gate sul VPS (v2) referenziava il container `webalpine`; `webalpine` è **fermo dal 30/10/2026 21:18:57 CET** (STOPPED). `lxc exec` su un container fermo esce con rc=1, quindi il componente che entra nel container non produce dati. Dichiarato da Pietro: `webalpine` è dismesso in modo definitivo | `lxc list`; log del gate e journal `backup-stv.service` su CT108; conferma di Pietro in chat | confermato |
| 2026-10-31 | **Copertura mancante prima di oggi:** il codice vivo è su `php74` (`/var/www/localhost`) e la configurazione del front end su `nginx-server` (nginx, Let's Encrypt, `cron.d`); il gate v2 salvava solo `webalpine`. Quindi **fino al 30/10 il codice in produzione e la config di `nginx-server` non erano nel backup** (gli snapshot `code`/`images-lxc` precedenti contengono solo `webalpine`) | lettura del gate v2; `lxc exec php74/nginx-server -- ls` dei percorsi | confermato |
| 2026-10-31 | **Cron `aggiorna_scadenze` non migrato:** l'unico crontab con chiamata HTTP è nel container `webalpine` (fermo), quindi il job delle 21:01 CET non gira più. Il valore del parametro `h=` nell'URL è un token in chiaro (non riportato qui). **Il run mancato di stasera è accettato da Pietro** ("non è un mio problema se lui ha configurato male il cron") | `lxc exec webalpine -- crontab -l` (a container avviato in precedenza); ricerca dei cron nei tre container | confermato (migrazione non fatta, non nostro compito) |
| 2026-10-31 | **Esposizione di segreto nell'output di sessione:** il token del cron (parametro `h=`, 32 caratteri esadecimali) è comparso per errore in due output di strumento della sessione (filtro `sed` che mascherava `token=` e non `h=`). Non riportato in chat né nei file di progetto. Mitigazione: da qui in avanti mascherare qualsiasi `[0-9a-fA-F]{32}`; rotazione del token consigliata quando il cron viene migrato (richiede modifica del codice dello sviluppatore) | revisione degli output | confermato |
| 2026-10-31 | **Percorsi mappati e salvati (gate v3.1):** `php74`: `var/www/localhost`, `etc/nginx`, `etc/vsftpd.conf`, `etc/fail2ban`, `etc/php`, `opt/php74`, `usr/local/etc`, `usr/local/php`, `usr/local/lib/php`, `usr/local/bin/php`, `usr/local/sbin/php-fpm`, `root/php7`. `nginx-server`: `etc/nginx`, `etc/letsencrypt`, `etc/cron.d`. `hostcfg` ora enumera tutti i container (`lxc config show --expanded` per ciascuno) e salva `php74-build.txt` (versione e Configure Command). `images-lxc`: export di `php74` e `nginx-server` (`--instance-only --compression none`) | prove con `lxc` reale (code, hostcfg, export di `nginx-server`) | confermato per code, hostcfg e export di `nginx-server`; **export di `php74` non provato** |
| 2026-10-31 | **Errore di progetto trovato in revisione e corretto prima dell'installazione:** la bozza v3 trattava rc=1 di `lxc exec` su container fermo come l'avviso di `tar` (file cambiati), cioè produceva in silenzio un backup vuoto. v3.1: controllo dello stato `RUNNING`, rc≥2 fatale, rc=1 solo avviso, e verifica `tar -tf` di ogni tar prima dell'invio. Provato con stub di `lxc` (container fermo → fallisce; tar rc=1 → avviso; tar rc=2 → fallisce) e con `lxc` reale | harness di test in scratchpad; run reali sul VPS | confermato |
| 2026-10-31 | **Run manuale di `backup-stv.service` su CT108 (10:25:47-10:26:36, ora del journal):** `db` OK (5 s), `code` OK (24 s), `pec` OK, `hostcfg` OK, `docs` (rsync) OK, retention e prune eseguiti, `Backup completato`. `is-failed` = inactive, `Result=success`, `ExecMainStatus=0`. `images-lxc` e `images-docker` non eseguiti (sabato; `IMAGES_WEEKDAY` = domenica) | `systemctl start backup-stv.service`; `systemctl is-failed`; `systemctl show -p Result -p ExecMainStatus`; `journalctl -u backup-stv.service` | confermato (contenuto degli snapshot **non** ispezionato da Claude, vedi verifiche) |
| 2026-10-31 | `backup-stv.sh` su CT108 ora salva `code` come `stv-code-containers.tar` e `images-lxc` come `stv-image-lxc-export.tar` (prima `stv-code-webalpine.tar` e `stv-image-webalpine-export.tar`). Ipotesi da verificare: restic raggruppa per host+percorsi; i nuovi nomi creano gruppi nuovi e i gruppi `webalpine` non ricevono più snapshot. Con `--keep-daily/weekly/monthly` applicato per gruppo, gli ultimi snapshot `webalpine` dovrebbero restare (nessun nuovo snapshot li fa decadere), ma non è provato | `diff` prima/dopo; `bash -n` | confermato per il diff; comportamento di restic: **ipotesi da verificare** |

## Verifiche da fare (a carico di Pietro: root su CT108, credenziali restic)

Non eseguibili da Claude (le credenziali restic non vanno lette da Claude).

```
set -a; . /etc/backup-stv.conf; set +a
restic snapshots --host stv-vps --compact
restic snapshots --host stv-vps --tag code --latest 3
restic dump --tag code --host stv-vps latest /stv-code-containers.tar | tar -tvf - | head
```

Atteso: un nuovo snapshot `code` con percorso `/stv-code-containers.tar`, contenente `php74.tar` e `nginx-server.tar` di dimensione non nulla; gli snapshot `/stv-code-webalpine.tar` e `/stv-image-webalpine-export.tar` ancora presenti. Il terzo comando elenca solo i due tar interni; per verificarne il contenuto: `... | tar -xOf - php74.tar | tar -tf - | grep -c 'var/www/localhost'` (atteso > 0).

## Findings aperti

| Priorità | Finding | Stato |
| --- | --- | --- |
| Alta | **Cron `aggiorna_scadenze` non migrato** dopo lo spegnimento di `webalpine`: il job delle 21:01 CET non gira (primo run mancato: 31/10 sera). Impatto funzionale non quantificato (aggiornamento scadenze) | Pietro: accettato. Responsabilità dello sviluppatore; ripristino = cron su `php74`/`nginx-server` con chiamata a `http://10.153.97.237:9980` o equivalente. Da riverificare lunedì 02/11 se le scadenze risultano aggiornate |
| Alta | **Token del cron in chiaro** nell'URL (finisce nei log nginx) e comparso in due output di sessione (31/10) | Ruotare il token al momento della migrazione del cron (richiede modifica del codice) |
| Media | **Prima esecuzione di `images-lxc` domenica 01/11 01:02 UTC:** export di `php74` (di GB, mai provato; l'export di `nginx-server` è provato) con spazio temporaneo in `/var/tmp` del VPS | Dopo il run: `journalctl -u backup-stv.service` e `df -h` sul VPS. Se fallisce solo `images-lxc`, gli altri componenti sono comunque salvati |
| Media | **Backup del codice vivo e di `nginx-server` assente fino al 30/10** (nessun punto di ripristino precedente) | Chiuso per il futuro dal 31/10 (verificare snapshot, vedi sopra). Il periodo 17-30/10 non è recuperabile dal backup |
| Media | **Quale `php.ini` usa php-fpm:** la CLI riporta `/opt/php74/etc/php.ini`, esiste anche `/usr/local/etc/php.ini`; entrambi i percorsi sono nel backup | Da verificare nel pool FPM (collegato al controllo residuo di C5) |
| Media | Copie del gate: non ancora su GitHub (regola di progetto: script su GitHub) | Pietro: indicare il repository |
| Bassa | Il fuso orario riportato per l'installazione del gate (11:24) e per il run (10:25 UTC del journal) non è stato riconciliato | Annotato; nessun impatto |
| Media (invariato) | Nessun test di ripristino; nessun monitoraggio del servizio; verifica mensile `backup-stv-check.timer` mai eseguita (prima il 01/11 05:00 UTC) | Vedi `registro-verifiche.md` e `todo-findings-critici.md` |
