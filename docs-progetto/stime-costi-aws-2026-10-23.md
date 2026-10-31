# Stime di costo AWS — proposta al titolare (23/10/2026)

Stato: STIMA, non preventivo. Nessun account AWS aperto, nulla costruito. Le cifre stanno nella sezione 7 del documento unico per il titolare (`2026.10.23_STV_Gestionale_stato_sicurezza_proposta_revamping_Rev01`, Appendice B.3). Nessun segreto.

**ATTENZIONE: la sezione «Revisione 23/10/2026 (sera)» in fondo aggiorna e, dove in conflitto (ingresso, database, backup, scope dei costi), sostituisce le sezioni «Architettura ipotizzata» e «Costi indicativi» qui sotto.**

## Decisione di Pietro (23/10, sera)
- Integrare nel documento unico la proposta di spostare tutto su AWS, applicativo distribuito su tecnologie e zone diverse.
- Presentarla come costo maggiore con vantaggio maggiore rispetto alla soluzione monolitica (server unico), con confronto in cui AWS tende a prevalere, costi indicativi di oggi e futuri, disegno dell'architettura, cos'è AWS in brevissimo.
- Rimosso dal documento il riferimento al numero di protocollo.
- Scelte già di Pietro (memoria progetto): fck-nat come NAT, SES per la posta applicativa, macchine piccole e approccio conservativo sui costi, copia fuori da AWS su homelab/QNAP (non deciso).

## Architettura ipotizzata (non costruita) — prima versione, vedi revisione
Regione Milano (eu-south-1, da confermare; Francoforte alternativa). Cloudflare davanti con tunnel (`cloudflared` sulle istanze, nessun IP pubblico; richiede delega dei nameserver). Due piccole istanze (t4g.small) in due zone, database RDS MySQL Multi-AZ (t4g.micro), documenti su S3 cifrato con versioni, chiavi/segreti in servizi gestiti, SES, CloudTrail/CloudWatch, fck-nat in una sola zona, copia notturna su QNAP, controllo con Checkmk. Variante senza tunnel: ALB (+circa 28 €/mese).

## Costi indicativi (€ al mese, senza IVA, cambio 1,1537 USD/EUR del 16/09/2026) — prima versione, vedi revisione

| Voce | Oggi: server unico | AWS una zona | AWS due zone |
| --- | --- | --- | --- |
| Server del programma | 12,5 (tutto compreso) | 14 | 28 |
| Database gestito | incluso | 14 | 27 |
| Rete e uscita (fck-nat, IPv4) | incluso | 7 | 7 |
| Archivio documenti, chiavi, posta | incluso | 3 | 3 |
| Registri, allarmi, copie | incluso | 3 | 3 |
| Totale al mese | circa 12,5 | circa 41 | circa 68 |
| Totale all'anno | 150 | circa 490 | circa 820 |
| Intervallo (±30%) | non applicabile | 340–630 | 570–1.060 |
| Multiplo di oggi | 1× | circa 3,2× | circa 5,5× |

Differenza tra due zone e una zona: circa 330 €/anno (controargomento principale alla seconda zona per pochi utenti; la configurazione scritta come codice permette di attivarla dopo).

## Fonti e stato (letto il 23/10/2026)

