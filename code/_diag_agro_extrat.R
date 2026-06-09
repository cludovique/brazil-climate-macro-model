setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

ENERGY_ROWS <- c("S19","S43","S20","S22","S40","S41")

sectors_of_interest <- c(
  "S01","S02","S03","S04",          # Agropecuário
  "S05","S06","S07",                 # Extrativista (oleo/gas, minerais, metais)
  # Reference: industry sectors already shocked
  "S29","S28","S24","S10"
)

cat("=== Energy coefficients: Agropecuário + Extrativista vs Industry reference ===\n")
cat(sprintf("%-6s  %-36s  %8s  %8s  %8s  %8s  | %8s %8s %8s\n",
    "Cod","Nome","A[S19]","A[S43]","A[S22]","A[S40]","Fossil","Bio","Elec"))
cat(strrep("-",100),"\n")
for (j in sectors_of_interest) {
  nm <- substr(setores$nome[setores$cod==j],1,36)
  s19 <- A["S19",j]; s43 <- A["S43",j]
  s22 <- A["S22",j]; s20 <- A["S20",j]
  s40 <- A["S40",j]; s41 <- A["S41",j]
  cat(sprintf("%-6s  %-36s  %8.5f  %8.5f  %8.5f  %8.5f  | %8.5f %8.5f %8.5f\n",
      j, nm, s19, s43, s20+s22, s40,
      s19+s43, s20+s22, s40+s41))
}

# Express as % of total energy input
cat("\n=== Same, as % of total energy input (Fossil+Bio+Elec) ===\n")
cat(sprintf("%-6s  %-36s  %7s  %7s  %7s  | %8s\n",
    "Cod","Nome","Fossil%","Bio%","Elec%","Total_A"))
cat(strrep("-",80),"\n")
for (j in sectors_of_interest) {
  s19 <- A["S19",j]+A["S43",j]
  bio <- A["S20",j]+A["S22",j]
  elc <- A["S40",j]+A["S41",j]
  tot <- s19+bio+elc
  if (tot < 1e-6) next
  nm <- substr(setores$nome[setores$cod==j],1,36)
  cat(sprintf("%-6s  %-36s  %6.1f%%  %6.1f%%  %6.1f%%  | %8.5f\n",
      j, nm, 100*s19/tot, 100*bio/tot, 100*elc/tot, tot))
}

# What proxy from MMA data could apply?
cat("\n=== Available MMA base values (2020) for proxy ===\n")
cat(sprintf("  Outros Indústria 2020: foss=%.3f  bio=%.3f  elec=%.3f\n",
    foss_out_2020, bio_out_2020, elec_out_2020))
cat(sprintf("  Transport 2020:        foss=%.4f  bio=%.4f  elec=%.4f\n",
    max(1-BASE2020$elec_tra-BASE2020$bio_tra,0), BASE2020$bio_tra, BASE2020$elec_tra))
cat(sprintf("  Industria Outros at 100D 2050:\n"))
pf100 <- foss_out_pct[["100D"]]["2050"]
pb100 <- bio_out_pct[["100D"]]["2050"]
pe100 <- elec_out_pct[["100D"]]["2050"]
cat(sprintf("    foss=%.3f  bio=%.3f  elec=%.3f\n", pf100, pb100, pe100))
cat(sprintf("    sc_f=%.2f  sc_b=%.2f  sc_e=%.2f\n",
    pf100/foss_out_2020, pb100/bio_out_2020, pe100/elec_out_2020))

# Context: total fossil spend by these sectors (economic scale)
cat("\n=== Economic scale: fossil spend (R$M) and output (R$M) 2018 ===\n")
cat(sprintf("%-6s  %-30s  %10s  %10s  %6s\n","Cod","Nome","x_2018 R$M","fossil R$M","foss%"))
cat(strrep("-",68),"\n")
for (j in sectors_of_interest[1:7]) {
  nm <- substr(setores$nome[setores$cod==j],1,30)
  xi <- x[names(x)==j]
  fi <- (A["S19",j]+A["S43",j]) * xi
  pct <- fi/xi*100
  cat(sprintf("%-6s  %-30s  %10.0f  %10.0f  %5.1f%%\n", j, nm, xi, fi, pct))
}
