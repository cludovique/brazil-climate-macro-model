setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
library(readxl)
options(OutDec=".")

MMA_PATH <- "data/raw/Planilha_Detalhamento Resultados MMA-SMC v3 AR5 (07_10_2024).xlsx"
all_sheets <- excel_sheets(MMA_PATH)
cat("Sheets:", paste(seq_along(all_sheets), all_sheets, sep="="), sep="\n  "); cat("\n\n")

read_raw <- function(idx) suppressMessages(read_excel(MMA_PATH, sheet=all_sheets[idx], col_names=FALSE))

# ── Sheet 10: Custos ─────────────────────────────────────────────────────────
cat("=== SHEET 10 (Custos) — primeiras 30 linhas ===\n")
cu <- read_raw(10)
for (i in 1:min(30, nrow(cu))) {
  row_vals <- paste(sapply(1:min(15, ncol(cu)), function(j) {
    v <- cu[[i,j]]
    if (is.na(v) || v=="") "." else substr(as.character(v),1,18)
  }), collapse="  |  ")
  cat(sprintf("  R%02d  %s\n", i, row_vals))
}

# ── Sheet 4: Energia — rows with investment / capacity info ─────────────────
cat("\n=== SHEET 4 (Energia) — rows 48-80 (capacidade instalada/expansão) ===\n")
en <- read_raw(4)
for (i in 48:min(80, nrow(en))) {
  v1 <- as.character(en[[i,1]]); v2 <- as.character(en[[i,2]]); v3 <- as.character(en[[i,3]])
  if (!is.na(v1) && nchar(trimws(v1))>0) {
    vals <- paste(sapply(c(3,5,6,7,12,13,14), function(j) {
      v <- en[[i,j]]; if(is.na(v)||v=="") "." else substr(as.character(round(as.numeric(v),3)),1,8)
    }), collapse="  ")
    cat(sprintf("  R%02d  %-35s  [base/25D: %s]\n", i, substr(paste(v1,v2),1,35), vals))
  }
}

# ── Sheet 5: Indústria — rows with investment/cost info ──────────────────────
cat("\n=== SHEET 5 (Indústria) — all labeled rows ===\n")
ind <- read_raw(5)
for (i in 1:min(nrow(ind), 80)) {
  v1 <- as.character(ind[[i,1]]); v2 <- as.character(ind[[i,2]])
  if (!is.na(v1) && nchar(trimws(v1))>0 && !grepl("^NA$",v1)) {
    vals <- paste(sapply(c(3,5,6,12,13), function(j) {
      v <- ind[[i,j]]; if(is.na(v)||v=="") "." else substr(as.character(v),1,10)
    }), collapse="  ")
    cat(sprintf("  R%02d  %-15s  %-30s  [%s]\n", i,
        substr(v1,1,15), substr(ifelse(is.na(v2),"",v2),1,30), vals))
  }
}

# ── Sheet 6: Transporte ───────────────────────────────────────────────────────
cat("\n=== SHEET 6 (Transporte) — all labeled rows ===\n")
tr <- read_raw(6)
for (i in 1:min(nrow(tr), 50)) {
  v1 <- as.character(tr[[i,1]]); v2 <- as.character(tr[[i,2]])
  if (!is.na(v1) && nchar(trimws(v1))>0 && !grepl("^NA$",v1)) {
    vals <- paste(sapply(c(3,5,6,12,13), function(j) {
      v <- tr[[i,j]]; if(is.na(v)||v=="") "." else substr(as.character(v),1,10)
    }), collapse="  ")
    cat(sprintf("  R%02d  %-15s  %-30s  [%s]\n", i,
        substr(v1,1,15), substr(ifelse(is.na(v2),"",v2),1,30), vals))
  }
}
