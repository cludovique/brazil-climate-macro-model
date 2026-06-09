# Diagnostic: Q1 (0.97 factor) + Q2 (Engine 3 double-counting)
setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
pkgs <- c("readxl","dplyr")
for (p in pkgs) suppressPackageStartupMessages(library(p, character.only=TRUE))

MMA_PATH <- "data/raw/Planilha_Detalhamento Resultados MMA-SMC v3 AR5 (07_10_2024).xlsx"
all_sheets <- excel_sheets(MMA_PATH)
read_mma <- function(idx) suppressMessages(read_excel(MMA_PATH, sheet=all_sheets[idx], col_names=FALSE))

# ── Q1: What is gdp_idx? ──────────────────────────────────────────────────────
cat("=== Q1: Pop/PIB sheet raw data ===\n")
pp <- read_mma(9)
cat("Sheet name:", all_sheets[9], "\n")
cat("Sheet dims:", nrow(pp), "x", ncol(pp), "\n")
cat("\nAll rows/cols (sheet is small):\n")
print(as.data.frame(pp))

cat("\nRow 3 full (pop_mil candidates):\n")
print(as.numeric(unlist(pp[3,])))
cat("\nRow 4 full (gdp_idx candidates):\n")
print(as.numeric(unlist(pp[4,])))

# The gdp_idx values used:
ANOS_STR <- c("2025","2030","2035","2040","2045","2050")
gdp_idx  <- setNames(suppressWarnings(as.numeric(unlist(pp[4, 4:9]))), ANOS_STR)
cat("\ngdp_idx read by code (pp[4, 4:9]):\n")
print(gdp_idx)

# Check if there is a 2020 value (col 3):
gdp_2020_val <- suppressWarnings(as.numeric(pp[[4, 3]]))
cat("\nValue at col 3 (expected 2020 base):", gdp_2020_val, "\n")

# If gdp_idx is an index relative to 2020, what is the implied 2018 base?
cat("\n--- GDP ratio interpretation ---\n")
cat("gdp_2018_factor used in code: 0.97\n")
cat("Meaning: GDP_2020 = 0.97 × GDP_2018 (2020 was ~3% BELOW 2018)\n")
cat("IBGE real GDP growth: 2018→2019: +1.1%, 2019→2020: -3.9%\n")
cat("Implied: GDP_2020/GDP_2018 =", round(1.011 * (1-0.039), 4), "\n")
cat("Alternative IBGE figures (various vintages):\n")
cat("  If 2019: +1.4%, 2020: -3.3%:  GDP_2020/GDP_2018 =", round(1.014 * (1-0.033), 4), "\n")
cat("  If 2019: +1.1%, 2020: -4.1%:  GDP_2020/GDP_2018 =", round(1.011 * (1-0.041), 4), "\n")

# gdp_rel_2018 values:
gdp_rel_2018 <- gdp_idx * 0.97
cat("\ngdp_rel_2018 = gdp_idx × 0.97 (growth factor relative to 2018 base):\n")
print(round(gdp_rel_2018, 4))
cat("Implied GDP scaling (delta_f / f_base = g - 1):\n")
print(round(gdp_rel_2018 - 1, 4))

# ── Q2: Engine 3 sectors vs ENGINE3_SECTORS ───────────────────────────────────
cat("\n\n=== Q2: Engine 3 sectors ===\n")

SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
N_sectors <- N

cat("ENGINE3_SECTORS (excluded from Engine 1a GDP scaling):\n")
ENGINE3_SECTORS <- c("S05","S19","S40","S42")
print(ENGINE3_SECTORS)

cat("\nSectors that Engine 3 ALSO calibrates (NOT in ENGINE3_SECTORS → double-counted):\n")
e3_all <- c("S05","S19","S40","S42",  # <-- in ENGINE3_SECTORS, correct
            "S22","S20","S43",          # biofuels: NOT excluded from E1a
            "S29","S28",                # steel/cement: NOT excluded from E1a
            "S01")                      # agriculture (partial): NOT excluded from E1a
double_counted <- setdiff(e3_all, ENGINE3_SECTORS)
cat(double_counted, "\n")

# Quantify the scale of double-counting
cat("\n--- GDP-scaling shock on double-counted sectors (100D, 2050) ---\n")
ANOS_STR <- c("2025","2030","2035","2040","2045","2050")
gdp_2018_factor <- 0.97
gdp_idx_vals <- setNames(suppressWarnings(as.numeric(unlist(pp[4, 4:9]))), ANOS_STR)
gdp_rel_2018 <- gdp_idx_vals * gdp_2018_factor
g_2050 <- gdp_rel_2018["2050"]
cat(sprintf("g_2050 = %.4f  → GDP-scaling delta_f multiplier: (g-1) = %.4f\n", g_2050, g_2050-1))

f_base <- rowSums(as.data.frame(DF))
# Simpler: use full row sums
DF_df <- as.data.frame(DF)
colnames(DF_df) <- c("Exportacoes","Gov","ISFLSF","Familias","FBCF","Var_Estoque")
DF_df$cod <- setores$cod
f_base_vec <- rowSums(DF_df[,1:6])
names(f_base_vec) <- setores$cod

cat("\nEngine 1a GDP shock on double-counted sectors (R$ milhões, 2050):\n")
for (s in double_counted) {
  if (s %in% names(f_base_vec)) {
    shock <- f_base_vec[s] * (g_2050 - 1)
    cat(sprintf("  %s: f_base = %8.0f  → delta_f_gdp_2050 = %8.0f R$M\n",
                s, f_base_vec[s], shock))
  }
}

cat("\nTotal GDP shock on double-counted sectors vs Engine 3 sectors:\n")
e3_shock_total <- sum(sapply(ENGINE3_SECTORS, function(s) {
  if (s %in% names(f_base_vec)) f_base_vec[s] * (g_2050 - 1) else 0
}), na.rm=TRUE)
dc_shock_total <- sum(sapply(double_counted, function(s) {
  if (s %in% names(f_base_vec)) f_base_vec[s] * (g_2050 - 1) else 0
}), na.rm=TRUE)
total_shock <- sum(f_base_vec, na.rm=TRUE) * (g_2050 - 1)
cat(sprintf("  Correctly excluded (ENGINE3_SECTORS): R$ %8.0f M  (%4.1f%% of total)\n",
            e3_shock_total, 100*e3_shock_total/total_shock))
cat(sprintf("  Double-counted (should be excluded):  R$ %8.0f M  (%4.1f%% of total)\n",
            dc_shock_total, 100*dc_shock_total/total_shock))
cat(sprintf("  All sectors total:                    R$ %8.0f M\n", total_shock))
