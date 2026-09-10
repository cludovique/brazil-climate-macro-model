# =============================================================================
# ERL PAPER — BASELINE LEVELS AND PERCENTAGE DIFFERENTIALS
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

model_text <- readLines("code/mma_shock_engines.R", warn = FALSE, encoding = "UTF-8")
model_text <- gsub(
  'setwd\\("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model"\\)',
  'setwd(Sys.getenv("GITHUB_WORKSPACE", unset=getwd()))',
  model_text
)
eval(parse(text = paste(model_text, collapse = "\n")), envir = .GlobalEnv)

all_gdp <- function(ano) {
  g <- gdp_rel_2018[as.character(ano)]
  z <- f_base * (g - 1)
  names(z) <- setores$cod
  z
}

calc_levels <- function(ano) {
  # Scientifically cleaner all-sector GDP counterfactual
  df_base <- all_gdp(ano)
  dx_base <- as.vector(L %*% df_base); names(dx_base) <- setores$cod

  Astar <- engine2_A_star("100D", ano)
  Lstar <- solve(diag(N) - Astar)
  df_gdp_full <- all_gdp(ano)
  for (s in ENGINE3_SECTORS) if (s %in% names(df_gdp_full)) df_gdp_full[s] <- 0
  dx3 <- engine3_delta_x("100D", ano)
  df3 <- as.vector((diag(N) - Astar) %*% dx3); names(df3) <- setores$cod
  dfinv <- engine1_inv("100D", ano)
  dx_full <- as.vector(Lstar %*% (df_gdp_full + dfinv + df3)); names(dx_full) <- setores$cod

  # Current dashboard baseline for comparison
  df_cur <- engine1_gdp("100D", ano)
  dx_cur <- as.vector(L %*% df_cur); names(dx_cur) <- setores$cod

  x0 <- sum(x)
  va0 <- sum(va_pib)
  emp0 <- sum(ocupacoes)

  va_base_delta <- sum(sat_gdp[setores$cod] * dx_base)
  va_full_delta <- sum(sat_gdp[setores$cod] * dx_full)
  va_cur_delta <- sum(sat_gdp[setores$cod] * dx_cur)

  emp_base_delta <- sum(sat_labor[setores$cod] * dx_base)
  emp_full_delta <- sum(sat_labor[setores$cod] * dx_full)
  emp_cur_delta <- sum(sat_labor[setores$cod] * dx_cur)

  data.frame(
    year = ano,
    gross_output_2018_Rbn = x0 / 1000,
    allGDP_baseline_output_Rbn = (x0 + sum(dx_base)) / 1000,
    NDC_output_Rbn = (x0 + sum(dx_full)) / 1000,
    output_premium_Rbn = (sum(dx_full) - sum(dx_base)) / 1000,
    output_premium_pct = (sum(dx_full) - sum(dx_base)) / (x0 + sum(dx_base)) * 100,
    current_baseline_output_Rbn = (x0 + sum(dx_cur)) / 1000,
    current_output_premium_pct = (sum(dx_full) - sum(dx_cur)) / (x0 + sum(dx_cur)) * 100,
    value_added_2018_Rbn = va0 / 1000,
    allGDP_baseline_va_Rbn = (va0 + va_base_delta) / 1000,
    NDC_va_Rbn = (va0 + va_full_delta) / 1000,
    va_premium_Rbn = (va_full_delta - va_base_delta) / 1000,
    va_premium_pct = (va_full_delta - va_base_delta) / (va0 + va_base_delta) * 100,
    current_baseline_va_Rbn = (va0 + va_cur_delta) / 1000,
    current_va_premium_pct = (va_full_delta - va_cur_delta) / (va0 + va_cur_delta) * 100,
    employment_2018 = emp0,
    allGDP_baseline_employment = emp0 + emp_base_delta,
    NDC_employment_job_equiv = emp0 + emp_full_delta,
    employment_premium_raw = emp_full_delta - emp_base_delta,
    employment_premium_pct_raw = (emp_full_delta - emp_base_delta) / (emp0 + emp_base_delta) * 100,
    current_baseline_employment = emp0 + emp_cur_delta,
    stringsAsFactors = FALSE
  )
}

res <- do.call(rbind, lapply(c(2025,2030,2035,2040,2045,2050), calc_levels))
write.csv(res, file.path(outdir, "baseline_levels_and_percentages.csv"), row.names = FALSE)

r <- res[res$year == 2050, ]
lines <- c(
  "# Baseline levels — 2050 diagnostic",
  "",
  sprintf("- All-sector GDP baseline gross output: **R$ %.2f trillion**.", r$allGDP_baseline_output_Rbn/1000),
  sprintf("- 100D gross output: **R$ %.2f trillion**.", r$NDC_output_Rbn/1000),
  sprintf("- Gross-output differential: **R$ %.1f bn (%.2f%%)**.", r$output_premium_Rbn, r$output_premium_pct),
  sprintf("- All-sector GDP baseline value added: **R$ %.2f trillion**.", r$allGDP_baseline_va_Rbn/1000),
  sprintf("- 100D value added: **R$ %.2f trillion**.", r$NDC_va_Rbn/1000),
  sprintf("- Value-added differential: **R$ %.1f bn (%.2f%%)**.", r$va_premium_Rbn, r$va_premium_pct),
  "",
  sprintf("For comparison, the current dashboard baseline gives a value-added premium of %.2f%% because Engine-3 sectors are frozen out of GDP scaling in the baseline.", r$current_va_premium_pct)
)
writeLines(lines, file.path(outdir, "baseline_levels_2050.md"), useBytes = TRUE)
