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

# ── Engine flags ───────────────────────────────────────────────────────────────
# Engine 1 (GDP scaling + transition investment) and Engine 2 (energy mix ∆A)
# are always active. Engines 3 & 4 are parked for the current delivery scope.
RUN_ENGINE3 <- TRUE    # Physical production volumes → ∆f  (O&G + elec calibrated to MMA)
RUN_ENGINE4 <- FALSE   # Emission-intensity satellite account (scope: future)

# ── Política de Localização Industrial (toggle) ────────────────────────────────
# FALSE (padrão): conteúdo doméstico fixo — realidade atual de importações
#   Turbinas eólicas: 40% doméstico (60% importado — Vestas/Siemens)
#   Painéis solares:  20% doméstico (80% importado — China dominante)
#   Baterias utility: 30% doméstico (70% importado)
#
# TRUE: conteúdo doméstico cresce linearmente 2026→2050, simulando:
#   política industrial de nacionalização da cadeia de energias renováveis
#   (ex: BNDES/Finame requisitos de conteúdo local, zonas francas, etc.)
#   Turbinas: 40% → 70%  |  Painéis: 20% → 55%  |  Baterias: 30% → 65%
#
# O toggle afeta apenas ALOC_INV (destino do FBCF de transição).
# Engine 2 e Engine 3 (técnicos/físicos) são idênticos em ambos os casos.
# Ambas as versões (LP e no-LP) são sempre exportadas para comparação no dashboard.
LOCALIZ_POLICY <- FALSE   # <── TOGGLE: TRUE = política de localização ativa

cat("=== MMA Shock Engines ===\n")
cat(sprintf("  Engines active: 1=YES  2=YES  3=%s  4=%s\n",
            ifelse(RUN_ENGINE3,"YES","no"), ifelse(RUN_ENGINE4,"YES","no")))

# =============================================================================
# PARTE 1 — CARREGA MODELO IO (via mip_epe_replication.R)
# =============================================================================
setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")

MMA_PATH <- "data/raw/Planilha_Detalhamento Resultados MMA-SMC v3 AR5 (07_10_2024).xlsx"
stopifnot(file.exists(MMA_PATH))

# Source mip_epe_replication in data-only mode: loads A, L, Z, x, x_safe,
# setores, N, DF, ALPHA, satellite, SAT_COEF, SAT_MULT and all helper functions.
# Sections 10–12 (exercises, summary, export) are skipped.
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")

# ── Aliases so the rest of this script keeps its original variable names ───────
# mip_epe_replication  → mma_shock_engines (legacy name)
#   ALPHA              → alpha_energia   (ktep / R$M, 6 sources × 73 sectors)
#   DF                 → demanda_final   (73 × 6 final demand, col names remapped)
alpha_energia <- ALPHA
demanda_final <- as.data.frame(DF)
colnames(demanda_final) <- c("Exportacoes","Gov","ISFLSF","Familias","FBCF","Var_Estoque")
demanda_final$cod <- setores$cod

cat("  IO carregado via mip_epe_replication: A, L, Z, x, ALPHA, satellite\n")

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
gdp_2018_factor <- 0.97   # GDP_2020 / GDP_2018 ≈ 0.97 (COVID contraction)
# IBGE real GDP: 2018→2019 +1.1%, 2019→2020 -3.9% → 1.011×0.961 = 0.972.
# The MMA gdp_idx is indexed to 2020=1; the MIP is in 2018 R$.
# Multiply gdp_idx by this ratio to convert to a 2018-based growth factor.
# NOTE: this factor is UNRELATED to the investment deflation (USD2023→R$2018),
# which uses the US CPI (1/1.25 ≈ 0.80) in a separate step in Engine 1b.

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
# Linhas verificadas: 16=energia primária, 17=energia final, 49=geração elétrica
# 62-68=% geração por fonte, 76=etanol+CCS, 78=diesel verde, 79=biometano
energia_primaria  <- get_scenario_row(en, 16)   # Mtep
geracao_elec      <- get_scenario_row(en, 49)   # TWh
pj_etanol_ccs     <- get_scenario_row(en, 76)   # PJ — Etanol + CCS
pj_diesel_vrd     <- get_scenario_row(en, 78)   # PJ — Diesel Verde (HVO)
pj_biometano      <- get_scenario_row(en, 79)   # PJ — Biometano/Gás
pj_gasolina_verde <- get_scenario_row(en, 77)   # PJ — Gasolina Verde (base 2020 = 0)
pj_bioqav         <- get_scenario_row(en, 80)   # PJ — BioQAV / SAF (base 2020 = 0)
pj_bunker_verde   <- get_scenario_row(en, 81)   # PJ — Bunker Verde (base 2020 = 0)

# ── 2.3c  Petróleo & Gás — volumes físicos (Sheet 4) ─────────────────────
# Linhas verificadas via _diag_mma_rows.R:
#   R37 = produção petróleo (kbep)          → Engine 3: S05
#   R39 = consumo bruto óleo cru (kbep)     → Engine 2: INDICADOR S19
#   R40 = derivados consumo doméstico (ktep) → Engine 2+3: S19
#   R41 = derivados exportação (ktep)        → Engine 2+3: S19
# Metodologia: BLUES INDICADOR — redução de consumo de cru por unidade de
# derivado captura coprocessamento (biomassa substituindo petróleo na refinaria).
prod_oleo      <- get_scenario_row(en, 37)   # kbep — produção bruta S05
consumo_bruto  <- get_scenario_row(en, 39)   # kbep — cru consumido pelas refinarias
deriv_dom      <- get_scenario_row(en, 40)   # ktep — derivados consumo doméstico
deriv_exp      <- get_scenario_row(en, 41)   # ktep — derivados exportação
prod_oleo_2020     <- get_base2020(en, 37)
consumo_bruto_2020 <- get_base2020(en, 39)
deriv_dom_2020     <- get_base2020(en, 40)
deriv_exp_2020     <- get_base2020(en, 41)
# Derivados total = doméstico + exportação (proxy output refinaria S19)
deriv_total <- lapply(CENS_MMA, function(cen)
  setNames(deriv_dom[[cen]] + deriv_exp[[cen]], ANOS_STR))
names(deriv_total) <- CENS_MMA
deriv_total_2020 <- deriv_dom_2020 + deriv_exp_2020

# ── 2.3b  Geração Elétrica — mix por fonte (% geração, Sheet 4) ───────────
# Usadas no Engine 2 para modificar A[S19/S43, S40/S41] (insumo fóssil de
# geração termelétrica) conforme a transição de fóssil→renovável na grade.
# Biomassa inclui biomassa convencional (R65) + biomassa+CCS (R66), pois ambas
# mantêm demanda por biocombustíveis (S22) como insumo de geração.
# Hidro/Eólica/Solar/Nuclear não têm linha de insumo energético na MIP → não
# entram nos fatores de escala (sc_e = 1, sem alteração nas linhas S40/S41).
foss_gen_pct <- get_scenario_row(en, 68)              # % geração fóssil
foss_gen_2020 <- get_base2020(en, 68)                 # 0.146
# Biomassa total = convencional + CCS (ambas usam S22 como insumo)
safe_sum2 <- function(df, r1, r2, cols) {
  safe <- function(v) { v <- suppressWarnings(as.numeric(unlist(v))); v[is.na(v)] <- 0; setNames(v, ANOS_STR) }
  list("25D"  = safe(df[r1, cols[1]:cols[2]]) + safe(df[r2, cols[1]:cols[2]]),
       "100D" = safe(df[r1, cols[3]:cols[4]]) + safe(df[r2, cols[3]:cols[4]]),
       "0D"   = safe(df[r1, cols[1]:cols[2]]) + safe(df[r2, cols[1]:cols[2]]))  # fallback = 25D
}
bio_gen_pct   <- safe_sum2(en, 65, 66, c(5,10,12,17))  # R65 biomassa + R66 biomassa+CCS
bio_gen_2020  <- sum(suppressWarnings(as.numeric(c(en[[65,3]], en[[66,3]]))), na.rm=TRUE)  # 0.093

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

# ── 2.4b  Indústria — sub-setores (BLUES-style, Planilha MMA Sheet 5) ─────
# Rows verified via _diag_mma_rows.R; cols_25d=5:10, cols_100d=12:17
# Ferro e Aço
foss_ferro_pct  <- get_scenario_row(ind, 32); foss_ferro_2020  <- get_base2020(ind, 32)  # 0.619
bio_ferro_pct   <- get_scenario_row(ind, 33); bio_ferro_2020   <- get_base2020(ind, 33)  # 0.290
elec_ferro_pct  <- get_scenario_row(ind, 34); elec_ferro_2020  <- get_base2020(ind, 34)  # 0.091
# Cimento
foss_cim_pct    <- get_scenario_row(ind, 45); foss_cim_2020    <- get_base2020(ind, 45)  # 0.674
bio_cim_pct     <- get_scenario_row(ind, 46); bio_cim_2020     <- get_base2020(ind, 46)  # 0.183
elec_cim_pct    <- get_scenario_row(ind, 47); elec_cim_2020    <- get_base2020(ind, 47)  # 0.144
# Químico
foss_qui_pct    <- get_scenario_row(ind, 56); foss_qui_2020    <- get_base2020(ind, 56)  # 0.666
bio_qui_pct     <- get_scenario_row(ind, 57); bio_qui_2020     <- get_base2020(ind, 57)  # 0.023
elec_qui_pct    <- get_scenario_row(ind, 58); elec_qui_2020    <- get_base2020(ind, 58)  # 0.312
# Outros Indústria
foss_out_pct    <- get_scenario_row(ind, 67); foss_out_2020    <- get_base2020(ind, 67)  # 0.307
bio_out_pct     <- get_scenario_row(ind, 68); bio_out_2020     <- get_base2020(ind, 68)  # 0.261
elec_out_pct    <- get_scenario_row(ind, 69); elec_out_2020    <- get_base2020(ind, 69)  # 0.433

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
# R68=cana(1000t), R72=milho total(1000t), R79=soja total(1000t)
# R77=oleaginosas energéticas (non-soja; girassol/canola/palma) (1000t)
cana_prod      <- get_scenario_row(ag, 68)
milho_prod     <- get_scenario_row(ag, 72)
soja_prod      <- get_scenario_row(ag, 79)
olea_prod      <- get_scenario_row(ag, 77)    # 1000t — oleaginosas energéticas (non-soja)
cana_2020      <- get_base2020(ag, 68)         # 692714 (1000t)
milho_2020     <- get_base2020(ag, 72)         # 108304
soja_2020      <- get_base2020(ag, 79)         # 123491
olea_2020      <- 4720                         # MMA Planilha 2, R77, col3 (confirmado)

