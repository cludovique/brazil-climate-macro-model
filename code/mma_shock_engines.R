# =============================================================================
# MMA-SMC → MIP SHOCK ENGINES
# Mapeia os cenários climáticos MMA-SMC v3 AR5 (2024) para a
# Matriz Insumo-Produto EPE/FIPE 2018 (73 setores)
#
# Engines:
#   1. Demanda Final (∆f)  — escala PIB + choques de investimento
#   2. Coef. Técnicos (∆A) — substituição de energia por fonte
#   3. Produção Exógena (∆x) — volumes físicos → R$ por setor
#   4. Coef. Emissão (e)   — MtCO2e por R$M de produto (conta satélite)
#
# Saída:  outputs/tables/mma_shock_results.xlsx
#         data/processed/mma_shocks.rds
# =============================================================================

pkgs <- c("readxl","dplyr","tidyr","writexl","stringr")
for (p in pkgs) { if (!requireNamespace(p,quietly=TRUE)) install.packages(p); library(p,character.only=TRUE) }
options(OutDec=".")
cat("=== MMA Shock Engines ===\n")

# =============================================================================
# PARTE 1 — CARREGA MODELO IO (EPE 2018, 73 setores)
# =============================================================================
setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")

MIP_PATH <- "data/raw/48008000008202670_Camila_Anexo 2.xlsx"
MMA_PATH <- "data/raw/Planilha_Detalhamento Resultados MMA-SMC v3 AR5 (07_10_2024).xlsx"
stopifnot(file.exists(MIP_PATH), file.exists(MMA_PATH))

cat("Lendo modelo IO...\n")
setores_raw <- read_excel(MIP_PATH, sheet="Lista PS",
                          col_names=FALSE, range=cell_cols("A:M"))
setores <- setores_raw |>
  select(cod=12, nome=13) |>
  filter(!is.na(cod), grepl("^S", as.character(cod))) |>
  mutate(cod=as.character(cod), nome=as.character(nome),
         id=as.integer(gsub("\\D","",cod)))
N <- nrow(setores)
cat(sprintf("  %d setores\n", N))

read_matrix <- function(sheet, r1, r2, c1, c2) {
  raw <- read_excel(MIP_PATH, sheet=sheet, col_names=FALSE)
  raw[r1:r2, c1:c2] |>
    mutate(across(everything(),
                  ~suppressWarnings(as.numeric(replace_na(as.character(.),"0"))))) |>
    as.matrix()
}

A <- read_matrix("Coeficientes Tecnicos", 5, 4+N, 4, 3+N)
L <- read_matrix("Leontief",              5, 4+N, 4, 3+N)
Z <- read_matrix("Usos SxS",              5, 4+N, 4, 3+N)
dimnames(A) <- dimnames(L) <- dimnames(Z) <- list(setores$cod, setores$cod)

usos_raw <- read_excel(MIP_PATH, sheet="Usos SxS", col_names=FALSE)
demanda_final <- usos_raw[5:(4+N), 78:83] |>
  mutate(across(everything(),
                ~suppressWarnings(as.numeric(replace_na(as.character(.),"0")))))
colnames(demanda_final) <- c("Exportacoes","Gov","ISFLSF","Familias","FBCF","Var_Estoque")
demanda_final$cod <- setores$cod

x       <- rowSums(Z) + rowSums(demanda_final[,1:6])
names(x) <- setores$cod
x_safe  <- ifelse(x > 0, x, 1)

# Coeficientes de energia (ktep / R$M)
linha_energia <- c(Derivados=125,Biodiesel=126,Etanol=127,
                   EE_Central=128,EE_Distrib=129,Gas_Natural=130)
obter_linha <- function(lr) {
  v <- suppressWarnings(as.numeric(as.character(unlist(usos_raw[lr, 4:(3+N)]))))
  v[is.na(v)] <- 0; setNames(v, setores$cod)
}
energia_base  <- do.call(rbind, lapply(linha_energia, obter_linha))
rownames(energia_base) <- names(linha_energia)
alpha_energia <- sweep(energia_base, 2, x_safe, "/")

cat("  IO carregado: A, L, Z, x, demanda_final, alpha_energia\n")

# =============================================================================
# PARTE 2 — EXTRAI DADOS MMA
# =============================================================================
cat("Lendo MMA...\n")

ANOS_MMA <- c(2025, 2030, 2035, 2040, 2045, 2050)
CENS_MMA <- c("25D","100D","0D")
ANOS_STR <- as.character(ANOS_MMA)

