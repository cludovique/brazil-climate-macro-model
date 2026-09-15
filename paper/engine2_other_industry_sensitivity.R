# =============================================================================
# ERL PAPER — ENGINE 2 OTHER-INDUSTRY SENSITIVITY
# =============================================================================
# Tests whether protecting likely material-feedstock coefficients in S23/S25/S26
# materially changes Engine 2 and the hard-constrained macro results.
#
# Variant A = current paper Engine 2.
# Variant B = "energy-only other industry":
#   - S23: protect petroleum-related row S19 from the generic other-industry
#          rebalance (potential petrochemical feedstock); electricity/bio/fossil
#          energy rows otherwise follow the scenario transformation.
#   - S25/S26: protect S20/S22 bio-related coefficients (likely material
#          feedstocks) from the generic other-industry rebalance.
# The test is deliberately conservative: protected coefficients are restored to
# their 2018 values after the current Engine 2 transformation, while the other
# energy rows remain scenario-adjusted.
# =============================================================================

options(scipen = 12, OutDec = ".")
repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = getwd())
setwd(repo_root)
outdir <- file.path("paper", "results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

source("paper/load_paper_model.R")

# For this sensitivity, we use the paper model as the reference.
engine2_A_star_energy_only <- function(cenario, ano) {
  A_ref <- engine2_A_star(cenario, ano)
  A_alt <- A_ref

  # Protect likely material feedstocks from generic fuel switching.
  if ("S23" %in% colnames(A_alt) && "S19" %in% rownames(A_alt)) {
    A_alt["S19", "S23"] <- A["S19", "S23"]
  }
  for (j in intersect(c("S25", "S26"), colnames(A_alt))) {
    for (i in intersect(c("S20", "S22"), rownames(A_alt))) {
      A_alt[i, j] <- A[i, j]
    }
  }
  A_alt
}

all_sector_gdp_shock <- function(ano) {
  g <- gdp_rel_2018[as.character(ano)]
  out <- f_base * (g - 1)
  names(out) <- setores$cod
  out
}
calc_va <- function(dx) sum(sat_gdp[setores$cod] * dx, na.rm = TRUE)
calc_output <- function(dx) sum(dx, na.rm = TRUE)

hard_solution_with_A <- function(A_star, cenario, ano) {
  L_star <- solve(diag(N) - A_star)
  C <- intersect(ENGINE3_SECTORS, setores$cod)
  df_gdp <- all_sector_gdp_shock(ano)
  df_inv <- engine1_inv(cenario, ano)
  dx_un <- as.vector(L_star %*% (df_gdp + df_inv)); names(dx_un) <- setores$cod
  dx_target <- engine3_delta_x(cenario, ano); names(dx_target) <- setores$cod
  gap_C <- dx_target[C] - dx_un[C]
  g_C <- as.vector(solve(L_star[C, C, drop = FALSE], gap_C)); names(g_C) <- C
  dx_con <- dx_un + as.vector(L_star[, C, drop = FALSE] %*% g_C)
  names(dx_con) <- setores$cod
  list(dx_un = dx_un, dx_con = dx_con)
}

years <- c(2025, 2030, 2035, 2040, 2045, 2050)
agg <- list(); sec <- list()
focus <- intersect(c("S23","S25","S26"), setores$cod)

for (yr in years) {
  A_cur <- engine2_A_star("100D", yr)
  A_alt <- engine2_A_star_energy_only("100D", yr)
  r_cur <- hard_solution_with_A(A_cur, "100D", yr)
  r_alt <- hard_solution_with_A(A_alt, "100D", yr)

  agg[[as.character(yr)]] <- data.frame(
    year = yr,
    current_unconstrained_output_Rbn = calc_output(r_cur$dx_un)/1000,
    energy_only_unconstrained_output_Rbn = calc_output(r_alt$dx_un)/1000,
    delta_unconstrained_output_Rbn = (calc_output(r_alt$dx_un)-calc_output(r_cur$dx_un))/1000,
    current_unconstrained_va_Rbn = calc_va(r_cur$dx_un)/1000,
    energy_only_unconstrained_va_Rbn = calc_va(r_alt$dx_un)/1000,
    delta_unconstrained_va_Rbn = (calc_va(r_alt$dx_un)-calc_va(r_cur$dx_un))/1000,
    current_hard_output_Rbn = calc_output(r_cur$dx_con)/1000,
    energy_only_hard_output_Rbn = calc_output(r_alt$dx_con)/1000,
    delta_hard_output_Rbn = (calc_output(r_alt$dx_con)-calc_output(r_cur$dx_con))/1000,
    current_hard_va_Rbn = calc_va(r_cur$dx_con)/1000,
    energy_only_hard_va_Rbn = calc_va(r_alt$dx_con)/1000,
    delta_hard_va_Rbn = (calc_va(r_alt$dx_con)-calc_va(r_cur$dx_con))/1000,
    stringsAsFactors = FALSE
  )

  for (j in focus) {
    sec[[length(sec)+1]] <- data.frame(
      year = yr, sector = j, sector_name = setores$nome[match(j,setores$cod)],
      current_unconstrained_dx_Rm = r_cur$dx_un[j],
      energy_only_unconstrained_dx_Rm = r_alt$dx_un[j],
      delta_unconstrained_Rm = r_alt$dx_un[j]-r_cur$dx_un[j],
      current_hard_dx_Rm = r_cur$dx_con[j],
      energy_only_hard_dx_Rm = r_alt$dx_con[j],
      delta_hard_Rm = r_alt$dx_con[j]-r_cur$dx_con[j],
      stringsAsFactors = FALSE
    )
  }
}

agg_df <- do.call(rbind, agg)
sec_df <- do.call(rbind, sec)
write.csv(agg_df, file.path(outdir, "engine2_other_industry_sensitivity_aggregate.csv"), row.names = FALSE)
write.csv(sec_df, file.path(outdir, "engine2_other_industry_sensitivity_sectors.csv"), row.names = FALSE)

# Document exactly which coefficients are protected and how large they are in base.
prot <- data.frame(
  sector = c("S23","S25","S25","S26","S26"),
  protected_row = c("S19","S20","S22","S20","S22"),
  base_coefficient = c(A["S19","S23"],A["S20","S25"],A["S22","S25"],A["S20","S26"],A["S22","S26"]),
  rationale = c(
    "petroleum-derived petrochemical material/feedstock may be embedded in S19 purchases",
    "bio-based material/feedstock may be embedded in S20 purchases",
    "bio-based material/feedstock may be embedded in S22 purchases",
    "bio-based material/feedstock may be embedded in S20 purchases",
    "bio-based material/feedstock may be embedded in S22 purchases"
  ), stringsAsFactors = FALSE
)
write.csv(prot, file.path(outdir, "engine2_other_industry_protected_coefficients.csv"), row.names = FALSE)

f <- function(x,d=3) format(round(x,d), scientific=FALSE, trim=TRUE)
r2050 <- agg_df[agg_df$year==2050,]
report <- c(
  "# Engine 2 other-industry sensitivity",
  "",
  "This test protects likely material-feedstock coefficients from the generic MMA `other industry` fuel-switching trajectory, while leaving the rest of Engine 2 unchanged.",
  "",
  "Protected coefficients: S19->S23 and S20/S22->S25/S26. This is a conservative diagnostic, not yet a final structural split between energy and feedstocks.",
  "",
  "## 2050 effect",
  "",
  paste0("- Unconstrained VA difference (energy-only minus current): **R$ ", f(r2050$delta_unconstrained_va_Rbn), " bn**."),
  paste0("- Hard-constrained VA difference: **R$ ", f(r2050$delta_hard_va_Rbn), " bn**."),
  paste0("- Unconstrained gross-output difference: **R$ ", f(r2050$delta_unconstrained_output_Rbn), " bn**."),
  paste0("- Hard-constrained gross-output difference: **R$ ", f(r2050$delta_hard_output_Rbn), " bn**."),
  "",
  "If these differences are small relative to the overall transition differential, the current residual-industry aggregation is robust to the feedstock interpretation. If they are material, the paper should retain the energy-only specification or introduce an explicit feedstock bridge.",
  "",
  "## Files",
  "",
  "- `engine2_other_industry_sensitivity_aggregate.csv`",
  "- `engine2_other_industry_sensitivity_sectors.csv`",
  "- `engine2_other_industry_protected_coefficients.csv`"
)
writeLines(report, file.path(outdir, "engine2_other_industry_sensitivity.md"), useBytes = TRUE)
cat("Engine 2 other-industry sensitivity complete.\n")
