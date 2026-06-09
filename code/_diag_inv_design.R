setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
library(readxl)
options(OutDec=".")

MMA_PATH <- "data/raw/Planilha_Detalhamento Resultados MMA-SMC v3 AR5 (07_10_2024).xlsx"
all_sheets <- excel_sheets(MMA_PATH)
read_raw <- function(idx) suppressMessages(read_excel(MMA_PATH, sheet=all_sheets[idx], col_names=FALSE))

# Column layout (same across all sheets)
# col3=base2020, col5-10=25D(2025-2050), col12-17=100D(2025-2050)
ANOS <- c(2025,2030,2035,2040,2045,2050)
get_val <- function(df, row, col) suppressWarnings(as.numeric(df[[row, col]]))
get_row <- function(df, row, cols) sapply(cols, function(c) get_val(df, row, c))

en  <- read_raw(4)
ind <- read_raw(5)
tr  <- read_raw(6)

# ── Energia Sheet 4 — GW installed capacity ─────────────────────────────────
# Cols: base=3, 25D=5:10, 100D=12:17
base_cols <- 3
c25 <- 5:10; c100 <- 12:17

cap_base  <- get_val(en, 50, 3)   # Total GW base
cap_eol_b <- get_val(en, 51, 3)   # Eólica base GW
cap_sol_b <- get_val(en, 52, 3)   # Solar base GW
cap_hid_b <- get_val(en, 53, 3)   # Hidro base GW
cap_bio_b <- get_val(en, 54, 3)   # Biomassa base GW
cap_bcs_b <- get_val(en, 55, 3)   # Biomassa CCS base GW
cap_nuc_b <- get_val(en, 56, 3)   # Nuclear base GW
cap_fos_b <- get_val(en, 57, 3)   # Fóssil base GW

cat("=== Capacidade Instalada 2020 (GW) ===\n")
cat(sprintf("  Total  = %.1f\n  Eólica = %.1f | Solar  = %.1f | Hidro  = %.1f\n  Bio    = %.1f | BioCSS = %.1f | Nuclear= %.1f | Fóssil = %.1f\n\n",
    cap_base, cap_eol_b, cap_sol_b, cap_hid_b, cap_bio_b, cap_bcs_b, cap_nuc_b, cap_fos_b))

# Capacity by year, by scenario
for (cen in c("25D","100D")) {
  cols <- if(cen=="25D") c25 else c100
  cat(sprintf("--- %s Capacidade Instalada (GW) ---\n", cen))
  cat(sprintf("  %-10s  %6s  %6s  %6s  %6s  %6s  %6s\n","Tech","2025","2030","2035","2040","2045","2050"))
  rows_labs <- list(Eolica=51, Solar=52, Hidro=53, Biomassa=54, BioCSS=55, Nuclear=56, Fossil=57, Total=50)
  for (lab in names(rows_labs)) {
    r <- rows_labs[[lab]]
    vals <- get_row(en, r, cols)
    base <- get_val(en, r, 3)
    deltas <- vals - base
    cat(sprintf("  %-10s  %s   [Δ: %s]\n", lab,
        paste(sprintf("%6.1f", vals), collapse="  "),
        paste(sprintf("%+5.1f", deltas), collapse="  ")))
  }
  # Key cumulative deltas at 2050
  eol_d50 <- get_val(en,51,cols[6]) - cap_eol_b
  sol_d50 <- get_val(en,52,cols[6]) - cap_sol_b
  hid_d50 <- get_val(en,53,cols[6]) - cap_hid_b
  bio_d50 <- (get_val(en,54,cols[6]) + get_val(en,55,cols[6])) - (cap_bio_b + cap_bcs_b)
  nuc_d50 <- get_val(en,56,cols[6]) - cap_nuc_b
  fos_d50 <- get_val(en,57,cols[6]) - cap_fos_b
  cat(sprintf("\n  NET NEW GW at 2050: Eolica=%+.0f  Solar=%+.0f  Hidro=%+.0f  Bio=%+.0f  Nuclear=%+.0f  Fossil=%+.0f\n\n",
      eol_d50, sol_d50, hid_d50, bio_d50, nuc_d50, fos_d50))
}

# ── Biofuels (Sheet 4, rows 76-80) ──────────────────────────────────────────
cat("--- Biocombustíveis PJ por cenário ---\n")
bfuels <- list(EtanolCCS=76, DieselVerde=78, Biometano=79, BioQAV=80)
for (cen in c("25D","100D")) {
  cols <- if(cen=="25D") c25 else c100
  cat(sprintf("  %s:\n", cen))
  for (nm in names(bfuels)) {
    vals <- get_row(en, bfuels[[nm]], cols)
    cat(sprintf("    %-12s  %s\n", nm, paste(sprintf("%6.1f", vals), collapse="  ")))
  }
}

