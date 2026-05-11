# =============================================================================
# MIP-EPE ENERGY 2018 — REPLICATION EXERCISE
# NT EPE/DEA/SEE/013/2023, Section 6.1
#
# Exercise: +5% increase in total exports
# Target results (NT published):
#   - Delta GDP:        R$ 38.5 billion  (+0.64%)
#   - Delta Employment: 258 thousand jobs (+0.25%)
#   - Delta Energy:     1,768 ktep       (+1.10%)
#   - By energy source: Derivatives=1025, Biodiesel=46, Ethanol=145,
#                       EE_Central=318, EE_Distrib=46, Gas=188 ktep
#
# Data sources:
#   ANX2: MIP-EPE Anexo 2 — 73-sector IO table (EPE/FIPE, 2023)
#          Sheets used: Lista PS, Usos SxS, Leontief
#
# Key insight: ALL indicator rows (energy tep, labor, VA) are already
# in the Usos SxS sheet below the 73 sector rows. No external data
# needed — everything is self-contained in Anexo 2.
#
# Row positions in Usos SxS (1-based, as seen in R):
#   Rows  5..77  : Z matrix (73x73 intermediate consumption)
#   Cols  4..76  : sector columns S01..S73
#   Cols 78..83  : final demand (Export, Gov, ISFLSF, Families, GFCF, ΔStock)
#   Row  78      : Prod Nacional
#   Row  79      : Importado
#   Row  88      : Remunerações (R10)
#   Row  89      : Salários (R11)
#   Row 100      : Valor Adicionado Bruto / PIB (N1)
#   Row 101      : Valor Bruto da Produção (P10)
#   Row 103      : Ocupações (workers)
#   Rows 115-123 : Labor breakdown (informal, formal, PPI, branca,
#                  homem, mulher, baixo_med, superior)
#   Row 125      : tep Derivados de petróleo
#   Row 126      : tep Biodiesel
#   Row 127      : tep Etanol
#   Row 128      : tep Eletricidade centralizada
#   Row 129      : tep Eletricidade distribuída
#   Row 130      : tep Gás Natural

# =============================================================================
# 0. PACKAGES
# =============================================================================

pkgs <- c("readxl", "dplyr", "tidyr", "writexl")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}
options(scipen = 10, OutDec = ".")

vis_pkgs <- c("ggplot2", "dplyr", "tidyr", "scales",
              "ggrepel", "patchwork", "forcats")
for (p in vis_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}

# =============================================================================
# 1. FILE PATH
# =============================================================================

ANX2 <- "48008000008202670_Camila_Anexo 2.xlsx"

# Auto-search if not found in working directory
if (!file.exists(ANX2)) {
  cands <- list.files(pattern = "Anexo.?2\\.xlsx$", ignore.case = TRUE)
  cands <- cands[!grepl("^~\\$", cands)]
  if (length(cands) == 0) stop("File not found: ", ANX2)
  ANX2 <- cands[1]
  message("Found: ", ANX2)
}


# =============================================================================
# 2. READ SECTOR LIST (S01..S73)
# =============================================================================

# Sector codes and names are in columns L and M of the Lista PS sheet
lista_raw <- read_excel(ANX2, sheet = "Lista PS",
                        col_names = FALSE,
                        range     = cell_cols("A:M"))

setores <- lista_raw |>
  select(cod = 12, nome = 13) |>
  filter(!is.na(cod), grepl("^S", as.character(cod))) |>
  mutate(
    cod  = as.character(cod),
    nome = as.character(nome),
    id   = as.integer(gsub("\\D", "", cod))
  )

N <- nrow(setores)          # should be 73
stopifnot("Expected 73 sectors" = N == 73)
message("Sectors loaded: ", N)


# =============================================================================
# 3. READ USOS SxS — FULL SHEET
# =============================================================================

# Read the entire sheet once so we can extract all row groups
sxs_raw <- read_excel(ANX2, sheet = "Usos SxS", col_names = FALSE)

