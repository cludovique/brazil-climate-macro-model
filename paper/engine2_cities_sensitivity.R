# =============================================================================
# ENGINE 2 CITIES / BUILDINGS SENSITIVITY
# =============================================================================
# Tests how much the common MMA cities/buildings energy-mix trajectory matters
# when applied to the heterogeneous IO proxy sectors used in Engine 2.
#
# Variants:
#   current          : existing paper Engine 2 cities block (all GRUPOS$cidades)
#   no_real_estate   : S59 (real estate) retains its 2018 energy coefficients
#   hospitality_only : only S52 accommodation and S53 food services receive the
#                      common cities/buildings mix; S59 and public/education/
#                      health services retain their 2018 energy coefficients.
#
# The second alternative is an intentionally conservative stress test, not a
# preferred specification. It provides an upper bound on the importance of the
# broad cities-sector mapping.
# =============================================================================

source("paper/load_paper_model.R")

dir.create("paper/results", showWarnings = FALSE, recursive = TRUE)

ENERGY_ROWS <- intersect(c("S19","S20","S22","S40","S41","S43"), rownames(A))
CITY_SECTORS <- intersect(GRUPOS$cidades, colnames(A))
sector_label <- function(j) {
  z <- setores$nome[match(j, setores$cod)]
  if (length(z) == 0 || is.na(z)) j else as.character(z[[1]])
}
scalar_named <- function(v, nm, default = NA_real_) {
  z <- v[nm]
  if (length(z) == 0 || is.na(z[[1]])) default else as.numeric(z[[1]])
}

# Baseline direct energy structure by city proxy sector.
city_structure <- do.call(rbind, lapply(CITY_SECTORS, function(j) {
  elec <- sum(A[intersect(c("S40","S41"), rownames(A)), j, drop=FALSE])
  bio  <- sum(A[intersect(c("S20","S22"), rownames(A)), j, drop=FALSE])
  foss <- sum(A[intersect(c("S19","S43"), rownames(A)), j, drop=FALSE])
  data.frame(
    sector = j,
    sector_name = sector_label(j),
    electricity_coef = elec,
    bio_coef = bio,
    fossil_coef = foss,
    total_energy_coef = elec + bio + foss,
    stringsAsFactors = FALSE
  )
}))
write.csv(city_structure, "paper/results/engine2_cities_baseline_structure.csv", row.names=FALSE)

# Return an Engine-2 matrix under a cities mapping variant.
engine2_cities_variant <- function(cenario, ano, variant = c("current","no_real_estate","hospitality_only")) {
  variant <- match.arg(variant)
  Astar <- engine2_A_star(cenario, ano)

  protect <- character(0)
  if (variant == "no_real_estate") {
    protect <- intersect("S59", CITY_SECTORS)
  } else if (variant == "hospitality_only") {
    protect <- setdiff(CITY_SECTORS, intersect(c("S52","S53"), CITY_SECTORS))
  }

  # Restore only the direct energy-supplier coefficients in protected columns.
  # All non-energy technical coefficients and all other Engine-2 blocks remain
  # exactly as in the current specification.
  if (length(protect) > 0 && length(ENERGY_ROWS) > 0) {
    Astar[ENERGY_ROWS, protect] <- A[ENERGY_ROWS, protect, drop=FALSE]
  }
  Astar
}

# Hard-constraint solver consistent with paper/constraint_audit.R.
hard_constraint_solution <- function(Astar, df_total, dx_target) {
  Lstar <- solve(diag(nrow(Astar)) - Astar)
  dx_u <- as.vector(Lstar %*% df_total); names(dx_u) <- rownames(Astar)
  C <- intersect(ENGINE3_SECTORS, names(dx_u))
  if (length(C) == 0) return(dx_u)
  target_C <- dx_target[C]
  LCC <- Lstar[C, C, drop=FALSE]
  gC <- solve(LCC, target_C - dx_u[C])
  dx_h <- dx_u + as.vector(Lstar[, C, drop=FALSE] %*% gC)
  names(dx_h) <- rownames(Astar)
  dx_h
}

# All-sector GDP baseline for paper counterfactual.
engine1_gdp_all <- function(ano) {
  g <- gdp_rel_2018[as.character(ano)]
  f_base * (g - 1)
}

# VA coefficients.
va_coef <- as.numeric(VA / pmax(x, 1e-12)); names(va_coef) <- names(x)

variants <- c("current","no_real_estate","hospitality_only")
rows <- list(); k <- 1
sector_rows <- list(); ks <- 1

