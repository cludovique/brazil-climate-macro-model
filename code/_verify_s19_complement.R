setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

As <- engine2_A_star("100D","2050")
ind <- As["S19","S19"] / A["S19","S19"]

cat("=== S19 coprocessamento complement — 100D 2050 ===\n")
cat(sprintf("indicador_s19 (implied)      = %.4f  (%.1f%% fossil remains)\n", ind, 100*ind))
cat(sprintf("A[S05,S19] base=%.4f  new=%.4f  drop=%+.4f\n",
    A["S05","S19"], As["S05","S19"], As["S05","S19"]-A["S05","S19"]))
cat(sprintf("A[S19,S19] base=%.4f  new=%.4f  drop=%+.4f\n",
    A["S19","S19"], As["S19","S19"], As["S19","S19"]-A["S19","S19"]))
cat(sprintf("A[S22,S19] base=%.4f  new=%.4f  gain=%+.4f\n",
    A["S22","S19"], As["S22","S19"], As["S22","S19"]-A["S22","S19"]))

foss_drop <- (A["S05","S19"] - As["S05","S19"]) + (A["S19","S19"] - As["S19","S19"])
bio_gain  <- As["S22","S19"] - A["S22","S19"]
cat(sprintf("\nConservation: fossil drop=%.4f  bio gain=%.4f  match=%s\n",
    foss_drop, bio_gain, ifelse(abs(foss_drop-bio_gain)<1e-6,"YES","~approx")))

res <- readRDS("data/processed/mma_shocks.rds")
ra  <- res[["res_all"]]
s19 <- ra[ra[["cenario"]]=="100D" & ra[["ano"]]==2050 & ra[["cod"]]=="S19",]
cat(sprintf("\ndelta_x_transition S19 (new) = R$ %+.0f M\n", s19[["delta_x_transition"]]))
cat(sprintf("(was -160721 before this fix)\n"))
