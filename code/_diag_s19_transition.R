setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

CEN <- "100D"; ANO <- "2050"

cat("=== S19 transition effect decomposition — 100D 2050 ===\n\n")

# ── 1. x[S19] base 2018 ─────────────────────────────────────────────────────
x_s19 <- x[names(x)=="S19"]
cat(sprintf("x[S19] base 2018 = R$ %.0f M\n\n", x_s19))

# ── 2. Engine 3 shock to S19 directly ───────────────────────────────────────
cat("--- Engine 3: physical production calibration ---\n")
dt_2020 <- deriv_total_2020
dd_100D <- deriv_dom[["100D"]][ANO]; de_100D <- deriv_exp[["100D"]][ANO]
dt_100D <- dd_100D + de_100D
ratio_s19 <- dt_100D / dt_2020
delta_x_e3_s19 <- x_s19 * (ratio_s19 - 1)
cat(sprintf("  deriv_total 2020 base   = %8.0f ktep\n", dt_2020))
cat(sprintf("  deriv_dom+exp 100D 2050 = %8.0f ktep\n", dt_100D))
cat(sprintf("  ratio = %.4f (%.1f%% of 2020 base)\n", ratio_s19, 100*ratio_s19))
cat(sprintf("  Engine 3 delta_x[S19]   = R$ %+.0f M  (%.1f%% of x_base)\n\n",
    delta_x_e3_s19, 100*delta_x_e3_s19/x_s19))

# ── 3. Engine 2: coefficient changes affecting S19 demand ─────────────────
cat("--- Engine 2: top sectors reducing A[S19,j] ---\n")
A_star_100D <- engine2_A_star(CEN, ANO)
delta_A_s19 <- A_star_100D["S19",] - A["S19",]
movers <- sort(delta_A_s19[abs(delta_A_s19) > 1e-4])
demand_s19 <- A["S19",] * x
demand_s19_star <- A_star_100D["S19",] * x
cat(sprintf("  %-6s  %-34s  %8s  %8s  %+8s  | %10s  %10s\n",
    "Cod","Nome","A_base","A*","ΔA","Dem_base","Dem*"))
cat(strrep("-",95),"\n")
for (j in names(movers)) {
  nm <- substr(setores$nome[setores$cod==j],1,34)
  cat(sprintf("  %-6s  %-34s  %8.4f  %8.4f  %+8.4f  | %10.0f  %10.0f\n",
      j, nm, A["S19",j], A_star_100D["S19",j], movers[j],
      demand_s19[j], demand_s19_star[j]))
}
total_dem_change <- sum(demand_s19_star) - sum(demand_s19)
cat(sprintf("\n  Total intermediate demand change: %+.0f M R$ (first-order approx)\n\n",
    total_dem_change))

# ── 4. Read results and show full decomposition ────────────────────────────
cat("--- Full dx decomposition from model results ---\n")
res <- readRDS("data/processed/mma_shocks.rds")
cat("RDS structure: "); cat(class(res)); cat(" | names: "); cat(paste(names(res)[1:min(8,length(names(res)))], collapse=", ")); cat("\n")

# Try to get dx values
if (is.data.frame(res)) {
  r100 <- res[res$cenario=="100D" & res$ano==2050,]
  r0D  <- res[res$cenario=="0D"   & res$ano==2050,]
} else if (is.list(res)) {
  cat("List elements: ", paste(names(res), collapse=", "), "\n")
  # Try accessing the main results table
  if ("resultados" %in% names(res)) {
    r100 <- res$resultados[res$resultados$cenario=="100D" & res$resultados$ano==2050,]
    r0D  <- res$resultados[res$resultados$cenario=="0D"   & res$resultados$ano==2050,]
  }
}

if (exists("r100") && nrow(r100) > 0) {
  s19_100D <- r100[r100$cod=="S19",]
  s19_0D   <- r0D[r0D$cod=="S19",]
  if (nrow(s19_100D) > 0) {
    dx_total   <- s19_100D$dx_total[1]
    dx_baseline<- s19_100D$dx_baseline_GDP[1]
    dx_trans   <- s19_100D$dx_transition[1]
    cat(sprintf("  x[S19] 2018 base          = R$ %10.0f M\n", x_s19))
    cat(sprintf("  dx_baseline_GDP (no trans)= R$ %+10.0f M\n", dx_baseline))
    cat(sprintf("  dx_transition (chart bar) = R$ %+10.0f M\n", dx_trans))
    cat(sprintf("  dx_total 100D 2050        = R$ %+10.0f M\n", dx_total))
    cat(sprintf("  x[S19] implied 100D 2050  = R$ %10.0f M  (%.1f%% of 2018)\n",
        x_s19 + dx_total, 100*(x_s19+dx_total)/x_s19))
    if (nrow(s19_0D) > 0)
      cat(sprintf("  x[S19] implied 0D 2050    = R$ %10.0f M  (%.1f%% of 2018)\n",
          x_s19 + s19_0D$dx_total[1], 100*(x_s19+s19_0D$dx_total[1])/x_s19))
  }
}

# ── 5. The key A[S19,S20] issue ───────────────────────────────────────────
cat("\n--- KEY: A[S19,S20] — the dominant channel ───────────────────────────\n")
x_s20 <- x[names(x)=="S20"]
cat(sprintf("  x[S20] base 2018 = R$ %.0f M\n", x_s20))
cat(sprintf("  A[S19,S20] base  = %.5f  → demand = R$ %.0f M\n",
    A["S19","S20"], A["S19","S20"]*x_s20))
cat(sprintf("  A[S19,S20]*      = %.5f  → demand = R$ %.0f M\n",
    A_star_100D["S19","S20"], A_star_100D["S19","S20"]*x_s20))
cat(sprintf("  Demand drop from S20 alone: R$ %.0f M\n",
    (A_star_100D["S19","S20"]-A["S19","S20"])*x_s20))
cat(sprintf("\n  BUT x[S20] at 100D 2050 will be MUCH larger (Engine 3: +diesel verde)\n"))
cat(sprintf("  This amplifies both the base demand AND the coefficient change.\n"))

# ── 6. Summary ────────────────────────────────────────────────────────────
cat("\n=== SUMMARY: WHY S19 LOSES R$150B IN THE TRANSITION ===\n")
cat(sprintf("  1. Engine 3 (physical production)   : R$ %+.0f M  (oil products declining)\n",
    delta_x_e3_s19))
cat(sprintf("  2. Engine 2 (demand coefficients)   : R$ %+.0f M  (every sector buys less)\n",
    total_dem_change))
cat(sprintf("     of which, top 3 channels:\n"))
top3 <- names(sort(delta_A_s19*x)[1:3])
for (j in top3) {
  nm <- substr(setores$nome[setores$cod==j],1,30)
  cat(sprintf("       %-6s %-30s: %+.0f M\n", j, nm, (A_star_100D["S19",j]-A["S19",j])*x[j]))
}
