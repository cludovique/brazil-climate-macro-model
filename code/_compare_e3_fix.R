# Before/after comparison of Engine 3 double-counting fix
# Loads current (fixed) results and regenerates old (unfixed) results in-memory
setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
pkgs <- c("readxl","dplyr","tidyr","writexl","stringr")
for (p in pkgs) suppressPackageStartupMessages(library(p, character.only=TRUE))
options(OutDec=".")

MMA_PATH <- "data/raw/Planilha_Detalhamento Resultados MMA-SMC v3 AR5 (07_10_2024).xlsx"
all_sheets <- excel_sheets(MMA_PATH)
read_mma <- function(idx) suppressMessages(read_excel(MMA_PATH, sheet=all_sheets[idx], col_names=FALSE))

# ── Load IO model ──────────────────────────────────────────────────────────────
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
alpha_energia <- ALPHA
demanda_final <- as.data.frame(DF)
colnames(demanda_final) <- c("Exportacoes","Gov","ISFLSF","Familias","FBCF","Var_Estoque")
demanda_final$cod <- setores$cod

ANOS_MMA <- c(2025,2030,2035,2040,2045,2050); CENS_MMA <- c("25D","100D","0D")
ANOS_STR <- as.character(ANOS_MMA)

# ── Load MMA ───────────────────────────────────────────────────────────────────
pp <- read_mma(9)
gdp_idx  <- setNames(suppressWarnings(as.numeric(unlist(pp[4, 4:9]))), ANOS_STR)
gdp_2018_factor <- 0.97
gdp_rel_2018 <- gdp_idx * gdp_2018_factor

en <- read_mma(4); ind <- read_mma(5); tr <- read_mma(6); ci <- read_mma(7)
ag <- read_mma(2); cu <- read_mma(10)
get_scenario_row <- function(df, r, cols_25d=5:10, cols_100d=12:17, cols_0d=19:24) {
  safe <- function(v) { v <- suppressWarnings(as.numeric(unlist(v))); v[is.na(v)] <- 0; setNames(v, ANOS_STR) }
  v25<-safe(df[r,cols_25d]); v100<-safe(df[r,cols_100d])
  v0<-tryCatch(safe(df[r,cols_0d]),error=function(e)v25); if(all(v0==0))v0<-v25
  list("25D"=v25,"100D"=v100,"0D"=v0)
}
get_base2020 <- function(df, r) suppressWarnings(as.numeric(df[[r,3]]))

geracao_elec <- get_scenario_row(en,49); prod_oleo <- get_scenario_row(en,37)
consumo_bruto <- get_scenario_row(en,39); deriv_dom <- get_scenario_row(en,40)
deriv_exp <- get_scenario_row(en,41); pj_etanol_ccs <- get_scenario_row(en,76)
pj_diesel_vrd <- get_scenario_row(en,78); pj_biometano <- get_scenario_row(en,79)
pj_gasolina_verde <- get_scenario_row(en,77); pj_bioqav <- get_scenario_row(en,80)
pj_bunker_verde <- get_scenario_row(en,81)
aco_prod <- get_scenario_row(ind,27); clinker_prod <- get_scenario_row(ind,41)
soja_prod <- get_scenario_row(ag,79); milho_prod <- get_scenario_row(ag,72)
cana_prod <- get_scenario_row(ag,68); olea_prod <- get_scenario_row(ag,77)

prod_oleo_2020 <- get_base2020(en,37)
consumo_bruto_2020 <- get_base2020(en,39)
deriv_dom_2020 <- get_base2020(en,40); deriv_exp_2020 <- get_base2020(en,41)
deriv_total_2020 <- deriv_dom_2020 + deriv_exp_2020
deriv_total <- lapply(CENS_MMA, function(cen)
  setNames(deriv_dom[[cen]] + deriv_exp[[cen]], ANOS_STR)); names(deriv_total) <- CENS_MMA
