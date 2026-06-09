setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

CEN <- "100D"
YRS <- c("2025","2030","2035","2040","2045","2050")

# Pre-compute A_star for all years once
A_stars <- lapply(YRS, function(y) engine2_A_star(CEN, y))
names(A_stars) <- YRS

# All industrial sectors (all groups)
IND_ALL <- unique(c(GRUPOS$ind_aco, GRUPOS$ind_cimento,
                    GRUPOS$ind_quimico, GRUPOS$ind_outros))

get_grupo <- function(j) {
  for (g in c("ind_aco","ind_cimento","ind_quimico","ind_outros"))
    if (j %in% GRUPOS[[g]]) return(g)
  return("(none)")
}

cat("==========================================================================\n")
cat(" INDÚSTRIA DE TRANSFORMAÇÃO — visão geral completa (100D)\n")
cat("==========================================================================\n\n")

cat("LEGENDA:\n")
cat("  Fóssil = A[S19,j] + A[S43,j]   |  Bio = A[S22,j]   |  Elec = A[S40,j]+A[S41,j]\n")
cat("  Δ% = variação vs base 2018 no ano indicado\n\n")

# ── Section 1: Scale factors from MMA ─────────────────────────────────────
cat("--- [1] FATORES DE ESCALA MMA 100D por sub-grupo ---\n")
cat(sprintf("  %-10s  %-8s  %5s  %5s  %5s  %5s  %5s  %5s\n",
    "Grupo","Fonte","2025","2030","2035","2040","2045","2050"))
cat(strrep("-",65),"\n")

sc_row <- function(label, pct_list, base0, cen="100D") {
  sc <- sapply(YRS, function(y) if(base0>1e-6) pct_list[[cen]][y]/base0 else NA)
  cat(sprintf("  %-10s  %-8s  %s\n", label, "",
      paste(sprintf("%5.2f", sc), collapse="  ")))
}

cat("  químico:\n")
sc_row("",foss_qui_pct,foss_qui_2020); cat(sprintf("    foss base=%.3f\n",foss_qui_2020))
sc_row("",bio_qui_pct, bio_qui_2020);  cat(sprintf("    bio  base=%.3f\n",bio_qui_2020))
sc_row("",elec_qui_pct,elec_qui_2020); cat(sprintf("    elec base=%.3f\n",elec_qui_2020))

cat("  outros:\n")
sc_row("",foss_out_pct,foss_out_2020); cat(sprintf("    foss base=%.3f\n",foss_out_2020))
sc_row("",bio_out_pct, bio_out_2020);  cat(sprintf("    bio  base=%.3f\n",bio_out_2020))
sc_row("",elec_out_pct,elec_out_2020); cat(sprintf("    elec base=%.3f\n",elec_out_2020))

cat("  ferro/aço:\n")
sc_row("",foss_ferro_pct,foss_ferro_2020); cat(sprintf("    foss base=%.3f\n",foss_ferro_2020))
sc_row("",bio_ferro_pct, bio_ferro_2020);  cat(sprintf("    bio  base=%.3f\n",bio_ferro_2020))
sc_row("",elec_ferro_pct,elec_ferro_2020); cat(sprintf("    elec base=%.3f\n",elec_ferro_2020))

cat("  cimento:\n")
sc_row("",foss_cim_pct,foss_cim_2020); cat(sprintf("    foss base=%.3f\n",foss_cim_2020))
sc_row("",bio_cim_pct, bio_cim_2020);  cat(sprintf("    bio  base=%.3f\n",bio_cim_2020))
sc_row("",elec_cim_pct,elec_cim_2020); cat(sprintf("    elec base=%.3f\n",elec_cim_2020))

# ── Section 2: Full coefficient table per sector ──────────────────────────
cat("\n--- [2] COEFICIENTES BASE E TRAJETÓRIA 100D (por setor) ---\n\n")