# Lê planilha pelo índice (evita problemas de codificação)
all_sheets <- excel_sheets(MMA_PATH)
# 1=ResultBLUES, 2=Agropecuária, 3=LULUCF, 4=Energia,
# 5=Indústria, 6=Transporte, 7=Cidades, 8=Resíduos, 9=Pop_PIB, 10=Custos
read_mma <- function(idx) suppressMessages(read_excel(MMA_PATH, sheet=all_sheets[idx], col_names=FALSE))

# Convenção de colunas (UNIFORME em todas as planilhas):
#   col 3  = 2020 (atual) — valor base
#   col 4  = separador em branco
#   col 5-10 = 25D (2025-2050)
#   col 11 = separador em branco
#   col 12-17 = 100D (2025-2050)
#   col 18 = separador em branco
#   col 19-24 = 0D (2025-2050)
get_scenario_row <- function(df, r, cols_25d=5:10, cols_100d=12:17, cols_0d=19:24) {
  safe <- function(v) { v <- suppressWarnings(as.numeric(unlist(v))); v[is.na(v)] <- 0; setNames(v, ANOS_STR) }
  v25  <- safe(df[r, cols_25d])
  v100 <- safe(df[r, cols_100d])
  v0   <- tryCatch(safe(df[r, cols_0d]), error=function(e) v25)
  if (all(v0==0)) v0 <- v25   # fallback se 0D não disponível
  list("25D"=v25, "100D"=v100, "0D"=v0)
}
get_base2020 <- function(df, r) { suppressWarnings(as.numeric(df[[r, 3]])) }

# ── 2.1  Pop e PIB -------------------------------------------------------
pp <- read_mma(9)
gdp_idx  <- setNames(suppressWarnings(as.numeric(unlist(pp[4, 4:9]))), ANOS_STR)
pop_mil  <- setNames(suppressWarnings(as.numeric(unlist(pp[3, 4:9]))), ANOS_STR)
gdp_2018_factor <- 0.97   # PIB 2018 ≈ 97% do PIB 2020

# ── 2.2  GHG agregado por cenário (ResultBLUES) --------------------------
rb <- read_mma(1)
parse_rb_block <- function(start_row) {
  df <- rb[start_row:(start_row+5), 2:8]
  mat <- matrix(suppressWarnings(as.numeric(as.matrix(df))), nrow=6, ncol=7)
  colnames(mat) <- c("Industria","Transportes","Energia","LULUCF",
                     "Agropecuaria","Residuos","Cidades")
  rownames(mat) <- ANOS_STR; mat
}
ghg_mma <- list("0D"=parse_rb_block(4), "25D"=parse_rb_block(14), "100D"=parse_rb_block(24))

# ── 2.3  Energia — mix tecnológico ----------------------------------------
en <- read_mma(4)
# Linhas verificadas: 23=industria%, 24=transporte%, 25=edificações%, 26=agricultura%
# 16=energia primária, 17=energia final, 49=geração elétrica
# 76=etanol+CCS, 78=diesel verde, 79=biometano
energia_primaria  <- get_scenario_row(en, 16)   # Mtep
geracao_elec      <- get_scenario_row(en, 49)   # TWh
pj_etanol_ccs     <- get_scenario_row(en, 76)   # PJ
pj_diesel_vrd     <- get_scenario_row(en, 78)   # PJ
pj_biometano      <- get_scenario_row(en, 79)   # PJ

# ── 2.4  Indústria — mix e produção ----------------------------------------
ind <- read_mma(5)
# Linhas verificadas: R18=% elec, R19=% bio, R27=aço(Mt), R28=ferro(Mt), R41=clinker(Mt)
elec_ind_pct  <- get_scenario_row(ind, 18)
bio_ind_pct   <- get_scenario_row(ind, 19)
aco_prod      <- get_scenario_row(ind, 27)   # Mt
ferro_prod    <- get_scenario_row(ind, 28)   # Mt
clinker_prod  <- get_scenario_row(ind, 41)   # Mt
elec_ind_2020 <- get_base2020(ind, 18)        # 0.33
bio_ind_2020  <- get_base2020(ind, 19)        # 0.23
aco_2020      <- get_base2020(ind, 27)        # 31.4 Mt
clinker_2020  <- get_base2020(ind, 41)        # 42.7 Mt

# ── 2.5  Transporte -------------------------------------------------------
tr <- read_mma(6)
# R14=% elec, R15=% biocomb (transporte total)
elec_tra_pct  <- get_scenario_row(tr, 14)
bio_tra_pct   <- get_scenario_row(tr, 15)
elec_tra_2020 <- get_base2020(tr, 14)         # 0.0036
bio_tra_2020  <- get_base2020(tr, 15)         # 0.303

