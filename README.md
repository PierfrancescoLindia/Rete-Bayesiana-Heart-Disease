# Panoramica

Questo progetto sviluppa una **Rete Bayesiana discreta** per modellare in modo probabilistico e interpretabile le relazioni tra variabili cliniche e diagnostiche del dataset **Heart Disease – Cleveland**, con focus sulla variabile target **hd** (presenza/assenza di patologia cardiaca). :contentReference[oaicite:1]{index=1}

Una rete bayesiana è un **modello grafico probabilistico** basato su un **DAG (Directed Acyclic Graph)**:
- i **nodi** rappresentano variabili aleatorie;
- gli **archi diretti** rappresentano dipendenze probabilistiche dirette;
- la struttura induce **indipendenze condizionali** e consente la **fattorizzazione** della distribuzione congiunta in prodotti di distribuzioni locali (CPT). :contentReference[oaicite:2]{index=2}

Obiettivo del progetto:
1. definire dominio e target diagnostico (**hd**);
2. preprocessare e rendere le variabili compatibili con BN discrete (discretizzazione + fattori);
3. apprendere la **struttura** del DAG con vincoli clinici (blacklist);
4. verificare indipendenze implicate dal DAG (d-separation + test $\chi^2$ sui dati);
5. stimare le **CPT** (parametri) con approccio bayesiano;
6. eseguire **inferenza** (probabilità a priori e a posteriori sotto evidenza). :contentReference[oaicite:3]{index=3}

# Dataset e variabile target

## Dataset

Dataset: **Heart Disease – Cleveland** (UCI repository). Ogni riga rappresenta un paziente con variabili:
- **demografiche**: `age`, `sex`;
- **clinica di base a riposo**: `cp`, `trestbps`, `chol`, `fbs`, `restecg`;
- **risposta allo sforzo**: `thalach`, `exang`, `oldpeak`, `slope`;
- **diagnostica avanzata**: `ca`, `thal`. :contentReference[oaicite:4]{index=4}

## Target: hd

Nel dataset originale la diagnosi è codificata da `num` (ordinale per severità). Nel progetto viene trasformata in binaria:
- `hd = no` se `num = 0`
- `hd = yes` se `num ≥ 1` :contentReference[oaicite:5]{index=5}

Questo consente di trattare il problema come **classificazione probabilistica**, interpretando le posteriori come probabilità diagnostiche.

# Preprocessing e discretizzazione

Poiché l’implementazione scelta richiede **variabili discrete**, il preprocessing mira a:
1) gestione missing;
2) conversione variabili numeriche-codificate in **fattori**;
3) discretizzazione delle variabili continue in classi ordinali. :contentReference[oaicite:6]{index=6}

## 1) Gestione valori mancanti

Nel dataset alcune celle possono essere codificate con `"?"`. Queste occorrenze vengono trattate come missing e imputate in modo **deterministico** tramite **moda** per variabile, scelta motivata da:
- pochi missing;
- semplicità e riproducibilità;
- evita perdita di osservazioni in campione moderato. :contentReference[oaicite:7]{index=7}

## 2) Trattamento variabili categoriali come fattori (codifiche)

Nel dataset Cleveland alcune variabili sono codificate numericamente ma sono **categoriche**. Vengono quindi convertite in fattori:

- `sex`: 0=femmina, 1=maschio → fattore binario  
- `cp`: 1..4 (tipi di dolore toracico) → fattore nominale a 4 stati  
- `fbs`: 0/1 → fattore binario  
- `restecg`: 0..2 → fattore nominale a 3 stati  
- `exang`: 0/1 → fattore binario  
- `slope`: 1..3 → fattore (categorie cliniche)  
- `thal`: {3,6,7} → fattore nominale  
- `ca`: {0,1,2,3} → fattore a 4 stati :contentReference[oaicite:8]{index=8}

## 3) Discretizzazione variabili continue (quantili)

Le variabili continue vengono discretizzate in **3 classi** tramite **quantili**, per ottenere fattori ordinali:
- `age` → (bassa, media, alta)
- `trestbps` → (bassa, media, alta)
- `chol` → (basso, medio, alto)
- `thalach` → (bassa, media, alta)
- `oldpeak` → (lieve, moderata, severa) :contentReference[oaicite:9]{index=9}

Motivazioni:
- compatibilità con BN discrete;
- riduzione complessità parametrica (CPT più stabili su campione moderato);
- interpretabilità clinica (classi ordinali). :contentReference[oaicite:10]{index=10}