for (j in IND_ALL) {
  grp <- get_grupo(j)
  nm  <- setores$nome[setores$cod==j]

  # Base values
  foss_b <- A["S19",j] + A["S43",j]
  bio_b  <- A["S22",j]
  elec_b <- A["S40",j] + ifelse("S41" %in% rownames(A), A["S41",j], 0)
  tot_b  <- foss_b + bio_b + elec_b

  # Flag: is S22 likely feedstock rather than energy?
  # Heuristic: if A[S22,j] > 2 × (A[S19,j]+A[S43,j]) → feedstock-dominated
  feedstock_flag <- if (foss_b > 1e-6 && bio_b > 2*foss_b) " *** BIO>2×FOSSIL (feedstock?)" else ""

  cat(sprintf("  %-6s  %-42s  [%s]%s\n", j, nm, grp, feedstock_flag))
  cat(sprintf("  %6s  %-10s  %8s  %8s  %8s  %8s  | %8s\n",
      "","Ano","Fóssil","Bio(S22)","Elec","Total","Bio/Foss"))
  cat(sprintf("  %6s  %-10s  %8.5f  %8.5f  %8.5f  %8.5f  | %8s\n",
      "","Base",foss_b,bio_b,elec_b,tot_b,
      if(foss_b>1e-6) sprintf("%.2fx",bio_b/foss_b) else "—"))

  for (yr in YRS) {
    As    <- A_stars[[yr]]
    foss_t <- As["S19",j] + As["S43",j]
    bio_t  <- As["S22",j]
    elec_t <- As["S40",j] + ifelse("S41" %in% rownames(As), As["S41",j], 0)
    tot_t  <- foss_t + bio_t + elec_t

    dpf <- if(foss_b>1e-6) sprintf("%+.0f%%", 100*(foss_t/foss_b-1)) else "n/a"
    dpb <- if(bio_b >1e-6) sprintf("%+.0f%%", 100*(bio_t /bio_b -1)) else
           if(bio_t>1e-6)  sprintf("+NEW")    else "—"
    dpe <- if(elec_b>1e-6) sprintf("%+.0f%%", 100*(elec_t/elec_b-1)) else "—"

    cat(sprintf("  %6s  %-10s  %8.5f  %8.5f  %8.5f  %8.5f  | f%s b%s e%s\n",
        "", yr, foss_t, bio_t, elec_t, tot_t, dpf, dpb, dpe))
  }
  cat("\n")
}

# ── Section 3: Red flags summary ──────────────────────────────────────────
cat("--- [3] ALERTAS — sectores com comportamento suspeito ---\n\n")

for (j in IND_ALL) {
  issues <- c()
  As_2025 <- A_stars[["2025"]]
  As_2050 <- A_stars[["2050"]]

  foss_b  <- A["S19",j]+A["S43",j]
  bio_b   <- A["S22",j]
  foss_25 <- As_2025["S19",j]+As_2025["S43",j]
  bio_25  <- As_2025["S22",j]
  foss_50 <- As_2050["S19",j]+As_2050["S43",j]
  bio_50  <- As_2050["S22",j]

  # Fossil increases in 2025
  if (foss_b > 1e-5 && foss_25 > foss_b * 1.05)
    issues <- c(issues, sprintf("fossil +%.0f%% in 2025", 100*(foss_25/foss_b-1)))

  # Bio goes to zero when it was non-trivial
  if (bio_b > 0.005 && bio_25 < 1e-6)
    issues <- c(issues, sprintf("bio ZERO in 2025 (was %.4f)", bio_b))

  # Bio is likely feedstock, not energy
  if (foss_b > 1e-6 && bio_b > 2*foss_b)
    issues <- c(issues, sprintf("A[S22]=%.4f >> A[foss]=%.4f — feedstock?", bio_b, foss_b))

  # Bio explodes at 2050
  if (bio_b > 1e-6 && bio_50 > 10*bio_b)
    issues <- c(issues, sprintf("bio ×%.0f by 2050", bio_50/bio_b))
  if (bio_b < 1e-6 && bio_50 > 0.005)
    issues <- c(issues, sprintf("bio created from zero → %.4f by 2050", bio_50))

  if (length(issues) > 0) {
    nm <- substr(setores$nome[setores$cod==j],1,38)
    grp <- get_grupo(j)
    cat(sprintf("  %-6s  %-38s  [%s]\n", j, nm, grp))
    for (iss in issues) cat(sprintf("    ⚠  %s\n", iss))
    cat("\n")
  }
}
cat("(sem mais alertas)\n")
