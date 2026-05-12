# =============================================================================
# MIP-EPE ENERGIA 2018 — ANÁLISE COMPLETA DE INSUMO-PRODUTO
# NT EPE/DEA/SEE/013/2023
#
# Models:     Open (Leontief B), Closed (BF, endogenous consumption),
#             Supply-side (Ghosh G)
# Indicators: Production multipliers (MP, MPT, MPTT)
#             Employment multipliers (ME, MEI, MET, MEII)
#             Income multipliers     (MR, MRI, MRT, MRII)
#             HR linkage indices     (BL, FL, FLG)
#             Variation coefficients (Vj, Vi)
#             Pure linkage indices   (PBL, PFL, PTL, normalized)
#             Hypothetical extraction (BLextrac, FLextrac)
#             Field of influence     (SI — optional, very slow)
# Shocks:     Ex1 +5% total exports     (NT Section 6.1 replication)
#             Ex2 +5% household EE S40  (NT Section 6.2 replication)
#             Ex3 fossil demand shock   (parameterised)
#             Ex4 renewable demand shock(parameterised)
#             Ex5 combined transition   (Ex3 + Ex4)
#
# Source: Anexo 2 — MIP-EPE 73-sector IO table, Brazil 2018
# =============================================================================


# =============================================================================
# 0. PACKAGES & GLOBAL FLAGS
# =============================================================================

pkgs <- c("readxl", "dplyr", "tidyr", "writexl",
          "ggplot2", "scales", "ggrepel", "patchwork", "forcats")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}
options(scipen = 10, OutDec = ".")

# ── Computation flags ─────────────────────────────────────────────────────────
# Set to FALSE to skip slow operations during development iterations
COMPUTE_SLOW      <- TRUE   # Pure linkage indices + hypothetical extraction (~1-3 min)
COMPUTE_VERY_SLOW <- FALSE  # Field of influence SI matrix (~10-15 min for N=73)

# ── Shock parameters — energy transition scenarios ────────────────────────────
# Ex3: fossil demand contraction
FOSSIL_SECTORS    <- c("S05", "S19", "S21", "S43")
FOSSIL_COMPONENT  <- "Export"  # demand component: Export|Gov|ISFLSF|Families|GFCF|DeltaStock|all
FOSSIL_PCT        <- -0.20     # -20% on chosen component

# Ex4: renewable demand expansion
RENEW_SECTORS     <- c("S20", "S22", "S40", "S41", "S42")
RENEW_COMPONENT   <- "GFCF"   # investment in new generating capacity
RENEW_PCT         <- +0.30    # +30% on chosen component

# ── Grouping scheme ───────────────────────────────────────────────────────────
# "nt4"    — 4 groups: Agropecuaria, Industria, Servicos, Energeticos
# "7group" — 7 groups: fossil/renewable split (best for NDC paper)
# "ibge"   — 17 groups: official SCN 2010
GROUPING_SCHEME <- "7group"

cat("=== MIP-EPE FULL ANALYSIS ===\n")
cat(sprintf("COMPUTE_SLOW=%s | COMPUTE_VERY_SLOW=%s | GROUPING=%s\n",
            COMPUTE_SLOW, COMPUTE_VERY_SLOW, GROUPING_SCHEME))
cat(sprintf("Ex3: %.0f%% %s on %s\n",
            FOSSIL_PCT * 100, FOSSIL_COMPONENT, paste(FOSSIL_SECTORS, collapse = "+")))
cat(sprintf("Ex4: +%.0f%% %s on %s\n",
            RENEW_PCT * 100, RENEW_COMPONENT, paste(RENEW_SECTORS, collapse = "+")))


# =============================================================================
# 1. FILE PATH
# =============================================================================

ANX2 <- "48008000008202670_Camila_Anexo 2.xlsx"
if (!file.exists(ANX2)) {
  cands <- list.files(path        = c(".", "data/raw"),
                      pattern     = "Anexo.?2\\.xlsx$",
                      ignore.case = TRUE,
                      full.names  = TRUE)
  cands <- cands[!grepl("^~\\$|/~\\$", cands)]
  if (length(cands) == 0) stop("File not found: ", ANX2)
  ANX2 <- cands[1]
  message("Found: ", ANX2)
}

OUTDIR <- if (dir.exists("outputs")) "outputs" else "."
if (!dir.exists(OUTDIR)) dir.create(OUTDIR, recursive = TRUE)


# =============================================================================
# 2. DATA LOADING
# =============================================================================

# ── 2.1  Sector list S01..S73 ─────────────────────────────────────────────────
lista_raw <- read_excel(ANX2, sheet = "Lista PS",
                        col_names = FALSE, range = cell_cols("A:M"))

setores <- lista_raw |>
  select(cod = 12, nome = 13) |>
  filter(!is.na(cod), grepl("^S", as.character(cod))) |>
  mutate(
    cod  = as.character(cod),
    nome = as.character(nome),
    id   = as.integer(gsub("\\D", "", cod))
  )

N <- nrow(setores)
stopifnot("Expected 73 sectors" = N == 73)
message("Sectors loaded: ", N)

# ── 2.2  Read Usos SxS once (rows 5..130+ contain all indicators) ─────────────
sxs_raw <- read_excel(ANX2, sheet = "Usos SxS", col_names = FALSE)

# Helper: one row of Usos SxS → named numeric vector (length N, named by sector)
get_row_vec <- function(row_r, col_start_r = 4, n = N) {
  vals <- suppressWarnings(
    as.numeric(as.character(unlist(
      sxs_raw[row_r, col_start_r:(col_start_r + n - 1)]
    )))
  )
  vals[is.na(vals)] <- 0
  setNames(vals, setores$cod)
}