# ── 2.6  Cidades ---------------------------------------------------------
ci <- read_mma(7)
# R26=% elec, R27=% biocomb, R29=% gás+GLP
elec_cid_pct  <- get_scenario_row(ci, 26)
bio_cid_pct   <- get_scenario_row(ci, 27)
gas_cid_pct   <- get_scenario_row(ci, 29)
elec_cid_2020 <- get_base2020(ci, 26)         # 0.625
bio_cid_2020  <- get_base2020(ci, 27)         # ~0
gas_cid_2020  <- get_base2020(ci, 29)         # 0.26

# ── 2.7  Agropecuária — produção física -----------------------------------
ag <- read_mma(2)
# R68=cana(1000t), R72=milho(1000t), R79=soja(1000t)
cana_prod      <- get_scenario_row(ag, 68)
milho_prod     <- get_scenario_row(ag, 72)
soja_prod      <- get_scenario_row(ag, 79)
cana_2020      <- get_base2020(ag, 68)         # 692714 (1000t)
milho_2020     <- get_base2020(ag, 72)         # 108304
soja_2020      <- get_base2020(ag, 79)         # 123491

# ── 2.8  Custos de investimento -----------------------------------------------
cu <- read_mma(10)
# Custo Anual Equivalente (bi USD2023/ano): rows 7-9, cols 6=25D inv, 10=100D inv
inv_cae_25d  <- suppressWarnings(as.numeric(unlist(cu[7:9, 6])))
inv_cae_100d <- suppressWarnings(as.numeric(unlist(cu[7:9, 10])))
inv_cae_25d[is.na(inv_cae_25d)]   <- 0
inv_cae_100d[is.na(inv_cae_100d)] <- 0
# USD2023 → R$2018: câmbio 2018 R$3.65/USD ÷ CPI US 1.25
USD2023_to_R2018 <- 3.65 / 1.25   # ≈ 2.92
inv_annual_R2018 <- list(
  "25D"  = inv_cae_25d  * USD2023_to_R2018,
  "100D" = inv_cae_100d * USD2023_to_R2018,
  "0D"   = inv_cae_25d  * USD2023_to_R2018 * 0.90
)
cat("  MMA carregado: GHG, mix energético, produção física, custos\n")

# =============================================================================
# PARTE 3 — MAPEAMENTO SETORES MMA → IO EPE
# =============================================================================

GRUPOS <- list(
  agro         = c("S01","S02","S03","S04","S06","S07","S08","S09"),
  lulucf       = c("S08","S09"),
  oleo_gas     = c("S05","S19","S21"),
  biocomb      = c("S20","S22"),
  eletricidade = c("S40","S41","S42","S43"),
  ind_aco      = c("S14"),
  ind_cimento  = c("S16"),
  ind_quimico  = c("S24","S25","S26"),
  ind_outros   = c("S10","S11","S12","S13","S15","S17","S18","S23",
                   "S27","S28","S29","S30","S31","S32","S33","S34",
                   "S35","S36","S37","S38","S39"),
  ind_all      = c("S10","S11","S12","S13","S14","S15","S16","S17","S18",
                   "S23","S24","S25","S26","S27","S28","S29","S30","S31",
                   "S32","S33","S34","S35","S36","S37","S38","S39"),
  transporte   = c("S50","S51","S52"),
  cidades      = c("S57","S58","S59","S60"),
  residuos     = c("S66","S67","S68"),
  construcao   = c("S44","S45")
)
GRUPOS <- lapply(GRUPOS, function(g) intersect(g, setores$cod))

# Linhas energéticas da matriz A que serão rebalanceadas
ENERGY_ROWS <- intersect(c("S19","S20","S22","S40","S41","S43"), setores$cod)

cat("  Mapeamentos setoriais definidos\n")

# =============================================================================
# PARTE 4 — ENGINE 1: DEMANDA FINAL (∆f = escala PIB + investimento)
# =============================================================================
cat("Construindo Engine 1 (∆f)...\n")

gdp_rel_2018 <- gdp_idx * gdp_2018_factor
f_base       <- rowSums(demanda_final[, c("Familias","Gov","ISFLSF","FBCF","Exportacoes")])
names(f_base) <- setores$cod

# 4a: Escala PIB — crescimento da demanda final relativo a 2018
engine1_gdp <- function(cenario, ano) {
  g <- gdp_rel_2018[as.character(ano)]
  f_base * (g - 1)
}

