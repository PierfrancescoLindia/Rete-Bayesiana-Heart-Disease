############################################################
# HEART DISEASE (CLEVELAND) - BAYESIAN NETWORK PROJECT
# Struttura: HC + BDeu (iss=10) con blacklist a tiers
# Target: hd (no/yes), nessun arco uscente da hd
# Riduzione: rimozione {trestbps,fbs,chol,restecg,thalach}
# Inferenza esatta: gRain (Junction Tree) + setEvidence/querygrain
############################################################

# ============================================================
# 0) Librerie
# ============================================================
library(bnlearn)
library(Rgraphviz)
library(gRain)

# ============================================================
# 1) Dataset: download + caricamento
# ============================================================
url  <- "https://archive.ics.uci.edu/ml/machine-learning-databases/heart-disease/processed.cleveland.data"
file <- "processed.cleveland.data"
if (!file.exists(file)) download.file(url, file, mode = "wb")

heart_raw <- read.csv(file, header = FALSE, stringsAsFactors = FALSE)
colnames(heart_raw) <- c(
  "age","sex","cp","trestbps","chol","fbs","restecg",
  "thalach","exang","oldpeak","slope","ca","thal","num"
)

# ============================================================
# 2) Preprocessing: missing, conversioni, imputazione (moda)
# ============================================================
heart_raw[heart_raw == "?"] <- NA

# converti tutto in numerico (il file ha codifiche numeriche)
for (v in names(heart_raw)) heart_raw[[v]] <- as.numeric(heart_raw[[v]])

mode_impute <- function(x){
  ux <- unique(x[!is.na(x)])
  ux[which.max(tabulate(match(x, ux)))]
}

for (v in names(heart_raw)) {
  if (any(is.na(heart_raw[[v]]))) {
    heart_raw[[v]][is.na(heart_raw[[v]])] <- mode_impute(heart_raw[[v]])
  }
}
stopifnot(sum(is.na(heart_raw)) == 0)

# ============================================================
# 3) Target: costruzione di hd + conversioni/discretizzazione
# ============================================================
heart_raw$hd  <- ifelse(heart_raw$num >= 1, 1, 0)
heart_raw$num <- NULL
heart_raw$hd  <- factor(heart_raw$hd, levels = c(0,1), labels = c("no","yes"))

heart <- heart_raw

# Variabili già discrete/codificate -> factor
disc_coded <- c("sex","cp","fbs","restecg","exang","slope","ca","thal","hd")
disc_coded <- intersect(disc_coded, names(heart))
for (v in disc_coded) heart[[v]] <- as.factor(heart[[v]])

# Variabili continue -> discretizzazione in 3 classi (quantili)
num_to_disc <- c("age","trestbps","chol","thalach","oldpeak")
num_to_disc <- intersect(num_to_disc, names(heart))
heart[num_to_disc] <- discretize(
  heart[num_to_disc],
  method  = "quantile",
  breaks  = 3,
  ordered = TRUE
)

stopifnot(is.data.frame(heart))
stopifnot(sum(is.na(heart)) == 0)

# ============================================================
# 4) Blacklist: hd sink + tiers + vincolo age<->sex
# ============================================================
nodes_all <- names(heart)

# (i) hd non può avere archi uscenti
bl_target <- data.frame(from = "hd", to = setdiff(nodes_all, "hd"))

# (ii) tiers (progressione clinico-temporale)
tier1_demo   <- intersect(c("age","sex"), nodes_all)
tier2_base   <- intersect(c("cp","trestbps","chol","fbs","restecg"), nodes_all)
tier3_stress <- intersect(c("thalach","exang","oldpeak","slope"), nodes_all)
tier4_adv    <- intersect(c("ca","thal"), nodes_all)
tier5_target <- intersect(c("hd"), nodes_all)

tiers <- list(tier1_demo, tier2_base, tier3_stress, tier4_adv, tier5_target)

# vieta archi "a ritroso": da tier più tardo -> tier più precoce
bl_list <- list()
k <- 1
for (i in seq_along(tiers)) {
  for (j in seq_along(tiers)) {
    if (j > i) {
      from_nodes <- tiers[[j]]
      to_nodes   <- tiers[[i]]
      if (length(from_nodes) > 0 && length(to_nodes) > 0) {
        bl_list[[k]] <- expand.grid(from = from_nodes, to = to_nodes,
                                    stringsAsFactors = FALSE)
        k <- k + 1
      }
    }
  }
}
bl_tiers <- unique(do.call(rbind, bl_list))

# (iii) nessun arco diretto age<->sex (in entrambe le direzioni)
bl_demo <- data.frame(from = c("age","sex"), to = c("sex","age"),
                      stringsAsFactors = FALSE)

blacklist <- unique(rbind(bl_target, bl_tiers, bl_demo))
cat("Blacklist costruita. Numero vincoli:", nrow(blacklist), "\n")