| Voce | Valore usato | Fonte letta | Stato |
| --- | --- | --- | --- |
| Cambio | 1,1537 USD/EUR (16/09/2026) | Banca d'Italia | confermato, non è il cambio di oggi |
| EC2 Milano | t4g.small 0,0192 USD/h; t4g.micro 0,0096; t4g.medium 0,0384 | aws-pricing.com (aggregatore) | non verificato su listino AWS (poi riletto dal calculator, vedi revisione) |
| RDS MySQL Milano | db.t4g.micro circa 13 USD/mese (istanza, una zona) | bytebase.com (aggregatore) | prezzo non verificato; T4g disponibile a Milano confermato (AWS what's new) |
| Multi-AZ | assunto 2× istanza e storage | pagina AWS Multi-AZ: standby sincrono, failover 1–2 minuti, nessun prezzo | raddoppio = ipotesi |
| IPv4 pubblico | 0,005 USD/h dal 01/02/2024 | AWS News Blog | confermato |
| ALB | 0,0225 USD/h + 0,008 USD/LCU-h (us-east-1); Milano stimata +15% | pagina AWS ELB (solo us-east-1) | stima |
| fck-nat | t4g.nano 0,0042 USD/h (regione non indicata), stimato 0,0048; 5 Gbps burst; HA non immune | GitHub AndrewGuenther/fck-nat | confermato dal progetto; prezzo regionale stima |
| Cloudflare Tunnel | disponibile su tutti i piani; più repliche cloudflared = HA | developers.cloudflare.com; blog Cloudflare | confermato; limiti Free non riportati |
| SES | 0,10 USD ogni 1.000 email | pagina AWS SES | confermato |
| Crediti nuovi account | fino a 200 USD, piano Free fino a 6 mesi | pagina AWS RDS Free Tier | confermato per RDS; applicabilità non verificata |
| Voci senza listino | EBS gp3 20 GB circa 2 USD/istanza; RDS 20 GB circa 2,8 USD; S3 circa 1; chiavi circa 1,5; registri/allarmi circa 3; copie circa 1; SES circa 0,5 | stima di Claude | non verificato |
| Costo attuale | 150 € + IVA/anno | dichiarato da Pietro | comando non registrato |

Le pagine ufficiali AWS (EC2, RDS, S3, ELB) non mostrano i prezzi regionali nel testo letto (tabelle espandibili). Prima di decidere: rifare il conto con AWS Pricing Calculator (fase 1).

## Aperto (prima versione)
- Regione (Milano o Francoforte), tunnel Cloudflare o ALB, delega NS a Cloudflare (decisione di Pietro, regola 7).
- Sconti per impegno annuale non valutati (parzialmente valutati nella revisione); costo del lavoro di costruzione dell'infrastruttura come codice non stimato.
- Chi sostiene il costo ricorrente e il lavoro (domanda del titolare).
- Il codice di calcolo (`cost.py`, `gen_widget.py`, `fig_aws.py`, `build.py`) va salvato su GitHub (regola 11): non ancora fatto.

---

# Revisione 23/10/2026 (sera) — assunzioni emerse in chat con Pietro

Stato: STIMA/PROGETTO. Nulla costruito, nessun account AWS, nessuna modifica eseguita (quindi nulla in change-log). Questa sezione AGGIORNA la precedente: dove c'è conflitto prevale questa, perché nasce da decisioni/posizioni espresse da Pietro in chat dopo la stesura. Etichette: [V] verificato su fonte primaria letta; [A] assunzione/ipotesi; [P] pianificato; [D] valutato, non deciso; [N] non verificato. Nessun segreto.

## 1. Cosa sostituisce cosa
| Tema | Versione sopra | Versione aggiornata | Stato |
| --- | --- | --- | --- |
| Ingresso | Cloudflare Tunnel (cloudflared), delega NS | Versione intermedia di stasera: ALB + WAF, Cloudflare DNS-only. SUPERATA dalla sezione 8 (Tier B): NS su Cloudflare deciso, ingresso con tunnel | superata, vedi §8 |
| Cloudflare Free | davanti al nuovo sistema | solo fronte temporaneo del VPS legacy dopo migrazione NS di studiotecnicoverro.it | [A] |
| Database | RDS MySQL Multi-AZ t4g.micro | RDS PostgreSQL Multi-AZ db.t4g.small (conservativo); MySQL vs PostgreSQL NON deciso (legacy è MySQL 8; il DB del revamping non è definito) | [D] |
| Backup | copia notturna QNAP | account AWS di backup separato (eu-central-1) con Object Lock compliance, vault lock AWS Backup, SCP; copia cross-region; bucket per dump logici; chiave KMS customer-managed condivisa con l'account di backup; terza copia su homelab | [P], costo del 2° account non ancora quantificato |
| Posta | SES | SES per posta ordinaria (alternativa: Microsoft Graph con mailbox condivisa a permessi RBAC + autenticazione a certificato); PEC via casella PEC esistente (SMTPS/IMAP; le ricevute hanno valore legale) | [D]; fornitore PEC NON identificato [N] |
| NAT | fck-nat | fck-nat su t4g.nano, AMI propria (Packer) consigliata; il NAT non filtra l'uscita (etichetta «uscita controllata» nel disegno era sbagliata); proxy con allow-list opzionale | scelta di Pietro; Sophos XGS/pfSense scartati |

## 2. Architettura assunta (disegno: `2026.10.21_STV_Architettura_logica_AWS_Rev00`, da portare a Rev01)
- Regione Milano eu-south-1 (Francoforte per le copie). Multi-AZ = due zone nella stessa regione (distanza «significativa», non oltre 100 km, nessun minimo pubblicato [N]).
- 2 nodi applicativi t4g.small (Django/gunicorn/nginx; worker sugli stessi nodi) in subnet private; ALB+WAF davanti.
- S3 documenti: versioning, SSE-KMS + cifratura applicativa, gateway endpoint VPC. Il legacy cifra con AES-256-CBC e passphrase letterale in config.php riga 28 (C1): nel nuovo sistema la chiave va in KMS/Secrets Manager.
- KMS CMK + Secrets Manager; CloudTrail, CloudWatch, GuardDuty, Config.
- Accesso amministrativo: SSM Session Manager + SSO/MFA. IaC: Terraform + GitHub Actions OIDC. Staging in account/VPC separato.
- Backup fuori AWS: pull-based (restic) da CT Proxmox dedicato di Pietro, IAM a sola lettura o Roles Anywhere, destinazione append-only/snapshot. QNAP all'88% di 6,8 TB senza quota: non adatto senza spazio dedicato [dichiarato da Pietro]. Costo vivo vicino a zero, escluso uscita dati S3 (da stimare: ~14 GB documenti + DB).
- Escrow chiave master offline, divisa tra 2 persone (le chiavi KMS sono regionali; senza escrow i documenti non sono decifrabili fuori da AWS).
- Lacune del disegno Rev00 riconosciute: DB con snapshot e replica backup continua opzionale, bucket dump con Object Lock nell'account di backup, chiave KMS condivisa. Solo gli snapshot erano disegnati.

## 3. Costi (USD, listino AWS Pricing Calculator, Milano, letto da Chrome il 23/10/2026)
- [V] Fonte: JSON del calculator `calculator.aws/pricing/2.0/meteredUnitMaps/` per EC2 (Linux on-demand, EU Milan) e RDS PostgreSQL (Single/Multi-AZ, OnDemand/Reserved). Sostituisce gli aggregatori usati sopra per EC2/RDS.
- [V] Subtotale verificato ≈ 113 USD/mese su ≈ 170 USD/mese on-demand complessivi di scenario HA con macchine piccole (ALB, WAF, 2 EC2, RDS Multi-AZ). Il resto (≈57 USD) è [N]: S3, EBS, IPv4 regionale, KMS, Secrets Manager, CloudWatch, GuardDuty, AWS Backup, trasferimento cross-region, free-tier egress 100 GB, NAT Gateway (non usato: fck-nat).
- [V] Scenari con riserva (RDS Reserved Instances): ≈ 123–148 USD/mese. Il dettaglio per riga di questi calcoli NON è stato conservato nel registro: va rieseguito e salvato in fase 1 (query riproducibili).
- [A] Intervallo realistico HA: ~160–200 USD/mese (circa 140–175 €/mese al cambio 1,1537). NON confrontabile con i 68 €/mese «due zone» sopra: quella tabella non includeva ALB, WAF, GuardDuty, Config, account di backup e usava t4g.micro. Differenza = scope diverso (alta affidabilità completa per un sistema critico), non solo prezzi.
- [A] Sconto Compute Savings Plans: coprono EC2, non RDS (RDS ha le Reserved Instances). Database Savings Plans: dataset visto, NON letto, da verificare in fase 1 [N].
- Cambio: 1,1537 USD/EUR (16/09/2026), non quello di oggi.

## 4. Confronto provider (stato di confidenza)
| Provider | Ordine di grandezza HA | Note | Stato |
| --- | --- | --- | --- |
| AWS Milano | ~160–200 USD/mese | PostgreSQL gestito, Multi-AZ, Object Lock, regione italiana | [V] parziale (calculator) |
| OVH | ~235–245 €/mese | prezzi dalla pagina ufficiale; nessuna regione italiana in pagina | [V] |
| Scaleway | 80–230 € | | [N] range |
| Azure / GCP | non stimati con cura | | bassa confidenza |
| Hetzner | — | nessun DB gestito; rincari 2026; disponibilità CX/CAX incerta | [N] |
| Aruba Cloud | ~55–110 € | solo DBaaS MySQL/SQL Server, backup 7 giorni, Single AZ, SLA debole; Pietro diffidente per esperienza. Candidato al più come destinazione di backup se Object Lock confermato | [N] prezzi non verificati su cloud.it |
Posizione: restare su un solo provider (più regioni) costa meno in uscita dati e complessità; la diversificazione reale è la copia su homelab. Uscita S3 verso esterno: costo per GB in uscita da stimare [N].

## 5. DNS e domini
- ingegneriaesicurezzasrl.it: vetrina su Cloudflare Pages Free, NS su Cloudflare, posta M365 parziale. Resta dov'è.
- studiotecnicoverro.it: dominio storico, M365 principale, hostname del gestionale; zona Cloudflare pronta, NS ancora da migrare. DECISO da Pietro (23/10, sera): la zona NS passa a Cloudflare. Hostname del nuovo gestionale da decidere una sola volta.
- Pre-flight migrazione NS (offerto, non eseguito): parità record, rimozione DS DNSSEC, MX/autodiscover in DNS-only, TTL, registrar lock, MFA hardware, export zona. Limiti Cloudflare Free dal ricordo (porte non-443, ~100 MB/~100 s) [N].

## 6. Ipotesi di continuità (da validare col titolare)
- RTO 4 h in orario lavorativo, RPO 1 h [A]. Perdita regione: 3–6 h solo dopo prova di ripristino ripetuta; 1–2 giorni la prima volta; perdita del provider: giorni [A, stime di Claude, non misurate].
- Con sorgenti e backup disponibili il riavvio in poche ore è plausibile ma NON dimostrato: serve un drill documentato.
- PITR con replica cross-region: opzionale.

## 7. Aperto (aggiunge a quanto sopra)
1. Costo del 2° account di backup, copia cross-region, ALB, WAF, GuardDuty, Config: da calcolare con il calculator e salvare le query.
2. PostgreSQL vs MySQL (dipende dalla scelta del revamping).
3. Fornitore e limiti della PEC; sorgente di pec-mailer con credenziali oscurate.
4. Prezzi non letti: S3, EBS, IPv4 regionale, KMS, Secrets Manager, CloudWatch, GuardDuty, Backup, trasferimento, Route 53, Database Savings Plans, Aruba/Seeweb.
5. Delega NS a Cloudflare: DECISA da Pietro (23/10, sera). Tunnel vs ALB: vedi §8 (Tier B propone il tunnel; Pietro non ha ancora confermato l'ingresso).
6. Diagramma Rev01 con le tre correzioni (non fatto).
7. Documento unico Rev01 (§7) ha ancora le cifre della tabella «Costi indicativi» sopra: va riallineato se Pietro conferma lo scope HA completo.

## 8. Tier B — configurazione intermedia proposta (23/10/2026, sera)
Stato: PROPOSTA, [D] non decisa. Nasce dalla richiesta di Pietro di una via di mezzo tra i ~68 €/mese della prima stima (scope ridotto) e i ~160–200 USD/mese della configurazione HA completa. Va validata col titolare sull'RTO.

Premessa: con RTO 4 h in orario lavorativo [A] il failover Multi-AZ da 1–2 minuti non è necessario; un restore da snapshot/PITR sta nella soglia (tempo di restore non misurato [N]). Se il titolare chiede «mai fermi», la risposta è Multi-AZ (Tier A) e il costo della riga DB almeno raddoppia.

### Differenze rispetto a Tier A (HA completa)
| Componente | Tier A (HA) | Tier B | Rischio accettato |
| --- | --- | --- | --- |
| Database | RDS Multi-AZ | RDS Single-AZ + PITR + copia snapshot cross-region | perdita zona/istanza = fermo di decine di minuti o più (stima, non misurata); perdita dati fino all'ultimo punto PITR (minuti) |
| App | 2 nodi in due zone | 1 nodo in Auto Scaling Group min=1/max=1 su due zone (self-healing) | fermo di qualche minuto a ogni sostituzione/deploy |
| Compliance | + AWS Config | CloudTrail + GuardDuty + allarmi base; Config rinviato | meno inventario/drift detection |
| Ingresso | ALB + WAF AWS | tunnel Cloudflare (vedi sotto) | dipendenza da Cloudflare; TLS terminato da Cloudflare |
| Backup | account separato, Object Lock | INVARIATO | nessuno: costo marginale piccolo, miglior rapporto rischio/costo |
| Upgrade | — | `multi_az = true` nell'IaC; conversione RDS con breve fermo | decisione rimandabile |

### Ingresso con NS su Cloudflare: opzioni
1. Tunnel Cloudflare (`cloudflared` sul nodo, connessione solo in uscita): nessun IP pubblico, nessuna porta in ingresso, niente ALB, niente WAF AWS. Cloudflare Access opzionale davanti al percorso amministrativo (MFA). Tier B usa questa. Connettore AWS-nativo di Cloudflare: non esiste; il «connettore» è proprio il tunnel (Magic WAN/Network Interconnect sono Enterprise [N]).
2. Proxy Cloudflare + ALB: security group dell'ALB limitato agli intervalli IP Cloudflare + Authenticated Origin Pulls (mTLS) o header segreto. L'origine resta tecnicamente su Internet, protetta da filtro; ALB si paga comunque.
3. DNS-only verso ALB: esposizione diretta, nessuna protezione Cloudflare; è la posizione precedente di stasera, ora superata.

Controargomenti al tunnel (da dichiarare al titolare):
- Cloudflare termina TLS: vede in chiaro il traffico applicativo, compresi dati sanitari. La cifratura applicativa dei documenti su S3 non protegge il transito al bordo. Servono DPA e base giuridica per trasferimenti/fornitore (adesione al Data Privacy Framework da verificare [N]); valutazione GDPR art. 9 a carico del titolare/DPO.
- Cloudflare in avaria = gestionale non raggiungibile. Mitigazione: ALB descritto come IaC pronto da attivare, ma l'attivazione non è istantanea (non è un failover) [A].
- Limite upload 100 MB per richiesta sul piano Free e Pro [V: developers.cloudflare.com, pagina errore 413, letta il 23/10/2026]. Per documenti più grandi servono upload diretto su S3 con URL pre-firmato (non passa da Cloudflare) o chunking. I documenti attuali sono ~14 GB su ~29.300 file: dimensione massima del singolo file NON verificata [N].
- Tunnel e Zero Trust Free: gratuità e limite utenti della versione Free NON verificati (pagina cloudflare.com/plans/zero-trust-services non riporta i dettagli) [N]. Prima di decidere leggere pagina piani ufficiale.
- Porte non-443: il proxy Cloudflare non è adatto a protocolli diversi da HTTP(S) senza servizi aggiuntivi [N, dal ricordo]. Nessun impatto previsto sul gestionale web.

### Costo Tier B (stima, USD/mese, on-demand; NON calcolato riga per riga)
- Tier B con ALB (opzione 2): ~100–130 USD [A, inferenza dalla proporzione del calcolo verificato ≈113 su ≈170 del Tier A; la scomposizione per riga non è stata conservata].
- Tier B con tunnel (opzione 1): ~65–90 USD [A]: tolti ALB (~25–28 € stimati nella prima versione) e WAF (prezzi regionali NON letti [N]). Più riduzione se NAT/fck-nat evitabile con nodi in subnet pubblica a security group chiuso (compromesso sulla sicurezza: sconsigliato per dati sanitari).
- Riserve RDS/Savings Plan abbassano il valore ma vincolano a 1–3 anni prima che il revamping esista: non raccomandato ora.
- Da fare in fase 1: calcolo riga per riga sul Pricing Calculator con query salvate (Tier A, Tier B-ALB, Tier B-tunnel).

### Domande per il titolare
1. Quanto fermo accetta (ore/giorni lavorativi)? Determina Tier A o B.
2. Accetta che un fornitore terzo (Cloudflare) termini TLS per dati sanitari? Se no: opzione 2/3 con ALB.
3. Chi sostiene costo ricorrente e lavoro.

### Raccomandazione corrente di Claude
Tier B con tunnel, backup account invariato, ALB come piano alternativo documentato. Resta da confermare da Pietro: ingresso tunnel e valutazione GDPR.

### 8.1 DNS: Cloudflare solo zona DNS (DNS-only) vs Route 53 (23/10/2026, sera)
- [V] Route 53, pagina prezzi AWS letta il 23/10/2026: zona ospitata 0,50 USD/mese (prime 25 zone, non prorata); query standard 0,40 USD per milione; alias verso ALB/CloudFront/S3 website/API Gateway senza costo query; health check 0,50 USD/mese (endpoint AWS) o 0,75 (non AWS); firma DNSSEC senza costo Route 53 ma con costi KMS.
- [A] Costo Route 53 per un dominio con pochi utenti: circa 1–3 USD/mese (zona + query + chiave KMS se DNSSEC); due domini circa il doppio. Volume query non misurato [N].
- [V per Cloudflare Free DNS] gratuito: non riletto oggi sulla pagina piani [N].
- Il costo del DNS non è il fattore decisivo (differenza ≈ 1–3 USD/mese). Lo è l'ingresso: con DNS-only il tunnel Cloudflare non è utilizzabile (richiede hostname proxato) → ALB obbligatorio, e senza proxy il WAF Cloudflare non filtra: il filtro L7 sarebbe solo AWS WAF (prezzi regionali non letti [N]). Il costo ricade quindi sulla variante Tier B con ALB (~100–130 USD/mese [A]), non sul Tier B con tunnel (~65–90 USD [A]).
- Argomento per tenere la zona su Cloudflare: indipendenza dal provider del carico in caso di compromissione/blocco dell'account AWS (DNS ancora controllabile per ripuntare); zona già pronta; ingegneriaesicurezzasrl.it resta comunque su Cloudflare (Pages). Argomento per Route 53: alias gratuiti, health check e failover routing nativi, un solo fornitore da gestire; contro: concentrazione di rischio nello stesso account.
- Raccomandazione corrente di Claude: zona su Cloudflare in DNS-only solo se si sceglie ALB; non spostare su Route 53 per risparmio (non esiste). Decisione di Pietro.