# 4b: Investimento de transição — alocado como FBCF por setor IO
ALOC_INV <- c(S40=0.15,S41=0.05,S42=0.03,S43=0.03,
              S22=0.08,S20=0.04,S05=0.05,
              S14=0.04,S16=0.02,S36=0.06,S37=0.06,
              S27=0.08,S44=0.12,S45=0.04,
              S50=0.04,S51=0.02,
              S01=0.03,S04=0.02,S08=0.03,
              S66=0.02,S67=0.02)
ALOC_INV <- ALOC_INV[names(ALOC_INV) %in% setores$cod]
ALOC_INV <- ALOC_INV / sum(ALOC_INV)

periodo_idx <- function(ano) if (ano<=2030) 1L else if (ano<=2035) 2L else 3L

engine1_inv <- function(cenario, ano) {
  inv_RM <- inv_annual_R2018[[cenario]][periodo_idx(ano)] * 1000
  delta_f <- numeric(N); names(delta_f) <- setores$cod
  for (cod in names(ALOC_INV)) delta_f[cod] <- delta_f[cod] + inv_RM * ALOC_INV[cod]
  delta_f
}

engine1 <- function(cenario, ano) engine1_gdp(cenario, ano) + engine1_inv(cenario, ano)
cat("  Engine 1 OK\n")

# =============================================================================
# PARTE 5 — ENGINE 2: COEFICIENTES TÉCNICOS (∆A = substituição de energia)
# =============================================================================
cat("Construindo Engine 2 (∆A)...\n")

BASE2020 <- list(
  elec_ind  = ifelse(is.na(elec_ind_2020), 0.33, elec_ind_2020),
  bio_ind   = ifelse(is.na(bio_ind_2020),  0.23, bio_ind_2020),
  elec_tra  = ifelse(is.na(elec_tra_2020), 0.004, elec_tra_2020),
  bio_tra   = ifelse(is.na(bio_tra_2020),  0.303, bio_tra_2020),
  elec_cid  = ifelse(is.na(elec_cid_2020), 0.625, elec_cid_2020),
  bio_cid   = ifelse(is.na(bio_cid_2020),  0.000, bio_cid_2020),
  gas_cid   = ifelse(is.na(gas_cid_2020),  0.260, gas_cid_2020)
)

engine2_A_star <- function(cenario, ano) {
  a  <- as.character(ano)
  A_star <- A

  # Redistribui coef. de energia de colunas `setor_cods` conforme novo mix
  rebalancear <- function(setor_cods, pct_e_new, pct_b_new, pct_e_base, pct_b_base) {
    pct_f_base <- max(1 - pct_e_base - pct_b_base, 0)
    pct_f_new  <- max(1 - pct_e_new  - pct_b_new,  0)
    for (j in setor_cods) {
      if (!(j %in% colnames(A_star))) next
      e_elec <- sum(A_star[intersect(c("S40","S41"), rownames(A_star)), j])
      e_bio  <- sum(A_star[intersect(c("S20","S22"), rownames(A_star)), j])
      e_foss <- sum(A_star[intersect(c("S19","S43"), rownames(A_star)), j])
      total  <- e_elec + e_bio + e_foss
      if (total <= 0) next
      new_e <- total * pct_e_new
      new_b <- total * pct_b_new
      new_f <- total * pct_f_new
      if (e_elec > 0) {
        for (r in intersect(c("S40","S41"), rownames(A_star)))
          A_star[r, j] <<- A_star[r, j] / e_elec * new_e
      } else if (new_e > 0 && "S40" %in% rownames(A_star)) {
        A_star["S40", j] <<- new_e
      }
      if (e_bio > 0) {
        for (r in intersect(c("S20","S22"), rownames(A_star)))
          A_star[r, j] <<- A_star[r, j] / e_bio * new_b
      } else if (new_b > 0 && "S22" %in% rownames(A_star)) {
        A_star["S22", j] <<- A_star["S22", j] + new_b
      }
      if (e_foss > 0) {
        for (r in intersect(c("S19","S43"), rownames(A_star)))
          A_star[r, j] <<- A_star[r, j] / e_foss * new_f
      }
    }
    A_star
  }

  pe_i <- elec_ind_pct[[cenario]][a]; pb_i <- bio_ind_pct[[cenario]][a]
  if (!is.na(pe_i) && !is.na(pb_i))
    A_star <- rebalancear(GRUPOS$ind_all, pe_i, pb_i, BASE2020$elec_ind, BASE2020$bio_ind)

  pe_t <- elec_tra_pct[[cenario]][a]; pb_t <- bio_tra_pct[[cenario]][a]
  if (!is.na(pe_t) && !is.na(pb_t))
    A_star <- rebalancear(GRUPOS$transporte, pe_t, pb_t, BASE2020$elec_tra, BASE2020$bio_tra)

  pe_c <- elec_cid_pct[[cenario]][a]; pb_c <- bio_cid_pct[[cenario]][a]
  if (!is.na(pe_c) && !is.na(pb_c))
    A_star <- rebalancear(GRUPOS$cidades, pe_c, pb_c, BASE2020$elec_cid, BASE2020$bio_cid)

  A_star
}

