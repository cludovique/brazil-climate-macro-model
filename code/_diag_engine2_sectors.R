# Diagnostic: Engine 2 — which sectors are affected, and by how much
# Shows A* vs A for fossil/biomass/electric rows, 100D 2050
setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
SOURCE_MODE <- TRUE
source("code/mip_epe_replication.R")
source("code/mma_shock_engines.R")
options(OutDec=".")

CEN <- "100D"; ANO <- 2050

# Get A* for 100D 2050
A_star <- engine2_A_star(CEN, ANO)

FOSSIL_ROWS  <- intersect(c("S19","S43"), rownames(A))
BIO_ROWS     <- intersect(c("S20","S22"), rownames(A))
ELEC_ROWS    <- intersect(c("S40","S41"), rownames(A))

get_sum <- function(mat, rows, col) sum(mat[intersect(rows, rownames(mat)), col], na.rm=TRUE)

# Build comparison table for all 73 sectors
rows <- lapply(setores$cod, function(j) {
  foss_base <- get_sum(A,      FOSSIL_ROWS, j)
  foss_new  <- get_sum(A_star, FOSSIL_ROWS, j)
  bio_base  <- get_sum(A,      BIO_ROWS,    j)
  bio_new   <- get_sum(A_star, BIO_ROWS,    j)
  elec_base <- get_sum(A,      ELEC_ROWS,   j)
  elec_new  <- get_sum(A_star, ELEC_ROWS,   j)
  # also check col changes (S19 as consumer of inputs)
  s05_base  <- if ("S05" %in% rownames(A)) A["S05", j] else 0
  s05_new   <- if ("S05" %in% rownames(A_star)) A_star["S05", j] else 0
  data.frame(
    cod=j,
    nome=substr(setores$nome[setores$cod==j],1,35),
    foss_base=round(foss_base,5), foss_new=round(foss_new,5),
    d_foss=round(foss_new-foss_base,5),
    bio_base=round(bio_base,5),  bio_new=round(bio_new,5),
    d_bio=round(bio_new-bio_base,5),
    elec_base=round(elec_base,5),elec_new=round(elec_new,5),
    d_elec=round(elec_new-elec_base,5),
    s05_base=round(s05_base,5),  s05_new=round(s05_new,5),
    d_s05=round(s05_new-s05_base,5),
    stringsAsFactors=FALSE
  )
})
tbl <- do.call(rbind, rows)
changed <- tbl[abs(tbl$d_foss)>1e-5 | abs(tbl$d_bio)>1e-5 |
               abs(tbl$d_elec)>1e-5 | abs(tbl$d_s05)>1e-5, ]
changed <- changed[order(abs(changed$d_foss)+abs(changed$d_bio)+abs(changed$d_elec), decreasing=TRUE),]

cat("=== ENGINE 2 AFFECTED SECTORS: A* vs A baseline (100D, 2050) ===\n")
cat("Only sectors with any coefficient change > 1e-5 shown\n\n")
cat(sprintf("%-6s  %-35s  %8s  %8s  %8s  %8s  %8s  %8s\n",
    "Cod","Nome","d_foss","d_bio","d_elec","foss_new","bio_new","elec_new"))
cat(strrep("-",95),"\n")
for (i in seq_len(nrow(changed))) {
  r <- changed[i,]
  cat(sprintf("%-6s  %-35s  %+8.5f  %+8.5f  %+8.5f  %8.5f  %8.5f  %8.5f\n",
      r$cod, r$nome,
      r$d_foss, r$d_bio, r$d_elec,
      r$foss_new, r$bio_new, r$elec_new))
}
cat(sprintf("\nTotal sectors changed: %d / %d\n", nrow(changed), nrow(tbl)))

# Separate: S19 column detail (S19 as consumer)
cat("\n=== S19 COLUMN: inputs INTO the refinery sector ===\n")
s19_col <- sort(abs(A_star[,"S19"] - A[,"S19"]), decreasing=TRUE)
s19_col <- s19_col[s19_col > 1e-6]
cat(sprintf("%-6s  %-38s  %10s  %10s  %+10s\n","Cod","Nome","A_base","A_star","delta"))
cat(strrep("-",78),"\n")
for (r in names(s19_col)) {
  nm <- substr(setores$nome[setores$cod==r],1,38)
  cat(sprintf("%-6s  %-38s  %10.5f  %10.5f  %+10.5f\n",
      r, nm, A[r,"S19"], A_star[r,"S19"], A_star[r,"S19"]-A[r,"S19"]))
}

# Group summary
cat("\n=== GROUP SUMMARY: total absolute A* change by group ===\n")
groups_def <- list(
  "Energia Fóssil (S05,S19,S21,S43)" = c("S05","S19","S21","S43"),
  "Energia Renovável (S20,S22)"       = c("S20","S22"),
  "Eletricidade (S40,S41,S42)"        = c("S40","S41","S42"),
  "Indústria pesada (S28,S29)"        = c("S28","S29"),
  "Transporte (S48-S51)"              = c("S48","S49","S50","S51"),
  "Cidades (S52,S53,S59,S66-S70)"     = c("S52","S53","S59","S66","S67","S68","S69","S70"),
  "Indústria geral"                   = GRUPOS$industria
)
for (gname in names(groups_def)) {
  gcods <- intersect(groups_def[[gname]], setores$cod)
  tot_chg <- sum(abs(A_star[,gcods] - A[,gcods]), na.rm=TRUE)
  n_chg   <- sum(colSums(abs(A_star[,gcods,drop=FALSE] - A[,gcods,drop=FALSE])) > 1e-5)
  cat(sprintf("  %-42s  %d sectors touched  total |ΔA| = %.4f\n",
      gname, n_chg, tot_chg))
}

cat("\n=== S19 specific: A[S22,S19] biomass complement ===\n")
cat(sprintf("  A[S22,S19] base  = %.5f\n", A["S22","S19"]))
cat(sprintf("  A[S22,S19] A*    = %.5f\n", A_star["S22","S19"]))
cat(sprintf("  delta            = %+.5f\n", A_star["S22","S19"] - A["S22","S19"]))
cat(sprintf("  A[S05,S19] base  = %.5f\n", A["S05","S19"]))
cat(sprintf("  A[S05,S19] A*    = %.5f\n", A_star["S05","S19"]))
cat(sprintf("  coprocessamento fraction = %.1f%%\n",
    (1 - A_star["S05","S19"]/A["S05","S19"])*100))
