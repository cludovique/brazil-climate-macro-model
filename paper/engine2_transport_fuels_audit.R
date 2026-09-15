# =============================================================================
# ERL PAPER — ENGINE 2 AVIATION / MARITIME FUEL VALUATION AUDIT
# =============================================================================
# Purpose
#   Audit the bespoke S49 maritime and S50 aviation substitutions in Engine 2.
#   The physical transition indicators come from the MMA pathways; this script
#   varies only the monetary value assigned to the new biofuel input relative to
#   the displaced fossil input.
#
# Current core assumption
#   displaced R$1 of S19 petroleum input -> +R$1 of S22 biofuel input (ratio=1).
#
# External constant-2018-price diagnostic
#   Maritime: Biodiesel B100 / Fuel oil A1 (R$/GJ)
#   Aviation: Biodiesel B100 / QAV (R$/GJ)
# Biodiesel is only a transparent biofuel valuation proxy; it is NOT asserted to
# be the technological price of marine e-fuels, HVO, or SAF. Therefore this is a
# sensitivity/validation exercise, not a replacement calibration.
# =============================================================================

options(scipen = 12, OutDec = ".")
source("paper/load_paper_model.R")
dir.create("paper/results", showWarnings = FALSE, recursive = TRUE)

prices <- read.csv("paper/data/engine2_price_bridge_2018.csv",
                   stringsAsFactors = FALSE, check.names = FALSE)
p_gj <- setNames(prices$price_R2018_per_GJ, prices$carrier)

p_bio <- unname(p_gj["Biodiesel B100"])
p_marine_fossil <- unname(p_gj["Fuel oil A1"])
p_aviation_fossil <- unname(p_gj["QAV"])

stopifnot(is.finite(p_bio), is.finite(p_marine_fossil), is.finite(p_aviation_fossil))

ratio_marine_anp <- p_bio / p_marine_fossil
ratio_aviation_anp <- p_bio / p_aviation_fossil

variants <- data.frame(
  variant = c("parity_current", "anp_b100_proxy"),
  marine_bio_to_fossil_value_ratio = c(1.0, ratio_marine_anp),
  aviation_bio_to_fossil_value_ratio = c(1.0, ratio_aviation_anp),
  stringsAsFactors = FALSE
)
write.csv(variants, "paper/results/engine2_transport_fuels_price_inputs.csv", row.names = FALSE)

# Re-apply only S49/S50 bespoke coefficients after the normal paper Engine 2
# matrix is built. This leaves every other Engine 2 block unchanged.
engine2_transport_variant <- function(cenario, ano, marine_ratio = 1, aviation_ratio = 1) {
  Astar <- engine2_A_star(cenario, ano)
  a <- as.character(ano)

  # S49 maritime physical substitution indicator.
  bunker_base_pj <- 40
  bio_s49_t <- suppressWarnings(as.numeric(pj_bunker_verde[[cenario]][a]))
  if (!is.na(bio_s49_t) && bio_s49_t >= 0 &&
      all(c("S19","S22") %in% rownames(Astar)) && "S49" %in% colnames(Astar)) {
    indicador_s49 <- bunker_base_pj / (bunker_base_pj + bio_s49_t)
    Astar["S19","S49"] <- A["S19","S49"] * indicador_s49
    Astar["S22","S49"] <- A["S22","S49"] +
      A["S19","S49"] * (1 - indicador_s49) * marine_ratio
  }

  # S50 aviation physical substitution indicator.
  bioqav_base_pj <- 270
  bio_s50_t <- suppressWarnings(as.numeric(pj_bioqav[[cenario]][a]))
  if (!is.na(bio_s50_t) && bio_s50_t >= 0 &&
      all(c("S19","S22") %in% rownames(Astar)) && "S50" %in% colnames(Astar)) {
    indicador_s50 <- bioqav_base_pj / (bioqav_base_pj + bio_s50_t)
    Astar["S19","S50"] <- A["S19","S50"] * indicador_s50
    Astar["S22","S50"] <- A["S22","S50"] +
      A["S19","S50"] * (1 - indicador_s50) * aviation_ratio
  }

  Astar
}

