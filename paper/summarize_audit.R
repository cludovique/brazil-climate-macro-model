# =============================================================================
# ERL PAPER — SUMMARIZE MODEL AUDIT FOR INTERPRETATION
# =============================================================================
# Reads the generated diagnostic CSVs and produces group-level and sector-level
# summaries that explain *why* the transition differential emerges.
# =============================================================================

options(scipen = 12, OutDec = ".")

repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = "")
if (!nzchar(repo_root)) {
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

sector <- read.csv(file.path(outdir, "sector_mechanism_va.csv"), check.names = FALSE)
shapley <- read.csv(file.path(outdir, "mechanism_shapley.csv"), check.names = FALSE)
baseline <- read.csv(file.path(outdir, "baseline_audit.csv"), check.names = FALSE)
domestic <- read.csv(file.path(outdir, "domestic_content_diagnostic.csv"), check.names = FALSE)

sector_id <- function(cod) suppressWarnings(as.integer(sub("^S", "", cod)))

grp7 <- function(cod) {
  id <- sector_id(cod)
  if (cod %in% c("S01", "S02", "S03")) return("Agriculture")
  if (cod %in% c("S04", "S06", "S07")) return("Extractive industry")
  if (cod %in% c("S05", "S19", "S21", "S43")) return("Fossil energy")
  if (cod %in% c("S20", "S22", "S40", "S41", "S42")) return("Renewable energy")
  if (!is.na(id) && (id %in% c(8:18, 23:39))) return("Manufacturing")
  if (cod %in% c("S44", "S45", "S48", "S49", "S50", "S51")) return("Infrastructure")
  if (!is.na(id) && (id %in% c(46, 47, 52:73))) return("Services")
  return("Other")
}

sector$group7 <- vapply(sector$cod, grp7, character(1))

group_summary <- aggregate(
  va_shapley_Rbn ~ year + mechanism + group7,
  data = sector,
  FUN = sum,
  na.rm = TRUE
)
write.csv(group_summary, file.path(outdir, "mechanism_group_va.csv"), row.names = FALSE)

# 2050 top positive and negative sectors for each mechanism.
s2050 <- subset(sector, year == 2050)
top_rows <- list()
for (m in unique(s2050$mechanism)) {
  d <- subset(s2050, mechanism == m)
  pos <- d[order(-d$va_shapley_Rbn), ][seq_len(min(10, nrow(d))), ]
  neg <- d[order(d$va_shapley_Rbn), ][seq_len(min(10, nrow(d))), ]
  pos$direction <- "positive"
  neg$direction <- "negative"
  pos$rank <- seq_len(nrow(pos))
  neg$rank <- seq_len(nrow(neg))
  top_rows[[paste0(m, "_pos")]] <- pos
  top_rows[[paste0(m, "_neg")]] <- neg
}
top_sector <- do.call(rbind, top_rows)
top_sector <- top_sector[, c("mechanism", "direction", "rank", "cod", "sector", "group7", "va_shapley_Rbn")]
write.csv(top_sector, file.path(outdir, "mechanism_top_sectors_2050.csv"), row.names = FALSE)

# Group-level 2050 ranking.
g2050 <- subset(group_summary, year == 2050)
g2050 <- g2050[order(g2050$mechanism, -g2050$va_shapley_Rbn), ]
write.csv(g2050, file.path(outdir, "mechanism_groups_2050.csv"), row.names = FALSE)

# Time profile of value-added mechanism contributions.
va_time <- subset(shapley, metric == "value_added")
va_time <- va_time[, c("year", "mechanism", "shapley_contribution", "total_transition_differential", "share_of_total")]
write.csv(va_time, file.path(outdir, "mechanism_va_time_profile.csv"), row.names = FALSE)

# Build a compact markdown interpretation table, leaving scientific prose to the manuscript.
fmt <- function(x) format(round(x, 1), big.mark = ",", scientific = FALSE, trim = TRUE)

lines <- c(
  "# Mechanism Story — diagnostic tables",
  "",
  "## Value-added decomposition over time (R$ bn, 2018 prices)",
  "",
  "| Year | Investment | Rewiring | Physical calibration | Net differential |",
  "|---:|---:|---:|---:|---:|"
)
for (yr in sort(unique(va_time$year))) {
  d <- subset(va_time, year == yr)
  gi <- function(m) d$shapley_contribution[d$mechanism == m][1]
  total <- unique(d$total_transition_differential)[1]
  lines <- c(lines, sprintf("| %d | %s | %s | %s | %s |",
                            yr, fmt(gi("investment")), fmt(gi("rewiring")),
                            fmt(gi("physical")), fmt(total)))
}

lines <- c(lines,
  "",
  "## 2050 value-added contribution by broad production-network group",
  ""
)
for (m in c("investment", "rewiring", "physical")) {
  lines <- c(lines, paste0("### ", m), "", "| Group | R$ bn |", "|---|---:|")
  d <- subset(g2050, mechanism == m)
  d <- d[order(-d$va_shapley_Rbn), ]
  for (i in seq_len(nrow(d))) {
    lines <- c(lines, sprintf("| %s | %s |", d$group7[i], fmt(d$va_shapley_Rbn[i])))
  }
  lines <- c(lines, "")
}

lines <- c(lines,
  "## 2050 leading individual sectors by mechanism",
  ""
)
for (m in c("investment", "rewiring", "physical")) {
  lines <- c(lines, paste0("### ", m), "", "**Largest positive contributions**", "")
  d <- subset(top_sector, mechanism == m & direction == "positive" & rank <= 6)
  for (i in seq_len(nrow(d))) {
    lines <- c(lines, sprintf("- %s — %s: R$ %s bn", d$cod[i], d$sector[i], fmt(d$va_shapley_Rbn[i])))
  }
  lines <- c(lines, "", "**Largest negative contributions**", "")
  d <- subset(top_sector, mechanism == m & direction == "negative" & rank <= 6)
  for (i in seq_len(nrow(d))) {
    lines <- c(lines, sprintf("- %s — %s: R$ %s bn", d$cod[i], d$sector[i], fmt(d$va_shapley_Rbn[i])))
  }
  lines <- c(lines, "")
}

lines <- c(lines,
  "## Baseline and domestic-content diagnostics",
  "",
  sprintf("- Current-model 2050 VA differential: R$ %s bn.", fmt(baseline$audit_current_va_Rbn[baseline$year == 2050])),
  sprintf("- All-sector-GDP baseline 2050 VA differential: R$ %s bn.", fmt(baseline$allGDP_va_Rbn[baseline$year == 2050])),
  sprintf("- Current domestic-content 2050 VA differential: R$ %s bn.", fmt(domestic$va_premium_observed_Rbn[domestic$year == 2050])),
  sprintf("- 100%% domestic-investment upper bound: R$ %s bn.", fmt(domestic$va_premium_full_domestic_Rbn[domestic$year == 2050])),
  "",
  "These tables are diagnostics. Mechanism labels refer to Shapley contributions, so interaction effects are allocated across mechanisms rather than reported as a residual."
)

writeLines(lines, file.path(outdir, "mechanism_story.md"), useBytes = TRUE)
cat("Mechanism summaries written to", outdir, "\n")