# Área agrícola (1000 ha) — contexto no dashboard; não calibra coeficientes IO
area_alimentos   <- get_scenario_row(ag, 115)  # Área de Alimentos (1000 ha)
area_energeticos <- get_scenario_row(ag, 116)  # Área de Energéticos (1000 ha)
area_alim_2020   <- 48562                      # MMA Planilha 2, R115, col3
area_ener_2020   <- 34401                      # MMA Planilha 2, R116, col3

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
  ind_aco      = c("S29"),   # S29 = Prod. ferro-gusa/ferroligas/siderurgia
  ind_cimento  = c("S28"),   # S28 = Fabricação de produtos de minerais não-metálicos
  # ind_quimico: apenas S24 (defensivos/tintas) — genuinamente petroquímico.
  # S25 (cosméticos) e S26 (farmoquímicos) EXCLUÍDOS: A[S22,S25]=0.025 e
  # A[S22,S26]=0.009 representam INSUMOS FEEDSTOCK (óleos vegetais, substratos de
  # fermentação), não energia biomassa. Aplicar sc_bio química (até 28.9×) ou
  # zerá-los em 2025 (sc_bio=0) gera explosão espúria de fóssil (+200%/+174%).
  # S25 e S26 migram para ind_outros (manufactura leve — trajetória mais suave).
  ind_quimico  = c("S24"),
  ind_outros   = c("S10","S11","S12","S13","S14","S15","S16","S17","S18","S23",
                   "S25","S26",   # cosméticos e farmoquímicos — feedstock bio, não energia
                   "S27","S30","S31","S32","S33","S34",
                   "S35","S36","S37","S38","S39"),
  ind_all      = c("S10","S11","S12","S13","S14","S15","S16","S17","S18",
                   "S23","S24","S25","S26","S27","S28","S29","S30","S31",
                   "S32","S33","S34","S35","S36","S37","S38","S39"),
  transporte   = c("S48","S49","S50","S51","S52"),  # S48 terrestre, S49 aquaviário, S50 aéreo, S51 armazenamento, S52 correio
  cidades      = c("S52","S53","S59","S66","S67","S68","S69","S70"),
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

# Setores calibrados pelo Engine 3: sua trajetória de produção é fixada pelos
# volumes físicos MMA (Engine 3), não pelo crescimento do PIB (Engine 1).
# Zeramos o componente GDP-scaling nesses setores para evitar dupla contagem.
# Regra: todo setor com apply_ratio() em engine3_delta_x deve estar aqui.
#
#   S05 = Extrativa petróleo/gás: pico 2030 + declínio 58% até 2050
#   S19 = Refino/derivados: segue deriv_dom + deriv_exp (MMA R40+R41)
#   S40 = Geração elétrica: segue TWh gerados (MMA R49)
#   S42 = Transmissão: proporcional à geração
#   S22 = Biocombustíveis avançados: etanol+CCS + gasolina verde + BioQAV
#   S20 = Biodiesel/HVO: diesel verde (MMA R78)
#   S43 = Gás/Biometano: 900 PJ base + crescimento biometano (MMA R79)
#   S29 = Siderurgia: produção de aço (MMA R27, Mt)
#   S28 = Cimento/Minerais: produção de clínquer (MMA R41, Mt)
# S01 (Agropecuária) NOT listed here. S01 is treated as GDP-only (Engine 1a)
# plus Leontief backward linkages from the energy sectors (S22, S20, S19, etc.).
# Those sectors already use soja/cana/olea as intermediate inputs (A matrix);
# when Engine 3 scales their physical output, Leontief propagates the implied
# agricultural demand back to S01 automatically via L[S01,S22], L[S01,S19], etc.
# A manual Engine 3 crop calibration on S01 would (a) double-count that indirect
# demand and (b) create a spurious negative "transition effect" in the dashboard
# because energy crops grow below GDP pace in all scenarios.
# Future improvement: Option 2 — differential 100D vs 25D policy delta for S01
# — is documented but not yet implemented.
ENGINE3_SECTORS <- c("S05","S19","S40","S42",
                     "S22","S20","S43",
                     "S29","S28")

# 4a: Escala PIB — crescimento da demanda final relativo a 2018
# Setores em ENGINE3_SECTORS recebem delta_f=0 aqui quando Engine 3 ativo.
engine1_gdp <- function(cenario, ano) {
  g  <- gdp_rel_2018[as.character(ano)]
  df <- f_base * (g - 1)
  if (RUN_ENGINE3)
    for (s in ENGINE3_SECTORS) if (s %in% names(df)) df[s] <- 0
  df
}

# 4b: Investimento de transição — alocado como FBCF por setor IO
#
# TIMING: Em 2026 o investimento ainda não foi realizado. Portanto investimento
# de transição só entra a partir de 2030 (primeiro ano de modelo após 2026).
# 2025 retorna delta_f = 0 para evitar salto artificial no ano base.
#
# ALOCAÇÃO DATA-DRIVEN: pesos derivados das adições físicas de capacidade
# da planilha MMA (Sheet 4 Energia + Sheet 6 Transporte + Sheet 7 Cidades),
# combinados com fatores de custo de capital por tecnologia (IRENA/EPE referência).
#
# Categorias de capex incluídas:
#   1. Eletricidade: eólica(+120 GW), solar(+19 GW), hidro(+13 GW), nuclear(+0.7 GW),
#                   biomassa+CCS(+11.7 GW), bateria armazenamento(+11 GW)
#   2. Biocombustíveis: biometano+dieselVerde+bioQAV (2.567 PJ na 100D 2050)
#   3. Coprocessamento refinaria: diesel verde + etanol CCS PJ requerem upgrade
#      de plantas de hidrotratamento/co-processamento em S19
#   4. Frota EV: ΔPJ_elétrico transporte × fator (Sheet 6 R13×R14)
#   5. Eficiência edificações: Δ% elétrico cidades × fator (Sheet 7 R26)
#
# CapEx unitário ($M): eólica $1.2B/GW, solar $0.7B/GW, hidro $2.5B/GW,
#   nuclear $8B/GW, biomCCS $2.5B/GW, bateria $0.3B/GW, biofuels $40M/PJ,
#   coprocessamento $15M/PJ, EV $15M/PJ, edificações $30B/unidade-fração
#
# Mapeamento tecnologia → setor IO (100D pesos pré-normalização):
#   Eólica:      S34(50%×40%dom) S45(30%) S33(10%) S42(10%)  [S34=máq.mecânicos; S37=transporte]
#   Solar:       S32(40%×20%dom) S45(30%) S33(20%) S42(10%)
#   Hidro:       S45(60%) S30(25%) S42(15%)
#   Nuclear:     S45(50%) S39(50%)
#   BiomCCS:     S22(35%) S45(40%) S33(15%) S30(10%)
#   Baterias:    S32(60%×30%dom) S33(40%)
#   Biofuels:    S22(50%) S45(42%) S30(8%)   [S20 removido — Engine3 já cresce S20]
#   Coprocss:    S19(40%) S45(35%) S33(15%) S27(10%)
#   EV fleet:    S35(40%) S36(40%) S33(20%)
#   Edificações: S45(55%) S33(30%) S32(15%)
#   [S45 = Construção; S44 = Água/esgoto — NÃO usar para capex civil]
#   [%dom = conteúdo doméstico: turbinas 40%, painéis 20%, baterias 30%]
#
# Pesos resultantes aprox. (normalizados, 100D 2050, pós-ajustes):
#   S45~40%, S22~19%, S33~9%, S42~7%, S30~4%, S34~9%, S32~1%,
#   S19~2%, S39~1%, S35~1%, S36~1%, S27~0.5%  [S20 excluído]
#
# NOTA: S40/S41/S29/S28 excluídos — crescem via Engine 3 (volume físico MMA).

# Função auxiliar: deriva pesos por cenário × ano a partir dos dados físicos MMA
# localiz: se TRUE aplica trajetória crescente de conteúdo doméstico (LOCALIZ_POLICY)
derive_aloc_inv <- function(cenario, ano = "2050", localiz = LOCALIZ_POLICY) {
  # col 2050: 100D=col17, 25D e 0D=col10 (0D é near-BAU → usa 25D como proxy)
  col50 <- if (cenario == "100D") 17L else 10L

  get_en  <- function(row) { v <- suppressWarnings(as.numeric(en[[row, col50]])); if(is.na(v)) 0 else v }
  get_en_b<- function(row) { v <- suppressWarnings(as.numeric(en[[row, 3]]));    if(is.na(v)) 0 else v }
  get_tr  <- function(row) { v <- suppressWarnings(as.numeric(tr[[row, col50]])); if(is.na(v)) 0 else v }
  get_tr_b<- function(row) { v <- suppressWarnings(as.numeric(tr[[row, 3]]));    if(is.na(v)) 0 else v }
  get_ci  <- function(row) { v <- suppressWarnings(as.numeric(ci[[row, col50]])); if(is.na(v)) 0 else v }
  get_ci_b<- function(row) { v <- suppressWarnings(as.numeric(ci[[row, 3]]));    if(is.na(v)) 0 else v }

  # ── 1. Eletricidade — adições de capacidade instalada (GW) ───────────────
  d_eol    <- max(get_en(51) - get_en_b(51), 0)   # eólica
  d_sol    <- max(get_en(52) - get_en_b(52), 0)   # solar
  d_hid    <- max(get_en(53) - get_en_b(53), 0)   # hidro
  d_nuc    <- max(get_en(56) - get_en_b(56), 0)   # nuclear
  d_bioccs <- max(get_en(55), 0)                   # biomassa+CCS (base=0)
  d_bat    <- max(get_en(58), 0)                   # armazenamento baterias (base=0)

  inv_eol    <- d_eol    * 1200   # $M/GW — IRENA 2023 Brasil
  inv_sol    <- d_sol    * 700
  inv_hid    <- d_hid    * 2500
  inv_nuc    <- d_nuc    * 8000   # referência Angra 3
  inv_bioccs <- d_bioccs * 2500   # BECCS: capex similar à biomassa convencional
  inv_bat    <- d_bat    * 300    # utility-scale battery (custo caindo)

  # ── 2. Biocombustíveis — PJ de capacidade instalada 2050 ─────────────────
  pj_bmet  <- get_en(79)   # biometano
  pj_dvrd  <- get_en(78)   # diesel verde (HVO)
  pj_qav   <- get_en(80)   # bioQAV
  pj_etccs <- get_en(76)   # etanol+CCS

  inv_bfuel <- (pj_bmet + pj_dvrd + pj_qav) * 40   # $M/PJ — planta biorrefinaria

  # ── 3. Coprocessamento em refinarias (S19) ────────────────────────────────
  # Diesel verde + etanol CCS processados em refinarias de petróleo exigem
  # upgrade de unidades de hidrotratamento e coprocessamento
  inv_copro <- (pj_dvrd + pj_etccs) * 15   # $M/PJ — fração do capex de refinaria

  # ── 4. Eletrificação do transporte (frota EV) ────────────────────────────
  # Sheet 6: R13=PJ total transporte, R14=% elétrico → ΔPJ elétrico
  delta_pj_ev <- max(get_tr(13) * get_tr(14) - get_tr_b(13) * get_tr_b(14), 0)
  inv_ev <- delta_pj_ev * 15   # $M/PJ — prêmio frota EV + infraestrutura recarga

  # ── 5. Eficiência e eletrificação de edificações ─────────────────────────
  # Sheet 7: R26=% elétrico nos usos finais de cidades (fração 0-1)
  delta_elec_cid <- max(get_ci(26) - get_ci_b(26), 0)
  inv_bldg <- delta_elec_cid * 30000   # $M por fração-unit (~0.2 → $6B)

  # ── 6. Conteúdo doméstico dos equipamentos importados ────────────────────
  # Interpolação linear entre valor base (2026) e valor alvo (2050).
  # LOCALIZ_POLICY=FALSE → constante no nível base (sem política de localização)
  # LOCALIZ_POLICY=TRUE  → cresce até o alvo (política industrial de conteúdo local)
  ano_n <- as.numeric(ano)
  t_loc <- if (localiz) max(0, min(1, (ano_n - 2026) / (2050 - 2026))) else 0

  dom_eol <- 0.40 + (0.70 - 0.40) * t_loc   # turbinas: 40% → 70% doméstico
  dom_sol <- 0.20 + (0.55 - 0.20) * t_loc   # painéis:  20% → 55%
  dom_bat <- 0.30 + (0.65 - 0.30) * t_loc   # baterias: 30% → 65%

  # ── 7. Mapeamento tecnologia → setor IO ──────────────────────────────────
  # NOTA: S45 = Construção (obras civis), S44 = Água/esgoto (errado para capex)

  raw <- c(
    S34 = inv_eol    * 0.50 * dom_eol,                  # turbinas eólicas — máq. e equip. mecânicos (CNAE 2821-6; S37=transporte, não turbinas)
    S32 = inv_sol    * 0.40 * dom_sol +                  # painéis (fração doméstica)
          inv_bat    * 0.60 * dom_bat +                  # baterias (fração doméstica)
          inv_bldg   * 0.15,                             # controles smart edilícios
    S45 = inv_eol    * 0.30 + inv_sol    * 0.30 +
          inv_hid    * 0.60 + inv_nuc    * 0.50 +
          inv_bioccs * 0.40 + inv_bfuel  * 0.42 +       # +0.12 redirecionado de S20
          inv_copro  * 0.35 + inv_bldg   * 0.55,        # Construção (obras civis, todas tecno.)
    S33 = inv_eol    * 0.10 + inv_sol    * 0.20 +
          inv_bat    * 0.40 + inv_bioccs * 0.15 +
          inv_copro  * 0.15 + inv_ev     * 0.20 +
          inv_bldg   * 0.30,                             # equip. elétricos (inversores, HVAC)
    S42 = inv_eol    * 0.10 + inv_sol    * 0.10 +
          inv_hid    * 0.15,                             # transmissão e distribuição
    S30 = inv_hid    * 0.25 + inv_bioccs * 0.10 +
          inv_bfuel  * 0.08,                             # metalurgia + vasos biodiesel (de S20)
    S22 = inv_bioccs * 0.35 + inv_bfuel  * 0.50,        # complexo biocombustíveis (supply chain)
    # S20 removido: Engine 3 já cresce S20 via volume físico MMA; sem FBCF direto
    S39 = inv_nuc    * 0.50,                             # manutenção/engenharia nuclear
    S19 = inv_copro  * 0.40,                             # coprocessamento em refinaria
    S27 = inv_copro  * 0.10,                             # material plástico/borracha (tubulação)
    S35 = inv_ev     * 0.40,                             # automóveis (prêmio EV)
    S36 = inv_ev     * 0.40                              # peças/baterias veiculares
  )
  raw <- raw[names(raw) %in% setores$cod]
  if (sum(raw) < 1e-6) raw <- raw + 1e-6    # guard against all-zero
  raw / sum(raw)
}

