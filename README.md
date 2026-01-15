# Rete-Bayesiana-Heart-Disease
## Modello probabilistico con rete bayesiana sul dataset Heart Disease (Cleveland)

## 1. Project Overview
Questo progetto sviluppa un modello basato su **Reti Bayesiane** per analizzare e stimare la probabilità di presenza di malattia cardiaca a partire da variabili cliniche e anagrafiche del paziente.

L’analisi segue un’impostazione “da relazione”:

- acquisizione e preparazione del dataset Heart Disease (Cleveland);
- selezione e trasformazione delle variabili (con eventuale discretizzazione);
- apprendimento della struttura della rete e stima delle probabilità (CPT);
- valutazione del modello tramite predizione del target e analisi degli errori;
- interpretazione delle dipendenze probabilistiche tra variabili e discussione dei risultati.

Il progetto è implementato in **R** ed è accompagnato da una relazione completa in PDF.

**File principali:**
- `reti bayesiane.R` – script R con l’intero workflow (dati → rete → risultati)
- `RETE_BAYESIANA ... .pdf` – relazione con metodologia, tabelle e grafici

---

## 2. Data Description
Il progetto utilizza il dataset **Heart Disease (Cleveland)**, frequentemente impiegato per studi di classificazione medica.  
Ogni osservazione rappresenta un paziente e include variabili descrittive (ad esempio età, sesso, indicatori clinici e risultati di test), oltre a una variabile target associata alla presenza/assenza (o grado) di patologia cardiaca.

L’obiettivo è utilizzare le sole informazioni disponibili nelle feature per stimare in modo probabilistico la classe del paziente e, soprattutto, comprendere **quali relazioni** tra variabili emergono dal modello.

**Nota metodologica:**  
L’interesse non è solo predittivo, ma anche interpretativo: la rete bayesiana permette di leggere le dipendenze tra variabili come legami probabilistici e di effettuare ragionamenti “what-if” (inferenza) in modo trasparente.

---

## 3. Metodologia (Rete Bayesiana)
La rete bayesiana è un modello probabilistico che rappresenta un insieme di variabili come un grafo orientato aciclico (DAG).  
Ogni arco rappresenta una dipendenza condizionale, mentre l’intero modello descrive la distribuzione congiunta tramite fattorizzazione in probabilità condizionate.

### 3.1 Preparazione del dataset
Prima dell’apprendimento vengono eseguiti passaggi per rendere i dati compatibili con il modello:
- gestione di variabili mancanti o codifiche non coerenti;
- eventuale discretizzazione di variabili continue (quando necessario);
- definizione della variabile target e delle variabili esplicative.

### 3.2 Apprendimento della rete
Il processo include due componenti:
- **apprendimento della struttura** (quali dipendenze inserire tra variabili);
- **stima dei parametri** (probabilità condizionate associate ai nodi).

La struttura ottenuta consente di identificare quali variabili risultano più direttamente informative per il target e come le variabili tra loro si influenzano in termini probabilistici.

### 3.3 Inferenza e valutazione
Una volta stimata la rete, il modello viene utilizzato per:
- stimare la probabilità del target dato un insieme di evidenze (variabili osservate);
- valutare la capacità predittiva tramite confronto tra classe prevista e reale;
- discutere gli errori e i casi più ambigui.

L’analisi viene supportata da tabelle e grafici riportati nella relazione.

---

## 4. Risultati (Sintesi)
I risultati principali evidenziano:
- quali variabili risultano più legate al target nella rete appresa;
- come cambiano le probabilità stimate del target al variare delle evidenze;
- prestazioni complessive del modello e principali fonti di errore.

La relazione approfondisce sia la parte quantitativa (performance) sia quella interpretativa (dipendenze e ragionamento probabilistico).

---

## 5. Considerazioni Conclusive
La rete bayesiana permette di affrontare il problema con un approccio probabilistico e interpretabile.  
I punti di forza sono:
- trasparenza delle relazioni tra variabili;
- possibilità di fare inferenza anche con informazione parziale;
- lettura “causale/probabilistica” (con le dovute cautele) delle dipendenze apprese.

Al tempo stesso, qualità dei risultati e stabilità del modello dipendono dalla preparazione dei dati, dalla discretizzazione e dalle scelte di apprendimento della struttura.

---

## 6. Repository Structure
Struttura consigliata:

