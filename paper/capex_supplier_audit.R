# =============================================================================
# ERL PAPER — CAPEX PURCHASER–SUPPLIER AUDIT
# =============================================================================
# Purpose:
#   Separate the sector that operates a transition asset from the sectors that
#   produce/build the capital asset. The current investment mapping occasionally
#   allocates CAPEX directly to sectors that are also hard-constrained by the NDC
#   production pathway (notably S42 transmission and S19 refining).
#
# Diagnostic alternative:
#   - preserve the existing technology-level CAPEX quantum;
#   - preserve the existing set of supplier sectors and their relative weights;
#   - remove operating/constrained sectors from each technology's CAPEX bundle;
#   - renormalize the remaining supplier weights to 100%.
#
# This is deliberately a diagnostic. It introduces no new supplier sectors and
# does not claim that the retained weights are final empirical investment
# structures. It tests whether operator-sector CAPEX assignment is driving the
# hard-constraint result.
# =============================================================================

options(scipen = 12, OutDec = ".")
repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = "")
if (!nzchar(repo_root)) {
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(script_arg)) {
    script_path <- normalizePath(sub("^--file=", "", script_arg[1]), mustWork = FALSE)
    repo_root <- dirname(dirname(script_path))
  } else repo_root <- getwd()
}
setwd(repo_root)
outdir <- file.path("paper", "results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# Source current paper-branch model.
model_text <- readLines("code/mma_shock_engines.R", warn = FALSE, encoding = "UTF-8")
model_text <- gsub(
  'setwd\\("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model"\\)',
  'setwd(Sys.getenv("GITHUB_WORKSPACE", unset=getwd()))',
  model_text
)
eval(parse(text = paste(model_text, collapse = "\n")), envir = .GlobalEnv)

all_sector_gdp_shock <- function(ano) {
  g <- gdp_rel_2018[as.character(ano)]
  out <- f_base * (g - 1)
  names(out) <- setores$cod
  out
}
calc_va <- function(dx) sum(sat_gdp[setores$cod] * dx, na.rm = TRUE)
calc_output <- function(dx) sum(dx, na.rm = TRUE)

# ---- Supplier-only investment allocation ------------------------------------
# Shares below come directly from the current technology mappings. When an
# operating/constrained sector is removed, remaining shares are renormalized.
renorm <- function(x) x / sum(x)

W <- list(
  wind = renorm(c(S34=.50, S45=.30, S33=.05, S39=.05)),          # S42 .10 removed
  solar = renorm(c(S32=.40, S45=.30, S33=.15, S39=.05)),        # S42 .10 removed
  hydro = renorm(c(S45=.60, S30=.25)),                           # S42 .15 removed
  nuclear = c(S34=.30, S45=.70),
  bioccs = c(S34=.10, S45=.55, S33=.10, S30=.20, S39=.05),
  battery = c(S32=.60, S33=.40),
  biofuel = c(S34=.18, S45=.52, S30=.30),
  copro = renorm(c(S45=.35, S33=.15, S27=.10)),                  # S19 .40 removed
  ev = c(S35=.40, S36=.40, S33=.20),
  buildings = c(S45=.55, S33=.20, S32=.15, S39=.10),
  lulucf = c(S03=.60, S01=.20, S45=.20)
)

.inv_raw_vec_supplier <- function(cenario, ano) {
  cc <- yr_col_mma(cenario, ano)
  pc <- prev_col_mma(cenario, ano)
  ge <- function(r, col) { v <- suppressWarnings(as.numeric(en[[r, col]])); if(is.na(v)) 0 else v }
  gt <- function(r, col) { v <- suppressWarnings(as.numeric(tr[[r, col]])); if(is.na(v)) 0 else v }
  gc <- function(r, col) { v <- suppressWarnings(as.numeric(ci[[r, col]])); if(is.na(v)) 0 else v }
  gl <- function(r, col) { v <- suppressWarnings(as.numeric(lu[[r, col]])); if(is.na(v)) 0 else v }

  d_eol    <- max(ge(51,cc) - ge(51,pc), 0)
  d_sol    <- max(ge(52,cc) - ge(52,pc), 0)
  d_hid    <- max(ge(53,cc) - ge(53,pc), 0)
  d_nuc    <- max(ge(56,cc) - ge(56,pc), 0)
  d_bioccs <- max(ge(55,cc) - ge(55,pc), 0)
  d_bat    <- max(ge(58,cc) - ge(58,pc), 0)

  inv <- list(
    wind    = d_eol * 1200,
    solar   = d_sol * 700,
    hydro   = d_hid * 2500,
    nuclear = d_nuc * 8000,
    bioccs  = d_bioccs * 2500,
    battery = d_bat * 300
  )

  bfuel_pj_delta <- max(
    (ge(79,cc)+ge(78,cc)+ge(80,cc)+ge(77,cc)+ge(81,cc)) -
    (ge(79,pc)+ge(78,pc)+ge(80,pc)+ge(77,pc)+ge(81,pc)), 0)
  inv$biofuel <- bfuel_pj_delta * 40
  inv$copro <- (max(ge(78,cc)-ge(78,pc),0) + max(ge(76,cc)-ge(76,pc),0)) * 15
  inv$ev <- max(gt(13,cc)*gt(14,cc) - gt(13,pc)*gt(14,pc), 0) * 15
  inv$buildings <- max(gc(26,cc) - gc(26,pc), 0) * 30000
  inv$lulucf <- max(gl(36,cc), 0) * 3.0 + max(gl(37,cc), 0) * 1.5

  raw <- setNames(numeric(0), character(0))
  add <- function(vec, amount) {
    if (!is.finite(amount) || amount == 0) return()
    for (s in names(vec)) raw[s] <<- (ifelse(is.na(raw[s]), 0, raw[s])) + amount * vec[s]
  }
  for (nm in names(inv)) add(W[[nm]], inv[[nm]])

  # Preserve the current model's cross-technology digital/engineering add-ons.
  # These are supplier services and are not NDC-constrained operating sectors.
  raw["S57"] <- ifelse(is.na(raw["S57"]),0,raw["S57"]) +
    (inv$wind+inv$solar+inv$hydro+inv$battery)*0.04 + inv$buildings*0.06
  raw["S61"] <- ifelse(is.na(raw["S61"]),0,raw["S61"]) +
    (inv$wind+inv$solar+inv$hydro+inv$bioccs+inv$biofuel+inv$copro+inv$nuclear)*0.04 + inv$buildings*0.05

  raw <- raw[names(raw) %in% setores$cod]
  raw[is.na(raw)] <- 0
  raw
}

ALOC_INV_SUPPLIER <- setNames(lapply(CENS_MMA, function(cen)
  setNames(lapply(ANOS_MMA, function(a) {
    raw <- .inv_raw_vec_supplier(cen, a)
    if (sum(raw) < 1e-6) raw <- raw + 1e-6
    raw / sum(raw)
  }), ANOS_MMA)
), CENS_MMA)

engine1_inv_supplier <- function(cenario, ano) {
  a <- as.character(ano)
  out <- setNames(numeric(N), setores$cod)
  inv_bi <- INV_ANNUAL[[cenario]][[a]]
  if (is.null(inv_bi) || inv_bi == 0) return(out)
  aloc <- ALOC_INV_SUPPLIER[[cenario]][[a]]
  inv_RM <- inv_bi * 1000
  for (cod in names(aloc)) {
    dc <- if (cod %in% names(DOM_CONTENT)) DOM_CONTENT[cod] else 1
    out[cod] <- out[cod] + inv_RM * aloc[cod] * dc
  }
  out
}

hard_solution <- function(ano, investment_fun) {
  cen <- "100D"
  A_star <- engine2_A_star(cen, ano)
  L_star <- solve(diag(N) - A_star)
  C <- intersect(ENGINE3_SECTORS, setores$cod)
  df_gdp <- all_sector_gdp_shock(ano)
  df_inv <- investment_fun(cen, ano)
  dx_base <- as.vector(L %*% df_gdp); names(dx_base) <- setores$cod
  dx_rewire <- as.vector(L_star %*% df_gdp); names(dx_rewire) <- setores$cod
  dx_un <- as.vector(L_star %*% (df_gdp + df_inv)); names(dx_un) <- setores$cod
  dx_target <- engine3_delta_x(cen, ano); names(dx_target) <- setores$cod
  gap <- dx_target[C] - dx_un[C]
  g_C <- as.vector(solve(L_star[C,C,drop=FALSE], gap)); names(g_C) <- C
  adj <- as.vector(L_star[,C,drop=FALSE] %*% g_C); names(adj) <- setores$cod
  dx_con <- dx_un + adj
  list(C=C, dx_base=dx_base, dx_rewire=dx_rewire, dx_un=dx_un,
       target=dx_target, g_C=g_C, adj=adj, dx_con=dx_con, df_inv=df_inv)
}

years <- c(2025,2030,2035,2040,2045,2050)
agg <- list(); sectors_out <- list(); maps <- list()
for (yr in years) {
  old <- hard_solution(yr, engine1_inv)
  sup <- hard_solution(yr, engine1_inv_supplier)

  agg[[as.character(yr)]] <- data.frame(
    year=yr,
    current_mapping_unconstrained_va_Rbn=(calc_va(old$dx_un)-calc_va(old$dx_base))/1000,
    current_mapping_constraint_adj_va_Rbn=(calc_va(old$dx_con)-calc_va(old$dx_un))/1000,
    current_mapping_final_va_Rbn=(calc_va(old$dx_con)-calc_va(old$dx_base))/1000,
    supplier_mapping_unconstrained_va_Rbn=(calc_va(sup$dx_un)-calc_va(sup$dx_base))/1000,
    supplier_mapping_constraint_adj_va_Rbn=(calc_va(sup$dx_con)-calc_va(sup$dx_un))/1000,
    supplier_mapping_final_va_Rbn=(calc_va(sup$dx_con)-calc_va(sup$dx_base))/1000,
    supplier_mapping_final_output_Rbn=(calc_output(sup$dx_con)-calc_output(sup$dx_base))/1000
  )

  for (cod in sup$C) {
    j <- match(cod,setores$cod)
    sectors_out[[length(sectors_out)+1]] <- data.frame(
      year=yr,cod=cod,sector=setores$nome[j],
      current_unconstrained_dx_Rbn=old$dx_un[cod]/1000,
      supplier_unconstrained_dx_Rbn=sup$dx_un[cod]/1000,
      ndc_target_dx_Rbn=sup$target[cod]/1000,
      current_required_adjustment_Rbn=(old$target[cod]-old$dx_un[cod])/1000,
      supplier_required_adjustment_Rbn=(sup$target[cod]-sup$dx_un[cod])/1000,
      supplier_balancing_final_demand_Rbn=sup$g_C[cod]/1000
    )
  }

  oldw <- ALOC_INV[["100D"]][[as.character(yr)]]
  neww <- ALOC_INV_SUPPLIER[["100D"]][[as.character(yr)]]
  allc <- union(names(oldw),names(neww))
  for (cod in allc) maps[[length(maps)+1]] <- data.frame(
    year=yr,cod=cod,sector=setores$nome[match(cod,setores$cod)],
    current_share=ifelse(cod %in% names(oldw),oldw[cod],0),
    supplier_share=ifelse(cod %in% names(neww),neww[cod],0),
    share_change=ifelse(cod %in% names(neww),neww[cod],0)-ifelse(cod %in% names(oldw),oldw[cod],0)
  )
}

agg_df <- do.call(rbind,agg)
sec_df <- do.call(rbind,sectors_out)
map_df <- do.call(rbind,maps)
write.csv(agg_df,file.path(outdir,"capex_supplier_aggregate.csv"),row.names=FALSE)
write.csv(sec_df,file.path(outdir,"capex_supplier_constrained_sectors.csv"),row.names=FALSE)
write.csv(map_df,file.path(outdir,"capex_supplier_mapping.csv"),row.names=FALSE)

# concise report
fmt <- function(x,d=1) format(round(x,d),big.mark=",",scientific=FALSE,trim=TRUE)
a <- agg_df[agg_df$year==2050,]
s <- sec_df[sec_df$year==2050,]
getsec <- function(cod,col) s[s$cod==cod,col]
report <- c(
  "# CAPEX purchaser–supplier audit",
  "",
  "This diagnostic separates **asset operators** from **capital-goods suppliers** while preserving the current technology CAPEX totals and existing supplier categories.",
  "Operating sectors that are also subject to NDC physical constraints are removed from the CAPEX allocation and their technology-specific shares are redistributed proportionally across the remaining supplier sectors.",
  "",
  "## What changed",
  "",
  "- Wind and solar: the current S42 transmission share is redistributed across the existing machinery, electrical-equipment, construction and installation suppliers.",
  "- Hydro: the current S42 share is redistributed across construction and metal-products suppliers.",
  "- Refinery co-processing: the current S19 refinery-operator share is redistributed across the existing construction, electrical-equipment and rubber/plastics suppliers.",
  "- No new supplier sector or new technology CAPEX quantum is introduced in this diagnostic.",
  "",
  "## 2050 hard-constraint comparison",
  "",
  sprintf("- Current CAPEX mapping: unconstrained VA differential **R$ %s bn**; NDC consistency adjustment **R$ %s bn**; final hard-constrained differential **R$ %s bn**.",fmt(a$current_mapping_unconstrained_va_Rbn),fmt(a$current_mapping_constraint_adj_va_Rbn),fmt(a$current_mapping_final_va_Rbn)),
  sprintf("- Supplier-only CAPEX mapping: unconstrained VA differential **R$ %s bn**; NDC consistency adjustment **R$ %s bn**; final hard-constrained differential **R$ %s bn**.",fmt(a$supplier_mapping_unconstrained_va_Rbn),fmt(a$supplier_mapping_constraint_adj_va_Rbn),fmt(a$supplier_mapping_final_va_Rbn)),
  sprintf("- Final supplier-only gross-output differential: **R$ %s bn**.",fmt(a$supplier_mapping_final_output_Rbn)),
  "",
  "## Selected constrained sectors, 2050",
  "",
  sprintf("- S42 Transmission: unconstrained change falls from **R$ %s bn** under the current mapping to **R$ %s bn** under supplier-only CAPEX; NDC target **R$ %s bn**.",fmt(getsec("S42","current_unconstrained_dx_Rbn")),fmt(getsec("S42","supplier_unconstrained_dx_Rbn")),fmt(getsec("S42","ndc_target_dx_Rbn"))),
  sprintf("- S19 Refining: unconstrained change falls from **R$ %s bn** to **R$ %s bn**; NDC target **R$ %s bn**.",fmt(getsec("S19","current_unconstrained_dx_Rbn")),fmt(getsec("S19","supplier_unconstrained_dx_Rbn")),fmt(getsec("S19","ndc_target_dx_Rbn"))),
  sprintf("- S05 Oil and gas extraction: unconstrained change shifts from **R$ %s bn** to **R$ %s bn**; NDC target **R$ %s bn**.",fmt(getsec("S05","current_unconstrained_dx_Rbn")),fmt(getsec("S05","supplier_unconstrained_dx_Rbn")),fmt(getsec("S05","ndc_target_dx_Rbn"))),
  "",
  "## Interpretation",
  "",
  "If the NDC consistency penalty becomes materially smaller, part of the previous negative hard-constraint adjustment was caused by assigning investment demand to the operating sectors whose production was subsequently constrained. If the aggregate result remains similar, the negative adjustment is primarily structural and comes from the NDC physical trajectories themselves rather than CAPEX double counting.",
  "",
  "This diagnostic should be replaced by empirically documented investment structures before the manuscript is frozen."
)
writeLines(report,file.path(outdir,"capex_supplier_audit.md"),useBytes=TRUE)
cat("CAPEX supplier audit complete.\n")