# Pré-computa pesos por cenário × ano (dois conjuntos: sem e com política)
# ALOC_INV_NOLP: conteúdo doméstico fixo (sem política de localização)
# ALOC_INV_LP:   conteúdo doméstico crescente (com política de localização)
# ALOC_INV:      conjunto ativo, determinado por LOCALIZ_POLICY
build_aloc <- function(localiz) {
  setNames(lapply(CENS_MMA, function(cen)
    setNames(lapply(ANOS_MMA, function(a) derive_aloc_inv(cen, a, localiz=localiz)),
             ANOS_MMA)
  ), CENS_MMA)
}
ALOC_INV_NOLP <- build_aloc(FALSE)
ALOC_INV_LP   <- build_aloc(TRUE)
ALOC_INV      <- if (LOCALIZ_POLICY) ALOC_INV_LP else ALOC_INV_NOLP

# Diagnóstico: imprime pesos para 2030 e 2050 (100D, ambas as políticas)
for (cen in c("100D")) {
  for (a in c("2030","2050")) {
    nolp <- ALOC_INV_NOLP[[cen]][[a]]
    lp   <- ALOC_INV_LP[[cen]][[a]]
    cat(sprintf("  ALOC_INV %s [%s] sem-LP: %s\n", cen, a,
      paste(sprintf("%s=%.0f%%", names(nolp), 100*nolp), collapse=" ")))
    cat(sprintf("  ALOC_INV %s [%s] com-LP: %s\n", cen, a,
      paste(sprintf("%s=%.0f%%", names(lp),   100*lp),   collapse=" ")))
  }
}

# Período de investimento: CAE por faixa de horizonte
# 2025 → zero (ainda não realizado; estamos em 2026)
# 2030 → CAE período 2020-2030 (proxy: aceleração inicial 2026-2030)
# 2035 → CAE período 2020-2035
# 2040-2050 → CAE período 2020-2050
periodo_idx <- function(ano) {
  ano_n <- as.numeric(ano)
  if (ano_n < 2030) return(0L)        # 2025: sem investimento (pré-2030)
  if (ano_n <= 2030) return(1L)       # 2030: CAE período 2020-2030
  if (ano_n <= 2035) return(2L)       # 2035: CAE período 2020-2035
  return(3L)                           # 2040-2050: CAE período 2020-2050
}

engine1_inv <- function(cenario, ano) {
  pi <- periodo_idx(ano)
  delta_f <- numeric(N); names(delta_f) <- setores$cod
  if (pi == 0L) return(delta_f)        # 2025: sem choque de investimento
  inv_RM <- inv_annual_R2018[[cenario]][pi] * 1000
  aloc   <- ALOC_INV[[cenario]][[as.character(ano)]]  # pesos ano-específicos
  for (cod in names(aloc)) delta_f[cod] <- delta_f[cod] + inv_RM * aloc[cod]
  delta_f
}

engine1 <- function(cenario, ano) engine1_gdp(cenario, ano) + engine1_inv(cenario, ano)
cat("  Engine 1 OK\n")

# =============================================================================
# PARTE 5 — ENGINE 2: COEFICIENTES TÉCNICOS (∆A = substituição de energia)
# =============================================================================
cat("Construindo Engine 2 (∆A)...\n")

BASE2020 <- list(
  elec_ind  = ifelse(is.na(elec_ind_2020), 0.33,  elec_ind_2020),
  bio_ind   = ifelse(is.na(bio_ind_2020),  0.23,  bio_ind_2020),
  elec_tra  = ifelse(is.na(elec_tra_2020), 0.004, elec_tra_2020),
  bio_tra   = ifelse(is.na(bio_tra_2020),  0.303, bio_tra_2020),
  elec_cid  = ifelse(is.na(elec_cid_2020), 0.625, elec_cid_2020),
  gas_cid   = ifelse(is.na(gas_cid_2020),  0.260, gas_cid_2020),
  # bio_cid_2020 from MMA R27 is a single biomass sub-type (≈1.86e-5, near zero).
  # The correct base share for "other / biomass / thermal" in buildings is inferred
  # as the residual: 1 - elec - gas = 1 - 0.625 - 0.260 = 0.115 (11.5%).
  # Using the spreadsheet value directly would produce sc_b = 10.8% / 0.002% ≈ 5800×.
  bio_cid   = max(1 - ifelse(is.na(elec_cid_2020), 0.625, elec_cid_2020) -
                      ifelse(is.na(gas_cid_2020),  0.260, gas_cid_2020), 0),
  # Geração elétrica: shares do mix de geração (proxy para insumos energéticos de S40/S41)
  foss_gen  = ifelse(is.na(foss_gen_2020), 0.146, foss_gen_2020),
  bio_gen   = ifelse(is.na(bio_gen_2020),  0.093, bio_gen_2020)
)

