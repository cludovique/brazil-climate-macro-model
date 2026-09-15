# =============================================================================
# ERL PAPER — ENGINE 2 CONSTANT-PRICE VALIDATION
# =============================================================================
# Purpose
#   1. Demonstrate that the normalized Engine 2 formula already implements a
#      constant-base-price revaluation of MMA/BLUES physical fuel shares.
#   2. Compare the relative prices implied by the 2018 IO coefficients and the
#      MMA 2020 physical shares with external 2018 ANP/MME/EPE benchmarks.
#
# IMPORTANT
# External energy prices are NOT multiplied into Engine 2. Doing so on top of
# a_i,0 * (s_i,t / s_i,0) would double-count relative prices. They are used as
# an external validation / sensitivity benchmark only.
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

# Use the paper loader so validation follows the exact paper-branch sector map.
source("paper/load_paper_model.R")

prices <- read.csv("paper/data/engine2_price_bridge_2018.csv", check.names = FALSE,
                   stringsAsFactors = FALSE)
price_gj <- setNames(prices$price_R2018_per_GJ, prices$carrier)

p_elec <- unname(price_gj["Electricity"])
p_bio  <- unname(price_gj["Biodiesel B100"])
p_gas  <- unname(price_gj["Natural gas"])
p_diesel <- unname(price_gj["Diesel"])
p_glp <- unname(price_gj["GLP"])
p_fuel_oil <- unname(price_gj["Fuel oil A1"])

energy_coeffs <- function(j) {
  c(
    elec = sum(A[intersect(c("S40", "S41"), rownames(A)), j], na.rm = TRUE),
    bio  = sum(A[intersect(c("S20", "S22"), rownames(A)), j], na.rm = TRUE),
    foss = sum(A[intersect(c("S19", "S43"), rownames(A)), j], na.rm = TRUE)
  )
}

external_fossil_price <- function(j, s19_proxy) {
  a19 <- if ("S19" %in% rownames(A)) A["S19", j] else 0
  a43 <- if ("S43" %in% rownames(A)) A["S43", j] else 0
  den <- a19 + a43
  if (den <= 0) return(s19_proxy)
  (a19 * s19_proxy + a43 * p_gas) / den
}

# Only the blocks that use the normalized rebalancear() closure are tested here.
# Generation, refining, shipping, aviation, biodiesel and biomethane use separate
# direct indicators and must be interpreted separately.
groups <- list(
  steel = list(
    sectors = GRUPOS$ind_aco,
    base = c(elec = elec_ferro_2020, bio = bio_ferro_2020, foss = foss_ferro_2020),
    new = function(cen, a) c(elec = elec_ferro_pct[[cen]][a],
                              bio = bio_ferro_pct[[cen]][a],
                              foss = foss_ferro_pct[[cen]][a]),
    fossil_proxy = p_fuel_oil
  ),
  cement = list(
    sectors = GRUPOS$ind_cimento,
    base = c(elec = elec_cim_2020, bio = bio_cim_2020, foss = foss_cim_2020),
    new = function(cen, a) c(elec = elec_cim_pct[[cen]][a],
                              bio = bio_cim_pct[[cen]][a],
                              foss = foss_cim_pct[[cen]][a]),
    fossil_proxy = p_fuel_oil
  ),
  chemicals = list(
    sectors = GRUPOS$ind_quimico,
    base = c(elec = elec_qui_2020, bio = bio_qui_2020, foss = foss_qui_2020),
    new = function(cen, a) c(elec = elec_qui_pct[[cen]][a],
                              bio = bio_qui_pct[[cen]][a],
                              foss = foss_qui_pct[[cen]][a]),
    fossil_proxy = p_fuel_oil
  ),
  other_industry = list(
    sectors = GRUPOS$ind_outros,
    base = c(elec = elec_out_2020, bio = bio_out_2020, foss = foss_out_2020),
    new = function(cen, a) c(elec = elec_out_pct[[cen]][a],
                              bio = bio_out_pct[[cen]][a],
                              foss = foss_out_pct[[cen]][a]),
    fossil_proxy = p_fuel_oil
  ),
  road_transport = list(
    # Paper specification: the aggregate road-fuel trajectory is a direct
    # technological recipe for land transport (S48) only. S51 is network-mediated.
    sectors = c("S48"),
    base = c(elec = BASE2020$elec_tra,
             bio = BASE2020$bio_tra,
             foss = max(1 - BASE2020$elec_tra - BASE2020$bio_tra, 0)),
    new = function(cen, a) {
      pe <- elec_tra_pct[[cen]][a]
      pb <- bio_tra_pct[[cen]][a]
      c(elec = pe, bio = pb, foss = max(1 - pe - pb, 0))
    },
    fossil_proxy = p_diesel
  ),
  cities = list(
    sectors = GRUPOS$cidades,
    base = c(elec = BASE2020$elec_cid,
             bio = BASE2020$bio_cid,
             foss = BASE2020$gas_cid),
    new = function(cen, a) {
      pe <- elec_cid_pct[[cen]][a]
      pg <- gas_cid_pct[[cen]][a]
      c(elec = pe, bio = max(1 - pe - pg, 0), foss = pg)
    },
    fossil_proxy = p_glp
  )
)

