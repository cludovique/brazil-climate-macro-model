# =============================================================================
# PAPER MODEL LOADER — branch-local corrections for publication audit
# =============================================================================
# This loader keeps `main` untouched and applies transparent paper-branch fixes
# before evaluating the scientific model.
#
# Current correction:
#   Engine 2 road transport must apply the aggregate transport energy-mix
#   trajectory to S48 (land transport) and S51 (storage and postal services),
#   not S52. In the 73-sector IO classification:
#     S51 = Armazenamento e correio
#     S52 = Alojamento
#   S52 remains in the cities/buildings block.
# =============================================================================

repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = getwd())
model_text <- readLines("code/mma_shock_engines.R", warn = FALSE, encoding = "UTF-8")

# Portable path for CI / paper workflows.
model_text <- gsub(
  'setwd\\("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model"\\)',
  'setwd(Sys.getenv("GITHUB_WORKSPACE", unset=getwd()))',
  model_text
)

# Engine 2 mapping correction: S52 (Alojamento) -> S51 (Armazenamento e correio)
# in the aggregate road-transport rebalance block only.
old_transport_call <- 'A_star <- rebalancear(c("S48","S52"),          # S49/S50/S51 fora — S49/S50 tratados abaixo'
new_transport_call <- 'A_star <- rebalancear(c("S48","S51"),          # S49/S50 tratados abaixo; S52 pertence ao bloco Cidades'
if (!any(grepl(old_transport_call, model_text, fixed = TRUE))) {
  stop("Expected Engine 2 S48/S52 transport mapping not found; inspect source before running paper model.")
}
model_text <- gsub(old_transport_call, new_transport_call, model_text, fixed = TRUE)

# Correct the misleading sector-map comment while preserving the actual group list.
model_text <- gsub(
  'transporte   = c("S48","S49","S50","S51","S52"),  # S48 terrestre, S49 aquaviário, S50 aéreo, S51 armazenamento, S52 correio',
  'transporte   = c("S48","S49","S50","S51"),        # S48 terrestre, S49 aquaviário, S50 aéreo, S51 armazenamento/correio',
  model_text,
  fixed = TRUE
)

# Evaluate the corrected paper-branch model in the global environment.
eval(parse(text = paste(model_text, collapse = "\n")), envir = .GlobalEnv)

# Hard guard against the original mapping reappearing unnoticed.
if (!identical(intersect(c("S48","S49","S50","S51"), GRUPOS$transporte), GRUPOS$transporte)) {
  warning("Unexpected transport group composition after paper-model load.")
}
cat("  Paper model correction active: Engine 2 road transport = S48 + S51; S52 = cities/buildings.\n")