# Modellazione: Rete Bayesiana discreta

## Struttura e semantica

La rete bayesiana è un DAG $G=(V,E)$ in cui:
- ogni nodo $X_i$ è una variabile discreta;
- la distribuzione congiunta fattorizza come:
$$
P(X_1,\dots,X_p) = \prod_{i=1}^{p} P(X_i \mid Pa(X_i))
$$
dove $Pa(X_i)$ sono i genitori di $X_i$ nel DAG. :contentReference[oaicite:11]{index=11}

# Blacklist (vincoli strutturali)

L’apprendimento strutturale viene guidato da una **blacklist**: un insieme di archi proibiti per incorporare conoscenza di dominio e garantire coerenza clinica. :contentReference[oaicite:12]{index=12}

Vincolo chiave:
- **la variabile target `hd` non può avere archi uscenti** (la diagnosi finale non “causa” retroattivamente sintomi, demografia o risultati dei test). :contentReference[oaicite:13]{index=13}

Inoltre viene adottata una logica a **livelli (tiers)** che riflette la progressione temporale/clinica dell’informazione:
1. Demografia: `age`, `sex`
2. Clinica di base: `cp`, `trestbps`, `chol`, `fbs`, `restecg`
3. Stress test: `thalach`, `exang`, `oldpeak`, `slope`
4. Diagnostica avanzata: `ca`, `thal` :contentReference[oaicite:14]{index=14}

La blacklist esclude archi “a ritroso” (es. diagnostica avanzata → demografia), riducendo spazio di ricerca e aumentando interpretabilità.

# Apprendimento automatico della struttura (DAG)

## Algoritmo: Hill-Climbing (HC)

La struttura del DAG viene appresa con **Hill-Climbing**:
- si parte da un grafo iniziale (tipicamente vuoto);
- a ogni iterazione si valuta una modifica locale:
  - aggiunta arco
  - rimozione arco
  - inversione arco
- si seleziona la modifica che migliora lo **score**;
- stop quando nessuna modifica migliora ulteriormente lo score (ottimo locale). :contentReference[oaicite:15]{index=15}

## Score considerati: AIC, BIC, BDeu

Sono confrontati tre criteri:
- **AIC**: tende a favorire strutture più dense (più archi), privilegiando fit.
- **BIC**: penalizzazione più severa della complessità, struttura più parsimoniosa.
- **BDeu**: score bayesiano con regolarizzazione tramite **equivalent sample size** (iss), utile con variabili discretizzate e campione moderato. :contentReference[oaicite:16]{index=16}

## Scelta del modello finale: BDeu (iss=10)

Dal confronto:
- HC + AIC → DAG più denso
- HC + BIC → DAG più semplice/frammentato
- HC + **BDeu (iss=10)** → compromesso equilibrato tra complessità e stabilità

Il DAG finale selezionato è quindi quello appreso con **HC + BDeu**. :contentReference[oaicite:17]{index=17}

# Analisi qualitativa delle relazioni apprese

La struttura selezionata (HC+BDeu, con blacklist) mostra relazioni coerenti con il dominio clinico. In sintesi: :contentReference[oaicite:18]{index=18}

- **Blocco demografico/clinica di base**: `age` influenza `trestbps` e `ca`; inoltre `trestbps → fbs` è interpretabile come dipendenza statistica mediata da fattori metabolici condivisi.
- **Sottografo sintomi/stress test**: `cp` influenza `exang` e `oldpeak`, con catena `oldpeak → slope` e impatti indiretti su risposta funzionale.
- **Diagnostica avanzata ed esito**: `ca` e `thal` influenzano direttamente `hd`; anche variabili funzionali (es. `thalach`) possono contribuire (a seconda della struttura completa vs ridotta). :contentReference[oaicite:19]{index=19}

# Indipendenze implicate dal DAG e test sui dati

La validazione non si limita agli archi: un DAG implica indipendenze condizionali derivabili via **d-separation**. Il progetto verifica alcune indipendenze selezionate con:
1) verifica sul grafo (d-separation)
2) verifica sui dati con test $\chi^2$ condizionato (Pearson), adatto a variabili discrete. :contentReference[oaicite:20]{index=20}

Esempi riportati:
- $cp \perp hd \mid \{exang, oldpeak, thalach\}$ con p-value 0.124
- $chol \perp exang \mid \{age, sex\}$ con p-value 0.760
- $ca \perp thalach \mid \{hd\}$ con p-value 0.214 :contentReference[oaicite:21]{index=21}

