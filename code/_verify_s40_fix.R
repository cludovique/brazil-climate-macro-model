setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

cat("=== S40 Geração Elétrica — coeficientes por cenário/ano ===\n\n")
cat(sprintf("Base 2018:  A[S19,S40]=%.5f  A[S43,S40]=%.5f  A[S22,S40]=%.5f\n\n",
    A["S19","S40"], A["S43","S40"], A["S22","S40"]))

cat(sprintf("MMA base 2020: pct_fossil=%.3f  pct_bio=%.3f\n\n",
    foss_gen_2020, bio_gen_2020))

cat(sprintf("%-6s  %-4s  %-8s  %-8s  %-8s  %-8s  %-8s  %-8s  | fossil_ind  bio_ind\n",
    "Cen","Ano","S19→S40","S43→S40","S22→S40","pct_foss","pct_bio","chk"))
cat(strrep("-", 95), "\n")

for (cen in c("25D","100D")) {
  for (yr in c("2025","2030","2035","2040","2045","2050")) {
    As <- engine2_A_star(cen, yr)
    pf  <- foss_gen_pct[[cen]][yr]
    pb  <- bio_gen_pct[[cen]][yr]
    ind_f <- if (!is.na(pf) && foss_gen_2020 > 1e-6) max(pf / foss_gen_2020, 0) else NA
    ind_b <- if (!is.na(pb) && bio_gen_2020 > 1e-6) max(pb / bio_gen_2020, 0) else NA
    cat(sprintf("%-6s  %-4s  %8.5f  %8.5f  %8.5f  %8.4f  %8.4f  %8s  | %8.3f  %8.3f\n",
        cen, yr,
        As["S19","S40"], As["S43","S40"], As["S22","S40"],
        ifelse(is.na(pf), NA, pf), ifelse(is.na(pb), NA, pb),
        "–",
        ifelse(is.na(ind_f), NA, ind_f),
        ifelse(is.na(ind_b), NA, ind_b)))
  }
  cat("\n")
}

# Consistency check at 100D 2050
cat("=== Conservation check 100D 2050 ===\n")
As100 <- engine2_A_star("100D","2050")
pf50  <- foss_gen_pct[["100D"]]["2050"]
pb50  <- bio_gen_pct[["100D"]]["2050"]
ind_f50 <- max(pf50 / foss_gen_2020, 0)
ind_b50 <- max(pb50 / bio_gen_2020,  0)
cat(sprintf("  pct_fossil 2050=%.4f → ind_foss=%.4f  (expect ~%.4f)\n",
    pf50, ind_f50, 0.007/0.146))
cat(sprintf("  pct_bio    2050=%.4f → ind_bio =%.4f  (expect ~%.4f)\n",
    pb50, ind_b50, 0.126/0.093))
cat(sprintf("  A[S19,S40]: base=%.5f → new=%.5f  (×%.3f)\n",
    A["S19","S40"], As100["S19","S40"], As100["S19","S40"]/A["S19","S40"]))
cat(sprintf("  A[S43,S40]: base=%.5f → new=%.5f  (×%.3f)\n",
    A["S43","S40"], As100["S43","S40"], As100["S43","S40"]/A["S43","S40"]))
cat(sprintf("  A[S22,S40]: base=%.5f → new=%.5f  (×%.3f)\n",
    A["S22","S40"], As100["S22","S40"], As100["S22","S40"]/A["S22","S40"]))

cat(sprintf("\n  Fóssil drop : %+.5f  (S19 drop %+.5f + S43 drop %+.5f)\n",
    (As100["S19","S40"] - A["S19","S40"]) + (As100["S43","S40"] - A["S43","S40"]),
    As100["S19","S40"] - A["S19","S40"],
    As100["S43","S40"] - A["S43","S40"]))
cat(sprintf("  Biomassa Δ  : %+.5f\n",
    As100["S22","S40"] - A["S22","S40"]))
cat("\nNote: bio Δ ≠ fossil drop because this is a mix-shift (intensity changes),\n")
cat("not a strict conservation (fóssil saindo é substituído por eólica/solar/hidro\n")
cat("sem input de combustível — biomassa cresce pela proporção no mix residual).\n")