# Helper: extract a single row as a numeric vector over the 73 sectors
# row_r: 1-based R row number (as seen in Excel)
# col_start_r: first column (default 4 = S01)
get_row_vec <- function(row_r, col_start_r = 4, n = N) {
  vals <- suppressWarnings(
    as.numeric(as.character(unlist(
      sxs_raw[row_r, col_start_r:(col_start_r + n - 1)]
    )))
  )
  vals[is.na(vals)] <- 0
  setNames(vals, setores$cod)
}

# Helper: extract a block of rows as a named matrix (rows = row_labels)
get_row_block <- function(row_r_vec, row_labels) {
  mat <- sapply(row_r_vec, get_row_vec)
  t(mat) |> `rownames<-`(row_labels) |> `colnames<-`(setores$cod)
}


# =============================================================================
# 4. Z MATRIX (73x73 intermediate consumption)
# =============================================================================

# Z occupies rows 5..77 (R), columns 4..76 (R)
Z <- sxs_raw[5:(4 + N), 4:(3 + N)] |>
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) |>
  as.matrix()
dimnames(Z) <- list(setores$cod, setores$cod)


# =============================================================================
# 5. FINAL DEMAND MATRIX (73 x 6)
# =============================================================================

# Columns 78..83 (R) = Export, Gov, ISFLSF, Families, GFCF, ΔStock
DF <- sxs_raw[5:(4 + N), 78:83] |>
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) |>
  as.data.frame()
colnames(DF) <- c("Export", "Gov", "ISFLSF", "Families", "GFCF", "DeltaStock")
rownames(DF) <- setores$cod


# =============================================================================
# 6. OUTPUT VECTOR AND VALUE ADDED
# =============================================================================

x      <- rowSums(Z) + rowSums(DF)          # total output per sector
names(x) <- setores$cod

# Row 100 (R) = VAB/PIB (N1 — Valor Adicionado Bruto)
va_pib <- get_row_vec(100)

# Row 101 (R) = VBP (P10 — Valor Bruto da Produção) — should match x
vbp    <- get_row_vec(101)

# Row 88 (R) = Remunerações (R10)
remuner <- get_row_vec(88)

# Row 89 (R) = Salários (R11)
salarios <- get_row_vec(89)

# Gross operating surplus (Row 96)
eob <- get_row_vec(96)

message(sprintf(
  "x total: R$ %.1f tri | VA/PIB: R$ %.1f tri",
  sum(x) / 1e6, sum(va_pib) / 1e6
))


# =============================================================================
# 7. LEONTIEF INVERSE (L)
# =============================================================================

# Read directly from the Leontief sheet (pre-computed in Anexo 2)
# Data: rows 5..77 (R), columns 4..76 (R)
l_raw <- read_excel(ANX2, sheet = "Leontief",
                    col_names = FALSE,
                    range = "D5:BX77")   # D=col4, BX=col76, rows 5-77

L <- l_raw |>
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) |>
  as.matrix()
dimnames(L) <- list(setores$cod, setores$cod)

# Verify
cat("L[1,1]:", L[1,1], "\n")     # should be ~1.027
cat("L[40,40]:", L[40,40], "\n") # should be ~1.331
cat("mult_S40:", sum(L[,"S40"]), "\n")  # should be ~2.006

# =============================================================================
# 8. EMPLOYMENT COEFFICIENTS (occupations per R$ million of output)
# =============================================================================

ocupacoes <- get_row_vec(102)

EMP_SHOCK_SCALE <- 0.4
coef_emp <- EMP_SHOCK_SCALE * ocupacoes / x_safe

occ <- ocupacoes


# =============================================================================
# 9. LABOR BREAKDOWN COEFFICIENTS
# =============================================================================
labor_rows <- c(
  Informal   = 115, Formal   = 116,
  PPI        = 117, Branca   = 118,
  Homem      = 119, Mulher   = 120,
  Baixo_Med  = 121, Superior = 122
)

labor_share <- sapply(labor_rows, function(r) {
  get_row_vec(r) / ifelse(ocupacoes > 0, ocupacoes, 1)
}) |>
  t() |>
  as.data.frame()