aco_2020 <- get_base2020(ind,27); clinker_2020 <- get_base2020(ind,41)
soja_2020 <- get_base2020(ag,79); milho_2020 <- get_base2020(ag,72)
cana_2020 <- get_base2020(ag,68); olea_2020 <- 4720

f_base <- rowSums(demanda_final[,1:5]); names(f_base) <- setores$cod
sat_gdp <- setNames(satellite$gdp_coef, satellite$cod)

# ── Engine 1a (shared) ─────────────────────────────────────────────────────────
make_engine1_gdp <- function(excl_sectors) {
  function(cenario, ano) {
    g <- gdp_rel_2018[as.character(ano)]
    df <- f_base * (g - 1)
    for (s in excl_sectors) if (s %in% names(df)) df[s] <- 0
    df
  }
}

# ── Engine 3 delta_x — OLD (absolute shocks for S01) ─────────────────────────
engine3_dx_OLD <- function(cenario, ano) {
  a <- as.character(ano)
  dx <- setNames(numeric(N), setores$cod)
  apply_r <- function(cod, vs, b) {
    vs <- suppressWarnings(as.numeric(vs)); b <- suppressWarnings(as.numeric(b))
    if (is.na(vs)||is.na(b)||b<=0) return()
    dx[cod] <<- dx[cod] + x[cod]*(vs/b-1)
  }
  CROP_WT <- c(soja=0.28,milho=0.10,cana=0.08,olea=0.01)
  vs_s <- suppressWarnings(as.numeric(soja_prod[[cenario]][a]))
  vs_m <- suppressWarnings(as.numeric(milho_prod[[cenario]][a]))
  vs_c <- suppressWarnings(as.numeric(cana_prod[[cenario]][a]))
  vs_o <- suppressWarnings(as.numeric(olea_prod[[cenario]][a]))
  if ("S01" %in% names(dx)) {
    if (!is.na(vs_s) && soja_2020>0) dx["S01"]<-dx["S01"]+x["S01"]*CROP_WT["soja"]*(vs_s/soja_2020-1)
    if (!is.na(vs_m) && milho_2020>0) dx["S01"]<-dx["S01"]+x["S01"]*CROP_WT["milho"]*(vs_m/milho_2020-1)
    if (!is.na(vs_c) && cana_2020>0) dx["S01"]<-dx["S01"]+x["S01"]*CROP_WT["cana"]*(vs_c/cana_2020-1)
    if (!is.na(vs_o) && olea_2020>0) dx["S01"]<-dx["S01"]+x["S01"]*CROP_WT["olea"]*(vs_o/olea_2020-1)
  }
  aco_safe <- ifelse(is.na(aco_2020)||aco_2020<=0,31.4,aco_2020)
  clin_safe <- ifelse(is.na(clinker_2020)||clinker_2020<=0,42.7,clinker_2020)
  apply_r("S29",aco_prod[[cenario]][a],aco_safe)
  apply_r("S28",clinker_prod[[cenario]][a],clin_safe)
  apply_r("S40",geracao_elec[[cenario]][a],679)
  apply_r("S42",geracao_elec[[cenario]][a],679)
  apply_r("S05",prod_oleo[[cenario]][a],ifelse(is.na(prod_oleo_2020)||prod_oleo_2020<=0,NA,prod_oleo_2020))
  apply_r("S19",deriv_total[[cenario]][a],ifelse(is.na(deriv_total_2020)||deriv_total_2020<=0,NA,deriv_total_2020))
  s22i <- sum(c(pj_etanol_ccs[[cenario]][a],pj_gasolina_verde[[cenario]][a],
                pj_bioqav[[cenario]][a],pj_bunker_verde[[cenario]][a]),na.rm=TRUE)
  apply_r("S22",1020+s22i,1020); apply_r("S20",230+pj_diesel_vrd[[cenario]][a],230)
  apply_r("S43",900+pj_biometano[[cenario]][a],900)
  dx
}