engine2_L_star <- function(A_star) {
  tryCatch(solve(diag(N) - A_star), error=function(e) { warning("L* singular; usa L base"); L })
}
cat("  Engine 2 OK\n")

# =============================================================================
# PARTE 6 — ENGINE 3: PRODUÇÃO EXÓGENA (∆x físico → R$)
# =============================================================================
cat("Construindo Engine 3 (∆x)...\n")

engine3_delta_x <- function(cenario, ano) {
  a <- as.character(ano)
  delta_x <- setNames(numeric(N), setores$cod)

  # Variação relativa vs 2020 aplicada ao x_2018
  apply_ratio <- function(cod, val_scen, base_2020) {
    if (!cod %in% names(delta_x)) return()
    vs <- suppressWarnings(as.numeric(val_scen))
    b  <- suppressWarnings(as.numeric(base_2020))
    if (is.na(vs) || is.na(b) || b <= 0) return()
    delta_x[cod] <<- delta_x[cod] + x[cod] * (vs / b - 1)
  }

  # Agropecuária
  apply_ratio("S04", cana_prod[[cenario]][a],  cana_2020)
  apply_ratio("S01", soja_prod[[cenario]][a],  soja_2020)
  apply_ratio("S02", milho_prod[[cenario]][a], milho_2020)

  # Indústria pesada (Mt → ratio)
  aco_2020_safe <- ifelse(is.na(aco_2020) || aco_2020<=0, 31.4, aco_2020)
  clin_2020_safe <- ifelse(is.na(clinker_2020) || clinker_2020<=0, 42.7, clinker_2020)
  apply_ratio("S14", aco_prod[[cenario]][a],     aco_2020_safe)
  apply_ratio("S16", clinker_prod[[cenario]][a], clin_2020_safe)

  # Geração elétrica (TWh)
  apply_ratio("S40", geracao_elec[[cenario]][a], 679)

  # Biocombustíveis: base 2020 + incremento cenário
  apply_ratio("S22", 1020 + pj_etanol_ccs[[cenario]][a], 1020)   # etanol base 1020 PJ
  apply_ratio("S20", 230  + pj_diesel_vrd[[cenario]][a],  230)   # biodiesel base 230 PJ
  apply_ratio("S43", 900  + pj_biometano[[cenario]][a],   900)   # gás/biometano base 900 PJ

  delta_x
}

# ∆f equivalente (inverso Leontief do lado da oferta): ∆f = (I-A*)∆x
engine3_delta_f <- function(cenario, ano, A_star=NULL) {
  dx <- engine3_delta_x(cenario, ano)
  Am <- if (!is.null(A_star)) A_star else A
  as.vector((diag(N) - Am) %*% dx)
}
cat("  Engine 3 OK\n")

# =============================================================================
# PARTE 7 — ENGINE 4: COEFICIENTES DE EMISSÃO (MtCO2e / R$M)
# =============================================================================
cat("Construindo Engine 4 (e_coef)...\n")

engine4_e_coef <- function(cenario, ano, delta_x=NULL) {
  a <- as.character(ano)
  e <- setNames(numeric(N), setores$cod)
  x_proj <- if (!is.null(delta_x)) pmax(x + delta_x, 1) else pmax(x, 1)
  ghg <- ghg_mma[[cenario]]
  if (is.null(ghg) || !a %in% rownames(ghg)) return(e)

  alocar <- function(cods, ghg_val) {
    cs <- intersect(cods, names(x_proj))
    if (!length(cs) || is.na(ghg_val) || ghg_val==0) return()
    tx <- sum(x_proj[cs]); if (tx<=0) return()
    for (c in cs) e[c] <<- e[c] + (x_proj[c]/tx) * ghg_val / x_proj[c]
  }

  alocar(GRUPOS$agro,                                  ghg[a,"Agropecuaria"])
  alocar(GRUPOS$lulucf,                                ghg[a,"LULUCF"])
  alocar(c(GRUPOS$oleo_gas,GRUPOS$biocomb,GRUPOS$eletricidade), ghg[a,"Energia"])
  alocar(GRUPOS$ind_all,                               ghg[a,"Industria"])
  alocar(GRUPOS$transporte,                            ghg[a,"Transportes"])
  alocar(GRUPOS$cidades,                               ghg[a,"Cidades"])
  alocar(GRUPOS$residuos,                              ghg[a,"Residuos"])
  e
}
cat("  Engine 4 OK\n")