engine2_A_star <- function(cenario, ano) {
  # 0D = sem transição → coeficientes técnicos permanecem em 2018; sem Engine 2.
  if (cenario == "0D") return(A)

  a      <- as.character(ano)
  A_star <- A

  # ── Método BLUES-style (sub-setor) ──────────────────────────────────────────
  # Para cada sub-setor MMA, calculamos fatores de escala por combustível:
  #   sc_fuel = share_fuel_cenario / share_fuel_2020
  # Os fatores são aplicados às linhas energéticas da coluna j de A_star,
  # seguidos de normalização que preserva a intensidade energética total
  # (soma dos coef. elétrico+bio+fóssil por coluna). A normalização é necessária
  # para evitar instabilidade numérica em L* = (I−A*)⁻¹ quando sc_e chega a 46×
  # (transporte elétrico: 0.36% → 16.7%). Verificado via diag_engine2.R.
  #
  # Diferença vs. abordagem anterior: cada sub-setor MMA (Ferro e Aço, Cimento,
  # Químico, Outros, Transporte, Cidades) usa seus próprios fatores de escala,
  # em vez de um único fator agregado para toda a indústria. Isso captura a
  # trajetória diferenciada de descarbonização entre sub-setores, seguindo a
  # metodologia BLUES/MMA descrita em "Insumo para Matriz Substituição Energia".

  # normalize=TRUE: preserva intensidade energética total (necessário quando sc_e
  # pode ser muito grande, ex: transporte elétrico 0.36%→16.7% → sc_e=46×).
  # normalize=FALSE: aplica fatores de escala diretamente — correto quando a mudança
  # é uma redução genuína de intensidade, ex: geração elétrica elimina 95% do fóssil.
  rebalancear <- function(setor_cods,
                          pct_e_new, pct_b_new, pct_f_new,
                          pct_e_base, pct_b_base, pct_f_base,
                          normalize = TRUE) {
    sc_e <- if (pct_e_base > 1e-6) pct_e_new / pct_e_base else 0
    sc_b <- if (pct_b_base > 1e-6) pct_b_new / pct_b_base else 0
    sc_f <- if (pct_f_base > 1e-6) pct_f_new / pct_f_base else 1
    for (j in setor_cods) {
      if (!(j %in% colnames(A_star))) next
      e_elec <- sum(A_star[intersect(c("S40","S41"), rownames(A_star)), j])
      e_bio  <- sum(A_star[intersect(c("S20","S22"), rownames(A_star)), j])
      e_foss <- sum(A_star[intersect(c("S19","S43"), rownames(A_star)), j])
      total  <- e_elec + e_bio + e_foss
      if (total <= 0) next
      new_e_raw <- e_elec * sc_e
      new_b_raw <- e_bio  * sc_b
      new_f_raw <- e_foss * sc_f
      sum_raw   <- new_e_raw + new_b_raw + new_f_raw
      if (sum_raw <= 0) next
      if (normalize) {
        # Normalização: preserva intensidade energética total por setor
        new_e <- total * new_e_raw / sum_raw
        new_b <- total * new_b_raw / sum_raw
        new_f <- total * new_f_raw / sum_raw
      } else {
        # Escalonamento direto: a intensidade total muda com a transição
        new_e <- new_e_raw
        new_b <- new_b_raw
        new_f <- new_f_raw
      }
      # Distribui dentro de cada sub-grupo proporcionalmente às shares existentes
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
        A_star["S22", j] <<- new_b
      }
      if (e_foss > 0) {
        for (r in intersect(c("S19","S43"), rownames(A_star)))
          A_star[r, j] <<- A_star[r, j] / e_foss * new_f
      }
    }
    A_star
  }

  # ── Indústria — 4 sub-setores MMA com fatores de escala próprios ───────────
  # Ferro e Aço → GRUPOS$ind_aco
  pf <- foss_ferro_pct[[cenario]][a]; pb <- bio_ferro_pct[[cenario]][a]
  pe <- elec_ferro_pct[[cenario]][a]
  if (!anyNA(c(pe,pb,pf)))
    A_star <- rebalancear(GRUPOS$ind_aco,
                          pe, pb, pf,
                          elec_ferro_2020, bio_ferro_2020, foss_ferro_2020)

  # Cimento → GRUPOS$ind_cimento
  pf <- foss_cim_pct[[cenario]][a]; pb <- bio_cim_pct[[cenario]][a]
  pe <- elec_cim_pct[[cenario]][a]
  if (!anyNA(c(pe,pb,pf)))
    A_star <- rebalancear(GRUPOS$ind_cimento,
                          pe, pb, pf,
                          elec_cim_2020, bio_cim_2020, foss_cim_2020)

  # Químico → GRUPOS$ind_quimico
  pf <- foss_qui_pct[[cenario]][a]; pb <- bio_qui_pct[[cenario]][a]
  pe <- elec_qui_pct[[cenario]][a]
  if (!anyNA(c(pe,pb,pf)))
    A_star <- rebalancear(GRUPOS$ind_quimico,
                          pe, pb, pf,
                          elec_qui_2020, bio_qui_2020, foss_qui_2020)

  # Outros Indústria → GRUPOS$ind_outros
  pf <- foss_out_pct[[cenario]][a]; pb <- bio_out_pct[[cenario]][a]
  pe <- elec_out_pct[[cenario]][a]
  if (!anyNA(c(pe,pb,pf)))
    A_star <- rebalancear(GRUPOS$ind_outros,
                          pe, pb, pf,
                          elec_out_2020, bio_out_2020, foss_out_2020)

  # ── Transporte — por sub-modal ─────────────────────────────────────────────
  # S48 terrestre + S51 armazenamento + S52 correio seguem o mix agregado MMA
  # (eletrificação via VEs + biocombustíveis terrestres).
  # S49 aquaviário e S50 aéreo NÃO se eletrificam no horizonte do modelo:
  #   o fator sc_e = elec_tra_2020%→cenário% ≈ 46× aplicado sobre base≈0 de
  #   eletricidade em S49/S50 produzia explosões espúrias (+2271%/+8360%).
  #   Estes modais usam trajetórias físicas dedicadas dos dados MMA:
  #     S49: pj_bunker_verde (bunker verde / amônia / HVO marítimo)
  #     S50: pj_bioqav       (combustível de aviação sustentável — SAF)
  pe_t <- elec_tra_pct[[cenario]][a]; pb_t <- bio_tra_pct[[cenario]][a]
  pf_t <- max(1 - pe_t - pb_t, 0)
  if (!anyNA(c(pe_t, pb_t)))
    A_star <- rebalancear(c("S48","S52"),          # S49/S50/S51 fora — S49/S50 tratados abaixo
                          pe_t, pb_t, pf_t,
                          BASE2020$elec_tra, BASE2020$bio_tra,
                          max(1 - BASE2020$elec_tra - BASE2020$bio_tra, 0))

  # ── Transporte aquaviário S49 — INDICADOR bunker verde ────────────────────
  # bunker_base_pj = consumo doméstico de óleo marítimo no Brasil 2020, BEN 2021.
  # indicador_s49 = fração fóssil = base / (base + pj_bunker_verde[t]).
  # Fossil ↓: A[S19,S49] × indicador.  Biomass ↑: complemento via S22.
  # Eletricidade (A[S40,S49]) NÃO é escalada (navios elétricos irrelevantes 2050).
  bunker_base_pj <- 40   # ~40 PJ bunker doméstico BR 2020 (BEN 2021, navegação interior)
  bio_s49_t <- suppressWarnings(as.numeric(pj_bunker_verde[[cenario]][a]))
  if (!is.na(bio_s49_t) && bio_s49_t >= 0) {
    indicador_s49 <- bunker_base_pj / (bunker_base_pj + bio_s49_t)
    if ("S19" %in% rownames(A_star) && "S49" %in% colnames(A_star))
      A_star["S19","S49"] <- A["S19","S49"] * indicador_s49
    if ("S22" %in% rownames(A_star) && "S49" %in% colnames(A_star))
      A_star["S22","S49"] <- A["S22","S49"] +
        A["S19","S49"] * (1 - indicador_s49)
  }

  # ── Transporte aéreo S50 — INDICADOR bioQAV ──────────────────────────────
  # bioqav_base_pj = consumo de QAV no Brasil 2020, BEN 2021 (~270 PJ, 6450 ktep).
  # indicador_s50 = fração fóssil = base / (base + pj_bioqav[t]).
  # Fossil ↓: A[S19,S50] × indicador.  Biomass ↑: complemento via S22.
  # Eletricidade (A[S40,S50]) NÃO é escalada (aeronaves elétricas irrelevantes 2050).
  bioqav_base_pj <- 270  # ~270 PJ QAV BR 2020 (BEN 2021: 6450 ktep × 41.87 MJ/kg)
  bio_s50_t <- suppressWarnings(as.numeric(pj_bioqav[[cenario]][a]))
  if (!is.na(bio_s50_t) && bio_s50_t >= 0) {
    indicador_s50 <- bioqav_base_pj / (bioqav_base_pj + bio_s50_t)
    if ("S19" %in% rownames(A_star) && "S50" %in% colnames(A_star))
      A_star["S19","S50"] <- A["S19","S50"] * indicador_s50
    if ("S22" %in% rownames(A_star) && "S50" %in% colnames(A_star))
      A_star["S22","S50"] <- A["S22","S50"] +
        A["S19","S50"] * (1 - indicador_s50)
  }

  # ── Cidades / Edifícios ────────────────────────────────────────────────────
  # GRUPOS$cidades = S52 (alojamento), S53 (alimentação), S59 (imobiliário),
  #   S66 (adm pública), S67-S68 (educação), S69-S70 (saúde).
  # Estes setores são os proxies IO para uso de energia em edifícios comerciais
  # e de serviços: o imobiliário (S59) compra eletricidade e gás como insumos
  # intermediários para "produzir" serviços de locação; hotéis e restaurantes
  # (S52/S53) têm alta intensidade energética em edificações; educação, saúde
  # e administração pública (S66-S70) representam edifícios públicos.
  #
  # Mix energético (3 componentes):
  #   Elétrico  : R26 = elec_cid_pct (% eletricidade)
  #   Gás/GLP   : R29 = gas_cid_pct  (% gás + GLP) → usado como "fossil" em rebalancear
  #   Bio/Outro : residual = 1 - elec - gas (inclui solar térmico, lenha, outros)
  # Base 2020: elec=62.5%, gas=26.0%, bio/outro=11.5% (residual — NÃO usa R27
  # de bio_cid_2020 ≈ 1.86e-5, que captura apenas um sub-tipo específico de
  # biomassa e produz sc_b ≈ 5800× se usado diretamente como base).
  pe_c <- elec_cid_pct[[cenario]][a]
  pg_c <- gas_cid_pct[[cenario]][a]
  pb_c <- max(1 - pe_c - pg_c, 0)   # bio/outro = residual do cenário
  if (!anyNA(c(pe_c, pg_c)))
    A_star <- rebalancear(GRUPOS$cidades,
                          pe_c, pb_c, pg_c,
                          BASE2020$elec_cid, BASE2020$bio_cid, BASE2020$gas_cid)

  # ── Geração Elétrica S40 — mix tecnológico MMA (indicadores diretos) ────────
  # Usa % de geração por fonte (foss_gen_pct / bio_gen_pct) carregados da planilha
  # MMA Sheet 4 (linhas 68 e 65+66) para escalar diretamente os coeficientes.
  #
  # FÓSSIL ↓  A[S19,S40]: derivados de petróleo (fuel oil, óleo diesel) nas UTEs.
  #           A[S43,S40]: gás natural nas termelétricas a gás.
  #           indicador = pct_fossil_t / pct_fossil_2020  (14.6% → 0.7% em 100D)
  #
  # BIOMASSA ↑/↓  A[S22,S40]: biomassa convencional + biomassa com CCS.
  #           indicador = pct_bio_t / pct_bio_2020  (9.3% → 12.6% em 100D 2050)
  #           bio_gen_pct já soma linha 65 (conv) + linha 66 (CCS) — ver safe_sum2.
  #           A[S22,S40] CRESCE porque a biomassa residual (UTE-bio) vira maior
  #           fracção de uma grade cada vez mais dominada por renováveis sem fuel.
  #
  # Hidro / Eólica / Solar / Nuclear: sem insumo de combustível na MIP →
  #   coeficientes não são alterados (não há linha S40 de geração nula a escalar).
  # S41 (distribuída = solar/micro-hidro): mesma lógica — sem combustível fóssil/
  #   biomassa → não é tocado aqui.
  pf_g <- foss_gen_pct[[cenario]][a]
  pb_g <- bio_gen_pct[[cenario]][a]
  if (!is.na(pf_g) && foss_gen_2020 > 1e-6) {
    ind_foss_g <- max(pf_g / foss_gen_2020, 0)
    if ("S19" %in% rownames(A_star) && "S40" %in% colnames(A_star))
      A_star["S19","S40"] <- A["S19","S40"] * ind_foss_g
    if ("S43" %in% rownames(A_star) && "S40" %in% colnames(A_star))
      A_star["S43","S40"] <- A["S43","S40"] * ind_foss_g
  }
  if (!is.na(pb_g) && bio_gen_2020 > 1e-6) {
    ind_bio_g <- max(pb_g / bio_gen_2020, 0)
    if ("S22" %in% rownames(A_star) && "S40" %in% colnames(A_star))
      A_star["S22","S40"] <- A["S22","S40"] * ind_bio_g
  }

  # ── Refino S19 — INDICADOR coprocessamento ────────────────────────────────
  # INDICADOR[t] = (consumo_bruto[t]/deriv_total[t]) / (consumo_bruto_2020/deriv_total_2020)
  # Interpreta: à medida que biomassa substitui petróleo cru (coprocessamento
  # 0%→52% em 100D 2050), o cru consumido por unidade de derivado cai.
  #
  # Dois lados da substituição:
  #   FÓSSIL ↓  A[S05,S19] = crude oil input         → × indicador_s19
  #             A[S19,S19] = self-consumption deriv.  → × indicador_s19
  #   BIOMASSA ↑ A[S22,S19] = bio-feedstock + bio-process-heat input
  #             += (A[S05,S19] + A[S19,S19])_base × (1 − indicador) × COPRO_BIO_RATIO
  #             A[S05,S19]=0.246: crude feedstock → replaced by bio-oil/pyrolysis.
  #             A[S19,S19]=0.256: refinery self-consumption for process heat →
  #               replaced by biomass residues (oil cake, biogas, bagasse-equiv).
  #             COPRO_BIO_RATIO = 1 (price parity). Calibrate with EPE/ANP.
  #
  # Fonte: MMA Planilha 4, R39=consumo_bruto, R40+R41=deriv_dom+exp.
  COPRO_BIO_RATIO <- 1.0   # bio-feedstock value per R$ of displaced crude (price parity)
  cb_t <- consumo_bruto[[cenario]][a]
  dt_t <- deriv_total[[cenario]][a]
  if (!anyNA(c(cb_t, dt_t)) &&
      !is.na(consumo_bruto_2020) && consumo_bruto_2020 > 1e-6 &&
      !is.na(deriv_total_2020)   && deriv_total_2020   > 1e-6 &&
      dt_t > 1e-6) {
    indicador_s19 <- max((cb_t / dt_t) / (consumo_bruto_2020 / deriv_total_2020), 0)
    # Guard: consumo_bruto for 25D/0D scenarios reads anomalously small (~781 ktep
    # vs expected ~650 000 ktep) — likely a data layout issue in the MMA spreadsheet
    # (row 39, cols 5-10 contain a different variable for those scenarios).
    # If the raw consumo_bruto is < 1% of the 2020 base, the indicator is meaningless;
    # fall back to indicador = 1 (no coprocessamento = appropriate for low-ambition paths).
    if (!is.na(cb_t) && cb_t < 0.01 * consumo_bruto_2020) indicador_s19 <- 1.0
    # Fossil side ↓
    if ("S05" %in% rownames(A_star) && "S19" %in% colnames(A_star))
      A_star["S05","S19"] <- A["S05","S19"] * indicador_s19
    if ("S19" %in% rownames(A_star) && "S19" %in% colnames(A_star))
      A_star["S19","S19"] <- A["S19","S19"] * indicador_s19
    # Biomass side ↑ — bio-inputs replace BOTH displaced crude AND displaced
    # self-consumption (process heat). A[S19,S19]=0.2555: the refinery burns
    # its own petroleum products for process heat/steam. In a bio-refinery
    # running on vegetable oils, this process heat comes from biomass residues
    # (oil cake, biogas, bagasse-equivalent) → routes to S22.
    # Complement base = A[S05,S19] (crude feedstock) + A[S19,S19] (process heat).
    if ("S22" %in% rownames(A_star) && "S19" %in% colnames(A_star))
      A_star["S22","S19"] <- A["S22","S19"] +
        (A["S05","S19"] + A["S19","S19"]) * (1 - indicador_s19) * COPRO_BIO_RATIO
  }

  # ── Biodiesel S20 — INDICADOR mistura (blend ratio) ──────────────────────
  # A[S19,S20] = 0.2747: derivados de petróleo → S20 (componente fóssil do diesel
  # misturado). Em 2018 o mandato era B10-B12; ao crescer, a fração fóssil cai.
  # A[S05,S20] = 0.2645: extração de petróleo → S20 (insumo de óleo bruto/upstream).
  #   A interpretação exata de A[S05,S20] é ambígua (pode ser integração vertical
  #   na TIP ou feedstock direto); aplicamos o indicador apenas a A[S19,S20]
  #   por enquanto. Ver TODO: investigar A[S05,S20] e decidir se deve cair também.
  #
  # Biomass side ↑ (novo): à medida que diesel fóssil é deslocado por HVO/biodiesel,
  #   o insumo de biocombustível de S22 aumenta na mesma proporção.
  #   A[S22,S20] += A[S19,S20] × (1 − indicador) × BIODIESEL_BIO_RATIO
  #   Ao contrário de S43 (feedstock = resíduo ≈ R$0), aqui o HVO/biodiesel compete
  #   no mesmo mercado que o diesel fóssil → parity assumption (1.0) é defensável.
  #   Resultado: Fóssil+Biomassa total é conservado (Sanity: 0.28207 = 0.28207).
  #
  # Source: pj_diesel_vrd = MMA Planilha 4, R78; S20 base = 230 PJ (Engine 3).
  s20_base_pj <- 230
  bio_s20_t   <- suppressWarnings(as.numeric(pj_diesel_vrd[[cenario]][a]))
  if (!is.na(bio_s20_t) && bio_s20_t >= 0 && s20_base_pj > 0) {
    indicador_s20 <- s20_base_pj / (s20_base_pj + bio_s20_t)   # 1.0 → ~0.20 in 100D 2050
    BIODIESEL_BIO_RATIO <- 1.0   # R$ S22 por R$ deslocado de S19 (mercado paritário)
    # Fossil ↓
    if ("S19" %in% rownames(A_star) && "S20" %in% colnames(A_star))
      A_star["S19","S20"] <- A["S19","S20"] * indicador_s20
    # Biomass ↑
    if ("S22" %in% rownames(A_star) && "S20" %in% colnames(A_star))
      A_star["S22","S20"] <- A["S22","S20"] +
        A["S19","S20"] * (1 - indicador_s20) * BIODIESEL_BIO_RATIO
  }

  # ── Gás Natural S43 — INDICADOR biometano ────────────────────────────────
  # INDICADOR[t] = fração fóssil de S43 = 900 / (900 + pj_biometano[t])
  # base 2020 ≈ 1.0 (biometano ≈ 0; S43 essencialmente 100% gás fóssil).
  #
  # Fossil side ↓: três coeficientes escalam com a fração fóssil restante:
  #   A[S05,S43] = 0.130 — maior insumo: extração upstream de gás (S05).
  #     Biometano vem de resíduos orgânicos, não de poços; A[S05] cai.
  #   A[S19,S43] = 0.001 — derivados de petróleo em operações de gás.
  #   A[S43,S43] = 0.017 — auto-consumo de gás fóssil (compressão etc.).
  #
  # Biomass side ↑: biometano requer feedstock orgânico (vinhaça S08/S09,
  #   resíduos agropecuários S01, RSO/esgoto S44). Esses insumos têm valor
  #   de mercado próximo de zero (são resíduos). Por isso roteamos o
  #   complemento via S22 (biocombustíveis), que capta o processamento/
  #   beneficiamento de biogás. Magnitude: deslocamento de A[S05,S43] ×
  #   BIOMETHANE_BIO_RATIO (= 1.0 paridade; calibrar com EPE/ANP).
  #
  # Fonte: MMA Planilha 4, R79=pj_biometano; base S43 = 900 PJ (Engine 3).
  bio_s43_t <- pj_biometano[[cenario]][a]
  s43_base_pj <- 900
  if (!is.na(bio_s43_t) && bio_s43_t >= 0) {
    indicador_s43 <- s43_base_pj / (s43_base_pj + bio_s43_t)  # 1.0 → ~0.46 em 2050
    BIOMETHANE_BIO_RATIO <- 1.0   # R$ S22 por R$ deslocado de S05; calibrar com EPE/ANP
    # Fossil ↓
    if ("S05" %in% rownames(A_star) && "S43" %in% colnames(A_star))
      A_star["S05","S43"] <- A["S05","S43"] * indicador_s43
    if ("S19" %in% rownames(A_star) && "S43" %in% colnames(A_star))
      A_star["S19","S43"] <- A["S19","S43"] * indicador_s43
    if ("S43" %in% rownames(A_star) && "S43" %in% colnames(A_star))
      A_star["S43","S43"] <- A["S43","S43"] * indicador_s43
    # Biomass ↑
    if ("S22" %in% rownames(A_star) && "S43" %in% colnames(A_star))
      A_star["S22","S43"] <- A["S22","S43"] +
        A["S05","S43"] * (1 - indicador_s43) * BIOMETHANE_BIO_RATIO
  }

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

  # S01 (Agropecuária) — NO Engine 3 shock applied here.
  # S01 grows via Engine 1a GDP scaling + Leontief backward linkages from the
  # energy sectors calibrated below (S22, S20, S19 use soja/cana/olea as
  # intermediate inputs; their expansion propagates demand to S01 via L[S01,·]).
  # Physical crop trajectories (cana, soja, milho, olea) are loaded and exported
  # to the dashboard for reference but do not drive S01 production directly.
  # Option 2 (100D vs 25D policy differential) deferred for future implementation.

  # Indústria pesada
  # S29 = Produção de ferro-gusa/ferroligas/siderurgia (NOT S14 = vestuário)
  # S28 = Fabricação de produtos de minerais não-metálicos (NOT S16 = madeira)
  aco_2020_safe  <- ifelse(is.na(aco_2020)     || aco_2020    <=0, 31.4, aco_2020)
  clin_2020_safe <- ifelse(is.na(clinker_2020) || clinker_2020<=0, 42.7, clinker_2020)
  apply_ratio("S29", aco_prod[[cenario]][a],     aco_2020_safe)   # S29 = Siderurgia
  apply_ratio("S28", clinker_prod[[cenario]][a], clin_2020_safe)  # S28 = Minerais não-metálicos

  # Geração elétrica (TWh)
  apply_ratio("S40", geracao_elec[[cenario]][a], 679)

  # Transmissão (S42) — proporcional à geração; ambas escalam pelo mesmo TWh
  apply_ratio("S42", geracao_elec[[cenario]][a], 679)

  # Petróleo bruto (S05) — produção física: pico 2030, declínio 58% até 2050
  # Base 2020 em kbep (MMA Planilha 4, R37); utiliza mesma unidade do MMA.
  apply_ratio("S05", prod_oleo[[cenario]][a],
              ifelse(is.na(prod_oleo_2020) || prod_oleo_2020 <= 0, NA_real_, prod_oleo_2020))

  # Refino / derivados (S19) — output: derivados dom + exp (ktep)
  # Permanece ~+6% acima de 2020 mesmo com queda de cru (coprocessamento).
  apply_ratio("S19", deriv_total[[cenario]][a],
              ifelse(is.na(deriv_total_2020) || deriv_total_2020 <= 0, NA_real_, deriv_total_2020))

  # Biocombustíveis: base 2020 + incremento cenário
  # S22 inclui todos os biocombustíveis avançados produzidos por biorefinarias:
  #   Etanol+CCS (base 1020 PJ) + Gasolina Verde + BioQAV + Bunker Verde (base=0)
  s22_inc <- sum(c(pj_etanol_ccs[[cenario]][a],
                   pj_gasolina_verde[[cenario]][a],
                   pj_bioqav[[cenario]][a],
                   pj_bunker_verde[[cenario]][a]), na.rm=TRUE)
  apply_ratio("S22", 1020 + s22_inc, 1020)
  apply_ratio("S20", 230  + pj_diesel_vrd[[cenario]][a],  230)   # biodiesel/HVO base 230 PJ
  apply_ratio("S43", 900  + pj_biometano[[cenario]][a],   900)   # gás/biometano base 900 PJ
  # Nota: o Engine 2 agora aplica um INDICADOR de biometano à coluna S43 de A*,
  # reduzindo A[S19,S43] e A[S43,S43] proporcionalmente à fração fóssil restante
  # (análogo ao indicador de coprocessamento de S19). Lacuna remanescente:
  # o aumento de insumos de biomassa em A[S22,S43] (feedstock para produção de
  # biometano) não é implementado por falta de coeficientes técnicos de produção
  # (insumos por PJ de biometano). Fonte recomendada: EPE/ANP.

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