message("Labor breakdown shares computed for ", length(labor_rows), " groups")


# =============================================================================
# 10. ENERGY COEFFICIENTS — ALPHA MATRIX (ktep per R$ million of output)
# =============================================================================
# Source: rows 125..130 of Usos SxS — already calibrated physical flows
# This is the CORRECT source for ALPHA (not Planilha 1/2/3 of Anexo 1)
# These rows give total ktep consumed by each sector in 2018

energy_rows <- c(
  Derivados   = 125,
  Biodiesel   = 126,
  Etanol      = 127,
  EE_Central  = 128,
  EE_Distrib  = 129,
  Gas_Natural = 130
)

# E matrix: (6 sources) x (73 sectors) — physical flows in ktep
E <- sapply(energy_rows, get_row_vec) |> t()
rownames(E) <- names(energy_rows)

# ALPHA: physical flow per R$ million of output
ALPHA <- sweep(E, 2, x_safe, "/")

message(sprintf(
  "ALPHA matrix: %dx%d | tep_deriv_S48=%.4f | tep_eecent_S40=%.4f",
  nrow(ALPHA), ncol(ALPHA),
  ALPHA["Derivados",   "S48"],
  ALPHA["EE_Central",  "S40"]
))


# =============================================================================
# 11. SECTOR GROUPS (for aggregated results)
# =============================================================================

# FLEXIBLE SECTOR GROUPING SYSTEM
# Define grupos here — the rest of the script adapts automatically.
#
# Switch between grouping schemes by changing GROUPING_SCHEME below.
# All charts, aggregations, and comparisons update automatically.
# =============================================================================

# Define energy sectors FIRST — used in all group definitions below
fossil_sectors    <- c("S05", "S19", "S21", "S43")
renewable_sectors <- c("S20", "S22", "S40", "S41", "S42")
energy_sectors    <- c(fossil_sectors, renewable_sectors)

GROUPING_SCHEME <- "nt4"   # Options: "nt4" | "7group" | "ibge"

grupos_nt4 <- list(
  Agropecuaria = c("S01","S02","S03"),
  Industria    = setores$cod[setores$id %in% 4:39 &
                               !setores$cod %in% energy_sectors],
  Servicos     = setores$cod[setores$id %in% 44:73 &
                               !setores$cod %in% energy_sectors],
  Energeticos  = energy_sectors
)

grupo_colors_nt4 <- c(
  Agropecuaria = "#3B6D11",
  Industria    = "#378ADD",
  Servicos     = "#888780",
  Energeticos  = "#1D9E75"
)

grupo_levels_nt4 <- c("Agropecuaria","Industria","Servicos","Energeticos")


# ── 7GROUP: Fossil vs Renewable split — best for NDC paper ───────────────────
# Shows fossil contraction and renewable expansion as separate bars.
# Construction and Transport isolated as key investment recipients.

grupos_7 <- list(
  Agropecuaria   = c("S01","S02","S03"),
  Ind_Extrativa  = c("S04","S06","S07"),
  Energia_Fossil = fossil_sectors,
  Energia_Renov  = renewable_sectors,
  Ind_Transform  = setores$cod[setores$id %in% c(8:18, 23:39)],
  Infraestrutura = c("S44","S45","S48","S49","S50","S51"),
  Servicos       = setores$cod[setores$id %in% c(46,47,52:73)]
)

grupo_colors_7 <- c(
  Agropecuaria   = "#3B6D11",
  Ind_Extrativa  = "#888780",
  Energia_Fossil = "#E24B4A",
  Energia_Renov  = "#1D9E75",
  Ind_Transform  = "#378ADD",
  Infraestrutura = "#534AB7",
  Servicos       = "#B4B2A9"
)

grupo_levels_7 <- c("Agropecuaria","Ind_Extrativa","Energia_Fossil",
                    "Energia_Renov","Ind_Transform","Infraestrutura","Servicos")