# =============================================================================
# PARTE 8 — LOOP DE SIMULAÇÕES
# =============================================================================
cat("Rodando simulações...\n")
resultados <- list()

for (cen in CENS_MMA) {
  for (ano in ANOS_MMA) {
    cat(sprintf("  %s | %d\n", cen, ano))

    # Engine 2: nova A* e L*
    A_star   <- engine2_A_star(cen, ano)
    L_star   <- engine2_L_star(A_star)

    # Engine 1: ∆f demanda final
    df1      <- engine1(cen, ano)
    # Engine 3: ∆f equivalente de produção exógena
    df3      <- engine3_delta_f(cen, ano, A_star)
    df_total <- df1 + df3

    # Propagação: ∆x = L* × ∆f
    dx_total <- as.vector(L_star %*% df_total)
    names(dx_total) <- setores$cod

    # Engine 4: coeficientes de emissão
    dx_exog  <- engine3_delta_x(cen, ano)
    e_coef   <- engine4_e_coef(cen, ano, delta_x=dx_total + dx_exog)

    # GHG direto do cenário MMA
    g   <- ghg_mma[[cen]]
    ghg_dir <- if (!is.null(g) && as.character(ano) %in% rownames(g))
                 sum(g[as.character(ano),], na.rm=TRUE) else NA_real_

    # Resultados por setor
    resultados[[paste(cen,ano,sep="_")]] <- data.frame(
      cenario         = cen,
      ano             = ano,
      cod             = setores$cod,
      nome            = setores$nome,
      x_base          = round(x, 1),
      delta_f_gdp     = round(engine1_gdp(cen, ano), 1),
      delta_f_inv     = round(engine1_inv(cen, ano), 1),
      delta_f_prod    = round(df3, 1),
      delta_f_total   = round(df_total, 1),
      delta_x_total   = round(dx_total, 1),
      delta_x_pct     = round(dx_total / x_safe * 100, 3),
      e_coef          = signif(e_coef, 4),
      ghg_induzido_mt = round(e_coef * dx_total, 6),
      mult_prod_star  = round(colSums(L_star), 4),
      stringsAsFactors = FALSE
    )
  }
}

res_all <- bind_rows(resultados)

# Resumo macro por cenário × ano
resumo <- res_all |>
  group_by(cenario, ano) |>
  summarise(
    delta_prod_bi        = round(sum(delta_x_total)/1e3, 2),
    delta_prod_pct_media = round(mean(delta_x_pct), 3),
    ghg_induzido_mt      = round(sum(ghg_induzido_mt), 3),
    inv_shock_bi         = round(sum(delta_f_inv)/1e3, 2),
    gdp_scaling_bi       = round(sum(delta_f_gdp)/1e3, 2),
    prod_shock_bi        = round(sum(delta_f_prod)/1e3, 2),
    .groups="drop"
  ) |>
  left_join(
    bind_rows(lapply(CENS_MMA, function(cen) {
      data.frame(cenario=cen, ano=ANOS_MMA,
                 ghg_cenario_mt = sapply(ANOS_STR, function(a) {
                   g <- ghg_mma[[cen]]
                   if (!is.null(g) && a %in% rownames(g)) sum(g[a,], na.rm=TRUE) else NA_real_
                 }), stringsAsFactors=FALSE)
    })),
    by=c("cenario","ano")
  )

cat(sprintf("  Simulações concluídas: %d cenário×ano\n", nrow(resumo)))

# =============================================================================
# PARTE 9 — EXPORTAÇÃO
# =============================================================================
cat("Exportando...\n")

top15 <- res_all |>
  group_by(cenario, ano) |>
  slice_max(order_by=abs(delta_x_total), n=15) |>
  select(cenario,ano,cod,nome,x_base,delta_x_total,delta_x_pct,
         delta_f_total,e_coef,ghg_induzido_mt) |>
  ungroup()