hard_constraint_solution <- function(Astar, df_total, dx_target) {
  Lstar <- solve(diag(nrow(Astar)) - Astar)
  dx_u <- as.vector(Lstar %*% df_total); names(dx_u) <- rownames(Astar)
  C <- intersect(ENGINE3_SECTORS, names(dx_u))
  if (length(C) == 0) return(dx_u)
  LCC <- Lstar[C, C, drop = FALSE]
  gC <- solve(LCC, dx_target[C] - dx_u[C])
  dx_h <- dx_u + as.vector(Lstar[, C, drop = FALSE] %*% gC)
  names(dx_h) <- rownames(Astar)
  dx_h
}

engine1_gdp_all <- function(ano) {
  g <- gdp_rel_2018[as.character(ano)]
  f_base * (g - 1)
}

va_coef <- as.numeric(VA / pmax(x, 1e-12)); names(va_coef) <- names(x)
L0 <- solve(diag(nrow(A)) - A)

agg_rows <- list(); ka <- 1
coef_rows <- list(); kc <- 1
sec_rows <- list(); ks <- 1

for (ano in ANOS_MMA) {
  cen <- "100D"
  a <- as.character(ano)
  df_gdp <- engine1_gdp_all(ano)
  df_inv <- engine1_inv(cen, ano)
  df_total <- df_gdp + df_inv
  dx_target <- engine3_delta_x(cen, ano)

  dx_base <- as.vector(L0 %*% df_gdp); names(dx_base) <- rownames(A)
  out_base <- sum(dx_base)
  va_base <- sum(va_coef * dx_base)

  for (iv in seq_len(nrow(variants))) {
    v <- variants[iv, ]
    Av <- engine2_transport_variant(
      cen, ano,
      marine_ratio = v$marine_bio_to_fossil_value_ratio,
      aviation_ratio = v$aviation_bio_to_fossil_value_ratio
    )
    M <- diag(nrow(Av)) - Av
    Lv <- solve(M)
    dx_u <- as.vector(Lv %*% df_total); names(dx_u) <- rownames(Av)
    dx_h <- hard_constraint_solution(Av, df_total, dx_target)

    rho <- max(Mod(eigen(Av, only.values = TRUE)$values))
    cond <- kappa(M)

    agg_rows[[ka]] <- data.frame(
      year = as.integer(ano),
      variant = v$variant,
      marine_ratio = v$marine_bio_to_fossil_value_ratio,
      aviation_ratio = v$aviation_bio_to_fossil_value_ratio,
      spectral_radius_A = rho,
      condition_number_I_minus_A = cond,
      unconstrained_output_diff_Rbn = (sum(dx_u) - out_base) / 1000,
      unconstrained_va_diff_Rbn = (sum(va_coef * dx_u) - va_base) / 1000,
      hard_output_diff_Rbn = (sum(dx_h) - out_base) / 1000,
      hard_va_diff_Rbn = (sum(va_coef * dx_h) - va_base) / 1000,
      stringsAsFactors = FALSE
    ); ka <- ka + 1

    for (j in intersect(c("S49","S50"), colnames(Av))) {
      coef_rows[[kc]] <- data.frame(
        year = as.integer(ano), variant = v$variant, sector = j,
        petroleum_coef_S19 = Av["S19", j],
        biofuel_coef_S22 = Av["S22", j],
        petroleum_plus_biofuel_coef = Av["S19", j] + Av["S22", j],
        stringsAsFactors = FALSE
      ); kc <- kc + 1

      sec_rows[[ks]] <- data.frame(
        year = as.integer(ano), variant = v$variant, sector = j,
        unconstrained_output_change_Rbn = dx_u[j] / 1000,
        hard_output_change_Rbn = dx_h[j] / 1000,
        stringsAsFactors = FALSE
      ); ks <- ks + 1
    }
  }
}

agg <- do.call(rbind, agg_rows)
coefs <- do.call(rbind, coef_rows)
secs <- do.call(rbind, sec_rows)

write.csv(agg, "paper/results/engine2_transport_fuels_sensitivity_aggregate.csv", row.names = FALSE)
write.csv(coefs, "paper/results/engine2_transport_fuels_coefficients.csv", row.names = FALSE)
write.csv(secs, "paper/results/engine2_transport_fuels_sector_outputs.csv", row.names = FALSE)