# ============================================================
# 5) Apprendimento strutturale: HC con AIC/BIC/BDeu
# ============================================================
set.seed(123)
dag_aic  <- hc(heart, score = "aic", blacklist = blacklist)
dag_bic  <- hc(heart, score = "bic", blacklist = blacklist)
dag_bdeu <- hc(heart, score = "bde", iss = 10, blacklist = blacklist)

# Score (utile per tabella in relazione)
cat("\n--- SCORE DAG (confronto interno ai criteri) ---\n")
cat("AIC  (dag_aic): ",  score(dag_aic,  data = heart, type = "aic"), "\n")
cat("AIC  (dag_bic): ",  score(dag_bic,  data = heart, type = "aic"), "\n")
cat("AIC  (dag_bdeu): ", score(dag_bdeu, data = heart, type = "aic"), "\n\n")

cat("BIC  (dag_aic): ",  score(dag_aic,  data = heart, type = "bic"), "\n")
cat("BIC  (dag_bic): ",  score(dag_bic,  data = heart, type = "bic"), "\n")
cat("BIC  (dag_bdeu): ", score(dag_bdeu, data = heart, type = "bic"), "\n\n")

cat("BDeu (iss=10, dag_aic):  ", score(dag_aic,  data = heart, type = "bde", iss = 10), "\n")
cat("BDeu (iss=10, dag_bic):  ", score(dag_bic,  data = heart, type = "bde", iss = 10), "\n")
cat("BDeu (iss=10, dag_bdeu): ", score(dag_bdeu, data = heart, type = "bde", iss = 10), "\n")

# Visualizzazione (opzionale)
graphviz.plot(dag_aic,  main = "HC + AIC (Blacklist tiers)", shape = "rectangle")
graphviz.plot(dag_bic,  main = "HC + BIC (Blacklist tiers)", shape = "rectangle")
graphviz.plot(dag_bdeu, main = "HC + BDeu (iss=10, Blacklist tiers)", shape = "rectangle")

# Scelta DAG finale
dag_final <- dag_bdeu
cat("\n--- ARCHI DAG FINALE (HC+BDeu) ---\n")
print(arcs(dag_final))
graphviz.plot(dag_final, main = "DAG finale (HC + BDeu, iss=10)", shape = "rectangle")

# ============================================================
# 6) Validazione struttura: d-separation + chi^2 (solo se nodi esistono)
# ============================================================
safe_dsep_ci <- function(dag, x, y, z, data){
  all_nodes <- nodes(dag)
  needed <- unique(c(x,y,z))
  if (!all(needed %in% all_nodes)) {
    cat("\n[SKIP] Nodi mancanti nel DAG per:", x, y, "\n")
    return(invisible(NULL))
  }
  cat("\n--- Test:", x, "⊥", y, "|", paste(z, collapse=", "), "---\n")
  print(dsep(dag, x, y, z))
  print(ci.test(x, y, z = z, data = data, test = "x2"))
}

# Verifica 1 — cp ⟂ hd | {exang, oldpeak, thalach}
safe_dsep_ci(dag_final, "cp", "hd", c("exang","oldpeak","thalach"), heart)

# Verifica 2 — chol ⟂ exang | {age, sex}
safe_dsep_ci(dag_final, "chol", "exang", c("age","sex"), heart)

# Verifica 3 — ca ⟂ thalach | hd
safe_dsep_ci(dag_final, "ca", "thalach", c("hd"), heart)

# ============================================================
# 7) Markov blanket di hd + test riduzione
# ============================================================
cat("\n--- Markov blanket / genitori / figli di hd ---\n")
print(mb(dag_final, "hd"))
print(parents(dag_final, "hd"))
print(children(dag_final, "hd"))

Z <- c("exang","ca","thal")

for (x in c("trestbps","fbs","chol","restecg")) {
  safe_dsep_ci(dag_final, x, "hd", Z, heart)
}

# Test specifico: thalach ⟂ hd | {exang, ca, thal}
safe_dsep_ci(dag_final, "thalach", "hd", Z, heart)

# ============================================================
# 8) Modello ridotto finale: rimozione sottografi laterali + thalach
# ============================================================
nodes_drop_final <- intersect(c("trestbps","fbs","chol","restecg","thalach"), nodes(dag_final))
nodes_keep_final <- setdiff(nodes(dag_final), nodes_drop_final)

dag_red_final <- subgraph(dag_final, nodes_keep_final)

cat("\n--- NODI MODELLO RIDOTTO FINALE ---\n")
print(nodes(dag_red_final))

cat("\n--- ARCHI MODELLO RIDOTTO FINALE ---\n")
print(arcs(dag_red_final))

graphviz.plot(dag_red_final,
              main  = "DAG ridotto finale",
              shape = "rectangle")

