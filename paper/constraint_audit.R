# =============================================================================
# ERL PAPER — NDC PHYSICAL-CONSTRAINT AUDIT
# =============================================================================
# Purpose:
#   Recast Engine 3 as a hard physical-consistency constraint rather than an
#   autonomous economic shock. The script compares:
#     (0) GDP-only baseline
#     (1) GDP + energy-input rewiring
#     (2) GDP + rewiring + transition investment (unconstrained solution)
#     (3) the same solution after imposing selected NDC production constraints.
#
# For constrained sectors C, the balancing final-demand adjustment g_C is chosen
# so that the final IO solution satisfies exactly:
#
#   dx_C = dx_C^NDC
#
# With A* and L* = (I-A*)^-1 already reflecting energy rewiring,
#
#   dx_unconstrained = L* df_unconstrained
#   g_C = (L*_{C,C})^-1 (dx_C^NDC - dx_unconstrained,C)
#   dx_constrained = dx_unconstrained + L*_{.,C} g_C
#
# Thus the NDC layer adjusts residual final demand only as much as necessary to
# reconcile the production network with the exogenous physical pathway.
# =============================================================================

options(scipen = 12, OutDec = ".")

repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = "")
if (!nzchar(repo_root)) {
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(script_arg)) {
    script_path <- normalizePath(sub("^--file=", "", script_arg[1]), mustWork = FALSE)
    repo_root <- dirname(dirname(script_path))
  } else repo_root <- getwd()
}
setwd(repo_root)
outdir <- file.path("paper", "results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# Source scientific model without editing its local-path line.
model_text <- readLines("code/mma_shock_engines.R", warn = FALSE, encoding = "UTF-8")
model_text <- gsub(
  'setwd\\("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model"\\)',
  'setwd(Sys.getenv("GITHUB_WORKSPACE", unset=getwd()))',
  model_text
)
eval(parse(text = paste(model_text, collapse = "\n")), envir = .GlobalEnv)

all_sector_gdp_shock <- function(ano) {
  g <- gdp_rel_2018[as.character(ano)]
  out <- f_base * (g - 1)
  names(out) <- setores$cod
  out
}

calc_va <- function(dx) sum(sat_gdp[setores$cod] * dx, na.rm = TRUE)
calc_output <- function(dx) sum(dx, na.rm = TRUE)

hard_constraint_solution <- function(cenario = "100D", ano) {
  A_star <- engine2_A_star(cenario, ano)
  L_star <- solve(diag(N) - A_star)
  C <- intersect(ENGINE3_SECTORS, setores$cod)

  df_gdp <- all_sector_gdp_shock(ano)
  df_inv <- engine1_inv(cenario, ano)

  # Sequential diagnostic states.
  dx_baseline <- as.vector(L %*% df_gdp)
  names(dx_baseline) <- setores$cod

  dx_rewired <- as.vector(L_star %*% df_gdp)
  names(dx_rewired) <- setores$cod

  df_unconstrained <- df_gdp + df_inv
  dx_unconstrained <- as.vector(L_star %*% df_unconstrained)
  names(dx_unconstrained) <- setores$cod

  # NDC physical target expressed as change relative to the model base.
  dx_target <- engine3_delta_x(cenario, ano)
  names(dx_target) <- setores$cod

  # Residual final-demand balancing adjustment only in constrained sectors.
  gap_C <- dx_target[C] - dx_unconstrained[C]
  L_CC <- L_star[C, C, drop = FALSE]
  g_C <- as.vector(solve(L_CC, gap_C))
  names(g_C) <- C

  adjustment <- as.vector(L_star[, C, drop = FALSE] %*% g_C)
  names(adjustment) <- setores$cod
  dx_constrained <- dx_unconstrained + adjustment

  # Reproduce current Engine-3-style implementation for diagnostic comparison.
  df_gdp_current <- df_gdp
  df_gdp_current[C] <- 0
  df_phys_current <- as.vector((diag(N) - A_star) %*% dx_target)
  names(df_phys_current) <- setores$cod
  dx_current_engine3 <- as.vector(L_star %*% (df_gdp_current + df_inv + df_phys_current))
  names(dx_current_engine3) <- setores$cod

  list(
    C = C,
    A_star = A_star,
    L_star = L_star,
    dx_baseline = dx_baseline,
    dx_rewired = dx_rewired,
    dx_unconstrained = dx_unconstrained,
    dx_target = dx_target,
    g_C = g_C,
    adjustment = adjustment,
    dx_constrained = dx_constrained,
    dx_current_engine3 = dx_current_engine3
  )
}

years <- c(2025, 2030, 2035, 2040, 2045, 2050)
aggregate_rows <- list()
sector_rows <- list()

for (yr in years) {
  r <- hard_constraint_solution("100D", yr)

  # Aggregate accounting for the sequential story.
  base_out <- calc_output(r$dx_baseline)
  rewire_out <- calc_output(r$dx_rewired)
  un_out <- calc_output(r$dx_unconstrained)
  con_out <- calc_output(r$dx_constrained)
  base_va <- calc_va(r$dx_baseline)
  rewire_va <- calc_va(r$dx_rewired)
  un_va <- calc_va(r$dx_unconstrained)
  con_va <- calc_va(r$dx_constrained)

  aggregate_rows[[as.character(yr)]] <- data.frame(
    year = yr,
    baseline_output_Rbn = base_out / 1000,
    rewiring_effect_output_Rbn = (rewire_out - base_out) / 1000,
    investment_effect_after_rewiring_output_Rbn = (un_out - rewire_out) / 1000,
    ndc_constraint_adjustment_output_Rbn = (con_out - un_out) / 1000,
    final_transition_output_differential_Rbn = (con_out - base_out) / 1000,
    baseline_va_Rbn = base_va / 1000,
    rewiring_effect_va_Rbn = (rewire_va - base_va) / 1000,
    investment_effect_after_rewiring_va_Rbn = (un_va - rewire_va) / 1000,
    ndc_constraint_adjustment_va_Rbn = (con_va - un_va) / 1000,
    final_transition_va_differential_Rbn = (con_va - base_va) / 1000,
    stringsAsFactors = FALSE
  )

  for (cod in r$C) {
    j <- match(cod, setores$cod)
    sector_rows[[length(sector_rows) + 1]] <- data.frame(
      year = yr,
      cod = cod,
      sector = setores$nome[j],
      baseline_dx_Rm = r$dx_baseline[cod],
      rewiring_dx_Rm = r$dx_rewired[cod],
      unconstrained_dx_Rm = r$dx_unconstrained[cod],
      ndc_target_dx_Rm = r$dx_target[cod],
      hard_constrained_dx_Rm = r$dx_constrained[cod],
      current_engine3_dx_Rm = r$dx_current_engine3[cod],
      rewiring_effect_Rm = r$dx_rewired[cod] - r$dx_baseline[cod],
      investment_effect_after_rewiring_Rm = r$dx_unconstrained[cod] - r$dx_rewired[cod],
      required_constraint_adjustment_Rm = r$dx_target[cod] - r$dx_unconstrained[cod],
      balancing_final_demand_Rm = r$g_C[cod],
      hard_constraint_error_Rm = r$dx_constrained[cod] - r$dx_target[cod],
      current_engine3_error_Rm = r$dx_current_engine3[cod] - r$dx_target[cod],
      stringsAsFactors = FALSE
    )
  }
}

aggregate_df <- do.call(rbind, aggregate_rows)
sector_df <- do.call(rbind, sector_rows)
write.csv(aggregate_df, file.path(outdir, "constraint_decomposition_aggregate.csv"), row.names = FALSE)
write.csv(sector_df, file.path(outdir, "constraint_decomposition_sectors.csv"), row.names = FALSE)

# Oil-specific interpretation table.
oil_df <- subset(sector_df, cod == "S05")
write.csv(oil_df, file.path(outdir, "constraint_oil_S05.csv"), row.names = FALSE)

# Markdown summary.
fmt <- function(x, d = 1) format(round(x, d), big.mark = ",", scientific = FALSE, trim = TRUE)
a2050 <- aggregate_df[aggregate_df$year == 2050, ]
o2050 <- oil_df[oil_df$year == 2050, ]
max_hard_err <- max(abs(sector_df$hard_constraint_error_Rm), na.rm = TRUE)
max_current_err <- max(abs(sector_df$current_engine3_error_Rm), na.rm = TRUE)

report <- c(
  "# NDC physical-constraint audit",
  "",
  "Engine 3 is treated here as a **hard physical-consistency layer**, not as a third autonomous economic shock.",
  "The unconstrained production network is generated by GDP growth, energy-input rewiring and transition investment. A residual final-demand vector is then solved only for the constrained sectors so that their final output changes match the NDC physical trajectory exactly.",
  "",
  "## Mathematical formulation",
  "",
  "For constrained sectors C:",
  "",
  "`dx_unconstrained = L* df_unconstrained`",
  "",
  "`g_C = (L*_{C,C})^{-1} (dx_C^NDC - dx_unconstrained,C)`",
  "",
  "`dx_constrained = dx_unconstrained + L*_{.,C} g_C`",
  "",
  sprintf("Maximum numerical hard-constraint error across constrained sectors/years: **%s R$ million**.", fmt(max_hard_err, 6)),
  "",
  "## 2050 aggregate sequential decomposition",
  "",
  sprintf("- Energy-input rewiring relative to the GDP-only baseline: **R$ %s bn value added**.", fmt(a2050$rewiring_effect_va_Rbn)),
  sprintf("- Transition investment added after rewiring: **R$ %s bn value added**.", fmt(a2050$investment_effect_after_rewiring_va_Rbn)),
  sprintf("- NDC physical-consistency adjustment: **R$ %s bn value added**.", fmt(a2050$ndc_constraint_adjustment_va_Rbn)),
  sprintf("- Final hard-constrained transition differential: **R$ %s bn value added**.", fmt(a2050$final_transition_va_differential_Rbn)),
  "",
  "This sequential decomposition is intentionally not presented as an order-invariant causal attribution. It answers a structural question: what the IO network implies after rewiring and investment, and how much residual adjustment is then required to make selected outputs consistent with the NDC pathway.",
  "",
  "## Oil and gas extraction (S05), 2050",
  "",
  sprintf("- GDP-only output change: **R$ %s bn**.", fmt(o2050$baseline_dx_Rm / 1000)),
  sprintf("- Effect of energy rewiring before investment: **R$ %s bn**.", fmt(o2050$rewiring_effect_Rm / 1000)),
  sprintf("- Additional investment/network effect after rewiring: **R$ %s bn**.", fmt(o2050$investment_effect_after_rewiring_Rm / 1000)),
  sprintf("- Unconstrained output change after rewiring + investment: **R$ %s bn**.", fmt(o2050$unconstrained_dx_Rm / 1000)),
  sprintf("- NDC physical target: **R$ %s bn**.", fmt(o2050$ndc_target_dx_Rm / 1000)),
  sprintf("- Required output adjustment to reach the NDC target: **R$ %s bn**.", fmt(o2050$required_constraint_adjustment_Rm / 1000)),
  sprintf("- Residual final-demand/export balancing term applied to S05: **R$ %s bn**.", fmt(o2050$balancing_final_demand_Rm / 1000)),
  "",
  "## Diagnostic on the current Engine 3 implementation",
  "",
  sprintf("The existing implementation does not impose the physical trajectory as an exact hard constraint once investment and network effects are added. Across the constrained sectors/years, the largest discrepancy between the current Engine-3 solution and the NDC target is **R$ %s bn of sectoral output change**.", fmt(max_current_err / 1000)),
  "",
  "This does not make the existing results unusable; it means Engine 3 is currently an additive calibration term rather than a strict constraint. The hard-constraint formulation is more faithful to the intended interpretation and should be evaluated before freezing paper results.",
  "",
  "## Files",
  "",
  "- `constraint_decomposition_aggregate.csv`",
  "- `constraint_decomposition_sectors.csv`",
  "- `constraint_oil_S05.csv`"
)
writeLines(report, file.path(outdir, "constraint_audit.md"), useBytes = TRUE)

cat("NDC physical-constraint audit complete.\n")
