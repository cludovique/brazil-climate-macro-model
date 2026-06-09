setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
options(OutDec=".")

cat("A[r,S20] base 2018 — top inputs INTO biodiesel sector:\n")
s20_col <- sort(A[,"S20"], decreasing=TRUE)
s20_col <- s20_col[s20_col > 1e-5]
for (r in names(s20_col)) {
  nm <- substr(setores$nome[setores$cod==r],1,40)
  cat(sprintf("  %-6s  %-40s  %.6f\n", r, nm, A[r,"S20"]))
}
cat(sprintf("\nFóssil base (A[S19]+A[S43] in S20): %.5f\n", A["S19","S20"]+A["S43","S20"]))
cat(sprintf("Biomassa base (A[S20]+A[S22] in S20): %.5f\n", A["S20","S20"]+A["S22","S20"]))

# indicador_s20 at 100D 2050 (from dashboard: A*[S19,S20] = 0.05450)
ind_implied <- 0.05450 / 0.27470
cat(sprintf("\nindicador_s20 at 100D 2050 (implied from dashboard) = %.4f\n", ind_implied))
cat(sprintf("Bio fraction to add = (1 - %.4f) = %.4f\n", ind_implied, 1-ind_implied))
cat(sprintf("A[S22,S20] complement = A[S19,S20]*%.4f = %.5f * %.4f = +%.5f\n",
    1-ind_implied, A["S19","S20"], 1-ind_implied, A["S19","S20"]*(1-ind_implied)))
cat(sprintf("A[S22,S20] new = %.5f + %.5f = %.5f\n",
    A["S22","S20"], A["S19","S20"]*(1-ind_implied), A["S22","S20"]+A["S19","S20"]*(1-ind_implied)))

cat("\nSanity check: fossil + biomass columns at 100D 2050 after fix:\n")
cat(sprintf("  Fossil:  A[S19,S20]* = %.5f (was %.5f)\n", A["S19","S20"]*ind_implied, A["S19","S20"]))
cat(sprintf("  Biomass: A[S22,S20]* = %.5f (was %.5f)\n",
    A["S22","S20"] + A["S19","S20"]*(1-ind_implied), A["S22","S20"]))
cat(sprintf("  Fossil+Biomass base  = %.5f\n", A["S19","S20"]+A["S43","S20"]+A["S20","S20"]+A["S22","S20"]))
cat(sprintf("  Fossil+Biomass 2050* = %.5f\n",
    A["S19","S20"]*ind_implied + A["S43","S20"] + A["S20","S20"] + A["S22","S20"]+A["S19","S20"]*(1-ind_implied)))
