setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
res  <- readRDS("data/processed/mma_shocks.rds")
ra   <- res[["res_all"]]
x_s19 <- 433811
options(OutDec=".")

s19_100 <- ra[ra[["cenario"]]=="100D" & ra[["ano"]]==2050 & ra[["cod"]]=="S19",]
s19_0D  <- ra[ra[["cenario"]]=="0D"  & ra[["ano"]]==2050 & ra[["cod"]]=="S19",]

cat("=== S19 Derivados de Petroleo — full picture 100D 2050 ===\n\n")
cat(sprintf("x[S19] base 2018                  = R$ %10.0f M\n", x_s19))
cat(sprintf("delta_x_baseline (GDP growth)     = R$ %+10.0f M  <- petroleum would GROW this much without transition\n",
    s19_100[["delta_x_baseline"]]))
cat(sprintf("delta_x_transition (the chart bar)= R$ %+10.0f M  <- transition REDUCES that growth\n",
    s19_100[["delta_x_transition"]]))
x_2050_100 <- x_s19 + s19_100[["delta_x_baseline"]] + s19_100[["delta_x_transition"]]
x_2050_0D  <- x_s19 + s19_0D[["delta_x_baseline"]]  + s19_0D[["delta_x_transition"]]
cat(sprintf("x[S19] implied at 100D 2050       = R$ %10.0f M  (%.0f%% of 2018 base)\n",
    x_2050_100, 100*x_2050_100/x_s19))
cat(sprintf("x[S19] implied at 0D 2050         = R$ %10.0f M  (%.0f%% of 2018 base — no transition)\n\n",
    x_2050_0D,  100*x_2050_0D/x_s19))
cat("CONCLUSION: S19 does NOT collapse — it still GROWS +27% from 2018.\n")
cat("The -R$161B transition effect = FOREGONE GROWTH vs GDP baseline,\n")
cat("not absolute production decline.\n")
cat(sprintf("In the no-transition (0D) world S19 would reach R$ %.0f M (%.0f%% of 2018).\n",
    x_2050_0D, 100*x_2050_0D/x_s19))