# ── IBGE: Official IBGE SCN 2010 macro groups ────────────────────────────────
# Use for papers targeting an IBGE/national accounts audience.

grupos_ibge <- list(
  Agropecuaria     = c("S01","S02","S03"),
  Ind_Extrativa    = c("S04","S05","S06","S07"),
  Ind_Transform    = setores$cod[setores$id %in% 8:39],
  Eletric_Gas      = c("S40","S41","S42","S43"),
  Construcao       = c("S45"),
  Comercio         = c("S46","S47"),
  Transporte       = c("S44","S48","S49","S50","S51"),
  Aloj_Aliment     = c("S52","S53"),
  Info_Comunic     = c("S54","S55","S56","S57"),
  Financeiro       = c("S58"),
  Imobiliario      = c("S59"),
  Serv_Prof        = c("S60","S61","S62"),
  Serv_Admin       = c("S63","S64","S65"),
  Adm_Publica      = c("S66"),
  Educacao         = c("S67","S68"),
  Saude            = c("S69","S70"),
  Outros_Serv      = c("S71","S72","S73")
)

grupo_colors_ibge <- c(
  Agropecuaria  = "#3B6D11", Ind_Extrativa = "#888780",
  Ind_Transform = "#378ADD", Eletric_Gas   = "#1D9E75",
  Construcao    = "#534AB7", Comercio      = "#B4B2A9",
  Transporte    = "#BA7517", Aloj_Aliment  = "#E24B4A",
  Info_Comunic  = "#9333EA", Financeiro    = "#0891B2",
  Imobiliario   = "#D97706", Serv_Prof     = "#15803D",
  Serv_Admin    = "#6B7280", Adm_Publica   = "#1E3A5F",
  Educacao      = "#92400E", Saude         = "#831843",
  Outros_Serv   = "#D1D5DB"
)

grupo_factor_levels <- names(grupos)


# =============================================================================
# APPLY CHOSEN SCHEME
# =============================================================================

if (GROUPING_SCHEME == "nt4") {
  grupos        <- grupos_nt4
  grupo_colors  <- grupo_colors_nt4
  grupo_levels  <- grupo_levels_nt4
  cat("Using NT4 grouping (4 groups — matches NT EPE/FIPE)\n")
  
} else if (GROUPING_SCHEME == "7group") {
  grupos        <- grupos_7
  grupo_colors  <- grupo_colors_7
  grupo_levels  <- grupo_levels_7
  cat("Using 7-group scheme (fossil/renewable split)\n")
  
} else if (GROUPING_SCHEME == "ibge") {
  grupos        <- grupos_ibge
  grupo_colors  <- grupo_colors_ibge
  grupo_levels  <- grupo_levels_ibge
  cat("Using IBGE SCN grouping (17 groups)\n")
  
} else {
  stop("Unknown GROUPING_SCHEME. Choose: 'nt4', '7group', or 'ibge'")
}

# Verify no overlap and complete coverage
total   <- sum(sapply(grupos, length))
overlap <- any(duplicated(unlist(grupos)))
cat(sprintf("  %d sectors | overlap: %s\n", total, overlap))
stopifnot("Sectors do not sum to 73" = total == 73)
stopifnot("Overlapping sectors found" = !overlap)


# =============================================================================
# NT COMPARISON COLLAPSE FUNCTION
# Maps any grouping scheme back to NT4 for validation table
# =============================================================================

