# =============================================================================
# ERL PAPER — ENGINE 2 SECTOR-MAPPING AUDIT
# =============================================================================
# Purpose:
#   Verify the sector mapping used by Engine 2 after the S51/S52 correction.
#   The audit checks block membership, overlaps, baseline energy coefficients,
#   and the actual 100D-2050 coefficient changes for S48/S51/S52.
# =============================================================================

options(scipen = 12, OutDec = ".")
repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = getwd())
setwd(repo_root)
outdir <- file.path("paper", "results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

source("paper/load_paper_model.R")

energy_coeffs <- function(M, j) {
  c(
    elec = sum(M[intersect(c("S40","S41"), rownames(M)), j], na.rm = TRUE),
    bio  = sum(M[intersect(c("S20","S22"), rownames(M)), j], na.rm = TRUE),
    foss = sum(M[intersect(c("S19","S43"), rownames(M)), j], na.rm = TRUE)
  )
}

blocks <- list(
  steel = GRUPOS$ind_aco,
  cement = GRUPOS$ind_cimento,
  chemicals = GRUPOS$ind_quimico,
  other_industry = GRUPOS$ind_outros,
  road_transport = intersect(c("S48","S51"), setores$cod),
  maritime = intersect("S49", setores$cod),
  aviation = intersect("S50", setores$cod),
  cities_buildings = GRUPOS$cidades
)

rows <- list()
for (b in names(blocks)) {
  for (j in blocks[[b]]) {
    a0 <- energy_coeffs(A, j)
    rows[[length(rows)+1]] <- data.frame(
      block = b,
      sector = j,
      sector_name = setores$nome[match(j, setores$cod)],
      a_electricity = a0["elec"],
      a_bio = a0["bio"],
      a_fossil = a0["foss"],
      a_energy_total = sum(a0),
      share_electricity_in_energy_coef = ifelse(sum(a0)>0, a0["elec"]/sum(a0), NA),
      share_bio_in_energy_coef = ifelse(sum(a0)>0, a0["bio"]/sum(a0), NA),
      share_fossil_in_energy_coef = ifelse(sum(a0)>0, a0["foss"]/sum(a0), NA),
      stringsAsFactors = FALSE
    )
  }
}
map_df <- do.call(rbind, rows)
write.csv(map_df, file.path(outdir, "engine2_sector_mapping.csv"), row.names = FALSE)

# Check overlaps among normalized blocks. Maritime/aviation are separate indicator
# blocks, so the key requirement is no accidental overlap among the broad rebalance blocks.
normalized_names <- c("steel","cement","chemicals","other_industry","road_transport","cities_buildings")
normalized_pairs <- combn(normalized_names, 2, simplify = FALSE)
overlap_rows <- lapply(normalized_pairs, function(p) {
  ov <- intersect(blocks[[p[1]]], blocks[[p[2]]])
  data.frame(block_1=p[1], block_2=p[2], overlap=paste(ov, collapse=";"), n_overlap=length(ov), stringsAsFactors=FALSE)
})
overlap_df <- do.call(rbind, overlap_rows)
write.csv(overlap_df, file.path(outdir, "engine2_block_overlaps.csv"), row.names = FALSE)

# Direct verification of the corrected S51/S52 mapping using 100D 2050.
A2050 <- engine2_A_star("100D", 2050)
check_sectors <- intersect(c("S48","S51","S52"), colnames(A))
check_rows <- list()
for (j in check_sectors) {
  b <- energy_coeffs(A, j)
  n <- energy_coeffs(A2050, j)
  check_rows[[length(check_rows)+1]] <- data.frame(
    sector=j,
    sector_name=setores$nome[match(j,setores$cod)],
    base_elec=b["elec"], base_bio=b["bio"], base_foss=b["foss"], base_total=sum(b),
    y2050_elec=n["elec"], y2050_bio=n["bio"], y2050_foss=n["foss"], y2050_total=sum(n),
    delta_elec=n["elec"]-b["elec"], delta_bio=n["bio"]-b["bio"], delta_foss=n["foss"]-b["foss"],
    stringsAsFactors=FALSE
  )
}
check_df <- do.call(rbind, check_rows)
write.csv(check_df, file.path(outdir, "engine2_S48_S51_S52_check.csv"), row.names = FALSE)

fmt <- function(x,d=5) format(round(x,d), scientific=FALSE, trim=TRUE)
getrow <- function(s) check_df[check_df$sector==s,,drop=FALSE]
r48 <- getrow("S48"); r51 <- getrow("S51"); r52 <- getrow("S52")
max_overlap <- max(overlap_df$n_overlap, na.rm=TRUE)

report <- c(
  "# Engine 2 sector-mapping audit",
  "",
  "## S51/S52 correction",
  "",
  "The paper model now applies the aggregate road-transport fuel-mix pathway to **S48 (Transporte terrestre)** and **S51 (Armazenamento e correio)**. **S52 (Alojamento)** is excluded from the transport block and remains in the cities/buildings block.",
  "",
  sprintf("- Maximum overlap among the broad normalized Engine-2 blocks: **%d sector(s)**.", max_overlap),
  "",
  "## 100D 2050 verification",
  "",
  sprintf("- S48 total modeled energy coefficient: %s in the base matrix and %s after Engine 2.", fmt(r48$base_total), fmt(r48$y2050_total)),
  sprintf("- S51 total modeled energy coefficient: %s in the base matrix and %s after Engine 2.", fmt(r51$base_total), fmt(r51$y2050_total)),
  sprintf("- S52 total modeled energy coefficient: %s in the base matrix and %s after the cities/buildings calibration.", fmt(r52$base_total), fmt(r52$y2050_total)),
  "",
  "Because the normalized rebalance closure preserves each column's total modeled energy coefficient, the diagnostic should mainly show a redistribution among electricity, bioenergy and fossil suppliers for S48, S51 and S52.",
  "",
  "## Interpretation for the next audit",
  "",
  "The coding error S52↔S51 is resolved for the paper workflow. The remaining question is substantive rather than syntactic: whether **S51 (storage and postal services)** should inherit the same aggregate road-transport physical fuel shares as S48. Since S51 combines warehousing and postal activities, this should be treated as a proxy assumption and tested against its baseline energy structure before publication.",
  "",
  "The largest broader Engine-2 aggregation assumption is `other_industry`: many heterogeneous manufacturing sectors inherit one common MMA 'other industry' energy-mix trajectory. This is not necessarily wrong given the available scenario data, but it should be documented and, if material, tested as a sensitivity.",
  "",
  "## Files",
  "",
  "- `engine2_sector_mapping.csv`",
  "- `engine2_block_overlaps.csv`",
  "- `engine2_S48_S51_S52_check.csv`"
)
writeLines(report, file.path(outdir, "engine2_mapping_audit.md"), useBytes=TRUE)
cat("Engine 2 mapping audit complete.\n")