# ── Industry Sheet 5 ─────────────────────────────────────────────────────────
cat("\n--- Indústria — produção física (Mt) ---\n")
for (cen in c("25D","100D")) {
  cols <- if(cen=="25D") c25 else c100
  aco_b  <- get_val(ind,27,3); aco_50 <- get_val(ind,27,cols[6])
  cli_b  <- get_val(ind,41,3); cli_50 <- get_val(ind,41,cols[6])
  cat(sprintf("  %s: Aço base=%.1f → 2050=%.1f (Δ%+.1f Mt)  |  Clínquer base=%.1f → 2050=%.1f (Δ%+.1f Mt)\n",
      cen, aco_b, aco_50, aco_50-aco_b, cli_b, cli_50, cli_50-cli_b))
}

# ── Transport electrification (Sheet 6) ─────────────────────────────────────
cat("\n--- Transporte — eletrificação PJ ---\n")
for (cen in c("25D","100D")) {
  cols <- if(cen=="25D") c25 else c100
  pj_tot <- get_row(tr, 13, cols)
  pct_el <- get_row(tr, 14, cols)
  pj_elec <- pj_tot * pct_el
  cat(sprintf("  %s PJ elec: %s\n", cen, paste(sprintf("%5.1f", pj_elec), collapse="  ")))
}

# ── PROPOSED ALLOCATION WEIGHTS ──────────────────────────────────────────────
cat("\n\n=== PROPOSTA: ALOC_INV DATA-DRIVEN (100D, médias 2030-2050) ===\n\n")

# Unit investment factors (relative $M per GW or per unit)
# Based on EPE / IRENA 2023 cost estimates for Brazil
CAPEX_GW <- c(Eolica=1200, Solar=700, Hidro=2500, Biomassa=1500, Nuclear=8000)
# $ per tonne of additional green capacity:
CAPEX_T  <- c(Aco=500, Clinker=300)  # marginal decarbonization capex $/t
# $ per PJ of biofuel plant:
CAPEX_PJ <- c(Biofuel=40)  # $M per PJ

# For 100D scenario, compute investment proxy by category
cols100 <- c100
# Average incremental capacity per 5-year period (normalized to 2030 as start)
# We'll compute from base to each year and take the 2030 increment as representative

cat("Technology         | ΔGW to 2050 | CapEx $M/GW | Investment proxy ($Bi)\n")
cat(strrep("-",70),"\n")

eol_50  <- get_val(en,51,cols100[6]) - cap_eol_b
sol_50  <- get_val(en,52,cols100[6]) - cap_sol_b
hid_50  <- get_val(en,53,cols100[6]) - cap_hid_b
bio_50  <- (get_val(en,54,cols100[6])+get_val(en,55,cols100[6])) - (cap_bio_b+cap_bcs_b)
nuc_50  <- get_val(en,56,cols100[6]) - cap_nuc_b

inv_eol <- max(eol_50,0) * CAPEX_GW["Eolica"] / 1000
inv_sol <- max(sol_50,0) * CAPEX_GW["Solar"]  / 1000
inv_hid <- max(hid_50,0) * CAPEX_GW["Hidro"]  / 1000
inv_bio <- max(bio_50,0) * CAPEX_GW["Biomassa"]/ 1000
inv_nuc <- max(nuc_50,0) * CAPEX_GW["Nuclear"] / 1000

# Biofuels (PJ at 2050)
bmet_50  <- get_val(en,79,cols100[6])
bdvd_50  <- get_val(en,78,cols100[6])
bqav_50  <- get_val(en,80,cols100[6])
inv_bfuel <- (bmet_50 + bdvd_50 + bqav_50) * CAPEX_PJ["Biofuel"] / 1000

# Green steel and cement
aco_50  <- get_val(ind,27,cols100[6]) - get_val(ind,27,3)
cli_50  <- get_val(ind,41,cols100[6]) - get_val(ind,41,3)
inv_aco <- max(aco_50,0) * 1e6 * CAPEX_T["Aco"]  / 1e12  # $Bi
inv_cli <- max(cli_50,0) * 1e6 * CAPEX_T["Clinker"]/ 1e12