# -----------------------------------------------------------------------------
# 1. Algebraic-equivalence test
# -----------------------------------------------------------------------------
equiv_rows <- list()
scenario <- "100D"
years <- c(2025, 2030, 2035, 2040, 2045, 2050)

for (gname in names(groups)) {
  g <- groups[[gname]]
  s0 <- as.numeric(g$base); names(s0) <- names(g$base)
  for (yr in years) {
    st <- as.numeric(g$new(scenario, as.character(yr))); names(st) <- names(g$base)
    if (any(!is.finite(st)) || any(!is.finite(s0))) next
    for (j in intersect(g$sectors, colnames(A))) {
      a0 <- energy_coeffs(j)
      total <- sum(a0)
      if (total <= 0 || any(s0 <= 1e-12)) next

      # Current normalized Engine 2 formula.
      raw_current <- a0 * (st / s0)
      if (sum(raw_current) <= 0) next
      target_current <- total * raw_current / sum(raw_current)

      # Explicit constant-price form using the prices IMPLIED by the base IO +
      # base physical shares. The proportional common factor cancels.
      p_implicit <- a0 / s0
      raw_price <- p_implicit * st
      target_price <- total * raw_price / sum(raw_price)

      equiv_rows[[length(equiv_rows) + 1]] <- data.frame(
        group = gname, year = yr, sector = j,
        max_abs_coefficient_difference = max(abs(target_current - target_price)),
        sum_energy_coefficient_base = total,
        sum_energy_coefficient_current = sum(target_current),
        sum_energy_coefficient_price_form = sum(target_price),
        stringsAsFactors = FALSE
      )
    }
  }
}

equiv_df <- do.call(rbind, equiv_rows)
write.csv(equiv_df, file.path(outdir, "engine2_constant_price_equivalence.csv"), row.names = FALSE)

# -----------------------------------------------------------------------------
# 2. External relative-price validation
# -----------------------------------------------------------------------------
validation_rows <- list()
for (gname in names(groups)) {
  g <- groups[[gname]]
  s0 <- as.numeric(g$base); names(s0) <- names(g$base)
  for (j in intersect(g$sectors, colnames(A))) {
    a0 <- energy_coeffs(j)
    if (sum(a0) <= 0 || any(s0 <= 1e-12)) next

    pimp <- a0 / s0
    if (!is.finite(pimp["foss"]) || pimp["foss"] <= 0) next
    pimp_rel <- pimp / pimp["foss"]

    pf_ext <- external_fossil_price(j, g$fossil_proxy)
    pext <- c(elec = p_elec, bio = p_bio, foss = pf_ext)
    pext_rel <- pext / pext["foss"]

    validation_rows[[length(validation_rows) + 1]] <- data.frame(
      group = gname,
      sector = j,
      sector_name = setores$nome[match(j, setores$cod)],
      base_physical_share_elec = s0["elec"],
      base_physical_share_bio = s0["bio"],
      base_physical_share_foss = s0["foss"],
      io_energy_coef_elec = a0["elec"],
      io_energy_coef_bio = a0["bio"],
      io_energy_coef_foss = a0["foss"],
      implicit_price_ratio_elec_to_foss = pimp_rel["elec"],
      implicit_price_ratio_bio_to_foss = pimp_rel["bio"],
      external_price_ratio_elec_to_foss = pext_rel["elec"],
      external_price_ratio_bio_to_foss = pext_rel["bio"],
      external_fossil_proxy_R_GJ = pf_ext,
      stringsAsFactors = FALSE
    )
  }
}
validation_df <- do.call(rbind, validation_rows)
write.csv(validation_df, file.path(outdir, "engine2_external_price_validation.csv"), row.names = FALSE)

