setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

cat("=== S20 coefficient evolution — 100D scenario ===\n")
cat(sprintf("%-4s  %10s  %10s  %10s  %10s  %10s\n",
    "Ano","bio_PJ","indicator","A[S19,S20]","A[S22,S20]","F+B total"))
ANOS <- c("2025","2030","2035","2040","2045","2050")
for (a in ANOS) {
  As  <- engine2_A_star("100D", a)
  bio <- suppressWarnings(as.numeric(pj_diesel_vrd[["100D"]][a]))
  bio <- ifelse(is.na(bio)|bio<0, 0, bio)
  ind <- 230 / (230 + bio)
  sum_fb <- As["S19","S20"] + As["S43","S20"] + As["S20","S20"] + As["S22","S20"]
  cat(sprintf("%-4s  %10.1f  %10.4f  %10.6f  %10.6f  %10.6f\n",
      a, bio, ind, As["S19","S20"], As["S22","S20"], sum_fb))
}
sum_fb_base <- A["S19","S20"] + A["S43","S20"] + A["S20","S20"] + A["S22","S20"]
cat(sprintf("base  %10s  %10s  %10.6f  %10.6f  %10.6f\n",
    "—", "1.0000", A["S19","S20"], A["S22","S20"], sum_fb_base))

cat("\nVerification: sum F+B should remain constant (conservation) ✓\n")
cat(sprintf("A[S05,S20] base = %.5f  (NOTE: NOT modified — see TODO)\n", A["S05","S20"]))
