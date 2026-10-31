# Contesto VPS gestionale (fonte: Specifiche Tecniche VPS v1.0, 11/07/2026; aggiornato con verifiche del 26/10/2026)

Stato: la parte "Dichiarato" viene dallo sviluppatore; la parte "Verificato 26/10" da output di comando (dettaglio in `registro-verifiche.md`). Nessun segreto in questo documento.

## Host
- VPS OVH `vps-deae2a20.vps.ovh.net`, Ubuntu, IP pubblico 57.131.13.35 (interfaccia **ens3**: regole con `-i eth0` non possono matchare). IPv6 attivo.
- sshd porta 53197, utente `ubuntu`, password oppure certificato + password.
- MySQL Oracle porta 36111 (X Protocol 33060 da disabilitare). `dropsql` chiude la porta, `bksql` backup del solo DB. **Verificato 26/10: 36111 in ascolto e senza DROP (C6).**
- pure-ftpd root 43177 (dichiarato "da disabilitare"), Falco, knockd, fail2ban, iptables + netfilter-persistent (iptables-nft 1.8.10, nft 1.0.9; `ipset` non installato).
- Snap `lxd` e `docker` con `--hold=forever`.
- Socket `/opt/file_service/file_service.sock` host↔container (non documentato).

## Container LXD (verificato 26/10: tre container)
- **nginx-server** (10.153.97.152): front end. Riceve 80/443 dal DNAT. Un solo vhost `intranet`, certificato Let's Encrypt (certbot timer), `real_ip` con range identici alla lista Cloudflare `/ips`. Niente Authenticated Origin Pulls.
- **php74** (10.153.97.237, Ubuntu, build PHP 7.4 non-distro): riceve da nginx-server; nginx su 9980/9999, php-fpm su 0.0.0.0:9000, vsftpd su 43173.
- **webalpine** (10.153.97.55, Alpine, unprivileged): non più il front end (era dichiarato come destinazione di 80/443). Contiene ancora nginx, php-fpm7, vsftpd 51141 (passive 30000-30100), certbot, cron PEC. Ruolo attuale da chiarire con lo sviluppatore.
- LXD su `lxdbr0` 10.153.97.0/24 (gateway 10.153.97.1). I proxy device LXD ascoltano su wildcard `*` v4 e v6. Tabelle nft `inet lxd` / `inet lxc`.
- Mount documenti: `/mtn/azienda` ← `/var/lxd/uploads/` sull'host, cifratura AES-256-CBC. Alias host `lxcalpine`.

## Docker `pec-mailer`
- App Python invio PEC, 172.17.0.2:2627 (bridge 172.17.0.0/16), DNAT su 2627, regole in DOCKER-USER. Raggiungibile dalla subnet LXC.

## Firewall
- Dichiarato: INPUT e FORWARD policy ACCEPT con DROP per porte specifiche; DNAT in PREROUTING di 80/443 e 8089, 8443, 51141, 30000-30100, 2627. Backup `iptables-backup-2026-05-30.rules`; poi 443 riaperta a tutti.
- **Verificato 26/10:** il traffico DNAT attraversa **FORWARD** (policy ACCEPT), non INPUT: i DROP in INPUT non proteggono le porte DNAT. **8443 raggiungibile via DNAT.** Il firewall live **differisce da `rules.v4`** (lo sviluppatore potrebbe essere al lavoro): non eseguire `netfilter-persistent save`.
- IPv6: `ip6tables` INPUT ACCEPT (21/10); proxy LXD in ascolto su `*` anche v6. Configurazione completa non raccolta, nessun test esterno v6.
- Filtro nginx su `Accept-Language: it-IT` (dichiarato).
- Piano origine solo Cloudflare: tabella nft `inet stv_cf_origin` in forward (vedi `todo-findings-critici.md`, CF2). Non applicata.

## DNS e Cloudflare (studiotecnicoverro.it)
- NS dal 25/10: `chance.ns.cloudflare.com`, `jessica.ns.cloudflare.com` (zona active, Free, account Verronet; propagazione confermata da Pietro il 26/10). Prima: `dns200/ns200.anycast.me`. 17 record. DNSSEC off. Zona OVH tenuta come riferimento/rollback (da verificare).
- `intranet` e `intranetbeta` → 57.131.13.35, entrambi proxied (API 25/10). Apex e `www` → 192.0.2.1 proxied con Redirect Rule verso `https://www.ingegneriaesicurezzasrl.it` (301, query preservata, path no). Nessun AAAA (l'AAAA di `intranetbeta`, eliminato il 25/10, puntava al VPS stesso). Posta M365 (MX apex), PEC `mx.ig-trustmail.com`, DMARC assente, DKIM M365 non presente (da verificare in M365).
- Impostazioni zona (API 25/10): SSL `full`, TLS min 1.0, Always HTTPS off, HSTS off, AOP off, nessuna WAF custom/rate limit.
- L'IP resta pubblico nell'SPF: **l'allowlist IP non basta** (un altro account Cloudflare può fare proxy verso l'origine) → AOP con cert custom o Tunnel. **L'origine non è ancora chiusa.**
- Stesso account: zona `ingegneriaesicurezzasrl.it` (Free, active), sito = Worker `ingegneria-e-sicurezza` (custom domain apex e `www`).

## Problemi segnalati dallo sviluppatore
- Tentativi di file injection su jQuery-File-Upload 9.12.5 (`gestionale/assets/plugins/jQuery-File-Upload-9.12.5/server/php/index.php`).
- Ispezioni manuali di `/gestionale/` da IP cinesi con `Accept-Language` modificato.
- Conflitti di subnet Docker/LXD dopo aggiornamenti (rimedio manuale documentato).
- Il gestionale richiede PHP < 8.

## Altro (da memoria progetto)
- Backup OVH giornaliero alle 13, premium 7 copie. Piano locale Proxmox → NFS QNAP (solo archivio documentale e DB). Non verificato che i backup coprano i nuovi container.
- Cloudflare Free in produzione dal 25/10 come protezione aggiuntiva; origine non ancora chiusa.