# ── Engine 3 delta_x — NEW (differential S01) ─────────────────────────────────
engine3_dx_NEW <- function(cenario, ano) {
  a <- as.character(ano)
  dx <- setNames(numeric(N), setores$cod)
  apply_r <- function(cod, vs, b) {
    vs <- suppressWarnings(as.numeric(vs)); b <- suppressWarnings(as.numeric(b))
    if (is.na(vs)||is.na(b)||b<=0) return()
    dx[cod] <<- dx[cod] + x[cod]*(vs/b-1)
  }
  CROP_WT <- c(soja=0.28,milho=0.10,cana=0.08,olea=0.01)
  vs_s <- suppressWarnings(as.numeric(soja_prod[[cenario]][a]))
  vs_m <- suppressWarnings(as.numeric(milho_prod[[cenario]][a]))
  vs_c <- suppressWarnings(as.numeric(cana_prod[[cenario]][a]))
  vs_o <- suppressWarnings(as.numeric(olea_prod[[cenario]][a]))
  g_2020 <- suppressWarnings(as.numeric(gdp_idx[a])); if(is.na(g_2020)||g_2020<=0) g_2020<-1
  if ("S01" %in% names(dx)) {
    if (!is.na(vs_s) && soja_2020>0) dx["S01"]<-dx["S01"]+x["S01"]*CROP_WT["soja"]*(vs_s/soja_2020-g_2020)
    if (!is.na(vs_m) && milho_2020>0) dx["S01"]<-dx["S01"]+x["S01"]*CROP_WT["milho"]*(vs_m/milho_2020-g_2020)
    if (!is.na(vs_c) && cana_2020>0) dx["S01"]<-dx["S01"]+x["S01"]*CROP_WT["cana"]*(vs_c/cana_2020-g_2020)
    if (!is.na(vs_o) && olea_2020>0) dx["S01"]<-dx["S01"]+x["S01"]*CROP_WT["olea"]*(vs_o/olea_2020-g_2020)
  }
  aco_safe <- ifelse(is.na(aco_2020)||aco_2020<=0,31.4,aco_2020)
  clin_safe <- ifelse(is.na(clinker_2020)||clinker_2020<=0,42.7,clinker_2020)
  apply_r("S29",aco_prod[[cenario]][a],aco_safe)
  apply_r("S28",clinker_prod[[cenario]][a],clin_safe)
  apply_r("S40",geracao_elec[[cenario]][a],679)
  apply_r("S42",geracao_elec[[cenario]][a],679)
  apply_r("S05",prod_oleo[[cenario]][a],ifelse(is.na(prod_oleo_2020)||prod_oleo_2020<=0,NA,prod_oleo_2020))
  apply_r("S19",deriv_total[[cenario]][a],ifelse(is.na(deriv_total_2020)||deriv_total_2020<=0,NA,deriv_total_2020))
  s22i <- sum(c(pj_etanol_ccs[[cenario]][a],pj_gasolina_verde[[cenario]][a],
                pj_bioqav[[cenario]][a],pj_bunker_verde[[cenario]][a]),na.rm=TRUE)
  apply_r("S22",1020+s22i,1020); apply_r("S20",230+pj_diesel_vrd[[cenario]][a],230)
  apply_r("S43",900+pj_biometano[[cenario]][a],900)
  dx
}

# ── Run mini-simulation for key scenario×years ────────────────────────────────
OLD_E3_SECTORS <- c("S05","S19","S40","S42")
NEW_E3_SECTORS <- c("S05","S19","S40","S42","S22","S20","S43","S29","S28")

e1gdp_old <- make_engine1_gdp(OLD_E3_SECTORS)
e1gdp_new <- make_engine1_gdp(NEW_E3_SECTORS)

