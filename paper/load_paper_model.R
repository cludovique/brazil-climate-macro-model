# =============================================================================
# PAPER MODEL LOADER — branch-local corrections for publication audit
# =============================================================================
# This loader keeps `main` untouched and applies transparent paper-branch fixes
# before evaluating the scientific model.
#
# Current correction:
#   Engine 2 aggregate road-transport energy-mix rewiring is applied directly
#   only to S48 (land transport). S51 (storage/postal services) is not assigned
#   the road-fuel trajectory directly: the 2018 EPE satellite shows physical
#   energy intensity only ~0.8% of S48 and an electricity-dominated direct mix,
#   so transport decarbonization should reach S51 primarily through its network
#   purchases from S48. S52 remains in the cities/buildings block.
# =============================================================================

repo_root <- Sys.getenv("GITHUB_WORKSPACE", unset = getwd())
model_text <- readLines("code/mma_shock_engines.R", warn = FALSE, encoding = "UTF-8")

# Portable path for CI / paper workflows.
model_text <- gsub(
  'setwd\\("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model"\\)',
  'setwd(Sys.getenv("GITHUB_WORKSPACE", unset=getwd()))',
  model_text
)

# Engine 2 mapping correction: the aggregate MMA road-transport trajectory is a
# direct technological recipe for S48 only. S49/S50 have dedicated physical fuel
# pathways below; S51 inherits transport changes through the production network;
# S52 belongs to the cities/buildings block.
old_transport_call <- 'A_star <- rebalancear(c("S48","S52"),          # S49/S50/S51 fora — S49/S50 tratados abaixo'
new_transport_call <- 'A_star <- rebalancear(c("S48"),                # S49/S50 dedicated; S51 network-mediated; S52 cities/buildings'
if (!any(grepl(old_transport_call, model_text, fixed = TRUE))) {
  stop("Expected Engine 2 S48/S52 transport mapping not found; inspect source before running paper model.")
}
model_text <- gsub(old_transport_call, new_transport_call, model_text, fixed = TRUE)

# Correct the sector-map comment/list used by diagnostics. This does not alter
# the dedicated S49/S50 treatment inside engine2_A_star().
model_text <- gsub(
  'transporte   = c("S48","S49","S50","S51","S52"),  # S48 terrestre, S49 aquaviário, S50 aéreo, S51 armazenamento, S52 correio',
  'transporte   = c("S48","S49","S50","S51"),        # S48 terrestre, S49 aquaviário, S50 aéreo, S51 armazenamento/correio',
  model_text,
  fixed = TRUE
)

# Evaluate the corrected paper-branch model in the global environment.
eval(parse(text = paste(model_text, collapse = "\n")), envir = .GlobalEnv)

# Guard the paper mapping explicitly. GRUPOS$transporte remains a classification
# group; direct road rewiring itself is restricted above to S48.
if (!all(c("S48","S49","S50","S51") %in% GRUPOS$transporte)) {
  warning("Unexpected transport group composition after paper-model load.")
}
cat("  Paper model correction active: Engine 2 road rewiring = S48 only; S51 = network-mediated; S52 = cities/buildings.\n")