# ── Satellite coefficients for economic impact (from mip_epe_replication) ─────
# These are per-R$M-of-output ratios: multiplied by Δx (or Δf) give direct/indirect splits
sat_gdp   <- setNames(satellite$gdp_coef,      satellite$cod)  # VA / R$M output
sat_labor <- setNames(satellite$labor_coef_raw, satellite$cod)  # persons / R$M output
sat_wage  <- setNames(satellite$wage_coef,      satellite$cod)  # R$ wages / R$M output
mult_base <- colSums(L)   # baseline production multipliers (constant across scenarios)

resultados      <- list()
energia_impacto <- list()   # collects ALPHA × ∆x energy impact per scenario × year
A_stars         <- list()   # stores A* matrices for each cen×ano (needed for coef_long_df)

for (cen in CENS_MMA) {
  for (ano in ANOS_MMA) {
    cat(sprintf("  %s | %d\n", cen, ano))

    # Engine 2: nova A* e L*
    A_star   <- engine2_A_star(cen, ano)
    A_stars[[paste(cen, ano, sep="_")]] <- A_star   # store for coef_long_df
    L_star   <- engine2_L_star(A_star)

    # Engine 1: ∆f demanda final
    df1      <- engine1(cen, ano)

    # Engine 3 (parked when RUN_ENGINE3 = FALSE)
    df3 <- if (RUN_ENGINE3) engine3_delta_f(cen, ano, A_star) else
             setNames(numeric(N), setores$cod)
    df_total <- df1 + df3

    # Propagação: ∆x = L* × ∆f
    dx_total <- as.vector(L_star %*% df_total)
    names(dx_total) <- setores$cod

    # Engine 3 exogenous volume (needed for Engine 4 even if Engine 3 is parked)
    dx_exog <- if (RUN_ENGINE3) engine3_delta_x(cen, ano) else
                 setNames(numeric(N), setores$cod)

    # Engine 4 (parked when RUN_ENGINE4 = FALSE)
    e_coef <- if (RUN_ENGINE4) engine4_e_coef(cen, ano, delta_x = dx_total + dx_exog) else
                setNames(numeric(N), setores$cod)

    # ── Energy impact: ALPHA × ∆x (ktep by source) ─────────────────────────
    # ALPHA is a 6-source × 73-sector matrix (ktep / R$M) from mip_epe_replication.
    # Multiplying by ∆x gives the induced change in energy consumption by source.
    # Classification: Derivados + Gas_Natural = fossil; all others = low-carbon/renewable.
    delta_e <- as.vector(ALPHA %*% dx_total)
    names(delta_e) <- rownames(ALPHA)
    FOSSIL_FONTES  <- c("Derivados", "Gas_Natural")   # natural gas is fossil
    RENOV_FONTES   <- c("Biodiesel", "Etanol", "EE_Central", "EE_Distrib")
    energia_impacto[[paste(cen, ano, sep="_")]] <- data.frame(
      cenario    = cen,
      ano        = ano,
      fonte      = names(delta_e),
      tipo       = ifelse(names(delta_e) %in% FOSSIL_FONTES, "fossil", "renovavel"),
      delta_ktep = round(delta_e, 4),
      stringsAsFactors = FALSE
    )

    # GHG direto do cenário MMA
    g   <- ghg_mma[[cen]]
    ghg_dir <- if (!is.null(g) && as.character(ano) %in% rownames(g))
                 sum(g[as.character(ano),], na.rm=TRUE) else NA_real_

    # ── Baseline: GDP scaling only, with 2018 A matrix (no investment, no Engine 2) ──
    # This is the counterfactual: "what if GDP grew but no transition happened?"
    # Transition effect = Total − Baseline = net impact of (investment + mix change)
    df_gdp_only   <- engine1_gdp(cen, ano)
    dx_baseline   <- as.vector(L %*% df_gdp_only)
    names(dx_baseline) <- setores$cod
    dx_transition <- dx_total - dx_baseline   # net effect of Engine 2 + investment

    # ── Economic impacts: direct + indirect + total ──────────────────────────
    # Direct  = satellite_coef × Δf_total  (sectors receiving the demand shock)
    # Indirect = satellite_coef × (Δx - Δf) (supply-chain propagation)
    # Total   = satellite_coef × Δx_total  = Direct + Indirect
    delta_va_dir  <- sat_gdp   * df_total
    delta_va_tot  <- sat_gdp   * dx_total
    delta_va_ind  <- delta_va_tot - delta_va_dir
    # Baseline (GDP only) vs Transition decomposition
    delta_va_base_vec  <- sat_gdp   * dx_baseline
    delta_va_trans_vec <- sat_gdp   * dx_transition

    delta_emp_dir <- sat_labor * df_total
    delta_emp_tot <- sat_labor * dx_total
    delta_emp_ind <- delta_emp_tot - delta_emp_dir
    delta_emp_base_vec  <- sat_labor * dx_baseline
    delta_emp_trans_vec <- sat_labor * dx_transition

    delta_rem_dir <- sat_wage  * df_total
    delta_rem_tot <- sat_wage  * dx_total
    delta_rem_ind <- delta_rem_tot - delta_rem_dir
    delta_rem_base_vec  <- sat_wage  * dx_baseline
    delta_rem_trans_vec <- sat_wage  * dx_transition

    mult_star_vec <- colSums(L_star)
    mult_shift    <- mult_star_vec - mult_base   # L* vs L: Engine-2 effect on multipliers

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
      delta_x_total      = round(dx_total, 1),
      delta_x_pct        = round(dx_total / x_safe * 100, 3),
      delta_x_baseline   = round(dx_baseline, 1),
      delta_x_transition = round(dx_transition, 1),
      # Value added
      delta_va_total    = round(delta_va_tot, 1),
      delta_va_direct   = round(delta_va_dir, 1),
      delta_va_indirect = round(delta_va_ind, 1),
      delta_va_baseline = round(delta_va_base_vec, 1),
      delta_va_transition = round(delta_va_trans_vec, 1),
      # Employment
      delta_emp_total      = round(delta_emp_tot, 1),
      delta_emp_direct     = round(delta_emp_dir, 1),
      delta_emp_indirect   = round(delta_emp_ind, 1),
      delta_emp_baseline   = round(delta_emp_base_vec, 1),
      delta_emp_transition = round(delta_emp_trans_vec, 1),
      # Wages/income
      delta_rem_total      = round(delta_rem_tot, 1),
      delta_rem_direct     = round(delta_rem_dir, 1),
      delta_rem_indirect   = round(delta_rem_ind, 1),
      delta_rem_baseline   = round(delta_rem_base_vec, 1),
      delta_rem_transition = round(delta_rem_trans_vec, 1),
      # Multipliers
      mult_prod_base  = round(mult_base, 4),
      mult_prod_star  = round(mult_star_vec, 4),
      mult_shift      = round(mult_shift, 4),
      e_coef          = signif(e_coef, 4),
      ghg_induzido_mt = round(e_coef * dx_total, 6),
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
    delta_prod_baseline_bi   = round(sum(delta_x_baseline)/1e3, 2),
    delta_prod_transition_bi = round(sum(delta_x_transition)/1e3, 2),
    delta_prod_pct_media = round(mean(delta_x_pct), 3),
    ghg_induzido_mt      = round(sum(ghg_induzido_mt), 3),
    inv_shock_bi         = round(sum(delta_f_inv)/1e3, 2),
    gdp_scaling_bi       = round(sum(delta_f_gdp)/1e3, 2),
    prod_shock_bi        = round(sum(delta_f_prod)/1e3, 2),
    # Economic aggregates
    delta_va_bi            = round(sum(delta_va_total)/1e3, 2),
    delta_va_direct_bi     = round(sum(delta_va_direct)/1e3, 2),
    delta_va_indirect_bi   = round(sum(delta_va_indirect)/1e3, 2),
    delta_va_baseline_bi   = round(sum(delta_va_baseline)/1e3, 2),
    delta_va_transition_bi = round(sum(delta_va_transition)/1e3, 2),
    delta_emp_total        = round(sum(delta_emp_total), 0),
    delta_emp_direct       = round(sum(delta_emp_direct), 0),
    delta_emp_indirect     = round(sum(delta_emp_indirect), 0),
    delta_emp_baseline     = round(sum(delta_emp_baseline), 0),
    delta_emp_transition   = round(sum(delta_emp_transition), 0),
    delta_rem_bi             = round(sum(delta_rem_total)/1e3, 2),
    delta_rem_direct_bi      = round(sum(delta_rem_direct)/1e3, 2),
    delta_rem_indirect_bi    = round(sum(delta_rem_indirect)/1e3, 2),
    delta_rem_baseline_bi    = round(sum(delta_rem_baseline)/1e3, 2),
    delta_rem_transition_bi  = round(sum(delta_rem_transition)/1e3, 2),
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

energia_impacto_df <- bind_rows(energia_impacto)

# ── Demanda por componente (Engine 1 decomposição) ────────────────────────────
# Mostra quanto do choque ΔF vem de cada tipo de demanda final por cenário×ano.
# Engine 1a (GDP) escala todos os componentes proporcionalmente; Engine 1b (Inv)
# é adicionado inteiramente como FBCF de transição.
tot_fam_bi  <- sum(demanda_final$Familias,                    na.rm=TRUE) / 1000
tot_gov_bi  <- sum(demanda_final$Gov + demanda_final$ISFLSF,  na.rm=TRUE) / 1000
tot_fbcf_bi <- sum(demanda_final$FBCF,                        na.rm=TRUE) / 1000
tot_exp_bi  <- sum(demanda_final$Exportacoes,                 na.rm=TRUE) / 1000
demanda_comp_df <- bind_rows(lapply(CENS_MMA, function(cen)
  bind_rows(lapply(ANOS_MMA, function(ano) {
    g   <- gdp_rel_2018[as.character(ano)] - 1
    pi  <- periodo_idx(ano)
    inv <- if (pi == 0L) 0 else inv_annual_R2018[[cen]][pi] * 1000 / 1000  # R$bi; 0 for 2025
    data.frame(
      cenario             = cen,
      ano                 = as.integer(ano),
      delta_familias_bi   = round(tot_fam_bi  * g, 2),
      delta_gov_bi        = round(tot_gov_bi  * g, 2),
      delta_fbcf_gdp_bi   = round(tot_fbcf_bi * g, 2),
      delta_fbcf_inv_bi   = round(inv,           2),
      delta_fbcf_total_bi = round(tot_fbcf_bi * g + inv, 2),
      delta_exp_bi        = round(tot_exp_bi  * g, 2),
      stringsAsFactors    = FALSE
    )
  }))
))

# ── Coeficientes técnicos energéticos A* por setor individual ────────────────
# Calcula A*[linha_energia, j] para todos os 73 setores j, para base2020 e 100D.
# Agrega S19+S43→Fóssil, S20+S22→Biomassa, S40+S41→Elétrico.
# Cada setor j recebe um grupo de filtragem (Indústria/Transporte/Cidades/Energia/Outros).
# Este dataset alimenta a tabela cruzada do dashboard (mostra setores individuais).
COD_GRUPO_TBL <- setNames(rep("Outros", nrow(setores)), setores$cod)
for (cod in GRUPOS$ind_all)    COD_GRUPO_TBL[cod] <- "Indústria"
for (cod in GRUPOS$transporte) COD_GRUPO_TBL[cod] <- "Transporte"
for (cod in GRUPOS$cidades)    COD_GRUPO_TBL[cod] <- "Cidades"
for (cod in intersect(c("S40","S41","S42","S43","S05","S06","S07",
                        "S19","S20","S21","S22"), setores$cod))
  COD_GRUPO_TBL[cod] <- "Energia"
ET_GROUPS <- list(
  "Fóssil"   = intersect(c("S19","S43"), rownames(A)),
  "Biomassa" = intersect(c("S20","S22"), rownames(A)),
  "Elétrico" = intersect(c("S40","S41"), rownames(A))
)
coef_sector_df <- bind_rows(lapply(c("base2020","100D"), function(cen_s) {
  anos_s <- if (cen_s=="base2020") 2020L else as.integer(ANOS_MMA)
  bind_rows(lapply(anos_s, function(ano_s) {
    mat_s <- if (cen_s=="base2020") A else A_stars[[paste(cen_s, ano_s, sep="_")]]
    if (is.null(mat_s)) return(NULL)
    bind_rows(lapply(setores$cod, function(j) {
      if (!(j %in% colnames(mat_s))) return(NULL)
      bind_rows(lapply(names(ET_GROUPS), function(et) {
        rows_et <- ET_GROUPS[[et]]
        cv <- if (length(rows_et)>0) sum(mat_s[rows_et, j]) else 0L
        data.frame(cenario=cen_s, ano=as.integer(ano_s),
                   cod=j, nome=setores$nome[setores$cod==j],
                   grupo=COD_GRUPO_TBL[j],
                   energy_type=et, coef=round(cv,7),
                   stringsAsFactors=FALSE)
      }))
    }))
  }))
}))
# Keep original coef_long_df (group aggregates) for ch-coef-evol chart
coef_long_df <- coef_sector_df |>
  group_by(cenario, ano, grupo, energy_type) |>
  summarise(coef=round(mean(coef),6), .groups="drop") |>
  rename(subsector=grupo)   # compat alias for existing chart code

cat(sprintf("  Simulações concluídas: %d cenário×ano\n", nrow(resumo)))
cat(sprintf("  Impacto energético calculado: %d fonte×cenário×ano\n", nrow(energia_impacto_df)))

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
    "Elec. edifícios 2020 (%)","Gás edifícios 2020 (%)","Bio/outro edifícios 2020 (% residual)",
    "Cana 2020 (1000t)","Soja 2020 (1000t)","Milho 2020 (1000t)",
    "Aço 2020 (Mt)","Clinker 2020 (Mt)","Geração elétrica 2020 (TWh)",
    "Petróleo bruto 2020 (kbep)","Consumo cru refinarias 2020 (kbep)",
    "Derivados doméstico 2020 (ktep)","Derivados exportação 2020 (ktep)",
    "Derivados totais 2020 (ktep)",
    "Etanol base 2020 (PJ)","Biodiesel base 2020 (PJ)","Gás/biometano base 2020 (PJ)",
    "ENGINE3_SECTORS (GDP override)"
  ),
  valor = c(
    3.65, 1.25, USD2023_to_R2018, gdp_2018_factor,
    BASE2020$elec_ind, BASE2020$bio_ind,
    BASE2020$elec_tra, BASE2020$bio_tra,
    BASE2020$elec_cid, BASE2020$gas_cid, BASE2020$bio_cid,
    cana_2020, soja_2020, milho_2020,
    aco_2020_safe  <- ifelse(is.na(aco_2020)||aco_2020<=0,31.4,aco_2020),
    clin_2020_safe <- ifelse(is.na(clinker_2020)||clinker_2020<=0,42.7,clinker_2020),
    679,
    ifelse(is.na(prod_oleo_2020)||prod_oleo_2020<=0, NA_real_, prod_oleo_2020),
    ifelse(is.na(consumo_bruto_2020)||consumo_bruto_2020<=0, NA_real_, consumo_bruto_2020),
    ifelse(is.na(deriv_dom_2020)||deriv_dom_2020<=0, NA_real_, deriv_dom_2020),
    ifelse(is.na(deriv_exp_2020)||deriv_exp_2020<=0, NA_real_, deriv_exp_2020),
    ifelse(is.na(deriv_total_2020)||deriv_total_2020<=0, NA_real_, deriv_total_2020),
    1020, 230, 900,
    NA_real_   # texto apenas
  ),
  fonte = c(
    rep("Assumido", 4),
    rep("MMA Planilha 5/6/7", 7),
    rep("MMA Planilha 2", 3),
    "MMA Planilha 5","MMA Planilha 5","MMA Planilha 4",
    "MMA Planilha 4 R37","MMA Planilha 4 R39",
    "MMA Planilha 4 R40","MMA Planilha 4 R41","Calculado R40+R41",
    rep("MMA Planilha 4", 3),
    "S05,S19,S40,S42"
  ),
  stringsAsFactors=FALSE
)

