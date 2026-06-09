setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

cat("--- S25 e S26 pos-correcao 100D ---\n")
for (j in c("S25","S26")) {
  cat(sprintf("\n%s — %s\n", j, setores$nome[setores$cod==j]))
  cat(sprintf("  %-6s  %8s  %8s  %8s  | notes\n","Ano","Fossil","Bio(S22)","Elec"))
  fb <- A["S19",j]+A["S43",j]; bb <- A["S22",j]; eb <- A["S40",j]
  cat(sprintf("  %-6s  %8.5f  %8.5f  %8.5f  (BASE 2018)\n","Base",fb,bb,eb))
  for (yr in c("2025","2030","2035","2040","2045","2050")) {
    As <- engine2_A_star("100D", yr)
    ft <- As["S19",j]+As["S43",j]; bt <- As["S22",j]; et <- As["S40",j]
    df <- if(fb>1e-6) sprintf("f%+.0f%%",100*(ft/fb-1)) else ""
    db <- if(bb>1e-6) sprintf("b%+.0f%%",100*(bt/bb-1)) else ""
    cat(sprintf("  %-6s  %8.5f  %8.5f  %8.5f  | %s %s\n",yr,ft,bt,et,df,db))
  }
}