cat(sprintf("Eólica             | %+6.0f GW   | %7.0f      | %6.1f\n", eol_50, CAPEX_GW["Eolica"], inv_eol))
cat(sprintf("Solar              | %+6.0f GW   | %7.0f      | %6.1f\n", sol_50, CAPEX_GW["Solar"],  inv_sol))
cat(sprintf("Hidro              | %+6.0f GW   | %7.0f      | %6.1f\n", hid_50, CAPEX_GW["Hidro"],  inv_hid))
cat(sprintf("Biomassa elétrica  | %+6.0f GW   | %7.0f      | %6.1f\n", bio_50, CAPEX_GW["Biomassa"],inv_bio))
cat(sprintf("Nuclear            | %+6.0f GW   | %7.0f      | %6.1f\n", nuc_50, CAPEX_GW["Nuclear"],inv_nuc))
cat(sprintf("Biocombustíveis    | %+6.0f PJ   | %7.0f $/PJ  | %6.1f\n", bmet_50+bdvd_50+bqav_50, CAPEX_PJ["Biofuel"]*1000, inv_bfuel))
cat(sprintf("Verde Aço (ΔMt)    | %+6.0f Mt   | %7.0f $/t   | %6.1f\n", aco_50, CAPEX_T["Aco"], inv_aco))
cat(sprintf("Verde Cimento (ΔMt)| %+6.0f Mt   | %7.0f $/t   | %6.1f\n", cli_50, CAPEX_T["Clinker"], inv_cli))

total_inv_proxy <- inv_eol + inv_sol + inv_hid + inv_bio + inv_nuc + inv_bfuel + inv_aco + inv_cli
cat(sprintf("\nTotal proxy (relative $Bi) = %.1f\n", total_inv_proxy))
cat("\nProposed IO sector allocation weights:\n\n")

# IO sector mapping by technology category
# Wind → S37 turbines(50%), S44 civil(30%), S33 electrical(10%), S42 grid(10%)
# Solar → S32 panels(40%), S44 civil(30%), S33 electrical(20%), S42 grid(10%)
# Hydro → S44 civil(60%), S30 metals/turbines(25%), S42 grid(15%)
# Biomassa elec → S22 biocombustivel(60%), S44 civil(40%)
# Nuclear → S39 maintenance/engineering(50%), S44 civil(50%)
# Biofuels → S22(50%), S20(20%), S44 plant construction(30%)
# Green steel → S29(70%), S44(20%), S33 electrical equip(10%)
# Green cement → S28(70%), S44(30%)
# Grid expansion: 10% of all electricity investment → S42

allocations <- list(
  S37 = inv_eol*0.50,                        # wind turbines (equip transporte)
  S32 = inv_sol*0.40,                        # solar panels (eletrônicos)
  S44 = inv_eol*0.30 + inv_sol*0.30 + inv_hid*0.60 + inv_bio*0.40 +
        inv_nuc*0.50 + inv_bfuel*0.30 + inv_aco*0.20 + inv_cli*0.30,  # civil
  S33 = inv_eol*0.10 + inv_sol*0.20 + inv_aco*0.10,    # electrical equipment
  S42 = inv_eol*0.10 + inv_sol*0.10 + inv_hid*0.15,    # grid/transmission
  S30 = inv_hid*0.25,                        # metals/turbines (hydro)
  S22 = inv_bio*0.60 + inv_bfuel*0.50,       # biocombustíveis
  S20 = inv_bfuel*0.20,                      # biodiesel
  S39 = inv_nuc*0.50,                        # maintenance/engineering (nuclear)
  S29 = inv_aco*0.70,                        # siderurgia verde
  S28 = inv_cli*0.70                         # cimento verde
)

tot <- sum(unlist(allocations))
cat(sprintf("  %-6s  %-40s  %8s  %6s\n","Cod","Setor","$Bi proxy","Weight"))
cat(strrep("-",70),"\n")

sector_names <- c(S37="Equip transporte (turbinas eólicas)",
                  S32="Eletrônicos (painéis solares)",
                  S44="Construção civil (obras de energia)",
                  S33="Equip elétricos (inversores, trafo)",
                  S42="Transmissão e distribuição",
                  S30="Metalurgia (turbinas hidro/outros)",
                  S22="Biocombustíveis complexo",
                  S20="Biodiesel/HVO",
                  S39="Manutenção e engenharia (nuclear)",
                  S29="Siderurgia verde",
                  S28="Cimento verde")

for (s in names(allocations)) {
  cat(sprintf("  %-6s  %-40s  %8.2f  %5.1f%%\n",
      s, sector_names[s], allocations[[s]], 100*allocations[[s]]/tot))
}
cat(sprintf("\n  TOTAL                                            %8.2f  100.0%%\n", tot))