compare_rows <- list()
for (cen in CENS_MMA) {
  for (ano in ANOS_MMA) {
    a <- as.character(ano)
    df_old <- e1gdp_old(cen, ano) + as.vector((diag(N)-A) %*% engine3_dx_OLD(cen,ano))
    df_new <- e1gdp_new(cen, ano) + as.vector((diag(N)-A) %*% engine3_dx_NEW(cen,ano))
    dx_old <- as.vector(L %*% df_old); names(dx_old) <- setores$cod
    dx_new <- as.vector(L %*% df_new); names(dx_new) <- setores$cod
    va_old <- sum(sat_gdp * dx_old) / 1e3
    va_new <- sum(sat_gdp * dx_new) / 1e3
    prod_old <- sum(dx_old) / 1e3
    prod_new <- sum(dx_new) / 1e3
    compare_rows[[length(compare_rows)+1]] <- data.frame(
      cenario=cen, ano=ano,
      prod_old=round(prod_old,2), prod_new=round(prod_new,2),
      prod_diff=round(prod_new-prod_old,2),
      va_old=round(va_old,2), va_new=round(va_new,2),
      va_diff=round(va_new-va_old,2)
    )
  }
}
comp <- bind_rows(compare_rows)

cat("=== BEFORE vs AFTER Engine 3 double-counting fix ===\n")
cat("(Engine 2 not applied here for speed; direction is the same)\n\n")
cat(sprintf("%-6s  %-4s  %10s  %10s  %9s   %8s  %8s  %8s\n",
    "Cen","Ano","Prod_OLD","Prod_NEW","Δ Prod","VA_OLD","VA_NEW","Δ VA"))
cat(strrep("-",80),"\n")
for (i in 1:nrow(comp)) {
  r <- comp[i,]
  cat(sprintf("%-6s  %4d  %10.1f  %10.1f  %+9.1f   %8.1f  %8.1f  %+8.1f\n",
      r$cenario, r$ano, r$prod_old, r$prod_new, r$prod_diff,
      r$va_old, r$va_new, r$va_diff))
}

cat("\n--- Sector-level decomposition: 100D 2050 ---\n")
a <- "2050"; cen <- "100D"
df_old_v <- e1gdp_old(cen,2050) + as.vector((diag(N)-A) %*% engine3_dx_OLD(cen,2050))
df_new_v <- e1gdp_new(cen,2050) + as.vector((diag(N)-A) %*% engine3_dx_NEW(cen,2050))
dx_old_v <- as.vector(L %*% df_old_v); names(dx_old_v) <- setores$cod
dx_new_v <- as.vector(L %*% df_new_v); names(dx_new_v) <- setores$cod

sectors_show <- c("S01","S20","S22","S28","S29","S43")
cat(sprintf("%-6s  %-40s  %10s  %10s  %9s\n","Cod","Nome","Δx_OLD","Δx_NEW","Δ diff"))
cat(strrep("-",78),"\n")
for (s in sectors_show) {
  nm <- setores$nome[setores$cod==s]
  cat(sprintf("%-6s  %-40s  %10.1f  %10.1f  %+9.1f\n",
      s, substr(nm,1,40), dx_old_v[s], dx_new_v[s], dx_new_v[s]-dx_old_v[s]))
}

cat("\n--- S01 crop differential breakdown (100D 2050) ---\n")
CROP_WT <- c(soja=0.28,milho=0.10,cana=0.08,olea=0.01)
crops <- list(soja=list(soja_prod,"soja",soja_2020),
              milho=list(milho_prod,"milho",milho_2020),
              cana=list(cana_prod,"cana",cana_2020),
              olea=list(olea_prod,"olea",olea_2020))
g2020 <- gdp_idx["2050"]
cat(sprintf("GDP index 2050 (vs 2020): %.4f  (vs 2018: %.4f)\n", g2020, g2020*0.97))
for (nm in names(crops)) {
  vs <- suppressWarnings(as.numeric(crops[[nm]][[1]][["100D"]]["2050"]))
  b  <- crops[[nm]][[3]]
  wt <- CROP_WT[nm]
  cat(sprintf("  %-6s: vs/base=%.3f  diff_from_gdp=%+.3f  weighted_dx=%+.1f R$M\n",
      nm, vs/b, vs/b - g2020, x["S01"] * wt * (vs/b - g2020)))
}