Interpretazione: nessuna evidenza di incoerenza tra indipendenze implicate e dipendenze empiriche osservate (nel set di verifiche effettuate).

# Markov Blanket della target e riduzione del modello

## Definizione

La **Markov Blanket** di un nodo $X$ è l’insieme minimo di variabili che rende $X$ indipendente dal resto del grafo:
$$
X \perp\!\!\!\perp Rest \mid MB(X)
$$
e in generale:
$$
MB(X) = Pa(X)\ \cup\ Ch(X)\ \cup\ Pa(Ch(X)).
$$ 
:contentReference[oaicite:22]{index=22}

## Markov Blanket di hd nel DAG appreso

Nel modello discusso, `hd` non ha figli (coerente con blacklist), e la Markov blanket coincide con i genitori:
$$
MB(hd)=\{exang, ca, thal\}.
$$ 
:contentReference[oaicite:23]{index=23}

## Motivazione e verifica empirica della riduzione

Poiché l’obiettivo è inferenza diagnostica su `hd`, si valuta un **modello ridotto** rimuovendo sottografi laterali (es. `trestbps–fbs`, `sex–chol–restecg`, e anche `thalach`), mantenendo i cammini rilevanti per l’inferenza su `hd`. :contentReference[oaicite:24]{index=24}

Esempio di verifica: test di indipendenza condizionale tra `thalach` e `hd` dato $\{exang, ca, thal\}$:
- $\chi^2 = 37.67$, df = 48, p-value = 0.858 (compatibile con indipendenza condizionale). :contentReference[oaicite:25]{index=25}

# Stima dei parametri: CPT (Conditional Probability Tables)

Una volta fissata la struttura, si stimano le **CPT** per ciascun nodo:
- nodi radice → distribuzioni marginali (priori)
- nodi con genitori → distribuzioni condizionate.

Il progetto usa `bn.fit` con stima **bayesiana** coerente con BDeu (iss=10). :contentReference[oaicite:26]{index=26}

## CPT nodi radice (modello ridotto)

Nel modello ridotto, `age`, `sex`, `cp` sono nodi radice → CPT marginali (priori). È riportata, ad esempio, la distribuzione a priori delle classi di età e delle categorie di `cp`, con interpretazione clinica (campione prevalentemente medio-alto; `cp` con prevalenza di categorie più severe). :contentReference[oaicite:27]{index=27}

## CPT nodi intermedi: blocchi interpretativi

Le CPT vengono analizzate per blocchi:
1) sintomatologia e risposta allo sforzo
2) anatomia coronarica
3) diagnostica funzionale avanzata :contentReference[oaicite:28]{index=28}

### Esempio 1 — Catena sintomi/stress test

Dal DAG ridotto:
$$
cp \rightarrow (exang, oldpeak) \rightarrow slope
$$
Le CPT quantificano la propagazione dell’informazione:
- $P(exang=1\mid cp)$ cresce molto per $cp=4$ (≈0.55), rispetto a cp meno severi (≈0.10–0.21). :contentReference[oaicite:29]{index=29}
- $P(oldpeak\mid cp)$ mostra che con $cp=4$ aumenta la probabilità della classe severa di oldpeak (≈0.40). :contentReference[oaicite:30]{index=30}
- $P(slope\mid oldpeak)$: con oldpeak lieve, $P(slope=1)\approx0.82$; con oldpeak severo aumenta $P(slope=2)\approx0.68$ e $P(slope=3)\approx0.17$. :contentReference[oaicite:31]{index=31}

### Esempio 2 — Anatomia coronarica

Dipendenza:
$$
age \rightarrow ca
$$
La CPT $P(ca\mid age)$ mostra trend coerente: con età più alta diminuisce $P(ca=0)$ e aumenta probabilità di coinvolgimento multivasale (es. $P(ca=2\mid age)$ da ≈0.04 a ≈0.24). :contentReference[oaicite:32]{index=32}

### Esempio 3 — Diagnostica funzionale avanzata

Nel modello ridotto:
$$
(thal \mid sex, slope)
$$
La CPT $P(thal\mid sex, slope)$ evidenzia:
- per slope=1 (più fisiologico) $P(thal=3)$ molto alta (≈0.96 per sex=0; ≈0.60 per sex=1);
- all’aumentare della severità (slope=2,3) cala $P(thal=3)$ e cresce $P(thal=7)$ (es. slope=2, sex=1: $P(thal=7)\approx0.606$). :contentReference[oaicite:33]{index=33}