maps_df <- bind_rows(lapply(names(GRUPOS), function(g)
  data.frame(grupo=g, cod=GRUPOS[[g]], stringsAsFactors=FALSE))) |>
  left_join(setores, by=c("cod"="cod"))

# ── Tabelas adicionais para o dashboard de engines ────────────────────────────

# Mix energético (Engine 2): % elec/bio/fossil por tipo de setor × cenário × ano
# Inclui agregados (Indústria/Transporte/Cidades) e sub-setores MMA
mix_rows <- list()
add_mix <- function(cen, a, tipo, pe, pb, pf, be, bb, bf) {
  mix_rows[[length(mix_rows)+1]] <<- data.frame(
    cenario=cen, ano=as.integer(a), tipo=tipo,
    pct_elec=pe, pct_bio=pb, pct_fossil=pf,
    base_elec=be, base_bio=bb, base_fossil=bf, stringsAsFactors=FALSE)
}
for (cen in CENS_MMA) {
  for (a in ANOS_STR) {
    pe_i <- elec_ind_pct[[cen]][a]; pb_i <- bio_ind_pct[[cen]][a]
    pe_t <- elec_tra_pct[[cen]][a]; pb_t <- bio_tra_pct[[cen]][a]
    pe_c <- elec_cid_pct[[cen]][a]; pb_c <- bio_cid_pct[[cen]][a]
    # Agregados (backward-compat)
    add_mix(cen,a,"Indústria",  pe_i,pb_i,pmax(1-pe_i-pb_i,0),
            BASE2020$elec_ind,BASE2020$bio_ind,pmax(1-BASE2020$elec_ind-BASE2020$bio_ind,0))
    add_mix(cen,a,"Transporte", pe_t,pb_t,pmax(1-pe_t-pb_t,0),
            BASE2020$elec_tra,BASE2020$bio_tra,pmax(1-BASE2020$elec_tra-BASE2020$bio_tra,0))
    add_mix(cen,a,"Cidades",    pe_c,pb_c,pmax(1-pe_c-pb_c,0),
            BASE2020$elec_cid,BASE2020$bio_cid,pmax(1-BASE2020$elec_cid-BASE2020$bio_cid,0))
    # Sub-setores (BLUES-style)
    add_mix(cen,a,"Ferro e Aço",
            elec_ferro_pct[[cen]][a], bio_ferro_pct[[cen]][a], foss_ferro_pct[[cen]][a],
            elec_ferro_2020, bio_ferro_2020, foss_ferro_2020)
    add_mix(cen,a,"Cimento",
            elec_cim_pct[[cen]][a],   bio_cim_pct[[cen]][a],   foss_cim_pct[[cen]][a],
            elec_cim_2020, bio_cim_2020, foss_cim_2020)
    add_mix(cen,a,"Químico",
            elec_qui_pct[[cen]][a],   bio_qui_pct[[cen]][a],   foss_qui_pct[[cen]][a],
            elec_qui_2020, bio_qui_2020, foss_qui_2020)
    add_mix(cen,a,"Outros Indústria",
            elec_out_pct[[cen]][a],   bio_out_pct[[cen]][a],   foss_out_pct[[cen]][a],
            elec_out_2020, bio_out_2020, foss_out_2020)
    # Geração Elétrica (S40/S41) — pct representa share de geração por fonte
    pf_g <- foss_gen_pct[[cen]][a]; pb_g <- bio_gen_pct[[cen]][a]
    pe_g <- if (!anyNA(c(pf_g,pb_g))) max(1-pf_g-pb_g,0) else max(1-BASE2020$foss_gen-BASE2020$bio_gen,0)
    add_mix(cen,a,"Geração Elétrica",
            pe_g, pb_g, pf_g,
            max(1-BASE2020$foss_gen-BASE2020$bio_gen,0), BASE2020$bio_gen, BASE2020$foss_gen)
  }
}
mix_df <- bind_rows(mix_rows)