# Differences from current price-parity assumption.
base <- agg[agg$variant == "parity_current",
            c("year","unconstrained_output_diff_Rbn","unconstrained_va_diff_Rbn",
              "hard_output_diff_Rbn","hard_va_diff_Rbn")]
names(base)[-1] <- paste0(names(base)[-1], "_parity")
diff <- merge(agg, base, by = "year")
diff$delta_unconstrained_output_Rbn <- diff$unconstrained_output_diff_Rbn - diff$unconstrained_output_diff_Rbn_parity
diff$delta_unconstrained_va_Rbn <- diff$unconstrained_va_diff_Rbn - diff$unconstrained_va_diff_Rbn_parity
diff$delta_hard_output_Rbn <- diff$hard_output_diff_Rbn - diff$hard_output_diff_Rbn_parity
diff$delta_hard_va_Rbn <- diff$hard_va_diff_Rbn - diff$hard_va_diff_Rbn_parity
write.csv(diff, "paper/results/engine2_transport_fuels_sensitivity_differences.csv", row.names = FALSE)

fmt <- function(z, d=3) format(round(z, d), nsmall = d, trim = TRUE)
r2050 <- diff[diff$year == 2050 & diff$variant == "anp_b100_proxy", ]

md <- c(
  "# Engine 2 aviation and maritime fuel-valuation audit",
  "",
  "## Question",
  "",
  "S49 (maritime) and S50 (aviation) use dedicated MMA physical fuel pathways. The current model reduces the S19 petroleum coefficient and adds the same monetary amount to S22 biofuels. That 1:1 replacement is a valuation assumption, not a consequence of constant prices.",
  "",
  "## Fixed-2018-price diagnostic",
  "",
  paste0("- Maritime proxy: 2018 Biodiesel B100 / Fuel oil A1 = **", fmt(ratio_marine_anp, 3), "** in R$/GJ."),
  paste0("- Aviation proxy: 2018 Biodiesel B100 / QAV = **", fmt(ratio_aviation_anp, 3), "** in R$/GJ."),
  "",
  "Biodiesel B100 is used only as a transparent observed biofuel price proxy. It is not treated as the technological price of SAF, marine HVO, ammonia or e-fuels. The ANP-proxy case is therefore a sensitivity benchmark, not the preferred calibration.",
  "",
  "## 2050 effect of replacing parity with the ANP biofuel proxy",
  "",
  paste0("- Unconstrained output difference relative to parity: **", fmt(r2050$delta_unconstrained_output_Rbn), " R$bn**."),
  paste0("- Unconstrained VA difference relative to parity: **", fmt(r2050$delta_unconstrained_va_Rbn), " R$bn**."),
  paste0("- Hard-constrained output difference relative to parity: **", fmt(r2050$delta_hard_output_Rbn), " R$bn**."),
  paste0("- Hard-constrained VA difference relative to parity: **", fmt(r2050$delta_hard_va_Rbn), " R$bn**."),
  "",
  "These deltas isolate monetary valuation of the replacement fuel while keeping the MMA physical substitution path, investment shock, all other Engine 2 mappings, and Engine 3 physical constraints unchanged.",
  "",
  "## Numerical stability",
  "",
  paste0("Across all tested years/variants, max spectral radius(A*) = **", fmt(max(agg$spectral_radius_A), 4), "**; max kappa(I-A*) = **", fmt(max(agg$condition_number_I_minus_A), 2), "**."),
  "",
  "## Files",
  "",
  "- `engine2_transport_fuels_price_inputs.csv`",
  "- `engine2_transport_fuels_coefficients.csv`",
  "- `engine2_transport_fuels_sector_outputs.csv`",
  "- `engine2_transport_fuels_sensitivity_aggregate.csv`",
  "- `engine2_transport_fuels_sensitivity_differences.csv`"
)
writeLines(md, "paper/results/engine2_transport_fuels_audit.md", useBytes = TRUE)

cat("Engine 2 aviation/maritime fuel valuation audit complete.\n")