for (ano in ANOS_MMA) {
  cen <- "100D"

  df_gdp <- engine1_gdp_all(ano)
  df_inv <- engine1_inv(cen, ano)
  df_total <- df_gdp + df_inv
  dx_target <- engine3_delta_x(cen, ano)

  # GDP-only reference is common to all variants.
  L0 <- solve(diag(nrow(A)) - A)
  dx_base <- as.vector(L0 %*% df_gdp); names(dx_base) <- rownames(A)
  out_base <- sum(dx_base)
  va_base <- sum(va_coef * dx_base)

  for (v in variants) {
    Av <- engine2_cities_variant(cen, ano, v)
    Lv <- solve(diag(nrow(Av)) - Av)
    dx_u <- as.vector(Lv %*% df_total); names(dx_u) <- rownames(Av)
    dx_h <- hard_constraint_solution(Av, df_total, dx_target)

    rows[[k]] <- data.frame(
      year=as.integer(ano), variant=v,
      unconstrained_output_diff_Rbn=(sum(dx_u)-out_base)/1000,
      unconstrained_va_diff_Rbn=(sum(va_coef*dx_u)-va_base)/1000,
      hard_output_diff_Rbn=(sum(dx_h)-out_base)/1000,
      hard_va_diff_Rbn=(sum(va_coef*dx_h)-va_base)/1000,
      stringsAsFactors=FALSE
    ); k <- k + 1

    for (j in CITY_SECTORS) {
      sector_rows[[ks]] <- data.frame(
        year=as.integer(ano), variant=v, sector=j,
        sector_name=sector_label(j),
        unconstrained_output_change_Rbn=scalar_named(dx_u, j)/1000,
        hard_output_change_Rbn=scalar_named(dx_h, j)/1000,
        stringsAsFactors=FALSE
      ); ks <- ks + 1
    }
  }
}

agg <- do.call(rbind, rows)
sec <- do.call(rbind, sector_rows)
write.csv(agg, "paper/results/engine2_cities_sensitivity_aggregate.csv", row.names=FALSE)
write.csv(sec, "paper/results/engine2_cities_sensitivity_sectors.csv", row.names=FALSE)

# Differences relative to current specification.
cur <- agg[agg$variant=="current",]
diffs <- merge(agg, cur[,c("year","unconstrained_output_diff_Rbn","unconstrained_va_diff_Rbn","hard_output_diff_Rbn","hard_va_diff_Rbn")], by="year", suffixes=c("","_current"))
diffs$delta_unconstrained_output_Rbn <- diffs$unconstrained_output_diff_Rbn - diffs$unconstrained_output_diff_Rbn_current
diffs$delta_unconstrained_va_Rbn <- diffs$unconstrained_va_diff_Rbn - diffs$unconstrained_va_diff_Rbn_current
diffs$delta_hard_output_Rbn <- diffs$hard_output_diff_Rbn - diffs$hard_output_diff_Rbn_current
diffs$delta_hard_va_Rbn <- diffs$hard_va_diff_Rbn - diffs$hard_va_diff_Rbn_current
write.csv(diffs, "paper/results/engine2_cities_sensitivity_differences.csv", row.names=FALSE)

r2050 <- diffs[diffs$year==2050,]
get2050 <- function(variant, field) {
  z <- r2050[r2050$variant == variant, field]
  if (length(z) == 0) NA_real_ else as.numeric(z[[1]])
}
fmt <- function(x) {
  if (length(x) == 0 || is.na(x)) return("NA")
  format(round(x,3), nsmall=3, trim=TRUE)
}
md <- c(
  "# Engine 2 cities/buildings sensitivity",
  "",
  "The current Engine 2 applies one common MMA cities/buildings energy-mix trajectory to S52, S53, S59 and S66-S70. This audit tests the importance of that broad proxy mapping without changing any other model component.",
  "",
  "## Baseline direct energy coefficients",
  "",
  paste0("The 2018 city-proxy sectors span total direct modeled energy coefficients from **", fmt(min(city_structure$total_energy_coef)), "** to **", fmt(max(city_structure$total_energy_coef)), "** per unit of gross output."),
  "",
  "## 2050 sensitivity relative to current specification",
  "",
  paste0("- Excluding S59 (real estate) from direct cities rewiring: unconstrained VA **", fmt(get2050("no_real_estate", "delta_unconstrained_va_Rbn")), " R$bn**; hard-constrained VA **", fmt(get2050("no_real_estate", "delta_hard_va_Rbn")), " R$bn**."),
  paste0("- Extreme hospitality-only stress test (only S52/S53 rewired): unconstrained VA **", fmt(get2050("hospitality_only", "delta_unconstrained_va_Rbn")), " R$bn**; hard-constrained VA **", fmt(get2050("hospitality_only", "delta_hard_va_Rbn")), " R$bn**."),
  "",
  "The hospitality-only case is deliberately conservative and should be interpreted as a bound on the cities/buildings mapping assumption, not as a preferred scenario.",
  "",
  "## Files",
  "",
  "- `engine2_cities_baseline_structure.csv`",
  "- `engine2_cities_sensitivity_aggregate.csv`",
  "- `engine2_cities_sensitivity_differences.csv`",
  "- `engine2_cities_sensitivity_sectors.csv`"
)
writeLines(md, "paper/results/engine2_cities_sensitivity.md")

cat("Engine 2 cities/buildings sensitivity complete.\n")
