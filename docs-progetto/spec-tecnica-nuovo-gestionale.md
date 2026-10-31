# Specifica tecnica del nuovo gestionale — puntatore e stato

Documento: "Specifica tecnica — Nuovo gestionale STV" (Claude Docs, bozza v0.2 del 25/10/2026): https://claude.ai/artifact/QCwMiLTDbyLYb2BdQdu6rs

Stato: BOZZA di requisiti e architettura, 12 sezioni. Nessuna attività di sviluppo avviata. Nessun segreto.

## Cosa contiene
1 scopo e stato del legacy; 2 principi e registro decisioni D1-D7; 3 requisiti funzionali per modulo (dall'uso misurato); 4 requisiti non funzionali (valori = ipotesi); 5 architettura logica (monolite modulare, 4 adattatori, disegno); 6 profili A server unico / B AWS economico / C AWS alta affidabilità; 7 modello dati e migrazione; 8 sicurezza applicativa (finding legacy → controlli); 9 processo di sviluppo e uso di Claude Code; 10 lavoro collaborativo con Claude in un team di due (cosa si condivide e dove, flusso, regole anti-conflitto, GitLab CI); 11 fasi 0-5; 12 rischi e questioni aperte.

## Decisioni prese (Pietro, 25/10/2026)
- Nuovo sviluppo su GitLab (istanza da definire: gitlab.com o self-managed). Resta in vigore GitHub per codice e script del lavoro di messa in sicurezza del legacy, salvo diversa indicazione di Pietro.
- Staging su laboratorio Proxmox di Pietro, dati sintetici, rete separata.
- Fornitore PEC: Intesi Group (MX di pec.studiotecnicoverro.it verso ig-trustmail.com, verificato via API Cloudflare il 25/10). Dalla guida Intesi: SMTP smtp.ig-trustmail.com:465 SSL/TLS, IMAP imap.ig-trustmail.com:993 SSL/TLS, password normale della casella; limiti di invio e password applicative non indicati.
- Modalità di lavoro in team: una sessione Claude per persona, condivisione solo via repository (CLAUDE.md, .claude/skills, agents, commands, settings.json, .mcp.json senza segreti); licenza per persona.

## Decisioni aperte (registro D1-D7)
D1 stack (Django vs Laravel, standby; ipotesi Claude: Django, controargomento: lo sviluppatore conosce PHP); D2 DB (ipotesi: PostgreSQL per RLS); D3 frontend server-rendered; D4 cifratura AEAD con chiave per file; D5 auth locale + MFA; D6 profilo hosting (titolare); D7 ingresso tunnel vs ALB.

## Da verificare / riallineare
- GitLab: gitlab.com o self-managed, piano e funzioni di approvazione obbligatoria/ambienti protetti.
- Seat Claude per lo sviluppatore; impostazioni gestite dalla console claude.ai dipendono dal piano (non verificato).
- Integrazione Claude Code con GitLab CI/CD: beta, mantenuta da GitLab; non attivarla nelle fasi 0-1.
- Cifre di costo del documento unico per il titolare (Rev01, sezione 7) ancora quelle della prima stima (490/820 €/anno): la specifica usa le stime riviste di `stime-costi-aws-2026-10-23.md`.
- Numerazione delle fasi da riconciliare con il documento di progetto; ripartizione delle giornate oltre le fasi 0-1 non fatta.
- Dipende dall'accordo dello sviluppatore sull'uso di Claude Code e dalla proprietà del codice legacy (non verificati).
- Cosa condividere con lo sviluppatore dello spazio di lavoro sul legacy (finding sfruttabili): da decidere con la mail ai finding.
