# Misura d'uso e controllo password — risultati del 2026-10-21

Fonte: query di `claude/query-misura-uso.md` lanciate su CT109 (MariaDB `usage_ct109`) dopo il caricamento di 5 tabelle di `ehlynhwstvintra` dallo snapshot restic `db` 153dad2a (dump delle 16:00 UTC del 21/10, cioè 18:00 ora di Roma). Stato dei dati: VERIFICATO (output di query), salvo dove indicato come inferenza. Solo conteggi, nessun valore personale riportato.

**Attenzione:** CT109 ora contiene dati personali reali (nomi, email, `password2` in chiaro, payload dei log). Nessun egress, nessun listener di rete, `skip-networking`. Da distruggere a fine analisi (insieme ai pacchetti di appoggio su CT108: `/root/ct109debs`, `/root/ct109.status`).

## Copertura
- `user_logs`: 110.919 righe dal 2025-11-25 al 2026-10-21 (11 mesi; prima del 25/11/2025 non c'è storico). 46 `user_id` distinti. Richieste per mese 9–15 mila (agosto 1,7 mila, ottobre parziale).
- `cons_log_attivita`: 33.638 righe dal 2019-02-07; 16–30 utenti, 40–64 aziende al mese nel 2025-26 (agosto minimo).
- `anag_utenti`: 173 righe; `cbo_classi`: 5.

## Uso per modulo (richieste / utenti / giorni attivi, 25/11/2025–21/10/2026)
- Nucleo: `aziende` 44.095 / 6 / 245; `dashboard` 9.724 / 46 / 275; `ajax_documenti` 6.181 / 30 / 215; `ajax_azienda` 5.504 / 5 / 242; `ajax_anagrafica_lavoratori` 5.181 / 20 / 205; `ajax_corsi_lavoratori` 4.705 / 20 / 174; `upload` 4.522 / 17 / 203; `download` 3.415 / 41 / 202; `scheda_azienda` 3.353 / 43 / 199; `ajax_giudizi_idoneita` 2.033 / 10 / 102; `gestione_scadenze` 2.508 / 5 / 108; `segnalazioni_scadenze` 1.967 / 6 / 61; `report` 478 / 15 / 159.
- Uso intermittente: `registro_corsi` 3.442 / 4 / 55; `commesse` 2.034 / 4 / 15; `download_massivo` 566 / 2 / 9; `template` 230 / 3 / 17 (ultimo 22/06/2026); `ajax_infortuni` 171 / 7 / 6; `ajax_reparti` 210 / 4 / 16; `ajax_rls` 56 / 4 / 21.
- Uso marginale o nullo: `ajax_automezzi` 24 / 5 / 8 (ultimo 22/07/2026); `ajax_commesse_attrezzature` 10 / 1 / 3; `ajax_dpi_consegnati` 7 / 3 / 4 (ultimo 01/06/2026); `ajax_professionisti` 4 / 2 / 3; `ajax_attrezzature` 2 / 2 / 2 (ultimo 03/04/2026); `ajax_turni_reparti` 1 / 1 / 1 (07/02/2026); `ajax_apprestamenti` 1 / 1 / 1 (27/01/2026). Nessun modulo ha zero righe: per la regola "nessuna azione negli ultimi 12 mesi" non ne esce nessuno; serve una soglia (proposta: meno di 10 giorni attivi in 11 mesi = candidato a rinvio).
- Caveat: le richieste `ajax_*` includono caricamenti automatici delle schede, non solo azioni volontarie; il conteggio è un limite superiore dell'uso.

## Chi usa il sistema (INFERENZA, non verificata con intervista)
- 6 utenti su `aziende`/`ajax_azienda` e 5 su `gestione_scadenze`: probabile nucleo operativo dello studio (5–6 persone). 41–46 utenti su `dashboard`, `download`, `scheda_azienda`: probabile utenza cliente/consultazione. Q2 per profilo non è utilizzabile: tutte le righe hanno `id_professionista` valorizzato e quindi il join con `anag_utenti.id_classe` non discrimina; il mapping `user_id` → tabella utenti è da chiarire nel codice.
- Concorrenza reale: 16–29 utenti distinti al mese; 3–5 concorrenti dichiarati da Pietro (plausibile).

## Scritture più frequenti (ultimi 11 mesi)
Caricamento documenti dipendenti (≈3.800 richieste window+upload), corsi lavoratori (≈3.000), giudizi di idoneità (≈1.500), modifica/aggiunta dipendente (≈1.800), aggiunta corsi (1.016), nomine lavoratori (≈580), registro corsi `salva_corso` 262 e `crea_registro` 141 (2–3 utenti), cancellazione attività dashboard 189 (1 utente).

## Scadenzario (conferma)
- Invio manuale: `cron/send_scadenze_azienda` 114 volte, 2 utenti, dal 02/02/2026 al 07/07/2026; `segnalazioni_scadenze/inviate` consultata 193 volte fino al 16/10/2026. Nessun invio registrato dopo il 07/07/2026 (limite: il log potrebbe non coprire invii da altri canali).
- `cron/aggiorna_scadenze` registrato 273 volte dal 29/01/2026 al 20/10/2026 (il cron giornaliero; prima del 29/01 non risulta nel log).
- `segnalazioni_scadenze/da_firmare` usato solo tra 11/06 e 17/07/2026.

## Password (confluito nel finding C4)
- `anag_utenti`: 173 utenti, 173 con hash di 32 caratteri (MD5 per formato), **171 con `password2` valorizzata**. (Che `password2` contenga la password in chiaro è dedotto dal codice di `ajax_utility`; i valori non sono stati letti.)
- `user_logs.payload` contiene la stringa `password` in: `ajax_utility/add_nuovo_account` 8 righe, `accesso_professionista/index` 7, `ajax_utility/window_reset_password` 3, `ajax_utility/reset_password` 2 (20 righe in tutto). `accesso_professionista/index` non è nell'elenco di esclusione del hook, quindi anche il login dei professionisti scrive la password in chiaro nel log (inferenza coerente con il codice; contenuto non letto).
- Conseguenza: le password in chiaro sono in DB, in `user_logs`, nel dump `db` e nei backup restic. La correzione dell'applicazione e la rotazione delle password vanno pianificate; fino ad allora chi legge il backup ha le credenziali.
