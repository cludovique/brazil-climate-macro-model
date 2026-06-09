setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

cat("\n=== S43 column changes in A* (100D, 2025 vs 2050) ===\n")
A25_early <- engine2_A_star("100D","2025")
A100_late <- engine2_A_star("100D","2050")

rows_check <- c("S05","S19","S43","S22","S44","S08")
cat(sprintf("%-6s  %-34s  %10s  %10s  %10s\n",
    "Sector","Nome","A_base","A*(100D_2025)","A*(100D_2050)"))
cat(strrep("-",80),"\n")
for (r in rows_check) {
  nm <- substr(setores$nome[setores$cod==r],1,34)
  cat(sprintf("%-6s  %-34s  %10.6f  %10.6f  %10.6f\n",
      r, nm, A[r,"S43"], A25_early[r,"S43"], A100_late[r,"S43"]))
}

ind_2025 <- 900/(900+suppressWarnings(as.numeric(pj_biometano[["100D"]]["2025"])))
ind_2050 <- 900/(900+suppressWarnings(as.numeric(pj_biometano[["100D"]]["2050"])))
cat(sprintf("\nindicador_s43: 2025=%.4f (bio≈%.0fPJ)  2050=%.4f (bio≈%.0fPJ)\n",
    ind_2025, suppressWarnings(as.numeric(pj_biometano[["100D"]]["2025"])),
    ind_2050, suppressWarnings(as.numeric(pj_biometano[["100D"]]["2050"]))))

cat("\n--- Verification: fossil side ---\n")
cat(sprintf("  A[S05,S43] base=0.1296, × ind_2050=%.4f → expect %.4f, got %.4f %s\n",
    ind_2050, A["S05","S43"]*ind_2050, A100_late["S05","S43"],
    ifelse(abs(A100_late["S05","S43"] - A["S05","S43"]*ind_2050)<1e-7,"✓ OK","✗ WRONG")))
cat(sprintf("  A[S43,S43] base=0.0174, × ind_2050=%.4f → expect %.4f, got %.4f %s\n",
    ind_2050, A["S43","S43"]*ind_2050, A100_late["S43","S43"],
    ifelse(abs(A100_late["S43","S43"] - A["S43","S43"]*ind_2050)<1e-7,"✓ OK","✗ WRONG")))

cat("\n--- Verification: biomass complement ---\n")
expected_bio <- A["S22","S43"] + A["S05","S43"]*(1-ind_2050)*1.0
cat(sprintf("  A[S22,S43]: base=%.6f + A[S05]*(1-ind)=%.6f → expect %.6f, got %.6f %s\n",
    A["S22","S43"], A["S05","S43"]*(1-ind_2050), expected_bio, A100_late["S22","S43"],
    ifelse(abs(A100_late["S22","S43"] - expected_bio)<1e-7,"✓ OK","✗ WRONG")))

cat("\n=== Economic impact check (100D, 2050) ===\n")
delta_A_S43 <- A100_late[,"S43"] - A[,"S43"]
movers <- sort(delta_A_S43[abs(delta_A_S43)>1e-5], decreasing=TRUE)
cat("Top coefficient changes in A*[·,S43]:\n")
for (r in names(movers)) {
  nm <- substr(setores$nome[setores$cod==r],1,38)
  cat(sprintf("  %-6s  %-38s  %+.5f\n", r, nm, movers[r]))
}
