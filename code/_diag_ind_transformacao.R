setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

cat("=== Indústria de Transformação — diagnóstico Engine 2 ===\n\n")

# ── 1. Which sectors are in each industrial group ──────────────────────────
cat("--- GRUPOS industriais ---\n")
for (g in c("agro","ind_aco","ind_cimento","ind_quimico","ind_outros")) {
  nm <- paste(sapply(GRUPOS[[g]], function(s)
    paste0(s,"(",substr(setores$nome[setores$cod==s],1,12),")")), collapse=", ")
  cat(sprintf("  %-14s → %s\n", g, nm))
}

# ── 2. MMA % energy mix for each industrial sub-group at all years ─────────
cat("\n--- MMA: % mix energético por sub-grupo (100D) ---\n")
cat(sprintf("  %-18s  %7s  %5s  %5s  %5s  %5s  %5s  %5s\n",
    "Sub-grupo","Base2020","2025","2030","2035","2040","2045","2050"))
cat(strrep("-", 73), "\n")

show_mix <- function(label, foss_pct, bio_pct, elec_pct,
                     f0, b0, e0, cenario="100D") {
  yrs <- c("2025","2030","2035","2040","2045","2050")
  f_vec <- sapply(yrs, function(y) foss_pct[[cenario]][y])
  b_vec <- sapply(yrs, function(y) bio_pct[[cenario]][y])
  e_vec <- sapply(yrs, function(y) elec_pct[[cenario]][y])
  cat(sprintf("  %-18s\n", label))
  cat(sprintf("    Fóssil  base=%.3f  %s\n", f0, paste(sprintf("%5.3f",f_vec), collapse="  ")))
  cat(sprintf("    Bio     base=%.3f  %s\n", b0, paste(sprintf("%5.3f",b_vec), collapse="  ")))
  cat(sprintf("    Elec    base=%.3f  %s\n", e0, paste(sprintf("%5.3f",e_vec), collapse="  ")))
}

show_mix("Ferro e Aço (S29)", foss_ferro_pct, bio_ferro_pct, elec_ferro_pct,
          foss_ferro_2020, bio_ferro_2020, elec_ferro_2020)
show_mix("Cimento (S28)",     foss_cim_pct,   bio_cim_pct,   elec_cim_pct,
          foss_cim_2020,   bio_cim_2020,   elec_cim_2020)
show_mix("Químico (S24-26)",  foss_qui_pct,   bio_qui_pct,   elec_qui_pct,
          foss_qui_2020,   bio_qui_2020,   elec_qui_2020)
show_mix("Outros (S10-S23+)", foss_out_pct,   bio_out_pct,   elec_out_pct,
          foss_out_2020,   bio_out_2020,   elec_out_2020)

# ── 3. Derived scale factors ─────────────────────────────────────────────
cat("\n--- Fatores de escala (sc = pct_t / pct_base) — 100D ---\n")
cat(sprintf("  %-18s  %12s  %5s  %5s  %5s  %5s  %5s  %5s\n",
    "Sub-grupo","Fonte","2025","2030","2035","2040","2045","2050"))
cat(strrep("-", 73), "\n")

show_sc <- function(label, pct_list, base, cenario="100D") {
  yrs <- c("2025","2030","2035","2040","2045","2050")
  sc_vec <- sapply(yrs, function(y) {
    v <- pct_list[[cenario]][y]
    if (base > 1e-6) v/base else 0
  })
  cat(sprintf("  %-18s  %12s  %s\n", label, "", paste(sprintf("%5.2f", sc_vec), collapse="  ")))
}

cat("  Químico:\n")
show_sc("  sc_foss", foss_qui_pct, foss_qui_2020)
show_sc("  sc_bio",  bio_qui_pct,  bio_qui_2020)
show_sc("  sc_elec", elec_qui_pct, elec_qui_2020)
cat("  Outros:\n")
show_sc("  sc_foss", foss_out_pct, foss_out_2020)
show_sc("  sc_bio",  bio_out_pct,  bio_out_2020)
show_sc("  sc_elec", elec_out_pct, elec_out_2020)

# ── 4. Base energy coefficients for key sectors ──────────────────────────
cat("\n--- Coeficientes energéticos base 2018 (A matrix) ---\n")
sectors_show <- c("S08","S09","S10","S11","S16","S17","S23","S24","S25","S26","S28","S29")
cat(sprintf("  %-6s  %-30s  %8s  %8s  %8s  %8s  | %-10s\n",
    "Cod","Nome","A[S19]","A[S43]","A[S22]","A[S40]","Grupo"))
cat(strrep("-", 85), "\n")
for (j in sectors_show) {
  grupo <- ""
  for (g in c("agro","ind_aco","ind_cimento","ind_quimico","ind_outros")) {
    if (j %in% GRUPOS[[g]]) { grupo <- g; break }
  }
  nm <- substr(setores$nome[setores$cod==j], 1, 30)
  cat(sprintf("  %-6s  %-30s  %8.5f  %8.5f  %8.5f  %8.5f  | %-10s\n",
      j, nm, A["S19",j], A["S43",j], A["S22",j], A["S40",j], grupo))
}

# ── 5. S24/S25 anomaly — what do the coefficients look like over time ─────
cat("\n--- S24 e S25 — coeficientes 100D todos os anos (verificar anomalia) ---\n")
for (j in c("S24","S25")) {
  nm <- setores$nome[setores$cod==j]
  cat(sprintf("\n  %s — %s\n", j, nm))
  cat(sprintf("  %-6s  %8s  %8s  %8s  %8s  (foss=S19+S43, bio=S22, elec=S40)\n",
      "Ano","A[S19]","A[S43]","A[S22]","A[S40]"))
  cat(sprintf("  %-6s  %8.5f  %8.5f  %8.5f  %8.5f  (BASE 2018)\n",
      "Base", A["S19",j], A["S43",j], A["S22",j], A["S40",j]))
  for (yr in c("2025","2030","2035","2040","2045","2050")) {
    As <- engine2_A_star("100D", yr)
    cat(sprintf("  %-6s  %8.5f  %8.5f  %8.5f  %8.5f\n",
        yr, As["S19",j], As["S43",j], As["S22",j], As["S40",j]))
  }
}