# Produção física (Engine 3): volumes por produto × cenário × ano
prod_fisica_rows <- list()
produtos <- list(
  list(cod="S01",  nome="Cana-de-açúcar (→S01)",          serie=cana_prod,       base=cana_2020,       unidade="1000 t"),
  list(cod="S01",  nome="Soja (→S01)",                    serie=soja_prod,       base=soja_2020,       unidade="1000 t"),
  list(cod="S01",  nome="Milho (→S01)",                   serie=milho_prod,      base=milho_2020,      unidade="1000 t"),
  list(cod="S01",  nome="Oleaginosas Energéticas (→S01)", serie=olea_prod,       base=olea_2020,       unidade="1000 t"),
  # Área agrícola: display-only no dashboard (não calibra IO)
  list(cod="S01",  nome="Área Alimentos",                 serie=area_alimentos,  base=area_alim_2020,  unidade="1000 ha"),
  list(cod="S01",  nome="Área Energéticos",               serie=area_energeticos,base=area_ener_2020,  unidade="1000 ha"),
  list(cod="S29",  nome="Aço",                     serie=aco_prod,       base=aco_2020_safe, unidade="Mt"),
  list(cod="S28",  nome="Clinker/Cimento",          serie=clinker_prod,   base=clin_2020_safe,unidade="Mt"),
  list(cod="S40",  nome="Eletricidade",             serie=geracao_elec,   base=679,           unidade="TWh"),
  list(cod="S05",  nome="Petróleo bruto (S05)",     serie=prod_oleo,      base=prod_oleo_2020,    unidade="kbep"),
  list(cod="S19",  nome="Derivados totais (S19)",   serie=deriv_total,    base=deriv_total_2020,  unidade="ktep"),
  list(cod="S22",  nome="Etanol+CCS",       serie=pj_etanol_ccs,    base=0, unidade="PJ incremento"),
  list(cod="S20",  nome="Diesel Verde",     serie=pj_diesel_vrd,    base=0, unidade="PJ incremento"),
  list(cod="S43",  nome="Biometano/Gás",    serie=pj_biometano,     base=0, unidade="PJ incremento"),
  # Biocombustíveis avançados (base 2020 = 0; valores = produção total PJ por cenário)
  list(cod="S22",  nome="Gasolina Verde",   serie=pj_gasolina_verde, base=0, unidade="PJ"),
  list(cod="S22",  nome="BioQAV",           serie=pj_bioqav,         base=0, unidade="PJ"),
  list(cod="S22",  nome="Bunker Verde",     serie=pj_bunker_verde,   base=0, unidade="PJ")
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
# Exporta ambas as políticas × cenário × ano para o toggle do dashboard
mk_aloc_df <- function(aloc_src, policy_label) {
  bind_rows(lapply(CENS_MMA, function(cen) {
    bind_rows(lapply(ANOS_MMA, function(a) {
      aloc_c <- aloc_src[[cen]][[as.character(a)]]
      data.frame(cenario=cen, ano=as.integer(a), localiz_policy=policy_label,
                 cod=names(aloc_c),
                 aloc_pct=round(as.numeric(aloc_c)*100, 2),
                 stringsAsFactors=FALSE)
    }))
  })) |>
    left_join(setores |> select(cod, nome), by="cod") |>
    arrange(cenario, ano, localiz_policy, desc(aloc_pct))
}
aloc_df <- bind_rows(
  mk_aloc_df(ALOC_INV_NOLP, "sem_localizacao"),
  mk_aloc_df(ALOC_INV_LP,   "com_localizacao")
)

# Multiplicadores de produção L* por cenário × ano (extraído de res_all)
mult_df <- res_all |>
  select(cenario, ano, cod, nome, mult_prod_star) |>
  arrange(cenario, ano, desc(mult_prod_star))

# Custos de investimento por cenário (Engine 1 inputs)
inv_df <- bind_rows(lapply(CENS_MMA, function(cen) {
  data.frame(
    cenario=cen, ano=ANOS_MMA,
    inv_bi_R2018=sapply(ANOS_MMA, function(a) {
      pi <- periodo_idx(a)
      round(if(pi==0L) 0 else inv_annual_R2018[[cen]][pi]*1e3/1e3, 2)
    }),
    stringsAsFactors=FALSE)
}))

# ── Macro base table (2018 baseline: output, VA, wages, EOB by sector) ─────────
macro_base_df <- data.frame(
  cod        = setores$cod,
  nome       = setores$nome,
  grupo_7    = grupo_map[setores$cod],
  grupo_nt4  = nt4_map[setores$cod],
  output_bi  = round(as.numeric(x)     / 1e3, 4),   # R$ bilhões
  va_bi      = round(as.numeric(va_pib)/ 1e3, 4),
  remuner_bi = round(as.numeric(remuner)/ 1e3, 4),
  eob_bi     = round(as.numeric(eob)   / 1e3, 4),
  emprego    = round(as.numeric(ocupacoes), 0),
  export_bi  = round(as.numeric(DF[,"Export"]) / 1e3, 4),
  familias_bi= round(as.numeric(DF[,"Families"])/ 1e3, 4),
  gfcf_bi    = round(as.numeric(DF[,"GFCF"])   / 1e3, 4),
  gov_bi     = round((as.numeric(DF[,"Gov"]) + as.numeric(DF[,"ISFLSF"])) / 1e3, 4),
  stringsAsFactors = FALSE
)

# ── Type I & II multipliers from mip_epe_replication (already in memory) ───────
# mult_prod: MP(I), MPT/MPTT(II), direct/indirect/induced
# mult_emp:  ME/MEI(I), MET/MEII(II)
# mult_rem:  MR/MRI(I), MRT/MRII(II)

# =============================================================================
# PARTE 8b — LINKAGES, LABOR BASELINE, TAX SATELLITE
# =============================================================================

# ── 8b.1  Linkage comparison: base L vs L* for 100D 2050 ─────────────────────
# ind_lig is already in memory from mip_epe_replication.R (section 6):
#   BL, FL, FLG, Vj, Vi, quadrante, eh_energia, eh_fossil, grupo
# We compute BL*/FLG* from A_stars[["100D_2050"]] to show how sector positions
# shift in the linkage space under the 100D transition.
A_star_s100 <- A_stars[["100D_2050"]]
if (!is.null(A_star_s100)) {
  L_star_s100 <- engine2_L_star(A_star_s100)
  # Ghosh supply-side: F* = diag(1/x) Z*  where  Z* = A* diag(x)
  Z_star_s100 <- A_star_s100 %*% diag(as.numeric(x_safe))
  F_star_s100 <- diag(1 / as.numeric(x_safe)) %*% Z_star_s100
  G_star_s100 <- tryCatch(solve(diag(N) - F_star_s100),
                          error = function(e) { warning("G* singular; usa G base"); G })
  BL_star  <- colMeans(L_star_s100) / mean(L_star_s100)
  FL_star  <- rowMeans(L_star_s100) / mean(L_star_s100)
  FLG_star <- rowMeans(G_star_s100) / mean(G_star_s100)
  quad_star <- dplyr::case_when(
    BL_star >= 1 & FLG_star >= 1 ~ "Setor-Chave",
    BL_star >= 1 & FLG_star <  1 ~ "Demanda acima da media",
    BL_star <  1 & FLG_star >= 1 ~ "Oferta acima da media",
    TRUE                         ~ "Independente"
  )
  names(quad_star) <- setores$cod
  linkage_100d_df <- data.frame(
    cod       = setores$cod,
    nome      = setores$nome,
    BL        = round(BL_star,  4),
    FL        = round(FL_star,  4),
    FLG       = round(FLG_star, 4),
    Vj        = NA_real_,
    Vi        = NA_real_,
    quadrante = quad_star,
    grupo     = grupo_map[setores$cod],
    stringsAsFactors = FALSE
  )
} else {
  linkage_100d_df <- NULL
}

# Combined base 2018 + 100D 2050 linkage comparison
linkage_comp_df <- bind_rows(
  ind_lig |>
    select(cod, nome, BL, FL, FLG, Vj, Vi, quadrante, grupo) |>
    mutate(cenario = "base2020", ano = 2020L),
  if (!is.null(linkage_100d_df))
    linkage_100d_df |> mutate(cenario = "100D", ano = 2050L)
) |> select(cenario, ano, cod, nome, BL, FL, FLG, Vj, Vi, quadrante, grupo)

cat(sprintf("  Linkage comparison: %d rows (base + 100D 2050)\n", nrow(linkage_comp_df)))

# ── 8b.2  Labor baseline by subcategory (2018, 8 groups × 73 sectors) ────────
# labor_share: 8×73 share matrix (fraction of sector employment by group)
# ocupacoes: 73-vector of absolute 2018 employment per sector
labor_baseline_df <- bind_rows(lapply(rownames(labor_share), function(grp) {
  abs_emp <- as.numeric(labor_share[grp, ]) * as.numeric(ocupacoes)
  data.frame(
    grupo_labor = grp,
    cod         = setores$cod,
    nome        = setores$nome,
    grupo_7     = grupo_map[setores$cod],
    emprego_abs = round(abs_emp, 0),
    share       = round(as.numeric(labor_share[grp, ]), 4),
    stringsAsFactors = FALSE
  )
}))
cat(sprintf("  Labor baseline: %d rows (%d groups × %d sectors)\n",
            nrow(labor_baseline_df), length(rownames(labor_share)), N))

# ── 8b.3  Tax satellite: net taxes on production (VA - Remuner - EOB) ─────────
# impostos_liq = implicit tax residual (includes net taxes on products + imports)
# tax_coef = impostos_liq / x_safe  →  R$ tax revenue per R$M of gross output
# delta_tax = tax_coef × delta_x  →  change in government revenue by scenario
impostos_liq <- as.numeric(va_pib) - as.numeric(remuner) - as.numeric(eob)
names(impostos_liq) <- setores$cod
tax_coef_vec <- impostos_liq / as.numeric(x_safe)
names(tax_coef_vec) <- setores$cod

# 2018 baseline tax structure per sector
tax_base_df <- data.frame(
  cod         = setores$cod,
  nome        = setores$nome,
  grupo_7     = grupo_map[setores$cod],
  va_bi       = round(as.numeric(va_pib)  / 1e3, 4),
  remuner_bi  = round(as.numeric(remuner) / 1e3, 4),
  eob_bi      = round(as.numeric(eob)     / 1e3, 4),
  impostos_bi = round(impostos_liq        / 1e3, 4),
  tax_coef    = round(tax_coef_vec,       6),
  stringsAsFactors = FALSE
)

# Delta tax by scenario × ano: join tax_coef onto res_all, then summarise
tax_shock_df <- res_all |>
  left_join(data.frame(cod = setores$cod, tax_coef = round(tax_coef_vec, 6)),
            by = "cod") |>
  mutate(
    delta_tax_total_bi   = round(tax_coef * delta_x_total   / 1e3, 4),
    delta_tax_direct_bi  = round(tax_coef * delta_f_total   / 1e3, 4),
    delta_tax_indirect_bi= round(tax_coef * (delta_x_total - delta_f_total) / 1e3, 4)
  ) |>
  group_by(cenario, ano) |>
  summarise(
    delta_tax_total_bi    = round(sum(delta_tax_total_bi,    na.rm = TRUE), 4),
    delta_tax_direct_bi   = round(sum(delta_tax_direct_bi,   na.rm = TRUE), 4),
    delta_tax_indirect_bi = round(sum(delta_tax_indirect_bi, na.rm = TRUE), 4),
    .groups = "drop"
  )

cat(sprintf("  Tax satellite: %d scenario×ano combinations\n", nrow(tax_shock_df)))

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
    "Energia_Impacto"     = energia_impacto_df,
    "Demanda_Componentes" = demanda_comp_df,
    "Coef_Tecnicos"       = coef_sector_df,
    "Premissas"           = premissas,
    "Mapeamento_Setores"  = maps_df,
    "Macro_Base"          = macro_base_df,        # 2018 baseline by sector
    "Mult_Producao"       = mult_prod,            # Type I (MP) + Type II (MPT/MPTT)
    "Mult_Emprego"        = mult_emp,             # Type I (ME/MEI) + Type II (MET/MEII)
    "Mult_Renda"          = mult_rem,             # Type I (MR/MRI) + Type II (MRT/MRII)
    "Ind_Ligacoes"        = ind_lig,              # Base 2018: BL/FL/FLG/Vj/Vi/quadrante
    "Linkage_Comp"        = linkage_comp_df,      # Base vs 100D 2050 linkage scatter data
    "Labor_Baseline"      = labor_baseline_df,    # 2018 employment by subcategory × sector
    "Tax_Base"            = tax_base_df,          # 2018 tax structure (VA residual) per sector
    "Tax_Choques"         = tax_shock_df          # ΔTax revenue by cenario × ano
  ),
  path=if (tryCatch({f<-file("outputs/tables/mma_shock_results.xlsx","a");close(f);TRUE},error=function(e)FALSE))
    "outputs/tables/mma_shock_results.xlsx" else
    "outputs/tables/mma_shock_results_new.xlsx"
)
cat("  Salvo: outputs/tables/mma_shock_results.xlsx\n")