premissas <- data.frame(
  descricao = c(
    "Câmbio 2018 (R$/USD)","CPI US 2018→2023","Fator USD2023→R$2018",
    "Fator ajuste PIB 2018 vs 2020",
    "Elec. indústria 2020 (%)","Bio indústria 2020 (%)",
    "Elec. transporte 2020 (%)","Bio transporte 2020 (%)",
    "Elec. edifícios 2020 (%)","Gás edifícios 2020 (%)",
    "Cana 2020 (1000t)","Soja 2020 (1000t)","Milho 2020 (1000t)",
    "Aço 2020 (Mt)","Clinker 2020 (Mt)","Geração elétrica 2020 (TWh)",
    "Etanol base 2020 (PJ)","Biodiesel base 2020 (PJ)","Gás/biometano base 2020 (PJ)"
  ),
  valor = c(
    3.65, 1.25, USD2023_to_R2018, gdp_2018_factor,
    BASE2020$elec_ind, BASE2020$bio_ind,
    BASE2020$elec_tra, BASE2020$bio_tra,
    BASE2020$elec_cid, BASE2020$gas_cid,
    cana_2020, soja_2020, milho_2020,
    aco_2020_safe  <- ifelse(is.na(aco_2020)||aco_2020<=0,31.4,aco_2020),
    clin_2020_safe <- ifelse(is.na(clinker_2020)||clinker_2020<=0,42.7,clinker_2020),
    679, 1020, 230, 900
  ),
  stringsAsFactors=FALSE
)

maps_df <- bind_rows(lapply(names(GRUPOS), function(g)
  data.frame(grupo=g, cod=GRUPOS[[g]], stringsAsFactors=FALSE))) |>
  left_join(setores, by=c("cod"="cod"))

# ── Tabelas adicionais para o dashboard de engines ────────────────────────────

# Mix energético (Engine 2): % elec/bio/fossil por tipo de setor × cenário × ano
mix_rows <- list()
for (cen in CENS_MMA) {
  for (a in ANOS_STR) {
    pe_i <- elec_ind_pct[[cen]][a]; pb_i <- bio_ind_pct[[cen]][a]
    pe_t <- elec_tra_pct[[cen]][a]; pb_t <- bio_tra_pct[[cen]][a]
    pe_c <- elec_cid_pct[[cen]][a]; pb_c <- bio_cid_pct[[cen]][a]
    mix_rows[[length(mix_rows)+1]] <- data.frame(
      cenario=cen, ano=as.integer(a), tipo="Indústria",
      pct_elec=pe_i, pct_bio=pb_i, pct_fossil=pmax(1-pe_i-pb_i,0),
      base_elec=BASE2020$elec_ind, base_bio=BASE2020$bio_ind,
      base_fossil=pmax(1-BASE2020$elec_ind-BASE2020$bio_ind,0), stringsAsFactors=FALSE)
    mix_rows[[length(mix_rows)+1]] <- data.frame(
      cenario=cen, ano=as.integer(a), tipo="Transporte",
      pct_elec=pe_t, pct_bio=pb_t, pct_fossil=pmax(1-pe_t-pb_t,0),
      base_elec=BASE2020$elec_tra, base_bio=BASE2020$bio_tra,
      base_fossil=pmax(1-BASE2020$elec_tra-BASE2020$bio_tra,0), stringsAsFactors=FALSE)
    mix_rows[[length(mix_rows)+1]] <- data.frame(
      cenario=cen, ano=as.integer(a), tipo="Cidades",
      pct_elec=pe_c, pct_bio=pb_c, pct_fossil=pmax(1-pe_c-pb_c,0),
      base_elec=BASE2020$elec_cid, base_bio=BASE2020$bio_cid,
      base_fossil=pmax(1-BASE2020$elec_cid-BASE2020$bio_cid,0), stringsAsFactors=FALSE)
  }
}
mix_df <- bind_rows(mix_rows)

# Produção física (Engine 3): volumes por produto × cenário × ano
prod_fisica_rows <- list()
produtos <- list(
  list(cod="S04",  nome="Cana-de-açúcar",  serie=cana_prod,      base=cana_2020,     unidade="1000 t"),
  list(cod="S01",  nome="Soja",             serie=soja_prod,      base=soja_2020,     unidade="1000 t"),
  list(cod="S02",  nome="Milho",            serie=milho_prod,     base=milho_2020,    unidade="1000 t"),
  list(cod="S14",  nome="Aço",              serie=aco_prod,       base=aco_2020_safe, unidade="Mt"),
  list(cod="S16",  nome="Clinker/Cimento",  serie=clinker_prod,   base=clin_2020_safe,unidade="Mt"),
  list(cod="S40",  nome="Eletricidade",     serie=geracao_elec,   base=679,           unidade="TWh"),
  list(cod="S22",  nome="Etanol+CCS",       serie=pj_etanol_ccs,  base=0,             unidade="PJ incremento"),
  list(cod="S20",  nome="Diesel Verde",     serie=pj_diesel_vrd,  base=0,             unidade="PJ incremento"),
  list(cod="S43",  nome="Biometano/Gás",    serie=pj_biometano,   base=0,             unidade="PJ incremento")
)
for (cen in CENS_MMA) {
  for (a in ANOS_STR) {
    for (p in produtos) {
      v <- suppressWarnings(as.numeric(p$serie[[cen]][a]))
      prod_fisica_rows[[length(prod_fisica_rows)+1]] <- data.frame(
        cenario=cen, ano=as.integer(a),
        cod=p$cod, produto=p$nome, unidade=p$unidade,
        valor=ifelse(is.na(v),NA,round(v,2)),
        base_2020=p$base,
        variacao_pct=ifelse(!is.na(v) && p$base>0, round((v/p$base-1)*100,1), NA_real_),
        stringsAsFactors=FALSE)
    }
  }
}
prod_fisica_df <- bind_rows(prod_fisica_rows)