# ── 2.3  Z matrix — 73×73 intermediate consumption ───────────────────────────
Z <- sxs_raw[5:(4 + N), 4:(3 + N)] |>
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) |>
  as.matrix()
dimnames(Z) <- list(setores$cod, setores$cod)

# ── 2.4  Final demand matrix DF — 73×6 ────────────────────────────────────────
# Columns: Export | Gov | ISFLSF | Families | GFCF | DeltaStock
DF <- sxs_raw[5:(4 + N), 78:83] |>
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) |>
  as.data.frame()
colnames(DF) <- c("Export", "Gov", "ISFLSF", "Families", "GFCF", "DeltaStock")
rownames(DF) <- setores$cod

# Total final demand vector (used in pure linkage indices)
y <- rowSums(DF)
names(y) <- setores$cod

# ── 2.5  Output, value added, factor payments ─────────────────────────────────
x <- rowSums(Z) + rowSums(DF)
names(x) <- setores$cod

# Safe denominator — replaces zeros to avoid NaN/Inf in coefficient calculations
x_safe <- ifelse(x > 0, x, 1)
names(x_safe) <- setores$cod

# Row positions in Usos SxS (1-based R index):
#   88  Remunerações (R10)      |  89  Salários (R11)
#   96  EOB                     | 100  VA/PIB (N1)
#  101  VBP check (P10)         | 102  Ocupações (persons)
# 115-122 labor breakdown
# 125-130 energy physical flows (ktep)
va_pib   <- get_row_vec(100)   # Valor Adicionado Bruto
vbp      <- get_row_vec(101)   # VBP — should match x (verification)
remuner  <- get_row_vec(88)    # Remunerações totais
salarios <- get_row_vec(89)    # Salários
eob      <- get_row_vec(96)    # Excedente Operacional Bruto

message(sprintf(
  "x: R$ %.2f tri | VA: R$ %.2f tri | VBP-x diff: %.2f%%",
  sum(x) / 1e6, sum(va_pib) / 1e6,
  abs(sum(x) - sum(vbp)) / sum(x) * 100
))

# ── 2.6  Employment ───────────────────────────────────────────────────────────
ocupacoes <- get_row_vec(102)
occ       <- ocupacoes          # alias used by mip_epe_visualizations.R

# ── 2.7  Labor breakdown shares (fraction of total employment per sector) ──────
labor_rows <- c(
  Informal  = 115, Formal    = 116,
  PPI       = 117, Branca    = 118,   # PPI = Preto, Pardo, Indígena
  Homem     = 119, Mulher    = 120,
  Baixo_Med = 121, Superior  = 122
)
occ_safe <- ifelse(ocupacoes > 0, ocupacoes, 1)
labor_share <- sapply(labor_rows, function(r) get_row_vec(r) / occ_safe) |>
  t() |>
  as.data.frame()
# Result: 8 rows (groups) × 73 columns (sectors), each cell = share of group in sector's employment

message("Labor breakdown shares computed for ", length(labor_rows), " groups")

# ── 2.8  Energy physical flows and intensity coefficients ──────────────────────
energy_rows <- c(
  Derivados   = 125, Biodiesel  = 126, Etanol     = 127,
  EE_Central  = 128, EE_Distrib = 129, Gas_Natural = 130
)
# E matrix: 6 sources × 73 sectors (ktep consumed per sector in 2018)
E_mat <- sapply(energy_rows, get_row_vec) |> t()
rownames(E_mat) <- names(energy_rows)

# ALPHA matrix: ktep per R$ million of output (energy intensity coefficients)
ALPHA <- sweep(E_mat, 2, x_safe, "/")

message(sprintf(
  "ALPHA check: Derivados/S48=%.4f | EE_Central/S40=%.4f",
  ALPHA["Derivados", "S48"], ALPHA["EE_Central", "S40"]
))

# ── 2.9  Satellite account: coefficients for transition analysis ─────────────
# Row 102 matches the NT baseline employment text. The NT shock tables imply
# 0.4 × row-102 occupations/output, so both raw and NT-calibrated labor
# coefficients are kept.
EMP_SHOCK_SCALE <- 0.4

ce_raw <- as.vector(ocupacoes / x_safe)
ce_nt  <- EMP_SHOCK_SCALE * ce_raw
names(ce_raw) <- names(ce_nt) <- setores$cod

wage_coef <- as.vector(remuner / x_safe)
gdp_coef  <- as.vector(va_pib  / x_safe)
names(wage_coef) <- names(gdp_coef) <- setores$cod

energy_total <- colSums(E_mat)
energy_fossil <- E_mat["Derivados", ] + E_mat["Gas_Natural", ]
energy_lowcarbon <- E_mat["Biodiesel", ] + E_mat["Etanol", ] +
  E_mat["EE_Central", ] + E_mat["EE_Distrib", ]

# Replace this named vector when sector-level CO2 data are available.
if (!exists("co2_sector")) {
  co2_sector <- setNames(rep(NA_real_, N), setores$cod)
}