## CPT della variabile target

La target è stimata come:
$$
P(hd \mid exang, ca, thal)
$$
dove $\{exang, ca, thal\}$ coincide con la Markov blanket di `hd`, quindi costituisce l’insieme minimo sufficiente per inferenza diagnostica nel modello ridotto. :contentReference[oaicite:34]{index=34}

Le tabelle di CPT sono riportate separando per valore di `thal` (3/6/7), e mostrano pattern coerenti: la probabilità di `hd=yes` cresce con severità anatomica (`ca`) e funzionale (`thal`) ed è accentuata da `exang=1`. :contentReference[oaicite:35]{index=35}

# Inferenza probabilistica (gRain)

## Framework

Inferenza esatta eseguita con **gRain**:
- conversione del modello parametrizzato (`bn.fit`) in oggetto `grain` (`as.grain()`)
- compilazione (`compile()`) con costruzione del **junction tree**
- propagazione delle credenze per ottenere marginali/posteriori. :contentReference[oaicite:36]{index=36}

## Evidenza e query

Workflow:
- `setEvidence()` impone osservazioni (condizionamento)
- `querygrain()` restituisce distribuzioni marginali/posteriori (dopo propagazione) :contentReference[oaicite:37]{index=37}

## Query di baseline (prior)

Distribuzione marginale a priori:
$$
P(hd)
$$
Nel modello ridotto:
- $P(hd=yes)\approx 0.466$
- $P(hd=no)\approx 0.534$ :contentReference[oaicite:38]{index=38}

## Evidenza parziale: effetto di exang

Posteriori diagnostiche:
$$
P(hd \mid exang)
$$
Risultati riportati:
- exang=0 → $P(hd=yes)\approx 0.369$
- exang=1 → $P(hd=yes)\approx 0.660$ :contentReference[oaicite:39]{index=39}

Interpretazione: `exang` (angina indotta da sforzo) aggiorna in modo marcato la probabilità diagnostica rispetto alla baseline.

## Evidenza completa sulla Markov blanket: scenari

Poiché i genitori di `hd` sono $\{exang, ca, thal\}$, fissare evidenza su questi nodi determina localmente la posteriore:
$$
P(hd=yes \mid exang, ca, thal)
$$
Esempi di scenari:
- scenario rassicurante (0,0,3) → $P(hd=yes)\approx 0.091$
- scenario alto rischio (1,2,7) → $P(hd=yes)\approx 0.984$ :contentReference[oaicite:40]{index=40}

# Output atteso

Alla fine del progetto si ottengono:
- dataset preprocessato (discretizzazione + fattori + imputazione)
- blacklist clinicamente motivata
- strutture DAG apprese con HC sotto score (AIC/BIC/BDeu) e selezione del DAG finale (BDeu)
- verifiche di indipendenza condizionale (d-separation + $\chi^2$)
- modello ridotto basato su Markov blanket di `hd`
- CPT stimate (bn.fit bayesiano, iss coerente)
- inferenze con gRain: baseline, posteriori sotto evidenza parziale/completa, scenari diagnostici :contentReference[oaicite:41]{index=41}

# Riproducibilità

Per riprodurre i risultati è essenziale:
- utilizzare lo stesso flusso di preprocessing (imputazione moda; discretizzazione per quantili in 3 classi; conversione fattori)
- applicare la stessa blacklist (vincoli di struttura, in particolare `hd` senza archi uscenti e tiers clinici)
- fissare lo stesso criterio e iperparametri di scoring (BDeu con `iss=10`)
- eseguire `bn.fit` con metodo bayesiano coerente con la scelta di struttura
- usare gRain con conversione, compilazione e evidenza/query secondo workflow indicato :contentReference[oaicite:42]{index=42}

# Glossario rapido

- **BN (Bayesian Network)**: modello probabilistico grafico su DAG
- **DAG**: grafo diretto aciclico
- **CPT**: tabella di probabilità condizionata $P(X\mid Pa(X))$
- **d-separation**: criterio grafico per indipendenza condizionale
- **Markov Blanket**: insieme minimo che rende un nodo indipendente dal resto del grafo
- **Hill-Climbing**: ricerca locale euristica nello spazio dei DAG
- **AIC/BIC/BDeu**: criteri di scoring per apprendimento strutturale
- **iss (equivalent sample size)**: regolarizzazione bayesiana nello score/stima
- **Inferenza esatta (junction tree)**: propagazione delle credenze in gRain :contentReference[oaicite:43]{index=43}