# PIB e População (Engine 1 input)
pib_pop_df <- data.frame(
  ano       = as.integer(ANOS_STR),
  gdp_index = as.numeric(gdp_idx),
  gdp_rel_2018 = as.numeric(gdp_idx) * gdp_2018_factor,
  crescimento_pct = round((as.numeric(gdp_idx) * gdp_2018_factor - 1) * 100, 2),
  pop_milhoes = as.numeric(pop_mil),
  stringsAsFactors=FALSE
)

# Alocação de investimento (Engine 1 — ALOC_INV)
aloc_df <- data.frame(
  cod      = names(ALOC_INV),
  aloc_pct = round(as.numeric(ALOC_INV) * 100, 2),
  stringsAsFactors=FALSE) |>
  left_join(setores |> select(cod, nome), by="cod") |>
  arrange(desc(aloc_pct))

# Multiplicadores de produção L* por cenário × ano (extraído de res_all)
mult_df <- res_all |>
  select(cenario, ano, cod, nome, mult_prod_star) |>
  arrange(cenario, ano, desc(mult_prod_star))

# Custos de investimento por cenário (Engine 1 inputs)
inv_df <- bind_rows(lapply(CENS_MMA, function(cen) {
  data.frame(
    cenario=cen, ano=ANOS_MMA,
    inv_bi_R2018=sapply(ANOS_MMA, function(a) round(inv_annual_R2018[[cen]][periodo_idx(a)]*1e3/1e3, 2)),
    stringsAsFactors=FALSE)
}))

dir.create("outputs/tables", showWarnings=FALSE, recursive=TRUE)
write_xlsx(
  list(
    "Resumo"              = resumo,
    "Top15_por_Setor"     = top15,
    "Resultados_Completos"= res_all,
    "Emissoes_Setoriais"  = res_all |> select(cenario,ano,cod,nome,e_coef,ghg_induzido_mt) |> filter(e_coef!=0),
    "Delta_F_Componentes" = res_all |> select(cenario,ano,cod,nome,delta_f_gdp,delta_f_inv,delta_f_prod,delta_f_total),
    "Mix_Energetico"      = mix_df,
    "Producao_Fisica"     = prod_fisica_df,
    "PIB_Pop"             = pib_pop_df,
    "Aloc_Investimento"   = aloc_df,
    "Multiplicadores"     = mult_df,
    "Investimento_Custos" = inv_df,
    "Premissas"           = premissas,
    "Mapeamento_Setores"  = maps_df
  ),
  path=if (tryCatch({f<-file("outputs/tables/mma_shock_results.xlsx","a");close(f);TRUE},error=function(e)FALSE))
    "outputs/tables/mma_shock_results.xlsx" else
    "outputs/tables/mma_shock_results_new.xlsx"
)
cat("  Salvo: outputs/tables/mma_shock_results.xlsx\n")

saveRDS(
  list(res_all=res_all, resumo=resumo, ghg_mma=ghg_mma,
       gdp_idx=gdp_idx, pop_mil=pop_mil,
       GRUPOS=GRUPOS, BASE2020=BASE2020, premissas=premissas,
       ANOS_MMA=ANOS_MMA, CENS_MMA=CENS_MMA),
  file="data/processed/mma_shocks.rds"
)
cat("  Salvo: data/processed/mma_shocks.rds\n")

# Console summary
cat("\n", strrep("=",60), "\n RESUMO SIMULAÇÕES\n", strrep("=",60), "\n", sep="")
print(resumo |> select(cenario,ano,delta_prod_bi,ghg_induzido_mt,ghg_cenario_mt) |> as.data.frame())
cat("\nConcluído.\n")