satellite <- data.frame(
  cod = setores$cod,
  nome = setores$nome,
  output = as.numeric(x),
  gdp = as.numeric(va_pib),
  jobs = as.numeric(ocupacoes),
  wages = as.numeric(remuner),
  energy_ktep = as.numeric(energy_total[setores$cod]),
  fossil_ktep = as.numeric(energy_fossil[setores$cod]),
  lowcarbon_ktep = as.numeric(energy_lowcarbon[setores$cod]),
  co2 = as.numeric(co2_sector[setores$cod]),
  labor_coef_raw = as.numeric(ce_raw[setores$cod]),
  labor_coef_nt = as.numeric(ce_nt[setores$cod]),
  wage_coef = as.numeric(wage_coef[setores$cod]),
  gdp_coef = as.numeric(gdp_coef[setores$cod]),
  energy_coef = as.numeric(energy_total[setores$cod] / x_safe[setores$cod]),
  fossil_energy_coef = as.numeric(energy_fossil[setores$cod] / x_safe[setores$cod]),
  lowcarbon_energy_coef = as.numeric(energy_lowcarbon[setores$cod] / x_safe[setores$cod]),
  carbon_coef = as.numeric(co2_sector[setores$cod] / x_safe[setores$cod]),
  fossil_share = as.numeric(energy_fossil[setores$cod] /
                              ifelse(energy_total[setores$cod] > 0,
                                     energy_total[setores$cod], NA_real_)),
  lowcarbon_share = as.numeric(energy_lowcarbon[setores$cod] /
                                 ifelse(energy_total[setores$cod] > 0,
                                        energy_total[setores$cod], NA_real_)),
  women_share = as.numeric(get_row_vec(120) / occ_safe),
  informality_share = as.numeric(get_row_vec(115) / occ_safe),
  low_education_share = as.numeric(get_row_vec(121) / occ_safe),
  stringsAsFactors = FALSE
)

SAT_COEF <- rbind(
  Labor_raw        = satellite$labor_coef_raw,
  Labor_NT         = satellite$labor_coef_nt,
  Wages            = satellite$wage_coef,
  GDP              = satellite$gdp_coef,
  Energy           = satellite$energy_coef,
  Fossil_Energy    = satellite$fossil_energy_coef,
  Lowcarbon_Energy = satellite$lowcarbon_energy_coef,
  Carbon           = satellite$carbon_coef
)
colnames(SAT_COEF) <- setores$cod

message("Satellite account built: labor, wages, GDP, energy, fossil share, demographics.")

# ── 2.10  Leontief inverse — pre-computed in Anexo 2 ───────────────────────────
l_raw <- read_excel(ANX2, sheet = "Leontief", col_names = FALSE, range = "D5:BX77")
L <- l_raw |>
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) |>
  as.matrix()
dimnames(L) <- list(setores$cod, setores$cod)

# Verification against NT published values
cat(sprintf(
  "L check: L[1,1]=%.4f (exp~1.027) | L[40,40]=%.4f (exp~1.331) | mult_S40=%.4f (exp~2.006)\n",
  L[1, 1], L[40, 40], sum(L[, "S40"])
))
message("Data loading complete.")


# =============================================================================
# 3. SECTOR GROUPS
# =============================================================================

fossil_sectors    <- c("S05", "S19", "S21", "S43")
renewable_sectors <- c("S20", "S22", "S40", "S41", "S42")
energy_sectors    <- c(fossil_sectors, renewable_sectors)

# ── NT4 (4 groups) ────────────────────────────────────────────────────────────
grupos_nt4 <- list(
  Agropecuaria = c("S01", "S02", "S03"),
  Industria    = setores$cod[setores$id %in% 4:43 & !setores$cod %in% energy_sectors],
  Servicos     = setores$cod[setores$id %in% 44:73 & !setores$cod %in% energy_sectors],
  Energeticos  = energy_sectors
)
grupo_colors_nt4 <- c(
  Agropecuaria = "#3B6D11", Industria = "#378ADD",
  Servicos     = "#888780", Energeticos = "#1D9E75"
)
grupo_levels_nt4 <- c("Agropecuaria", "Industria", "Servicos", "Energeticos")

# ── 7-group (fossil vs renewable split — NDC/energy-transition analysis) ───────
grupos_7 <- list(
  Agropecuaria   = c("S01", "S02", "S03"),
  Ind_Extrativa  = c("S04", "S06", "S07"),
  Energia_Fossil = fossil_sectors,
  Energia_Renov  = renewable_sectors,
  Ind_Transform  = setores$cod[setores$id %in% c(8:18, 23:39)],
  Infraestrutura = c("S44", "S45", "S48", "S49", "S50", "S51"),
  Servicos       = setores$cod[setores$id %in% c(46, 47, 52:73)]
)
grupo_colors_7 <- c(
  Agropecuaria   = "#3B6D11", Ind_Extrativa  = "#888780",
  Energia_Fossil = "#E24B4A", Energia_Renov  = "#1D9E75",
  Ind_Transform  = "#378ADD", Infraestrutura = "#534AB7",
  Servicos       = "#B4B2A9"
)
grupo_levels_7 <- c("Agropecuaria", "Ind_Extrativa", "Energia_Fossil",
                    "Energia_Renov", "Ind_Transform", "Infraestrutura", "Servicos")

