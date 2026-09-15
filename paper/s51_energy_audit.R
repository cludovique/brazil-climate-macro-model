# =============================================================================
# ERL PAPER — S51 ENERGY-USE AUDIT
# =============================================================================
# Question: should S51 (Armazenamento e correio) inherit the aggregate transport
# energy-mix trajectory, or is most transport-energy demand already represented
# in S48 (Transporte terrestre)?
#
# Evidence used:
#   1) 2018 monetary technical coefficients A for petroleum/gas/electricity/bio;
#   2) EPE physical energy satellite coefficients ALPHA (ktep per R$ million);
#   3) comparison with S48 and S52.
# =============================================================================

options(scipen = 12, OutDec = ".")
repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = getwd())
setwd(repo_root)
source("paper/load_paper_model.R")

outdir <- file.path("paper", "results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

sectors_check <- intersect(c("S48", "S51", "S52"), setores$cod)

safe_sum_A <- function(rows, j) sum(A[intersect(rows, rownames(A)), j], na.rm = TRUE)

# Monetary energy inputs embedded in the IO technical coefficients.
mon_rows <- lapply(sectors_check, function(j) {
  petroleum <- safe_sum_A(c("S19"), j)
  gas <- safe_sum_A(c("S43"), j)
  electricity <- safe_sum_A(c("S40", "S41"), j)
  bio <- safe_sum_A(c("S20", "S22"), j)
  total_energy <- petroleum + gas + electricity + bio
  data.frame(
    sector = j,
    sector_name = setores$nome[match(j, setores$cod)],
    petroleum_coef = petroleum,
    gas_coef = gas,
    fossil_coef = petroleum + gas,
    electricity_coef = electricity,
    bio_coef = bio,
    total_energy_coef = total_energy,
    petroleum_share_energy_spend = ifelse(total_energy > 0, petroleum / total_energy, NA),
    fossil_share_energy_spend = ifelse(total_energy > 0, (petroleum + gas) / total_energy, NA),
    electricity_share_energy_spend = ifelse(total_energy > 0, electricity / total_energy, NA),
    bio_share_energy_spend = ifelse(total_energy > 0, bio / total_energy, NA),
    stringsAsFactors = FALSE
  )
})
mon <- do.call(rbind, mon_rows)

# Physical energy satellite coefficients (ktep / R$ million output).
# The loaded EPE account uses these source names in the model.
phys_sources <- intersect(c("Derivados", "Gas_Natural", "Biodiesel", "Etanol",
                            "EE_Central", "EE_Distrib"), rownames(ALPHA))
phys_rows <- lapply(sectors_check, function(j) {
  vals <- setNames(rep(0, 6), c("Derivados", "Gas_Natural", "Biodiesel", "Etanol", "EE_Central", "EE_Distrib"))
  present <- intersect(names(vals), rownames(ALPHA))
  vals[present] <- ALPHA[present, j]
  petroleum <- vals["Derivados"]
  gas <- vals["Gas_Natural"]
  electricity <- vals["EE_Central"] + vals["EE_Distrib"]
  bio <- vals["Biodiesel"] + vals["Etanol"]
  total <- petroleum + gas + electricity + bio
  data.frame(
    sector = j,
    physical_petroleum_ktep_per_Rm = petroleum,
    physical_gas_ktep_per_Rm = gas,
    physical_fossil_ktep_per_Rm = petroleum + gas,
    physical_electricity_ktep_per_Rm = electricity,
    physical_bio_ktep_per_Rm = bio,
    physical_total_energy_ktep_per_Rm = total,
    physical_petroleum_share = ifelse(total > 0, petroleum / total, NA),
    physical_fossil_share = ifelse(total > 0, (petroleum + gas) / total, NA),
    physical_electricity_share = ifelse(total > 0, electricity / total, NA),
    physical_bio_share = ifelse(total > 0, bio / total, NA),
    stringsAsFactors = FALSE
  )
})
phys <- do.call(rbind, phys_rows)

res <- merge(mon, phys, by = "sector", all.x = TRUE)
# Restore intuitive order.
res <- res[match(sectors_check, res$sector), ]

# Relative intensity to S48, useful for deciding whether S51 is genuinely
# transport-energy intensive or mainly a service/logistics sector.
base48_mon <- res$total_energy_coef[res$sector == "S48"]
base48_phys <- res$physical_total_energy_ktep_per_Rm[res$sector == "S48"]
res$total_energy_coef_relative_to_S48 <- res$total_energy_coef / base48_mon
res$physical_energy_intensity_relative_to_S48 <- res$physical_total_energy_ktep_per_Rm / base48_phys

write.csv(res, file.path(outdir, "s51_energy_audit.csv"), row.names = FALSE)

fmt_pct <- function(x) ifelse(is.finite(x), sprintf("%.1f%%", 100*x), "NA")
fmt_num <- function(x, d=5) ifelse(is.finite(x), format(round(x,d), scientific=FALSE, trim=TRUE), "NA")
get <- function(s, v) res[res$sector == s, v][[1]]

report <- c(
  "# S51 energy-use audit",
  "",
  "This diagnostic compares S51 (Armazenamento e correio) with S48 (Transporte terrestre) and S52 (Alojamento) using the 2018 IO technical coefficients and the EPE physical-energy satellite account.",
  "",
  "## Monetary IO energy coefficients",
  "",
  sprintf("- S48 total energy coefficient: **%s**; petroleum: **%s**; electricity: **%s**.", fmt_num(get("S48","total_energy_coef")), fmt_num(get("S48","petroleum_coef")), fmt_num(get("S48","electricity_coef"))),
  sprintf("- S51 total energy coefficient: **%s**; petroleum: **%s**; electricity: **%s**.", fmt_num(get("S51","total_energy_coef")), fmt_num(get("S51","petroleum_coef")), fmt_num(get("S51","electricity_coef"))),
  sprintf("- S51 monetary energy intensity is **%.1f%% of S48**.", 100*get("S51","total_energy_coef_relative_to_S48")),
  "",
  "## Physical EPE energy satellite",
  "",
  sprintf("- S48 physical total-energy intensity: **%s ktep/R$M**, with petroleum/fossil share **%s** and electricity share **%s**.", fmt_num(get("S48","physical_total_energy_ktep_per_Rm"),8), fmt_pct(get("S48","physical_fossil_share")), fmt_pct(get("S48","physical_electricity_share"))),
  sprintf("- S51 physical total-energy intensity: **%s ktep/R$M**, with petroleum/fossil share **%s** and electricity share **%s**.", fmt_num(get("S51","physical_total_energy_ktep_per_Rm"),8), fmt_pct(get("S51","physical_fossil_share")), fmt_pct(get("S51","physical_electricity_share"))),
  sprintf("- S51 physical energy intensity is **%.1f%% of S48**.", 100*get("S51","physical_energy_intensity_relative_to_S48")),
  "",
  "## Interpretation rule",
  "",
  "If S51 has substantial direct fossil/electric energy intensity relative to S48, applying the transport fuel-mix trajectory can be defended as a broad logistics-sector proxy. If its direct energy intensity is small, then applying the full S48 transport transition to S51 likely overstates direct fuel substitution: transport services purchased by S51 are already represented through intermediate purchases from S48 and therefore propagate through the Leontief network without rewriting S51's own energy coefficients.",
  "",
  "See `s51_energy_audit.csv` for the full monetary and physical coefficient comparison."
)
writeLines(report, file.path(outdir, "s51_energy_audit.md"), useBytes = TRUE)
cat("S51 energy-use audit complete.\n")
