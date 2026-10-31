# Query di misura d'uso e controlli A12/A13 (sola lettura, solo conteggi)

Stato: PREPARATE il 2026-10-21, NON ancora eseguite. Le esegue Pietro come root sul DB di produzione `ehlynhwstvintra`. Nessuna query stampa `payload`, `note`, nomi o email: l'output contiene solo conteggi, date e id numerici. Prima di incollare l'output in chat, controllare che non contenga altro.

Come: `mysql -u root -p ehlynhwstvintra` (o l'accesso già in uso), sessione `--read-only` se disponibile. Salvare l'output in un file locale, non nel repository.

Fatti dal codice (verificato): il hook `loghook` scrive in `user_logs` una riga per ogni richiesta (`action` = `controller/metodo`), con `user_id`, `id_professionista` e `payload`; `ip_address` e `user_agent` sono vuoti. Esclusi: `accesso/index`, `home/index`. `cons_log_attivita` è il registro attività per azienda (data, azienda, utente). Il periodo coperto dalla tabella va misurato (Q0): il campo `timestamp` ha default `CURRENT_TIMESTAMP`.

## Q0 — copertura dei log
```sql
SELECT MIN(`timestamp`) primo, MAX(`timestamp`) ultimo, COUNT(*) righe, COUNT(DISTINCT user_id) utenti FROM user_logs;
```

## Q1 — uso per modulo (controller), ultimi 12 mesi
```sql
SELECT SUBSTRING_INDEX(action,'/',1) modulo, COUNT(*) richieste, COUNT(DISTINCT user_id) utenti,
       COUNT(DISTINCT DATE(`timestamp`)) giorni_attivi, MAX(`timestamp`) ultimo_uso
FROM user_logs WHERE `timestamp` >= NOW() - INTERVAL 12 MONTH
GROUP BY 1 ORDER BY richieste DESC;
```
Lettura: modulo senza righe negli ultimi 12 mesi = non entra in V1 (regola dell'Appendice A). Attenzione: le richieste `ajax_*` contano anche i caricamenti automatici, non solo azioni volontarie.

## Q2 — profili che usano il sistema, per mese (ultimi 12 mesi)
```sql
SELECT DATE_FORMAT(l.`timestamp`,'%Y-%m') mese,
       CASE WHEN l.id_professionista IS NOT NULL THEN 'professionista' ELSE CONCAT('classe_', u.id_classe) END profilo,
       COUNT(*) richieste, COUNT(DISTINCT l.user_id) utenti
FROM user_logs l LEFT JOIN anag_utenti u ON u.id = l.user_id
WHERE l.`timestamp` >= NOW() - INTERVAL 12 MONTH
GROUP BY 1,2 ORDER BY 1,2;
```
Nota: l'associazione `user_id` → `anag_utenti.id` è un'ipotesi (la sessione memorizza `id`); se i profili risultano tutti NULL, l'ipotesi è falsa.

## Q3 — azioni più frequenti di scrittura (candidati a "funzioni davvero usate")
```sql
SELECT action, COUNT(*) n, COUNT(DISTINCT user_id) utenti, MAX(`timestamp`) ultimo
FROM user_logs
WHERE `timestamp` >= NOW() - INTERVAL 12 MONTH
  AND (action REGEXP '(add|nuov|salva|modifica|elimina|cancella|invia|send|upload|genera|crea)')
GROUP BY action ORDER BY n DESC LIMIT 60;
```

## Q4 — attività registrate per mese e per utente (senza note)
```sql
SELECT DATE_FORMAT(data_attivita,'%Y-%m') mese, COUNT(*) attivita, COUNT(DISTINCT id_utente) utenti, COUNT(DISTINCT id_azienda) aziende
FROM cons_log_attivita WHERE data_attivita >= CURDATE() - INTERVAL 24 MONTH
GROUP BY 1 ORDER BY 1;
```

## Q5 — invio scadenze (conferma che parte solo a mano)
```sql
SELECT action, COUNT(*) n, MIN(`timestamp`) primo, MAX(`timestamp`) ultimo
FROM user_logs WHERE action LIKE '%scadenz%' OR action LIKE '%invio%' OR action LIKE '%pec%'
GROUP BY action ORDER BY n DESC LIMIT 30;
```

## A12 — `password2` è popolata? (solo conteggio, nessun valore)
```sql
SELECT COUNT(*) utenti, SUM(password2 IS NOT NULL AND password2<>'') con_password2,
       SUM(password IS NOT NULL AND LENGTH(password)=32) con_md5_32
FROM anag_utenti;
```

## A13 — password nei log (solo conteggio, nessun valore)
```sql
SELECT action, COUNT(*) righe_con_password
FROM user_logs WHERE payload LIKE '%password%'
GROUP BY action ORDER BY righe_con_password DESC LIMIT 20;
```
Se Q-A13 restituisce righe: i backup (restic, dump `153dad2a`) contengono password in chiaro; la rotazione delle password va pianificata dopo la correzione dell'applicazione.
