# Schema DB del gestionale (solo DDL, snapshot `db` 153dad2a del 21/10/2026)

Nessun dato né segreto. VERIFICATO = output di comando sul DDL; INFERENZA = dedotto, non provato.

## Come è stato estratto
- Pietro (root, CT 108): `restic dump 153dad2a /stv-db-mysql-all-databases.sql`, filtrato con `grep -v` sulle righe `INSERT INTO|REPLACE INTO|LOCK TABLES|UNLOCK TABLES|ALTER TABLE ... DISABLE KEYS`. Restavano 2 righe `INSERT IGNORE` su `innodb_index_stats`/`innodb_table_stats` (statistiche interne di MySQL, nessun dato applicativo), rimosse in un secondo filtro.
- Risultato: 9.708 righe, circa 745 KB, 0 righe di INSERT/REPLACE, footer `-- Dump completed`. Copiato sul CT 109 in `/work/ddl/stv-ddl.sql` (sha256 `1766eb7c…58f59f5`). Copie su CT 108 (`/root/stv-ddl*.sql`) da cancellare dopo l'uso.
- Il dump contiene 3 schemi: `mysql` (30 tabelle di sistema), `ehlynhwstvintra` (102 tabelle), `gestionale` (86 tabelle).

## Fatti verificati
| Tema | Fatto |
|---|---|
| Database in produzione | `home.php` e `scadenze_cron.php` definiscono `ENVIRONMENT='production'`; `config/production/database.php` punta a **`ehlynhwstvintra`**. `config/database.php` (base) punta a `gestionale`, ma è usato solo se l'ambiente non è impostato. `development` punta anch'esso a `ehlynhwstvintra`. |
| `gestionale` | Copia **vecchia e parziale**: mancano 16 tabelle presenti in `ehlynhwstvintra` (`anag_aziende`, tutto il modulo `cons_commesse_*`, `cbo_commesse_documenti`, `rel_nomine_pagine`, `segnalazioni_scadenze_abilitazioni`, `segnalazioni_scadenze_documenti`); nessuna tabella solo sua. 75 tabelle identiche, 11 con definizione diversa. Spiega le viste non valide (rimandano a tabelle assenti, es. `anag_aziende`). Non è usato dal codice in produzione (secondo la config); uso reale da confermare nei log. |
| Dimensione schema vivo | 102 tabelle InnoDB: `cbo_` 24, `cons_` 42, `anag_` 8, `rel_` 15, `segnalazioni_` 4, `ticket_` 3, `user_` 3, più `ci_sessions`, `ateco_2025`, `tmp_report_giudizi`. 39 chiavi esterne. 2 tabelle senza PK (`ateco_2025`, `tmp_report_giudizi`). |
| Charset | Mix: 78 tabelle `utf8mb3`, 18 `utf8mb4`, 6 `latin1`. Rischio di incoerenze di collation nella migrazione. |
| Logica nel DB | 0 trigger, 0 stored procedure/function, 0 event. Tutta la logica sta nei controller; il DB ha solo viste (46 per schema) per scadenze e conteggi. |
| Viste | Definer unico `ehlynhwstvintra@localhost`. Le viste di scadenze (corsi, DPI, giudizi di idoneità, nomine, contratti, documenti) sono la logica dello scadenzario. |
| Credenziali utente | `anag_utenti.password` e `password2`: `varchar(45)`. `anag_professionisti.password_accesso_aziende`: `varchar(255)`. `user_access_tempt` traccia tentativi e recupero password. 45 caratteri sono compatibili con MD5 esadecimale (32), non con bcrypt (60): **coerente con l'inferenza MD5**, formato reale dei valori NON verificato. `password_accesso_aziende` potrebbe contenere password in chiaro o cifrate: da verificare sul codice. |
| Dati personali | Codice fiscale, data/luogo di nascita, sesso, indirizzo, telefono, email in `anag_dipendenti`, `anag_professionisti`, `anag_rappresentanti_legali`, `cons_docenti`, `cons_registro_partecipanti_corsi`, `cons_corsi_validazioni`, `cons_commesse_lavoratori`. Tutti `varchar`/`date`: nessuna evidenza di cifratura a livello colonna (le lunghezze `varchar(245)` non permettono di escluderla; da verificare sul codice). |
| Categorie particolari (art. 9) | **Presenti nello schema**: `cons_giudizi_idoneita`, `cons_infortuni`, `rel_protocollo_sanitario`, `cbo_accertamenti_sanitari` (riferimento), `sorveglianza_sanitaria` su aziende, `medico_*` in commesse; i documenti collegano `id_giudizio_idoneita` e `id_infortunio`. Il contenuto delle tabelle non è stato letto: la presenza di dati sanitari reali è la conclusione ragionevole ma non provata sui valori. |
| Sessioni e log | `ci_sessions` (con `user_data` text, sessioni su DB), `user_logs` (user_id, session_id, ip, user_agent, `payload` text) e `user_logs_actions`: base per misurare l'uso reale e per capire cosa finisce nei payload. |
| Tabelle `tmp_` | `tmp_report_giudizi` senza PK in produzione: tabella di appoggio per il report dei giudizi (il report non è puro). |

## Aperti
- Confermare con i log o col codice che nulla usa più `gestionale`; poi decidere su dismissione (chiesto allo sviluppatore il 21/10).
- Formato reale degli hash (da verificare solo sulla lunghezza e sul charset, senza stampare valori).
- Leggere `user_logs.payload` come struttura (non contenuti): può contenere dati personali o password.
- Righe per tabella e uso reale: richiede il DB vivo, non il DDL (query di sola lettura da fare con Pietro/utente dedicato).