# ── IBGE (17 groups — national accounts classification) ───────────────────────
grupos_ibge <- list(
  Agropecuaria  = c("S01", "S02", "S03"),
  Ind_Extrativa = c("S04", "S05", "S06", "S07"),
  Ind_Transform = setores$cod[setores$id %in% 8:39],
  Eletric_Gas   = c("S40", "S41", "S42", "S43"),
  Construcao    = "S45",
  Comercio      = c("S46", "S47"),
  Transporte    = c("S44", "S48", "S49", "S50", "S51"),
  Aloj_Aliment  = c("S52", "S53"),
  Info_Comunic  = c("S54", "S55", "S56", "S57"),
  Financeiro    = "S58",
  Imobiliario   = "S59",
  Serv_Prof     = c("S60", "S61", "S62"),
  Serv_Admin    = c("S63", "S64", "S65"),
  Adm_Publica   = "S66",
  Educacao      = c("S67", "S68"),
  Saude         = c("S69", "S70"),
  Outros_Serv   = c("S71", "S72", "S73")
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

# ── Apply chosen scheme ───────────────────────────────────────────────────────
if (GROUPING_SCHEME == "nt4") {
  grupos        <- grupos_nt4
  grupo_colors  <- grupo_colors_nt4   # used by mip_epe_visualizations.R
  grupo_levels  <- grupo_levels_nt4
  cat("Grouping: NT4 (4 groups)\n")
} else if (GROUPING_SCHEME == "7group") {
  grupos        <- grupos_7
  grupo_colors  <- grupo_colors_7
  grupo_levels  <- grupo_levels_7
  cat("Grouping: 7-group (fossil/renewable split)\n")
} else if (GROUPING_SCHEME == "ibge") {
  grupos        <- grupos_ibge
  grupo_colors  <- grupo_colors_ibge
  grupo_levels  <- names(grupos_ibge)
  cat("Grouping: IBGE (17 groups)\n")
} else {
  stop("Unknown GROUPING_SCHEME: '", GROUPING_SCHEME,
       "'. Choose: 'nt4', '7group', or 'ibge'")
}

# grupo_factor_levels defined AFTER grupos is assigned (avoids forward-reference bug)
grupo_factor_levels <- names(grupos)

# Verify coverage
stopifnot("Sector count != 73"   = sum(sapply(grupos, length)) == N)
stopifnot("Overlapping sectors"  = !any(duplicated(unlist(grupos))))

# Lookup vectors: sector code → group label
make_grupo_map <- function(g) setNames(rep(names(g), sapply(g, length)), unlist(g))
grupo_map <- make_grupo_map(grupos)
nt4_map   <- make_grupo_map(grupos_nt4)

cat(sprintf("  %d sectors across %d groups | no overlaps\n",
            N, length(grupos)))


# =============================================================================
# 4. IO MODELS
# =============================================================================

# ── 4.1  Open model (Leontief) ────────────────────────────────────────────────
# Technical coefficient matrix A
A <- Z %*% diag(1 / x_safe)
dimnames(A) <- list(setores$cod, setores$cod)

# Use pre-computed Leontief inverse from Anexo 2 as B
# (validated against NT — see section 2.9 check above)
B <- L
I_n <- diag(N)

# Satellite-account multipliers: indicator impact per R$1 million of final demand.
# Rows are indicators; columns are shocked sectors.
SAT_MULT <- SAT_COEF %*% B
colnames(SAT_MULT) <- setores$cod

# ── 4.2  Closed model (endogenous household consumption) ──────────────────────
# Household consumption coefficients: spending share of each sector per unit income
# Income coefficients: wage bill per unit of sector output
hc   <- matrix(DF$Families / sum(remuner), ncol = 1)  # N×1 column
hr   <- matrix(remuner / x_safe, nrow = 1)             # 1×N row

# Augmented coefficient matrix (N+1)×(N+1) and its Leontief inverse
AF   <- rbind(cbind(A, hc), cbind(hr, 0))
IF_n <- diag(N + 1)
BF   <- solve(IF_n - AF)
dimnames(BF) <- list(c(setores$cod, "HH"), c(setores$cod, "HH"))

# ── 4.3  Supply-side model (Ghosh) ────────────────────────────────────────────
# Named F_mat to avoid overwriting base R's F (= FALSE)
F_mat <- diag(1 / x_safe) %*% Z
dimnames(F_mat) <- list(setores$cod, setores$cod)
G <- solve(I_n - F_mat)
dimnames(G) <- list(setores$cod, setores$cod)

message("IO models built: Open (B=L), Closed (BF), Supply-side Ghosh (G)")


# =============================================================================
# 5. MULTIPLIERS
# =============================================================================

# ── 5.1  Production multipliers ───────────────────────────────────────────────
# MP   — simple (open model): total production induced per R$1 of final demand
# MPT  — total  (closed model, all N+1 rows): includes induced income effect
# MPTT — truncated total (closed, first N rows only): sector-to-sector part
MP   <- colSums(B)
MPT  <- colSums(BF[seq_len(N + 1), seq_len(N)])
MPTT <- colSums(BF[seq_len(N),     seq_len(N)])

# Decomposition into direct / indirect / induced effects
direct   <- colSums(A)
indirect <- MP   - direct
induced  <- MPT  - MP

mult_prod <- data.frame(
  cod      = setores$cod,
  nome     = setores$nome,
  MP       = round(MP,   4),
  MPT      = round(MPT,  4),
  MPTT     = round(MPTT, 4),
  direct   = round(direct,   4),
  indirect = round(indirect, 4),
  induced  = round(induced,  4),
  grupo    = grupo_map[setores$cod],
  stringsAsFactors = FALSE
)

# ── 5.2  Employment multipliers ───────────────────────────────────────────────
# ce     — employment coefficient (workers per R$ M of output)
# ME     — simple: direct + indirect workers per R$M final demand
# MEI    — type I  = ME / ce (multiplier relative to direct effect)
# MET    — total truncated (closed model, N×N part)
# MEII   — type II = MET / ce
ce     <- as.vector(ocupacoes / x_safe)
names(ce) <- setores$cod
Ce_hat <- diag(ce)

E_gen  <- Ce_hat %*% B                # N×N employment generator (open)
EF_gen <- Ce_hat %*% BF[1:N, 1:N]    # N×N employment generator (closed, truncated)

ME   <- colSums(E_gen)
MEI  <- ifelse(ce > 0, ME  / ce, 0)
MET  <- colSums(EF_gen)
MEII <- ifelse(ce > 0, MET / ce, 0)

mult_emp <- data.frame(
  cod  = setores$cod,
  nome = setores$nome,
  ME   = round(ME,   4),
  MEI  = round(MEI,  4),
  MET  = round(MET,  4),
  MEII = round(MEII, 4),
  grupo = grupo_map[setores$cod],
  stringsAsFactors = FALSE
)

# ── 5.3  Income (remuneration) multipliers ────────────────────────────────────
# cr     — income coefficient (R$ remuneration per R$ M of output)
# MR     — simple: direct + indirect remuneration per R$M final demand
# MRI    — type I  = MR / cr
# MRT    — total truncated (closed model)
# MRII   — type II = MRT / cr
cr     <- as.vector(remuner / x_safe)
names(cr) <- setores$cod
Cr_hat <- diag(cr)

R_gen  <- Cr_hat %*% B
RF_gen <- Cr_hat %*% BF[1:N, 1:N]

MR   <- colSums(R_gen)
MRI  <- ifelse(cr > 0, MR  / cr, 0)
MRT  <- colSums(RF_gen)
MRII <- ifelse(cr > 0, MRT / cr, 0)

mult_rem <- data.frame(
  cod  = setores$cod,
  nome = setores$nome,
  MR   = round(MR,   4),
  MRI  = round(MRI,  4),
  MRT  = round(MRT,  4),
  MRII = round(MRII, 4),
  grupo = grupo_map[setores$cod],
  stringsAsFactors = FALSE
)

message("Multipliers computed: MP/MPT/MPTT | ME/MEI/MET/MEII | MR/MRI/MRT/MRII")


# =============================================================================
# 6. LINKAGE INDICES
# =============================================================================

# ── 6.1  Hirschman-Rasmussen ─────────────────────────────────────────────────
B_star <- mean(B)
BL     <- colMeans(B) / B_star    # backward linkage (Uj): demand-pull strength
FL     <- rowMeans(B) / B_star    # forward linkage  (Ui): Leontief-based

G_star <- mean(G)
FLG    <- rowMeans(G) / G_star    # forward linkage via Ghosh (supply-push strength)

# Sector classification: quadrant defined using BL and FLG (as in IP-GIC.R)
quadrante_hr <- dplyr::case_when(
  BL >= 1 & FLG >= 1 ~ "Setor-Chave",
  BL >= 1 & FLG <  1 ~ "Demanda acima da media",
  BL <  1 & FLG >= 1 ~ "Oferta acima da media",
  TRUE               ~ "Independente"
)
names(quadrante_hr) <- setores$cod

# ── 6.2  Variation coefficients (dispersion — how concentrated are linkages?) ──
# Vj: high = sector's backward effect concentrated in few sectors
# Vi: high = sector's forward effect concentrated in few sectors
MC <- colMeans(B)
ML <- rowMeans(B)
Vj <- apply(B, 2, sd) / MC
Vi <- apply(B, 1, sd) / ML

ind_lig <- data.frame(
  cod        = setores$cod,
  nome       = setores$nome,
  BL         = round(BL,  4),
  FL         = round(FL,  4),
  FLG        = round(FLG, 4),
  Vj         = round(Vj,  4),
  Vi         = round(Vi,  4),
  quadrante  = quadrante_hr,
  eh_energia = setores$cod %in% energy_sectors,
  eh_fossil  = setores$cod %in% fossil_sectors,
  eh_renov   = setores$cod %in% renewable_sectors,
  grupo      = grupo_map[setores$cod],
  stringsAsFactors = FALSE
)

# ── 6.3  Pure linkage indices (Guilhoto-Sonis) ────────────────────────────────
# Vectorized: N solves of (N-1)×(N-1) systems instead of the naive N³ loop
# PBL[j] = production impact on the rest of economy if sector j's demand link is cut
# PFL[j] = production impact on the rest of economy if sector j's supply link is cut
# PTL[j] = PBL + PFL
if (COMPUTE_SLOW) {
  message("Computing pure linkage indices (", N, " matrix solves)...")

  IPL_mat <- matrix(NA_real_, nrow = N, ncol = 3,
                    dimnames = list(setores$cod, c("PBL", "PFL", "PTL")))

  for (j in seq_len(N)) {
    Ajj <- A[j, j]
    DJ  <- 1 / (1 - Ajj)                  # scalar Leontief of isolated sector j
    Ajr <- A[j,  -j, drop = FALSE]        # 1 × (N-1): sector j's purchases from rest
    Arj <- A[-j,  j, drop = FALSE]        # (N-1) × 1: rest's purchases from sector j
    Arr <- A[-j, -j]                       # (N-1) × (N-1): rest-of-economy submatrix
    DR  <- solve(I_n[-j, -j] - Arr)       # Leontief of rest of economy
    yj  <- y[j]
    yr  <- y[-j]

    IPL_mat[j, "PBL"] <- sum(DR %*% Arj) * DJ * yj
    IPL_mat[j, "PFL"] <- as.numeric(DJ * Ajr %*% DR %*% yr)
    IPL_mat[j, "PTL"] <- IPL_mat[j, "PBL"] + IPL_mat[j, "PFL"]
  }

  # Normalize: express each index as multiple of its sector-average
  IPL_means <- colMeans(IPL_mat)
  IPLN_mat  <- sweep(IPL_mat, 2, IPL_means, "/")

  ind_puros <- data.frame(
    cod      = setores$cod,
    nome     = setores$nome,
    PBL      = round(IPL_mat[, "PBL"],  2),
    PFL      = round(IPL_mat[, "PFL"],  2),
    PTL      = round(IPL_mat[, "PTL"],  2),
    PBLN     = round(IPLN_mat[, "PBL"], 4),
    PFLN     = round(IPLN_mat[, "PFL"], 4),
    PTLN     = round(IPLN_mat[, "PTL"], 4),
    grupo    = grupo_map[setores$cod],
    stringsAsFactors = FALSE
  )
  message("Pure linkage indices complete.")
} else {
  ind_puros <- NULL
  message("Skipped: pure linkage indices (COMPUTE_SLOW = FALSE)")
}


# =============================================================================
# 7. HYPOTHETICAL EXTRACTION
# =============================================================================
# BLextrac[j]: production lost if sector j stops buying from all others
#              (demand-side, Leontief)
# FLextrac[i]: production lost if sector i stops selling to all others
#              (supply-side, Ghosh)

if (COMPUTE_SLOW) {
  message("Computing hypothetical extraction (", 2 * N, " matrix solves)...")

  # Primary input (value added) per sector: used as supply vector for Ghosh side
  sp_vec <- as.numeric(x) - colSums(Z)

  BLextrac <- numeric(N)
  FLextrac <- numeric(N)
  names(BLextrac) <- names(FLextrac) <- setores$cod

  for (j in seq_len(N)) {
    ABL      <- A;  ABL[, j] <- 0
    BBL      <- solve(I_n - ABL)
    BLextrac[j] <- sum(x) - sum(BBL %*% y)
  }

  for (i in seq_len(N)) {
    FFL      <- F_mat;  FFL[i, ] <- 0
    GFL      <- solve(I_n - FFL)
    FLextrac[i] <- sum(x) - sum(t(sp_vec) %*% GFL)
  }

  extrac <- data.frame(
    cod    = setores$cod,
    nome   = setores$nome,
    BL_abs = round(BLextrac, 2),
    FL_abs = round(FLextrac, 2),
    BL_pct = round(BLextrac / sum(x) * 100, 4),
    FL_pct = round(FLextrac / sum(x) * 100, 4),
    grupo  = grupo_map[setores$cod],
    stringsAsFactors = FALSE
  )
  message("Hypothetical extraction complete.")
} else {
  extrac <- NULL
  message("Skipped: hypothetical extraction (COMPUTE_SLOW = FALSE)")
}


# =============================================================================
# 8. FIELD OF INFLUENCE  (optional — very slow)
# =============================================================================
# SI[i,j]: how much does a marginal increase in A[i,j] propagate across B?
# High SI = the i→j technical link is structurally influential.

if (COMPUTE_VERY_SLOW) {
  message("Computing field of influence (", N^2, " Leontief inversions)...")
  epsilon  <- 0.001
  E_incr   <- matrix(0, N, N)
  SI       <- matrix(0, N, N, dimnames = list(setores$cod, setores$cod))

  for (i in seq_len(N)) {
    for (j in seq_len(N)) {
      E_incr[i, j] <- epsilon
      BE      <- solve(I_n - (A + E_incr))
      SI[i, j] <- sum(((BE - B) / epsilon)^2)
      E_incr[i, j] <- 0
    }
  }
  message("Field of influence complete.")
} else {
  SI <- NULL
  message("Skipped: field of influence (COMPUTE_VERY_SLOW = FALSE)")
}


# =============================================================================
# 9. SHOCK ENGINE
# =============================================================================

# ── 9.1  Build a shock vector from sector codes + demand component + % ─────────
# component: one of the DF column names, or "all" to use total final demand
make_delta_f <- function(sectors, component = "all", pct = 0.05) {
  delta <- setNames(numeric(N), setores$cod)
  if (component == "all") {
    delta[sectors] <- rowSums(DF[sectors, , drop = FALSE]) * pct
  } else {
    delta[sectors] <- DF[sectors, component] * pct
  }
  delta
}

# ── 9.2  Core simulation ──────────────────────────────────────────────────────
simulate_shock <- function(delta_f,
                           shock_name    = "Shock",
                           print_results = TRUE) {
  delta_f    <- setNames(as.numeric(delta_f), setores$cod)

  # Leontief propagation: Δx = B · Δf
  delta_x    <- as.vector(B %*% delta_f);    names(delta_x)  <- setores$cod

  # Factor-payment impacts (proportional to baseline coefficients)
  delta_va   <- (va_pib   / x_safe) * delta_x
  delta_rem  <- (remuner  / x_safe) * delta_x
  delta_sal  <- (salarios / x_safe) * delta_x
  delta_eob  <- (eob      / x_safe) * delta_x
  delta_emp  <- (ocupacoes / x_safe) * delta_x

  # Energy impacts by source: Δg = ALPHA · Δx  (ktep)
  delta_g    <- as.vector(ALPHA %*% delta_x);  names(delta_g) <- rownames(ALPHA)

  # Labor breakdown: distribute delta_emp by baseline demographic shares
  delta_labor <- sapply(rownames(labor_share), function(grp) {
    sum(as.numeric(labor_share[grp, ]) * delta_emp)
  })

  # Full sector-level data frame
  sector_results <- data.frame(
    cod           = setores$cod,
    nome          = setores$nome,
    grupo         = grupo_map[setores$cod],
    grupo_nt4     = nt4_map[setores$cod],
    eh_energia    = setores$cod %in% energy_sectors,
    eh_fossil     = setores$cod %in% fossil_sectors,
    eh_renovavel  = setores$cod %in% renewable_sectors,
    x_base        = round(x,         2),
    delta_f       = round(delta_f,   4),
    delta_x       = round(delta_x,   4),
    delta_va      = round(delta_va,  4),
    delta_rem     = round(delta_rem, 4),
    delta_sal     = round(delta_sal, 4),
    delta_eob     = round(delta_eob, 4),
    delta_emp     = round(delta_emp, 1),
    var_x_pct     = round(delta_x   / x_safe                                   * 100, 4),
    var_va_pct    = round(delta_va  / ifelse(va_pib    > 0, va_pib,    1)      * 100, 4),
    var_emp_pct   = round(delta_emp / ifelse(ocupacoes > 0, ocupacoes, 1)      * 100, 4),
    stringsAsFactors = FALSE
  )

  # Group-level aggregates
  agg <- data.frame(
    grupo        = names(grupos),
    delta_x      = sapply(grupos, function(s) sum(delta_x[s])),
    delta_va     = sapply(grupos, function(s) sum(delta_va[s])),
    delta_rem    = sapply(grupos, function(s) sum(delta_rem[s])),
    delta_emp    = sapply(grupos, function(s) sum(delta_emp[s])),
    delta_energy = sapply(grupos, function(s) {
      sum(ALPHA[, s, drop = FALSE] %*% delta_x[s])
    }),
    stringsAsFactors = FALSE
  )

  if (print_results) {
    cat(sprintf(
      "  [%s]\n    Δx=R$%.2fbi | ΔVA=R$%.2fbi | Δemp=%.1fk | ΔE=%.1fktep\n",
      shock_name,
      sum(delta_x)   / 1e3,
      sum(delta_va)  / 1e3,
      sum(delta_emp) / 1e3,
      sum(delta_g)
    ))
  }

  list(
    shock_name     = shock_name,
    delta_f        = delta_f,
    delta_x        = delta_x,
    delta_va       = delta_va,
    delta_rem      = delta_rem,
    delta_sal      = delta_sal,
    delta_eob      = delta_eob,
    delta_emp      = delta_emp,
    delta_g        = delta_g,
    delta_labor    = delta_labor,
    sector_results = sector_results,
    energy_detail  = sector_results[sector_results$cod %in% energy_sectors, ],
    fossil_detail  = sector_results[sector_results$cod %in% fossil_sectors, ],
    renov_detail   = sector_results[sector_results$cod %in% renewable_sectors, ],
    agg            = agg
  )
}


# =============================================================================
# 10. EXERCISES
# =============================================================================

cat("\n=== EXERCISES ===\n")

# ── Ex1: +5% total exports (NT Section 6.1 replication) ──────────────────────
res_ex1 <- simulate_shock(
  make_delta_f(setores$cod, component = "Export", pct = 0.05),
  "+5% Exports (NT 6.1)"
)
# NT targets: ΔVA=R$38.5bi | Δemp=258k | ΔE=1,768ktep
cat(sprintf("    NT check → ΔVA: R$%.1fbi (NT: 38.5) | ΔE: %.0fktep (NT: 1768)\n",
            sum(res_ex1$delta_va) / 1e3, sum(res_ex1$delta_g)))

# ── Ex2: +5% household electricity demand S40 (NT Section 6.2 replication) ───
delta_f_ex2        <- setNames(numeric(N), setores$cod)
delta_f_ex2["S40"] <- DF["S40", "Families"] * 0.05
res_ex2 <- simulate_shock(delta_f_ex2, "+5% Household EE S40 (NT 6.2)")
cat(sprintf("    NT check → S40 shock: R$%.2fbi (NT: ~4.6bi)\n",
            delta_f_ex2["S40"] / 1e3))

# ── Ex3: Fossil demand contraction (parameterised at top of script) ───────────
res_ex3 <- simulate_shock(
  make_delta_f(FOSSIL_SECTORS, FOSSIL_COMPONENT, FOSSIL_PCT),
  sprintf("%.0f%% %s — fossil (Ex3)", FOSSIL_PCT * 100, FOSSIL_COMPONENT)
)

# ── Ex4: Renewable demand expansion (parameterised at top of script) ──────────
res_ex4 <- simulate_shock(
  make_delta_f(RENEW_SECTORS, RENEW_COMPONENT, RENEW_PCT),
  sprintf("+%.0f%% %s — renewable (Ex4)", RENEW_PCT * 100, RENEW_COMPONENT)
)

# ── Ex5: Combined energy transition (Ex3 + Ex4 simultaneously) ───────────────
res_ex5 <- simulate_shock(
  make_delta_f(FOSSIL_SECTORS, FOSSIL_COMPONENT, FOSSIL_PCT) +
    make_delta_f(RENEW_SECTORS, RENEW_COMPONENT, RENEW_PCT),
  "Energy transition: fossil contraction + renewable expansion (Ex5)"
)

# Collect all shocks for summary output
all_shocks <- list(res_ex1, res_ex2, res_ex3, res_ex4, res_ex5)


# =============================================================================
# 11. SUMMARY TO CONSOLE
# =============================================================================

cat("\n=== INDICATOR SUMMARY ===\n")

cat("\nTop 10 production multipliers (MP):\n")
mult_prod |>
  arrange(desc(MP)) |>
  head(10) |>
  mutate(nome_c = substr(nome, 1, 35)) |>
  select(cod, nome_c, MP, MPT, induced, grupo) |>
  print()

cat("\nLinkage indices — energy sectors (BL and FLG):\n")
ind_lig |>
  filter(eh_energia) |>
  mutate(nome_c = substr(nome, 1, 35)) |>
  select(cod, nome_c, BL, FLG, Vj, Vi, quadrante) |>
  arrange(desc(BL)) |>
  print()

cat("\nSectors by Rasmussen quadrant:\n")
print(table(ind_lig$quadrante))

cat("\nShock comparison (R$ billion | thousand jobs | ktep):\n")
shock_summary <- data.frame(
  exercicio = sapply(all_shocks, `[[`, "shock_name"),
  dx_bi     = sapply(all_shocks, function(r) round(sum(r$delta_x)   / 1e3, 2)),
  dVA_bi    = sapply(all_shocks, function(r) round(sum(r$delta_va)  / 1e3, 2)),
  demp_mil  = sapply(all_shocks, function(r) round(sum(r$delta_emp) / 1e3, 1)),
  dE_ktep   = sapply(all_shocks, function(r) round(sum(r$delta_g),         1)),
  stringsAsFactors = FALSE
)
print(shock_summary, row.names = FALSE)


# =============================================================================
# 12. EXPORT
# =============================================================================

# ── Helper: wide energy data frames ───────────────────────────────────────────
energy_sources <- rownames(E_mat)

make_energy_wide <- function(mat, label_suffix = "") {
  df <- as.data.frame(t(mat))
  df$cod       <- rownames(df)
  df$nome      <- setores$nome[match(df$cod, setores$cod)]
  df$grupo     <- grupo_map[df$cod]
  df$total     <- round(rowSums(df[, energy_sources, drop = FALSE]), 4)
  df <- df[, c("cod", "nome", "grupo", energy_sources, "total")]
  rownames(df) <- NULL
  df
}

# ── Build shock-combined long tables ──────────────────────────────────────────
shocks_sector_long <- do.call(rbind, lapply(all_shocks, function(r) {
  r$sector_results |> mutate(exercicio = r$shock_name)
}))

shocks_agg_long <- do.call(rbind, lapply(all_shocks, function(r) {
  r$agg |> mutate(exercicio = r$shock_name)
}))

shocks_energy_long <- do.call(rbind, lapply(all_shocks, function(r) {
  data.frame(
    exercicio  = r$shock_name,
    fonte      = names(r$delta_g),
    delta_ktep = round(r$delta_g, 4),
    stringsAsFactors = FALSE
  )
}))

shocks_labor_long <- do.call(rbind, lapply(all_shocks, function(r) {
  data.frame(
    exercicio = r$shock_name,
    grupo_lab = names(r$delta_labor),
    delta_emp = round(r$delta_labor, 1),
    stringsAsFactors = FALSE
  )
}))

# ── Assemble sheet list ────────────────────────────────────────────────────────
out_list <- list(

  # Reference
  "Setores" = setores |>
    mutate(grupo     = grupo_map[cod],
           grupo_nt4 = nt4_map[cod],
           eh_energia = cod %in% energy_sectors,
           eh_fossil  = cod %in% fossil_sectors,
           eh_renov   = cod %in% renewable_sectors),

  # Baseline descriptive
  "Baseline" = data.frame(
    cod         = setores$cod,
    nome        = setores$nome,
    grupo       = grupo_map[setores$cod],
    vbp         = round(x,         2),
    va_pib      = round(va_pib,    2),
    remuner     = round(remuner,   2),
    salarios    = round(salarios,  2),
    eob         = round(eob,       2),
    ocupacoes   = round(ocupacoes, 0),
    coef_emp    = round(ce,        6),
    coef_rem    = round(cr,        6),
    stringsAsFactors = FALSE
  ),

  # Multipliers
  "Mult_Producao" = mult_prod,
  "Mult_Emprego"  = mult_emp,
  "Mult_Renda"    = mult_rem,

  # Linkage indices
  "Ind_Ligacao"   = ind_lig,

  # Energy
  "Energia_Fluxos_ktep" = make_energy_wide(E_mat),
  "Energia_Alpha"       = make_energy_wide(ALPHA),

  # Demand final
  "Demanda_Final" = data.frame(cod = setores$cod, nome = setores$nome,
                               grupo = grupo_map[setores$cod],
                               DF, stringsAsFactors = FALSE),

  # Shock results — individual
  "Choque_Ex1_NT"     = res_ex1$sector_results,
  "Choque_Ex2_NT"     = res_ex2$sector_results,
  "Choque_Ex3_Fossil" = res_ex3$sector_results,
  "Choque_Ex4_Renov"  = res_ex4$sector_results,
  "Choque_Ex5_Trans"  = res_ex5$sector_results,

  # Shock results — combined
  "Choques_Setor"   = shocks_sector_long,
  "Choques_Grupos"  = shocks_agg_long,
  "Choques_Energia" = shocks_energy_long,
  "Choques_Labor"   = shocks_labor_long,
  "Choques_Resumo"  = shock_summary
)

# Append slow-compute results if available
if (!is.null(ind_puros)) out_list[["Ind_Puros"]]     <- ind_puros
if (!is.null(extrac))    out_list[["Extr_Hipotetica"]] <- extrac
if (!is.null(SI)) {
  si_df <- as.data.frame(SI)
  si_df <- cbind(setor_linha = rownames(si_df), si_df)
  rownames(si_df) <- NULL
  out_list[["Campo_Influencia"]] <- si_df
}

out_path <- file.path(OUTDIR, "mip_epe_replication_results.xlsx")
write_xlsx(out_list, path = out_path)

cat(sprintf("\nSaved: %s (%d sheets)\n", out_path, length(out_list)))
cat("=== DONE ===\n")
