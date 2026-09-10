# =============================================================================
# ERL PAPER — MODEL AUDIT AND MECHANISM DECOMPOSITION
# =============================================================================
# Purpose:
#   1. Reproduce the current 100D transition-premium headline results.
#   2. Audit the current baseline definition against an all-sector GDP baseline.
#   3. Decompose the transition differential into three mechanisms using Shapley
#      values, which allocate non-additive interactions consistently:
#        M1 Investment allocation
#        M2 Technical-coefficient / energy-input rewiring
#        M3 Physical-production calibration
#   4. Quantify the role of domestic content in transition investment.
#   5. Compare raw and NT-calibrated employment coefficients.
#
# This script does NOT modify the scientific model. It sources the current model
# and runs diagnostic counterfactual combinations for the paper.
# =============================================================================

options(scipen = 12, OutDec = ".")

# ---- repository root ---------------------------------------------------------
repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = "")
if (!nzchar(repo_root)) {
  # Local use: paper/model_audit.R -> repository root is parent of paper/
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(script_arg)) {
    script_path <- normalizePath(sub("^--file=", "", script_arg[1]), mustWork = FALSE)
    repo_root <- dirname(dirname(script_path))
  } else {
    repo_root <- getwd()
  }
}
setwd(repo_root)

outdir <- file.path("paper", "results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ---- source current model without changing the original hard-coded local path
# mma_shock_engines.R currently contains a Windows-specific setwd(). For the
# reproducibility audit we replace only that path at runtime; no scientific line
# of the source model is altered.
model_text <- readLines("code/mma_shock_engines.R", warn = FALSE, encoding = "UTF-8")
model_text <- gsub(
  'setwd\\("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model"\\)',
  'setwd(Sys.getenv("GITHUB_WORKSPACE", unset=getwd()))',
  model_text
)
source_text <- paste(model_text, collapse = "\n")
eval(parse(text = source_text), envir = .GlobalEnv)

# ---- helpers -----------------------------------------------------------------
metric_names <- c("gross_output", "value_added", "employment_raw", "employment_nt", "wages")

all_sector_gdp_shock <- function(ano) {
  g <- gdp_rel_2018[as.character(ano)]
  out <- f_base * (g - 1)
  names(out) <- setores$cod
  out
}

current_gdp_shock <- function(cenario, ano) {
  # Uses current model behavior, i.e. Engine-3 sectors are suppressed whenever
  # RUN_ENGINE3 is TRUE.
  engine1_gdp(cenario, ano)
}

get_labor_nt <- function() {
  setNames(satellite$labor_coef_nt, satellite$cod)
}

run_configuration <- function(cenario = "100D", ano,
                              investment = FALSE,
                              rewiring = FALSE,
                              physical = FALSE,
                              baseline_definition = c("all_sector_gdp", "current_model"),
                              dom_override = NULL) {
  baseline_definition <- match.arg(baseline_definition)
  a <- as.character(ano)

  A_use <- if (rewiring) engine2_A_star(cenario, ano) else A
  L_use <- solve(diag(N) - A_use)

  # GDP component. Under the scientifically cleaner switch design, physical=TRUE
  # replaces GDP-driven growth in Engine-3 sectors with the physical trajectory.
  if (baseline_definition == "all_sector_gdp") {
    df_gdp <- all_sector_gdp_shock(ano)
    if (physical) {
      for (s in ENGINE3_SECTORS) if (s %in% names(df_gdp)) df_gdp[s] <- 0
    }
  } else {
    # Reproduce the current code's baseline behavior for diagnostic comparison.
    df_gdp <- current_gdp_shock(cenario, ano)
  }

  # Investment component. Optionally override domestic-content assumptions.
  df_inv <- setNames(numeric(N), setores$cod)
  if (investment) {
    if (is.null(dom_override)) {
      df_inv <- engine1_inv(cenario, ano)
    } else {
      inv_bi <- INV_ANNUAL[[cenario]][[a]]
      if (!is.null(inv_bi) && is.finite(inv_bi) && inv_bi != 0) {
        inv_RM <- inv_bi * 1000
        aloc <- ALOC_INV[[cenario]][[a]]
        for (cod in names(aloc)) {
          dc <- if (length(dom_override) == 1) {
            as.numeric(dom_override)
          } else if (cod %in% names(dom_override)) {
            as.numeric(dom_override[cod])
          } else {
            1.0
          }
          df_inv[cod] <- df_inv[cod] + inv_RM * aloc[cod] * dc
        }
      }
    }
  }

  # Physical-production calibration. The target Δx is translated into an
  # equivalent final-demand vector using the A matrix active in this coalition.
  df_phys <- setNames(numeric(N), setores$cod)
  if (physical) {
    dx_target <- engine3_delta_x(cenario, ano)
    df_phys <- as.vector((diag(N) - A_use) %*% dx_target)
    names(df_phys) <- setores$cod
  }

  df_total <- df_gdp + df_inv + df_phys
  dx <- as.vector(L_use %*% df_total)
  names(dx) <- setores$cod

  va_vec <- sat_gdp[setores$cod] * dx
  emp_raw_vec <- sat_labor[setores$cod] * dx
  emp_nt_coef <- get_labor_nt()
  emp_nt_vec <- emp_nt_coef[setores$cod] * dx
  wage_vec <- sat_wage[setores$cod] * dx

  list(
    dx = dx,
    va = va_vec,
    emp_raw = emp_raw_vec,
    emp_nt = emp_nt_vec,
    wages = wage_vec,
    metrics = c(
      gross_output = sum(dx, na.rm = TRUE),
      value_added = sum(va_vec, na.rm = TRUE),
      employment_raw = sum(emp_raw_vec, na.rm = TRUE),
      employment_nt = sum(emp_nt_vec, na.rm = TRUE),
      wages = sum(wage_vec, na.rm = TRUE)
    )
  )
}

# Coalition encoding for the three mechanisms
mechanisms <- c("investment", "rewiring", "physical")
coalitions <- expand.grid(
  investment = c(FALSE, TRUE),
  rewiring = c(FALSE, TRUE),
  physical = c(FALSE, TRUE),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
coalitions$key <- apply(coalitions[, mechanisms], 1, function(z) paste(as.integer(z), collapse = ""))

run_all_coalitions <- function(cenario, ano, baseline_definition = "all_sector_gdp", dom_override = NULL) {
  out <- list()
  for (i in seq_len(nrow(coalitions))) {
    r <- coalitions[i, ]
    out[[r$key]] <- run_configuration(
      cenario = cenario, ano = ano,
      investment = r$investment,
      rewiring = r$rewiring,
      physical = r$physical,
      baseline_definition = baseline_definition,
      dom_override = dom_override
    )
  }
  out
}

# Shapley contribution of each mechanism for a scalar metric.
shapley_scalar <- function(runs, metric) {
  n <- length(mechanisms)
  phi <- setNames(numeric(n), mechanisms)

  for (m in mechanisms) {
    others <- setdiff(mechanisms, m)
    # Enumerate all subsets of the two remaining mechanisms.
    subsets <- list(character(0), others[1], others[2], others)
    for (S in subsets) {
      row0 <- setNames(rep(FALSE, n), mechanisms)
      row0[S] <- TRUE
      row1 <- row0
      row1[m] <- TRUE
      k0 <- paste(as.integer(row0), collapse = "")
      k1 <- paste(as.integer(row1), collapse = "")
      s <- length(S)
      weight <- factorial(s) * factorial(n - s - 1) / factorial(n)
      phi[m] <- phi[m] + weight * (runs[[k1]]$metrics[metric] - runs[[k0]]$metrics[metric])
    }
  }
  phi
}

# Shapley decomposition for sector-level vectors (value added and gross output).
shapley_vector <- function(runs, vector_name) {
  n <- length(mechanisms)
  template <- switch(vector_name,
    dx = runs[[1]]$dx,
    va = runs[[1]]$va,
    emp_raw = runs[[1]]$emp_raw,
    emp_nt = runs[[1]]$emp_nt,
    wages = runs[[1]]$wages
  )
  phi <- matrix(0, nrow = length(template), ncol = n,
                dimnames = list(names(template), mechanisms))

  for (m in mechanisms) {
    others <- setdiff(mechanisms, m)
    subsets <- list(character(0), others[1], others[2], others)
    for (S in subsets) {
      row0 <- setNames(rep(FALSE, n), mechanisms)
      row0[S] <- TRUE
      row1 <- row0
      row1[m] <- TRUE
      k0 <- paste(as.integer(row0), collapse = "")
      k1 <- paste(as.integer(row1), collapse = "")
      v0 <- runs[[k0]][[vector_name]]
      v1 <- runs[[k1]][[vector_name]]
      s <- length(S)
      weight <- factorial(s) * factorial(n - s - 1) / factorial(n)
      phi[, m] <- phi[, m] + weight * (v1 - v0)
    }
  }
  phi
}

# ---- 1. Reproduce current model headline and audit baseline ------------------
years <- c(2025, 2030, 2035, 2040, 2045, 2050)
headline_rows <- list()

for (yr in years) {
  # Current model baseline and full configuration
  cur_base <- run_configuration("100D", yr, FALSE, FALSE, FALSE, "current_model")
  cur_full <- run_configuration("100D", yr, TRUE, TRUE, TRUE, "current_model")

  # All-sector GDP baseline and internally consistent full model
  alt_base <- run_configuration("100D", yr, FALSE, FALSE, FALSE, "all_sector_gdp")
  alt_full <- run_configuration("100D", yr, TRUE, TRUE, TRUE, "all_sector_gdp")

  # Current repository summary, when available
  rr <- resumo[resumo$cenario == "100D" & resumo$ano == yr, , drop = FALSE]

  headline_rows[[as.character(yr)]] <- data.frame(
    year = yr,
    repo_transition_output_Rbn = if (nrow(rr)) rr$delta_prod_transition_bi else NA_real_,
    repo_transition_va_Rbn = if (nrow(rr)) rr$delta_va_transition_bi else NA_real_,
    repo_transition_emp_raw = if (nrow(rr)) rr$delta_emp_transition else NA_real_,
    audit_current_output_Rbn = (cur_full$metrics["gross_output"] - cur_base$metrics["gross_output"]) / 1000,
    audit_current_va_Rbn = (cur_full$metrics["value_added"] - cur_base$metrics["value_added"]) / 1000,
    audit_current_emp_raw = cur_full$metrics["employment_raw"] - cur_base$metrics["employment_raw"],
    allGDP_output_Rbn = (alt_full$metrics["gross_output"] - alt_base$metrics["gross_output"]) / 1000,
    allGDP_va_Rbn = (alt_full$metrics["value_added"] - alt_base$metrics["value_added"]) / 1000,
    allGDP_emp_raw = alt_full$metrics["employment_raw"] - alt_base$metrics["employment_raw"],
    baseline_freeze_bias_output_Rbn = ((cur_full$metrics["gross_output"] - cur_base$metrics["gross_output"]) -
                                       (alt_full$metrics["gross_output"] - alt_base$metrics["gross_output"])) / 1000,
    baseline_freeze_bias_va_Rbn = ((cur_full$metrics["value_added"] - cur_base$metrics["value_added"]) -
                                   (alt_full$metrics["value_added"] - alt_base$metrics["value_added"])) / 1000,
    stringsAsFactors = FALSE
  )
}
headline_df <- do.call(rbind, headline_rows)
write.csv(headline_df, file.path(outdir, "baseline_audit.csv"), row.names = FALSE)

# ---- 2. Shapley mechanism decomposition -------------------------------------
shapley_rows <- list()
standalone_rows <- list()
sector_rows <- list()

for (yr in years) {
  runs <- run_all_coalitions("100D", yr, "all_sector_gdp")
  base <- runs[["000"]]
  full <- runs[["111"]]

  for (metric in metric_names) {
    phi <- shapley_scalar(runs, metric)
    total <- full$metrics[metric] - base$metrics[metric]
    standalone <- c(
      investment = runs[["100"]]$metrics[metric] - base$metrics[metric],
      rewiring = runs[["010"]]$metrics[metric] - base$metrics[metric],
      physical = runs[["001"]]$metrics[metric] - base$metrics[metric]
    )
    interaction <- total - sum(standalone)

    units_div <- if (metric %in% c("gross_output", "value_added", "wages")) 1000 else 1
    units <- if (metric %in% c("gross_output", "value_added", "wages")) "R$ bn (2018)" else "jobs/job-equivalents"

    for (m in mechanisms) {
      shapley_rows[[length(shapley_rows) + 1]] <- data.frame(
        year = yr, metric = metric, mechanism = m,
        shapley_contribution = as.numeric(phi[m]) / units_div,
        total_transition_differential = as.numeric(total) / units_div,
        share_of_total = if (abs(total) > 1e-12) as.numeric(phi[m] / total) else NA_real_,
        units = units,
        stringsAsFactors = FALSE
      )
      standalone_rows[[length(standalone_rows) + 1]] <- data.frame(
        year = yr, metric = metric, mechanism = m,
        standalone_effect = as.numeric(standalone[m]) / units_div,
        total_interaction = as.numeric(interaction) / units_div,
        units = units,
        stringsAsFactors = FALSE
      )
    }
  }

  # Sector-level Shapley decomposition for VA in each year.
  phi_va <- shapley_vector(runs, "va")
  for (j in seq_along(setores$cod)) {
    cod <- setores$cod[j]
    for (m in mechanisms) {
      sector_rows[[length(sector_rows) + 1]] <- data.frame(
        year = yr,
        cod = cod,
        sector = setores$nome[j],
        mechanism = m,
        va_shapley_Rbn = phi_va[cod, m] / 1000,
        stringsAsFactors = FALSE
      )
    }
  }
}

shapley_df <- do.call(rbind, shapley_rows)
standalone_df <- do.call(rbind, standalone_rows)
sector_df <- do.call(rbind, sector_rows)
write.csv(shapley_df, file.path(outdir, "mechanism_shapley.csv"), row.names = FALSE)
write.csv(standalone_df, file.path(outdir, "mechanism_standalone_and_interactions.csv"), row.names = FALSE)
write.csv(sector_df, file.path(outdir, "sector_mechanism_va.csv"), row.names = FALSE)

# ---- 3. Domestic-content diagnostic -----------------------------------------
# Compare observed MAI-based factors with a 100%-domestic upper-bound. The paper
# can later add empirically motivated low/high cases once ranges are selected.
dom_rows <- list()
for (yr in years) {
  base <- run_configuration("100D", yr, FALSE, FALSE, FALSE, "all_sector_gdp")
  obs <- run_configuration("100D", yr, TRUE, TRUE, TRUE, "all_sector_gdp", dom_override = NULL)
  full_dom <- run_configuration("100D", yr, TRUE, TRUE, TRUE, "all_sector_gdp", dom_override = 1.0)

  dom_rows[[as.character(yr)]] <- data.frame(
    year = yr,
    va_premium_observed_Rbn = (obs$metrics["value_added"] - base$metrics["value_added"]) / 1000,
    va_premium_full_domestic_Rbn = (full_dom$metrics["value_added"] - base$metrics["value_added"]) / 1000,
    recoverable_va_from_zero_import_leakage_Rbn = (full_dom$metrics["value_added"] - obs$metrics["value_added"]) / 1000,
    output_premium_observed_Rbn = (obs$metrics["gross_output"] - base$metrics["gross_output"]) / 1000,
    output_premium_full_domestic_Rbn = (full_dom$metrics["gross_output"] - base$metrics["gross_output"]) / 1000,
    stringsAsFactors = FALSE
  )
}
dom_df <- do.call(rbind, dom_rows)
write.csv(dom_df, file.path(outdir, "domestic_content_diagnostic.csv"), row.names = FALSE)

# ---- 4. Employment coefficient diagnostic ----------------------------------
emp_rows <- list()
for (yr in years) {
  runs <- run_all_coalitions("100D", yr, "all_sector_gdp")
  raw <- runs[["111"]]$metrics["employment_raw"] - runs[["000"]]$metrics["employment_raw"]
  nt  <- runs[["111"]]$metrics["employment_nt"] - runs[["000"]]$metrics["employment_nt"]
  emp_rows[[as.character(yr)]] <- data.frame(
    year = yr,
    transition_job_equiv_raw = raw,
    transition_job_equiv_NTcalibrated = nt,
    NT_to_raw_ratio = if (abs(raw) > 1e-12) nt / raw else NA_real_,
    stringsAsFactors = FALSE
  )
}
emp_df <- do.call(rbind, emp_rows)
write.csv(emp_df, file.path(outdir, "employment_coefficient_diagnostic.csv"), row.names = FALSE)

# ---- 5. Compact markdown report ---------------------------------------------
row2050 <- headline_df[headline_df$year == 2050, ]
sh2050_va <- subset(shapley_df, year == 2050 & metric == "value_added")
sh2050_out <- subset(shapley_df, year == 2050 & metric == "gross_output")
dom2050 <- dom_df[dom_df$year == 2050, ]
emp2050 <- emp_df[emp_df$year == 2050, ]

pct <- function(x) sprintf("%.1f%%", 100 * x)
num <- function(x, d = 1) format(round(x, d), big.mark = ",", scientific = FALSE, trim = TRUE)

report <- c(
  "# Model Audit 1 — ERL paper",
  "",
  "This report is generated from the current model code and input data on the paper branch.",
  "It is a diagnostic document, not yet manuscript text.",
  "",
  "## 1. Baseline audit",
  "",
  sprintf("- Current-model 2050 gross-output transition differential: **R$ %s bn**.", num(row2050$audit_current_output_Rbn)),
  sprintf("- Current-model 2050 value-added transition differential: **R$ %s bn**.", num(row2050$audit_current_va_Rbn)),
  sprintf("- Using an all-sector GDP-growth counterfactual, the 2050 gross-output differential is **R$ %s bn** and the value-added differential is **R$ %s bn**.", num(row2050$allGDP_output_Rbn), num(row2050$allGDP_va_Rbn)),
  sprintf("- Difference attributable to the current baseline freezing Engine-3 sectors rather than allowing GDP-driven growth: **R$ %s bn output** and **R$ %s bn value added**.", num(row2050$baseline_freeze_bias_output_Rbn), num(row2050$baseline_freeze_bias_va_Rbn)),
  "",
  "**Interpretation:** the manuscript should use the all-sector GDP counterfactual as the primary baseline if the intent is 'GDP grows but the transition does not occur'. The current dashboard baseline should be retained only if its narrower definition is explicitly intended and defended.",
  "",
  "## 2. Why does the transition differential emerge? — Shapley decomposition",
  "",
  "Shapley values decompose the full result while allocating interactions among the three mechanisms, so the contributions add exactly to the modeled transition differential.",
  "",
  "### 2050 value added",
  "",
  sprintf("- Investment allocation: **R$ %s bn** (%s of the total differential).", num(sh2050_va$shapley_contribution[sh2050_va$mechanism == "investment"]), pct(sh2050_va$share_of_total[sh2050_va$mechanism == "investment"])),
  sprintf("- Energy-input rewiring: **R$ %s bn** (%s).", num(sh2050_va$shapley_contribution[sh2050_va$mechanism == "rewiring"]), pct(sh2050_va$share_of_total[sh2050_va$mechanism == "rewiring"])),
  sprintf("- Physical-production calibration: **R$ %s bn** (%s).", num(sh2050_va$shapley_contribution[sh2050_va$mechanism == "physical"]), pct(sh2050_va$share_of_total[sh2050_va$mechanism == "physical"])),
  "",
  "### 2050 gross output",
  "",
  sprintf("- Investment allocation: **R$ %s bn** (%s of the total differential).", num(sh2050_out$shapley_contribution[sh2050_out$mechanism == "investment"]), pct(sh2050_out$share_of_total[sh2050_out$mechanism == "investment"])),
  sprintf("- Energy-input rewiring: **R$ %s bn** (%s).", num(sh2050_out$shapley_contribution[sh2050_out$mechanism == "rewiring"]), pct(sh2050_out$share_of_total[sh2050_out$mechanism == "rewiring"])),
  sprintf("- Physical-production calibration: **R$ %s bn** (%s).", num(sh2050_out$shapley_contribution[sh2050_out$mechanism == "physical"]), pct(sh2050_out$share_of_total[sh2050_out$mechanism == "physical"])),
  "",
  "## 3. Domestic supply-chain capture",
  "",
  sprintf("- 2050 value-added premium with current MAI-based domestic-content factors: **R$ %s bn**.", num(dom2050$va_premium_observed_Rbn)),
  sprintf("- 2050 value-added premium under a 100%%-domestic investment upper bound: **R$ %s bn**.", num(dom2050$va_premium_full_domestic_Rbn)),
  sprintf("- Difference: **R$ %s bn** of additional value added under zero investment import leakage.", num(dom2050$recoverable_va_from_zero_import_leakage_Rbn)),
  "",
  "This is an upper-bound diagnostic, not yet a policy scenario. Empirically grounded localization sensitivities should be selected before publication.",
  "",
  "## 4. Employment coefficient sensitivity",
  "",
  sprintf("- 2050 transition labor requirement using raw 2018 sectoral coefficients: **%s** job-equivalents.", num(emp2050$transition_job_equiv_raw, 0)),
  sprintf("- Using the NT-calibrated employment coefficients: **%s** job-equivalents.", num(emp2050$transition_job_equiv_NTcalibrated, 0)),
  sprintf("- NT-calibrated/raw ratio: **%s**.", pct(emp2050$NT_to_raw_ratio)),
  "",
  "## 5. Files produced",
  "",
  "- `baseline_audit.csv`",
  "- `mechanism_shapley.csv`",
  "- `mechanism_standalone_and_interactions.csv`",
  "- `sector_mechanism_va.csv`",
  "- `domestic_content_diagnostic.csv`",
  "- `employment_coefficient_diagnostic.csv`",
  "",
  "## 6. Next paper step",
  "",
  "Use the mechanism decomposition to build Figure 2, then write the Results section around the mechanism story rather than around headline totals alone. The sector-level Shapley file can be used to explain which supply chains transmit each mechanism."
)
writeLines(report, file.path(outdir, "model_audit_1.md"), useBytes = TRUE)

cat("\nERL model audit complete. Results written to", outdir, "\n")
