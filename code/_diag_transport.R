setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

# ── 1. Current A* coefficients for transport sectors ──────────────────────
cat("=== BASE 2018 A coefficients for transport sectors ===\n")
TRANS <- c("S48","S49","S50","S51","S52")
ENERGY_ROWS <- c("S19","S43","S20","S22","S40","S41")
cat(sprintf("%-6s  %-26s  %8s  %8s  %8s  %8s  %8s  %8s  | %8s %8s %8s\n",
    "Cod","Nome","A[S19]","A[S43]","A[S20]","A[S22]","A[S40]","A[S41]",
    "Fossil","Bio","Elec"))
cat(strrep("-",100),"\n")
for (j in TRANS) {
  nm <- substr(setores$nome[setores$cod==j],1,26)
  s19 <- A["S19",j]; s43 <- A["S43",j]
  s20 <- A["S20",j]; s22 <- A["S22",j]
  s40 <- A["S40",j]; s41 <- A["S41",j]
  cat(sprintf("%-6s  %-26s  %8.5f  %8.5f  %8.5f  %8.5f  %8.5f  %8.5f  | %8.5f %8.5f %8.5f\n",
      j, nm, s19, s43, s20, s22, s40, s41,
      s19+s43, s20+s22, s40+s41))
}

# ── 2. Current A* at 100D 2050 (the problematic scenario) ─────────────────
cat("\n=== A* at 100D 2050 — CURRENT (elec explosion visible) ===\n")
A100 <- engine2_A_star("100D","2050")
cat(sprintf("%-6s  %-26s  %8s  %8s  %8s  %8s  | %8s %8s %8s\n",
    "Cod","Nome","A[S19]*","A[S43]*","A[S22]*","A[S40]*","Fossil","Bio","Elec"))
cat(strrep("-",90),"\n")
for (j in TRANS) {
  nm <- substr(setores$nome[setores$cod==j],1,26)
  cat(sprintf("%-6s  %-26s  %8.5f  %8.5f  %8.5f  %8.5f  | %8.5f %8.5f %8.5f\n",
      j, nm, A100["S19",j], A100["S43",j], A100["S22",j], A100["S40",j],
      A100["S19",j]+A100["S43",j], A100["S20",j]+A100["S22",j],
      A100["S40",j]+A100["S41",j]))
}

# ── 3. pj_bioqav and pj_bunker_verde trajectories ─────────────────────────
cat("\n=== pj_bioqav and pj_bunker_verde (MMA scenarios) ===\n")
cat(sprintf("%-4s  %10s  %10s  %10s  %10s  %10s  %10s\n",
    "Ano","bioqav_25D","bioqav_100D","bioqav_0D","bunkv_25D","bunkv_100D","bunkv_0D"))
cat(strrep("-",70),"\n")
ANOS <- c("2025","2030","2035","2040","2045","2050")
for (a in ANOS) {
  bq25  <- suppressWarnings(as.numeric(pj_bioqav[["25D"]][a]))
  bq100 <- suppressWarnings(as.numeric(pj_bioqav[["100D"]][a]))
  bq0   <- suppressWarnings(as.numeric(pj_bioqav[["0D"]][a]))
  bv25  <- suppressWarnings(as.numeric(pj_bunker_verde[["25D"]][a]))
  bv100 <- suppressWarnings(as.numeric(pj_bunker_verde[["100D"]][a]))
  bv0   <- suppressWarnings(as.numeric(pj_bunker_verde[["0D"]][a]))
  cat(sprintf("%-4s  %10.1f  %10.1f  %10.1f  %10.1f  %10.1f  %10.1f\n",
      a,
      ifelse(is.na(bq25),0,bq25), ifelse(is.na(bq100),0,bq100), ifelse(is.na(bq0),0,bq0),
      ifelse(is.na(bv25),0,bv25), ifelse(is.na(bv100),0,bv100), ifelse(is.na(bv0),0,bv0)))
}

# ── 4. Implied PJ scale from IO table ──────────────────────────────────────
cat("\n=== Implied fuel consumption for S49/S50 from IO × energy intensity ===\n")
# x[S49] × A[S19,S49] = R$ value of petroleum bought by maritime sector
# Convert: 1 R$ billion of petroleum ≈ [price calibration]
# Better: use BEN 2020 estimates directly
cat("  From IO: A[S19,S49] × x[S49] = petroleum spend of maritime sector\n")
x_s49 <- x[names(x)=="S49"]; x_s50 <- x[names(x)=="S50"]
cat(sprintf("  S49 petroleum spend: %.0f × %.5f = R$ %.0f M\n",
    x_s49, A["S19","S49"], x_s49 * A["S19","S49"]))
cat(sprintf("  S50 petroleum spend: %.0f × %.5f = R$ %.0f M\n",
    x_s50, A["S19","S50"], x_s50 * A["S19","S50"]))
cat("\n  BEN 2020 reference (for base PJ):\n")
cat("    QAV (aviation): ~270 PJ/year (6,450 ktep × 41.87 MJ/kg)\n")
cat("    Marine bunker BR domestic: ~30-50 PJ/year\n")
cat("    International shipping (not in IO scope): additional ~50 PJ\n")
cat("\n  Suggested base PJ values:\n")
cat("    bioqav_base_pj  = 270  (aviation fuel Brazil 2020 BEN)\n")
cat("    bunker_base_pj  = 40   (domestic marine fuel Brazil 2020 BEN)\n")

# ── 5. What the indicators would look like ────────────────────────────────
cat("\n=== indicador trajectories if using these bases (100D) ===\n")
bioqav_base <- 270; bunker_base <- 40
cat(sprintf("%-4s  %10s  %10s  %10s  %10s\n",
    "Ano","bioqav_PJ","ind_S50","bunkv_PJ","ind_S49"))
cat(strrep("-",50),"\n")
for (a in ANOS) {
  bq <- suppressWarnings(as.numeric(pj_bioqav[["100D"]][a]))
  bv <- suppressWarnings(as.numeric(pj_bunker_verde[["100D"]][a]))
  bq <- ifelse(is.na(bq)|bq<0, 0, bq)
  bv <- ifelse(is.na(bv)|bv<0, 0, bv)
  ind50 <- bioqav_base / (bioqav_base + bq)
  ind49 <- bunker_base / (bunker_base + bv)
  cat(sprintf("%-4s  %10.1f  %10.4f  %10.1f  %10.4f\n", a, bq, ind50, bv, ind49))
}
