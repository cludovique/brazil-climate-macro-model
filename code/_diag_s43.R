setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

# ── 1. Full A[·,S43] column: what goes INTO gas sector ──────────────────────
cat("=== A[·,S43] column — inputs INTO S43 (Gás Natural), 2018 base ===\n")
s43_col <- sort(A[,"S43"], decreasing=TRUE)
s43_col <- s43_col[s43_col > 1e-6]
cat(sprintf("  %-6s  %-40s  %10s\n","Cod","Nome","A[r,S43]"))
cat(strrep("-",62),"\n")
for (r in names(s43_col)) {
  nm <- substr(setores$nome[setores$cod==r],1,40)
  cat(sprintf("  %-6s  %-40s  %10.6f\n", r, nm, A[r,"S43"]))
}
cat(sprintf("\n  Total column sum (intermediate inputs): %.5f\n", sum(A[,"S43"])))

# ── 2. Engine 2 indicator for S43 across scenarios and years ────────────────
cat("\n=== Engine 2 indicador_s43 = 900 / (900 + pj_biometano) ===\n")
cat(sprintf("  %-6s  %-4s  %10s  %10s  %10s  %10s  %10s\n",
    "Cen","Ano","bio_PJ","indicador","A[S19,S43]","A[S43,S43]","A[S22,S43]"))
cat(strrep("-",72),"\n")
ANOS_STR <- c("2025","2030","2035","2040","2045","2050")
for (cen in c("25D","100D")) {
  for (a in ANOS_STR) {
    bio_t <- suppressWarnings(as.numeric(pj_biometano[[cen]][a]))
    bio_t <- ifelse(is.na(bio_t)|bio_t<0, 0, bio_t)
    ind   <- 900 / (900 + bio_t)
    As <- engine2_A_star(cen, a)
    cat(sprintf("  %-6s  %4s  %10.1f  %10.4f  %10.6f  %10.6f  %10.6f\n",
        cen, a, bio_t, ind,
        As["S19","S43"], As["S43","S43"],
        As["S22","S43"]))
  }
  cat("\n")
}

# ── 3. The biomass gap: what SHOULD A[S22,S43] or A[S44,S43] be? ────────────
cat("=== The biomass feedstock gap ===\n")
cat(sprintf("  A[S22,S43] base 2018 = %.6f\n", A["S22","S43"]))
cat(sprintf("  A[S44,S43] base 2018 = %.6f  (S44 = water/sanitation/waste)\n",
    ifelse("S44" %in% rownames(A), A["S44","S43"], NA_real_)))
cat(sprintf("  A[S08,S43] base 2018 = %.6f  (S08 = sugar/cane sector)\n",
    ifelse("S08" %in% rownames(A), A["S08","S43"], NA_real_)))
cat(sprintf("  A[S01,S43] base 2018 = %.6f  (S01 = agriculture)\n",
    ifelse("S01" %in% rownames(A), A["S01","S43"], NA_real_)))
cat("\n")
cat("  The fossil reduction currently applied:\n")
cat(sprintf("    A[S19,S43] drops by %.6f at 100D 2050 (×0.46 of base)\n",
    A["S19","S43"] * (1 - 900/(900+suppressWarnings(as.numeric(pj_biometano[["100D"]]["2050"]))))))
cat(sprintf("    A[S43,S43] drops by %.6f at 100D 2050\n",
    A["S43","S43"] * (1 - 900/(900+suppressWarnings(as.numeric(pj_biometano[["100D"]]["2050"]))))))
cat("\n")
cat("  What we're MISSING: organic feedstock inputs to biometano production.\n")
cat("  Biometano sources in Brazil:\n")
cat("    ~40% sugarcane vinasse/bagasse (S08 / S09)\n")
cat("    ~35% urban organic waste / sewage sludge (S44)\n")
cat("    ~25% agricultural manure, other (S01)\n")
cat("\n  These feedstocks are essentially WASTE streams — near-zero monetary value.\n")
cat("  The correct IO coefficient A[S44,S43] would be very small in R$ terms.\n")
cat("  BUT: the biometano process also needs S22 inputs (compression, upgrading).\n")
cat("\n  Practical implication: the biomass ROW in the dashboard (A[S20]+A[S22], j)\n")
cat("  cannot pick up the organic-waste feedstock unless S44 is added to ENERGY_ROWS.\n")
cat("  Options:\n")
cat("    A) Add A[S44,S43] increment with rough coefficient (needs EPE/ANP data)\n")
cat("    B) Add A[S22,S43] increment as proxy for biometano upgrading inputs\n")
cat("    C) Flag as known gap — feedstock is waste (near-zero R$ value), impact small\n")

# ── 4. Magnitude check: how large would the biomass increment need to be? ───
cat("\n=== Magnitude: what A[bio,S43] increment is implied by biometano scale? ===\n")
bio_2050 <- suppressWarnings(as.numeric(pj_biometano[["100D"]]["2050"]))
x_s43    <- x[names(x)=="S43"]
cat(sprintf("  pj_biometano 100D 2050 = %.0f PJ\n", bio_2050))
cat(sprintf("  x[S43] 2018 = R$ %.0f M\n", x_s43))
cat(sprintf("  S43 base 900 PJ; bio fraction at 2050 = %.1f%%\n", 100*bio_2050/(900+bio_2050)))
# If biometano costs ~ R$30/GJ to produce (EPE estimate), and 1 PJ = 1e6 GJ:
cost_per_pj <- 30e6  # R$/PJ rough estimate
bio_cost_2050 <- bio_2050 * cost_per_pj  # R$M
cat(sprintf("  Rough biometano production cost @R$30/GJ: R$ %.0f M\n", bio_cost_2050))
cat(sprintf("  As A coefficient: %.5f (bio_cost / x_s43)\n", bio_cost_2050 / x_s43))
cat("  (Compare: A[S19,S43] base = 0.000980 — very small reference)\n")