collapse_to_nt4 <- function(vec_by_group) {
  # vec_by_group: named vector with values per group (any scheme)
  # Returns named vector with 4 NT groups
  
  # Build a mapping from sector code to NT4 group
  nt4_map <- setNames(
    rep(names(grupos_nt4), sapply(grupos_nt4, length)),
    unlist(grupos_nt4)
  )
  
  # For each sector, get its NT4 group
  # Then get all sector codes in current grupos
  all_sectors <- unlist(grupos)
  nt4_groups  <- nt4_map[all_sectors]
  
  # Get delta_x values for each sector
  # (need to work with raw delta_x, not group aggregates)
  # This function is used inside simulate_shock — see updated version below
  c(
    Agropecuaria = sum(vec_by_group[names(grupos) %in% "Agropecuaria"],  na.rm=TRUE),
    Industria    = sum(vec_by_group[grepl("Ind|Extr", names(vec_by_group))],  na.rm=TRUE),
    Servicos     = sum(vec_by_group[grepl("Serv|Infra|Aloj|Info|Fin|Imob|Adm|Educ|Saude|Outr|Com|Transp",
                                          names(vec_by_group))], na.rm=TRUE),
    Energeticos  = sum(vec_by_group[grepl("Energ|Eletric", names(vec_by_group))], na.rm=TRUE)
  )
}

# =============================================================================
# 12. SIMULATION FUNCTION
# =============================================================================

simulate_shock <- function(delta_f,
                           shock_name = "Shock",
                           print_results = TRUE) 
{
  # 1. Leontief: final demand shock -> sector output
  delta_x <- as.vector(L %*% delta_f)
  names(delta_x) <- setores$cod
  
  # 2. Sector indicators
  delta_va  <- (va_pib  / x_safe) * delta_x
  delta_rem <- (remuner / x_safe) * delta_x
  delta_emp <- coef_emp * delta_x
  
  # 3. Final energy use by source, ktep
  delta_g <- as.vector(ALPHA %*% delta_x)
  names(delta_g) <- rownames(ALPHA)
  
  # 4. Labor breakdown, using baseline shares
  delta_labor <- sapply(rownames(labor_share), function(grp) {
    sum(as.numeric(labor_share[grp, ]) * delta_emp)
  })
  
  # 5. Energy-sector Leontief results: output, GDP, employment
  energy_sector_results <- data.frame(
    cod = energy_sectors,
    nome = setores$nome[match(energy_sectors, setores$cod)],
    delta_output = as.numeric(delta_x[energy_sectors]),
    delta_gdp = as.numeric(delta_va[energy_sectors]),
    delta_emp = as.numeric(delta_emp[energy_sectors]),
    var_output_pct = as.numeric(delta_x[energy_sectors] / x[energy_sectors] * 100),
    stringsAsFactors = FALSE
  )
  
  # 6. Aggregates by chosen sector groups
  agg <- data.frame(
    grupo = names(grupos),
    delta_output = sapply(grupos, function(s) sum(delta_x[s])),
    delta_gdp = sapply(grupos, function(s) sum(delta_va[s])),
    delta_emp = sapply(grupos, function(s) sum(delta_emp[s])),
    delta_energy = sapply(grupos, function(s) sum(ALPHA[, s, drop = FALSE] %*% delta_x[s])),
    stringsAsFactors = FALSE
  )
}

# =============================================================================
# 13. EXERCISE 1 — +5% TOTAL EXPORTS (Section 6.1 of NT)
# =============================================================================

delta_f_ex1 <- DF$Export * 0.05
names(delta_f_ex1) <- setores$cod

res_ex1 <- simulate_shock(delta_f_ex1, "+5% Exports")


# =============================================================================
# 14. EXERCISE 2 — +5% TOTAL EXPORTS (Section 6.1 of NT)
# =============================================================================
# S40 = Geração centralizada de energia elétrica
# Column 3 in DF = Families (0-indexed: Export=0, Gov=1, ISFLSF=2, Families=3)

i_s40 <- which(setores$cod == "S40")

families_s40 <- DF$Families[i_s40]

cat(sprintf("S40 baseline household consumption: R$ %.2f bi\n",
            families_s40 / 1e3))
cat(sprintf("+5%% shock:                         R$ %.2f bi  (NT: R$ 4.6 bi)\n",
            families_s40 * 0.05 / 1e3))

# Shock vector: only S40 household demand increases
delta_f_ex2 <- setNames(rep(0, N), setores$cod)
delta_f_ex2["S40"] <- families_s40 * 0.05

res_ex2 <- simulate_shock(delta_f_ex2,
                          "+5% Household demand S40 (NT Section 6.2)")