# ============================================================
# 9) Stima CPT (Parameter learning): completo e ridotto
# ============================================================
fit_base <- bn.fit(dag_final, data = heart, method = "bayes", iss = 10)

fit_red_final <- bn.fit(
  dag_red_final,
  data   = heart[, nodes(dag_red_final)],
  method = "bayes",
  iss    = 10
)

cat("\n--- CPT hd (modello completo) ---\n")
print(fit_base$hd)

cat("\n--- CPT hd (modello ridotto finale) ---\n")
print(fit_red_final$hd)

# (Opzionale) CPT nodi radice del ridotto finale, se ti servono in relazione
cat("\n--- CPT nodi radice (ridotto finale, se presenti) ---\n")
for (v in c("age","sex","cp")) if (v %in% names(fit_red_final)) print(fit_red_final[[v]])

# (Opzionale) CPT blocchi intermedi (ridotto finale)
cat("\n--- CPT nodi intermedi (ridotto finale, se presenti) ---\n")
for (v in c("exang","oldpeak","slope","ca","thal")) if (v %in% names(fit_red_final)) print(fit_red_final[[v]])

# ============================================================
# 10) Inferenza esatta (Junction Tree) con gRain
# ============================================================

# conversione bnlearn -> gRain + compilazione (junction tree)
gr  <- as.grain(fit_red_final)
grc <- compile(gr)

# helper: P(hd=yes)
post_yes <- function(g){
  as.numeric(querygrain(g, nodes = "hd", type = "marginal")$hd["yes"])
}

# STEP 10.1: prior P(hd)
q0 <- querygrain(grc, nodes = "hd", type = "marginal")
q0
p0_no  <- as.numeric(q0$hd["no"])
p0_yes <- as.numeric(q0$hd["yes"])
c(P_hd_no = p0_no, P_hd_yes = p0_yes)

# livelli reali (robusto: evita hardcode "0","1","3","7" se cambiano)
lvl_exang <- levels(heart$exang)
lvl_ca    <- levels(heart$ca)
lvl_thal  <- levels(heart$thal)

# STEP 10.2: evidenza singola su exang (0 vs 1)
g_ex0 <- setEvidence(grc, nodes = "exang", states = lvl_exang[1])
g_ex1 <- setEvidence(grc, nodes = "exang", states = lvl_exang[2])

q_ex0 <- querygrain(g_ex0, nodes = "hd", type = "marginal")
q_ex1 <- querygrain(g_ex1, nodes = "hd", type = "marginal")
q_ex0; q_ex1

p_ex0 <- as.numeric(q_ex0$hd["yes"])
p_ex1 <- as.numeric(q_ex1$hd["yes"])
c(
  prior_yes        = p0_yes,
  post_yes_exang0  = p_ex0,
  post_yes_exang1  = p_ex1,
  delta_exang0     = p_ex0 - p0_yes,
  delta_exang1     = p_ex1 - p0_yes
)

# STEP 10.3: scenari su MB(hd) = {exang, ca, thal}
# Nota: qui scegliamo esplicitamente stati coerenti con la tua relazione:
# exang=0/1, ca=0/1/2, thal=3/7
# (ma li prendiamo dai livelli reali del dataset)

# utility per prendere uno stato specifico se esiste
pick_state <- function(levels_vec, wanted){
  if (!(wanted %in% levels_vec)) stop("Stato ", wanted, " non presente nei livelli: ", paste(levels_vec, collapse=", "))
  wanted
}

s_ex0 <- pick_state(lvl_exang, "0")
s_ex1 <- pick_state(lvl_exang, "1")
s_ca0 <- pick_state(lvl_ca,    "0")
s_ca1 <- pick_state(lvl_ca,    "1")
s_ca2 <- pick_state(lvl_ca,    "2")
s_th3 <- pick_state(lvl_thal,  "3")
s_th7 <- pick_state(lvl_thal,  "7")

# Scenario 1: rassicurante exang=0, ca=0, thal=3
g1 <- setEvidence(grc, nodes = c("exang","ca","thal"), states = c(s_ex0, s_ca0, s_th3))
p1 <- post_yes(g1)

# Scenario 2: intermedio exang=1, ca=1, thal=3
g2 <- setEvidence(grc, nodes = c("exang","ca","thal"), states = c(s_ex1, s_ca1, s_th3))
p2 <- post_yes(g2)

# Scenario 3: alto exang=1, ca=2, thal=7
g3 <- setEvidence(grc, nodes = c("exang","ca","thal"), states = c(s_ex1, s_ca2, s_th7))
p3 <- post_yes(g3)

c(prior = p0_yes, scen1 = p1, scen2 = p2, scen3 = p3)

# STEP 10.4: evidenza su age (fuori MB di hd)
age_levels <- levels(heart$age)
res_age <- sapply(age_levels, function(a){
  g <- setEvidence(grc, nodes = "age", states = a)
  post_yes(g)
})
res_age