max_err <- if (nrow(equiv_df)) max(equiv_df$max_abs_coefficient_difference, na.rm = TRUE) else NA_real_
median_e_ratio <- median(validation_df$implicit_price_ratio_elec_to_foss, na.rm = TRUE)
median_b_ratio <- median(validation_df$implicit_price_ratio_bio_to_foss, na.rm = TRUE)
median_e_ext <- median(validation_df$external_price_ratio_elec_to_foss, na.rm = TRUE)
median_b_ext <- median(validation_df$external_price_ratio_bio_to_foss, na.rm = TRUE)

fmt <- function(x, d = 4) format(round(x, d), scientific = FALSE, trim = TRUE)
report <- c(
  "# Engine 2 constant-price validation",
  "",
  "## Main result",
  "",
  "The normalized Engine 2 formula already has a constant-base-price interpretation. For each energy group, the current transformation",
  "",
  "`a_i,t(raw) = a_i,0 * (s_i,t / s_i,0)`",
  "",
  "followed by normalization to the original total energy coefficient is algebraically identical to valuing the new physical shares with the relative prices implied by the base IO coefficients and base physical shares.",
  "",
  sprintf("Maximum numerical difference between the current formula and the explicit implied-price formulation across tested 100D sectors/years: **%s**.", fmt(max_err, 12)),
  "",
  "The normalization is a separate closure assumption: it holds the total modeled monetary energy-input coefficient fixed while only the carrier composition changes. It should not be described as holding physical energy intensity constant.",
  "",
  "Therefore the ANP/MME/EPE 2018 prices should **not** be multiplied into the current normalized Engine 2 formula as an additional factor. That would count relative prices twice. External prices are used here as a benchmark for the relative valuations implied by the base IO/MMA bridge.",
  "",
  "## External price benchmark",
  "",
  "The external price bridge is instead used to ask whether the relative prices implicitly embedded by the IO/MMA base-year mapping are broadly compatible with observed 2018 energy-price evidence.",
  "",
  sprintf("Across the tested normalized Engine-2 columns, the median implicit electricity/fossil relative-price ratio is **%s**, compared with a median external benchmark of **%s**.", fmt(median_e_ratio, 2), fmt(median_e_ext, 2)),
  sprintf("The median implicit bio/fossil ratio is **%s**, compared with an external benchmark of **%s** using biodiesel as the bioenergy proxy.", fmt(median_b_ratio, 2), fmt(median_b_ext, 2)),
  "",
  "These comparisons are diagnostics, not calibration targets. Differences can arise because the IO rows aggregate multiple products, MMA physical shares use 2020 while the IO table is 2018, and observed market-stage prices differ across carriers.",
  "",
  "## Scope",
  "",
  "This audit covers the blocks that use the normalized `rebalancear()` closure: steel, cement, chemicals, other industry, road transport (S48 only) and cities/buildings. Electricity generation, refining, shipping, aviation, biodiesel and biomethane use separate direct indicators in Engine 2 and require their own calibration checks.",
  "",
  "## Files",
  "",
  "- `engine2_constant_price_equivalence.csv`",
  "- `engine2_external_price_validation.csv`",
  "- source price bridge: `paper/data/engine2_price_bridge_2018.csv`"
)
writeLines(report, file.path(outdir, "engine2_price_validation.md"), useBytes = TRUE)

cat(sprintf("Engine 2 constant-price audit complete; max equivalence error = %.3e\n", max_err))