saveRDS(
  list(
    res_all          = res_all,
    resumo           = resumo,
    ghg_mma          = ghg_mma,
    gdp_idx          = gdp_idx,
    pop_mil          = pop_mil,
    GRUPOS           = GRUPOS,
    BASE2020         = BASE2020,
    premissas        = premissas,
    ANOS_MMA         = ANOS_MMA,
    CENS_MMA         = CENS_MMA,
    energia_impacto  = energia_impacto_df,
    demanda_comp     = demanda_comp_df,       # Engine 1 ΔF by demand component
    coef_sector      = coef_sector_df,        # A* energy coef by IO sector×year (base+100D)
    coef_long        = coef_long_df,          # same, grouped average (for dashboard charts)
    satellite        = satellite,
    ALPHA            = ALPHA,
    # Multipliers (Type I & II)
    mult_prod        = mult_prod,             # MP / MPT / MPTT + direct/indirect/induced
    mult_emp         = mult_emp,              # ME/MEI (Type I) + MET/MEII (Type II)
    mult_rem         = mult_rem,              # MR/MRI (Type I) + MRT/MRII (Type II)
    # Linkage indices
    ind_lig          = ind_lig,               # Base 2018: BL/FL/FLG/Vj/Vi/quadrante
    linkage_comp     = linkage_comp_df,       # Base vs 100D 2050 scatter comparison
    # Labor & tax satellites (2018 baseline)
    labor_baseline   = labor_baseline_df,     # 2018 employment by subcategory × sector
    tax_base         = tax_base_df,           # 2018 VA decomposition + tax_coef per sector
    tax_shock        = tax_shock_df           # ΔTax revenue by cenario × ano
  ),
  file = "data/processed/mma_shocks.rds"
)
cat("  Salvo: data/processed/mma_shocks.rds\n")

# Console summary
cat("\n", strrep("=",60), "\n RESUMO SIMULAÇÕES\n", strrep("=",60), "\n", sep="")
print(resumo |> select(cenario,ano,delta_prod_bi,ghg_induzido_mt,ghg_cenario_mt) |> as.data.frame())
cat("\nConcluído.\n")
