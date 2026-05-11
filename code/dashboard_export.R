# =============================================================================
# DASHBOARD EXPORT — MIP ENERGIA BRASIL 2018
# EPE / FIPE — NT EPE/DEA/SEE/013/2023
#
# Run AFTER mip_epe.R. Requires in memory:
#   setores, A, L, Z, demanda_final, x, x_seguro, N, mp, mult_df,
#   lig, choque1, choque2, energia_base, alpha_energia,
#   energia_choque1, energia_choque2, cod_energia,
#   usos_raw, obter_linha_usos
#
# Outputs:
#   outputs/mip_energia_dashboard.xlsx   — wide format (analyst)
#   outputs/mip_energia_flat.xlsx        — long/tidy format (Power BI / Tableau)
# =============================================================================

# 0. SETUP
# =============================================================================

for (p in c("writexl", "dplyr", "tidyr")) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}

OUTDIR    <- "outputs"
ANO_BASE  <- 2018
FONTE     <- "MIP EPE/FIPE — NT EPE/DEA/SEE/013/2023"
DATA_EXEC <- format(Sys.time(), "%Y-%m-%d %H:%M")

if (!dir.exists(OUTDIR)) dir.create(OUTDIR, recursive = TRUE)

cat("=== DASHBOARD EXPORT START ===\n")


# =============================================================================
# 1. EXTRA ROWS FROM USOS SxS (VA, employment, labor breakdown)
#    Uses usos_raw + obter_linha_usos already in memory from mip_epe.R
# =============================================================================

linhas_extra <- c(
  VA_PIB      = 100,   # Valor Adicionado Bruto (N1)
  VBP_Check   = 101,   # Valor Bruto da Producao (should match x)
  Ocupacoes   = 102,   # Pessoal ocupado (pessoas)
  Remuner     = 88,    # Remuneracoes (R10)
  Salarios    = 89,    # Salarios (R11)
  EOB         = 96     # Excedente Operacional Bruto
)

linhas_labor <- c(
  Informal   = 115,
  Formal     = 116,
  PPI        = 117,    # Preto, Pardo, Indigena
  Branca     = 118,
  Homem      = 119,
  Mulher     = 120,
  Baixo_Med  = 121,    # Ensino fundamental/medio
  Superior   = 122     # Ensino superior
)

extra <- lapply(linhas_extra, obter_linha_usos)
labor <- lapply(linhas_labor, obter_linha_usos)

va_pib   <- extra[["VA_PIB"]]
ocupacoes <- extra[["Ocupacoes"]]
remuner   <- extra[["Remuner"]]
salarios  <- extra[["Salarios"]]
eob       <- extra[["EOB"]]

# Employment multiplier: occupations per R$ million of final demand
coef_emp <- ocupacoes / x_seguro
mult_emp  <- as.vector(t(coef_emp) %*% L)   # type-1 employment multiplier
names(mult_emp) <- setores$cod_setor

# Income multiplier (remunerations per R$ million of final demand)
coef_rem <- remuner / x_seguro
mult_rem  <- as.vector(t(coef_rem) %*% L)
names(mult_rem) <- setores$cod_setor

# Labor shares (fraction of total employment in each category)
labor_share <- sapply(labor, function(v) {
  occ_pos <- ifelse(ocupacoes > 0, ocupacoes, 1)
  round(v / occ_pos, 4)
})

cat("Extra indicators loaded: VA, employment, labor breakdown\n")


# =============================================================================
# 2. SECTOR DIMENSION TABLE
# =============================================================================

fossil_sectors    <- c("S05", "S19", "S21", "S43")
renewable_sectors <- c("S20", "S22", "S40", "S41", "S42")
energy_sectors    <- c(fossil_sectors, renewable_sectors)

# NT4 grouping (matches EPE/FIPE NT)
grupos_nt4 <- list(
  Agropecuaria = c("S01", "S02", "S03"),
  Industria    = setores$cod_setor[setores$id_setor %in% 4:43 &
                                     !setores$cod_setor %in% energy_sectors],
  Servicos     = setores$cod_setor[setores$id_setor %in% 44:73 &
                                     !setores$cod_setor %in% energy_sectors],
  Energeticos  = energy_sectors
)

# 7-group (fossil vs renewable split — NDC analysis)
grupos_7g <- list(
  Agropecuaria   = c("S01", "S02", "S03"),
  Ind_Extrativa  = c("S04", "S06", "S07"),
  Energia_Fossil = fossil_sectors,
  Energia_Renov  = renewable_sectors,
  Ind_Transform  = setores$cod_setor[setores$id_setor %in% c(8:18, 23:39)],
  Infraestrutura = c("S44", "S45", "S48", "S49", "S50", "S51"),
  Servicos       = setores$cod_setor[setores$id_setor %in% c(46, 47, 52:73)]
)

make_grupo_map <- function(grupos) {
  setNames(rep(names(grupos), sapply(grupos, length)), unlist(grupos))
}

nt4_map <- make_grupo_map(grupos_nt4)
g7_map  <- make_grupo_map(grupos_7g)

# Energy sector labels
nomes_energia <- c(
  S05 = "Extracao Petroleo/Gas",   S19 = "Derivados de Petroleo",
  S20 = "Biodiesel",               S21 = "Coquerias",
  S22 = "Biocombustiveis (Etanol)", S40 = "Geracao Centralizada EE",
  S41 = "Geracao Distribuida EE",  S42 = "Transmissao/Distrib EE",
  S43 = "Gas Natural"
)

tab_setores <- setores %>%
  mutate(
    grupo_nt4    = nt4_map[cod_setor],
    grupo_7g     = g7_map[cod_setor],
    eh_energia   = cod_setor %in% energy_sectors,
    eh_fossil    = cod_setor %in% fossil_sectors,
    eh_renovavel = cod_setor %in% renewable_sectors,
    nome_energia = ifelse(eh_energia, nomes_energia[cod_setor], NA_character_)
  ) %>%
  select(cod_setor, id_setor, nome_setor,
         grupo_nt4, grupo_7g,
         eh_energia, eh_fossil, eh_renovavel, nome_energia)

stopifnot("NT4 grouping does not cover 73 sectors" =
            sum(sapply(grupos_nt4, length)) == 73)
stopifnot("7G grouping does not cover 73 sectors"  =
            sum(sapply(grupos_7g, length)) == 73)

cat("Sector dimension table built:", nrow(tab_setores), "rows\n")


# =============================================================================
# 3. BASELINE MACROECONOMIC INDICATORS (one row per sector)
# =============================================================================

# Intermediate consumption: columns = purchases; rows = sales
CI_comprado  <- colSums(Z)   # sector's total purchases from other sectors
CI_vendido   <- rowSums(Z)   # sector's total sales to other sectors

# Final demand totals per sector
fd <- demanda_final %>%
  select(-cod_setor) %>%
  as.matrix()
rownames(fd) <- setores$cod_setor

tab_baseline <- tab_setores %>%
  select(cod_setor, nome_setor, grupo_nt4, grupo_7g, eh_energia) %>%
  mutate(
    # Production
    vbp_milhoes            = round(x[cod_setor], 2),
    va_milhoes             = round(va_pib[cod_setor], 2),
    va_share_vbp_pct       = round(va_pib[cod_setor] / x_seguro[cod_setor] * 100, 2),
    eob_milhoes            = round(eob[cod_setor], 2),
    remuner_milhoes        = round(remuner[cod_setor], 2),
    salarios_milhoes       = round(salarios[cod_setor], 2),
    # Employment
    ocupacoes_pessoas      = round(ocupacoes[cod_setor], 0),
    ocupacoes_por_milhao   = round(coef_emp[cod_setor], 4),
    # Intermediate consumption
    CI_comprado_milhoes    = round(CI_comprado[cod_setor], 2),
    CI_vendido_milhoes     = round(CI_vendido[cod_setor], 2),
    CI_share_vbp_pct       = round(CI_comprado[cod_setor] / x_seguro[cod_setor] * 100, 2),
    # Final demand components
    export_milhoes         = round(fd[cod_setor, "Exportacoes"], 2),
    gov_milhoes            = round(fd[cod_setor, "Gov"], 2),
    isflsf_milhoes         = round(fd[cod_setor, "ISFLSF"], 2),
    familias_milhoes       = round(fd[cod_setor, "Familias"], 2),
    fbcf_milhoes           = round(fd[cod_setor, "FBCF"], 2),
    var_estoque_milhoes    = round(fd[cod_setor, "Var_Estoque"], 2),
    demanda_final_total_milhoes = round(rowSums(fd)[cod_setor], 2),
    export_share_df_pct    = round(fd[cod_setor, "Exportacoes"] /
                                     pmax(rowSums(fd)[cod_setor], 1) * 100, 2)
  )

# Append labor shares
tab_baseline <- tab_baseline %>%
  mutate(
    share_informal_pct  = round(labor_share[cod_setor, "Informal"]  * 100, 2),
    share_formal_pct    = round(labor_share[cod_setor, "Formal"]    * 100, 2),
    share_ppi_pct       = round(labor_share[cod_setor, "PPI"]       * 100, 2),
    share_branca_pct    = round(labor_share[cod_setor, "Branca"]    * 100, 2),
    share_homem_pct     = round(labor_share[cod_setor, "Homem"]     * 100, 2),
    share_mulher_pct    = round(labor_share[cod_setor, "Mulher"]    * 100, 2),
    share_baixo_med_pct = round(labor_share[cod_setor, "Baixo_Med"] * 100, 2),
    share_superior_pct  = round(labor_share[cod_setor, "Superior"]  * 100, 2)
  )

cat("Baseline table:", nrow(tab_baseline), "sectors x", ncol(tab_baseline), "indicators\n")


# =============================================================================
# 4. MULTIPLIERS & LINKAGE INDICES (one row per sector)
# =============================================================================

tab_multiplic <- tab_setores %>%
  select(cod_setor, nome_setor, grupo_nt4, grupo_7g, eh_energia) %>%
  left_join(
    mult_df %>% select(cod_setor, mult_producao = multiplicador),
    by = "cod_setor"
  ) %>%
  left_join(
    lig %>% select(cod_setor, ligacao_tras, ligacao_frente, quadrante),
    by = "cod_setor"
  ) %>%
  mutate(
    mult_emprego         = round(mult_emp[cod_setor], 4),
    mult_renda           = round(mult_rem[cod_setor], 4),
    rank_mult_producao   = rank(-mult_producao,   ties.method = "min"),
    rank_ligacao_tras    = rank(-ligacao_tras,     ties.method = "min"),
    rank_ligacao_frente  = rank(-ligacao_frente,   ties.method = "min"),
    rank_mult_emprego    = rank(-mult_emprego,     ties.method = "min"),
    acima_media_tras     = ligacao_tras   >= 1,
    acima_media_frente   = ligacao_frente >= 1
  )

cat("Multipliers & linkages table built\n")


# =============================================================================
# 5. ENERGY MATRICES (wide and long)
# =============================================================================

fontes_energia <- rownames(energia_base)   # 6 physical sources

# Long format: setor × fonte → ktep + intensity
tab_energia_long <- expand.grid(
  cod_setor = setores$cod_setor,
  fonte     = fontes_energia,
  stringsAsFactors = FALSE
) %>%
  mutate(
    ktep        = mapply(function(s, f) energia_base[f, s],   cod_setor, fonte),
    intensidade = mapply(function(s, f) alpha_energia[f, s],  cod_setor, fonte),
    ktep        = round(ktep, 4),
    intensidade = round(intensidade, 6)
  ) %>%
  left_join(tab_setores %>%
              select(cod_setor, nome_setor, grupo_nt4, grupo_7g, eh_energia),
            by = "cod_setor") %>%
  filter(ktep != 0)

# Wide format: one column per energy source
tab_energia_wide <- as.data.frame(t(energia_base)) %>%
  tibble::rownames_to_column("cod_setor") %>%
  left_join(tab_setores %>% select(cod_setor, nome_setor, grupo_nt4, eh_energia),
            by = "cod_setor") %>%
  mutate(total_ktep = rowSums(across(all_of(fontes_energia)))) %>%
  left_join(
    as.data.frame(t(alpha_energia)) %>%
      tibble::rownames_to_column("cod_setor") %>%
      rename_with(~ paste0("intens_", .), all_of(fontes_energia)),
    by = "cod_setor"
  ) %>%
  select(cod_setor, nome_setor, grupo_nt4, eh_energia,
         all_of(fontes_energia), total_ktep,
         starts_with("intens_"))

cat("Energy matrices: long", nrow(tab_energia_long), "rows |",
    "wide", nrow(tab_energia_wide), "x", ncol(tab_energia_wide), "\n")


# =============================================================================
# 6. SHOCK RESULTS — full sector detail + energy impacts
# =============================================================================

# Helper: enrich a choque data.frame with VA, employment, energy impacts
enrich_choque <- function(choque_df, delta_x_vec, exercicio_label, descricao) {
  delta_va   <- (va_pib   / x_seguro) * delta_x_vec
  delta_emp  <- coef_emp              * delta_x_vec
  delta_rem  <- (remuner  / x_seguro) * delta_x_vec

  choque_df %>%
    left_join(tab_setores %>% select(cod_setor, grupo_nt4, grupo_7g),
              by = "cod_setor") %>%
    mutate(
      exercicio           = exercicio_label,
      descricao           = descricao,
      delta_va_milhoes    = round(delta_va[cod_setor],  3),
      delta_emp_pessoas   = round(delta_emp[cod_setor], 1),
      delta_rem_milhoes   = round(delta_rem[cod_setor], 3),
      va_share_delta_pct  = round(delta_va[cod_setor] /
                                    pmax(abs(va_pib[cod_setor]), 1) * 100, 4)
    ) %>%
    rename(
      vbp_base_milhoes   = x_base,
      delta_prod_milhoes = delta_prod,
      variacao_prod_pct  = var_pct
    ) %>%
    select(exercicio, descricao,
           cod_setor, nome_setor, grupo_nt4, grupo_7g, eh_energia,
           vbp_base_milhoes, delta_prod_milhoes, variacao_prod_pct,
           delta_va_milhoes, delta_emp_pessoas, delta_rem_milhoes,
           va_share_delta_pct)
}

delta_x_exp  <- setNames(choque1$delta_prod, choque1$cod_setor)
delta_x_elet <- setNames(choque2$delta_prod, choque2$cod_setor)

tab_choque1 <- enrich_choque(
  choque1, delta_x_exp,
  "Ex1_+5%_Exportacoes",
  "+5% demanda de exportacao em todos os setores"
)

tab_choque2 <- enrich_choque(
  choque2, delta_x_elet,
  "Ex2_+5%_Familias_S40",
  "+5% consumo familias — Geracao Centralizada EE (S40)"
)

# Combined long table
tab_choques_long <- bind_rows(tab_choque1, tab_choque2)

# Energy source impacts per exercise
tab_energia_choques <- bind_rows(
  data.frame(
    exercicio = "Ex1_+5%_Exportacoes",
    fonte     = names(energia_choque1),
    delta     = round(as.numeric(energia_choque1), 4),
    unidade   = ifelse(names(energia_choque1) == "Transmissao",
                       "R$ milhoes (setor S42)", "ktep"),
    stringsAsFactors = FALSE
  ),
  data.frame(
    exercicio = "Ex2_+5%_Familias_S40",
    fonte     = names(energia_choque2),
    delta     = round(as.numeric(energia_choque2), 4),
    unidade   = ifelse(names(energia_choque2) == "Transmissao",
                       "R$ milhoes (setor S42)", "ktep"),
    stringsAsFactors = FALSE
  )
)

cat("Shock tables built\n")


# =============================================================================
# 7. AGGREGATED RESULTS BY SECTOR GROUP
# =============================================================================

agg_by <- function(tab, group_col, ...) {
  tab %>%
    group_by(grupo = .data[[group_col]]) %>%
    summarise(...)
}

# Baseline aggregated — NT4
agg_baseline_nt4 <- agg_by(tab_baseline, "grupo_nt4",
  n_setores              = n(),
  vbp_bilhoes            = round(sum(vbp_milhoes)   / 1e3, 2),
  va_bilhoes             = round(sum(va_milhoes)     / 1e3, 2),
  export_bilhoes         = round(sum(export_milhoes) / 1e3, 2),
  familias_bilhoes       = round(sum(familias_milhoes) / 1e3, 2),
  fbcf_bilhoes           = round(sum(fbcf_milhoes)   / 1e3, 2),
  ocupacoes_mil          = round(sum(ocupacoes_pessoas) / 1e3, 1),
  .groups = "drop"
) %>% mutate(esquema = "NT4")

# Baseline aggregated — 7G
agg_baseline_7g <- agg_by(tab_baseline, "grupo_7g",
  n_setores              = n(),
  vbp_bilhoes            = round(sum(vbp_milhoes)   / 1e3, 2),
  va_bilhoes             = round(sum(va_milhoes)     / 1e3, 2),
  export_bilhoes         = round(sum(export_milhoes) / 1e3, 2),
  familias_bilhoes       = round(sum(familias_milhoes) / 1e3, 2),
  fbcf_bilhoes           = round(sum(fbcf_milhoes)   / 1e3, 2),
  ocupacoes_mil          = round(sum(ocupacoes_pessoas) / 1e3, 1),
  .groups = "drop"
) %>% mutate(esquema = "7G")

# Shock aggregated — NT4 (both exercises)
agg_choques_nt4 <- bind_rows(
  agg_by(tab_choque1, "grupo_nt4",
    n_setores          = n(),
    delta_prod_bilhoes = round(sum(delta_prod_milhoes) / 1e3, 3),
    delta_va_bilhoes   = round(sum(delta_va_milhoes)   / 1e3, 3),
    delta_emp_mil      = round(sum(delta_emp_pessoas)  / 1e3, 1),
    .groups = "drop") %>% mutate(exercicio = "Ex1_+5%_Exportacoes"),
  agg_by(tab_choque2, "grupo_nt4",
    n_setores          = n(),
    delta_prod_bilhoes = round(sum(delta_prod_milhoes) / 1e3, 3),
    delta_va_bilhoes   = round(sum(delta_va_milhoes)   / 1e3, 3),
    delta_emp_mil      = round(sum(delta_emp_pessoas)  / 1e3, 1),
    .groups = "drop") %>% mutate(exercicio = "Ex2_+5%_Familias_S40")
)

# Shock aggregated — 7G
agg_choques_7g <- bind_rows(
  agg_by(tab_choque1, "grupo_7g",
    n_setores          = n(),
    delta_prod_bilhoes = round(sum(delta_prod_milhoes) / 1e3, 3),
    delta_va_bilhoes   = round(sum(delta_va_milhoes)   / 1e3, 3),
    delta_emp_mil      = round(sum(delta_emp_pessoas)  / 1e3, 1),
    .groups = "drop") %>% mutate(exercicio = "Ex1_+5%_Exportacoes"),
  agg_by(tab_choque2, "grupo_7g",
    n_setores          = n(),
    delta_prod_bilhoes = round(sum(delta_prod_milhoes) / 1e3, 3),
    delta_va_bilhoes   = round(sum(delta_va_milhoes)   / 1e3, 3),
    delta_emp_mil      = round(sum(delta_emp_pessoas)  / 1e3, 1),
    .groups = "drop") %>% mutate(exercicio = "Ex2_+5%_Familias_S40")
)

# Energy aggregated by NT4 group
agg_energia_nt4 <- tab_energia_long %>%
  group_by(grupo_nt4, fonte) %>%
  summarise(ktep_total = round(sum(ktep), 2), .groups = "drop") %>%
  pivot_wider(names_from = fonte, values_from = ktep_total, values_fill = 0)

cat("Aggregated tables built\n")


# =============================================================================
# 8. QUADRANT SUMMARY
# =============================================================================

tab_quadrantes <- lig %>%
  left_join(tab_setores %>% select(cod_setor, grupo_nt4, grupo_7g, eh_energia),
            by = "cod_setor") %>%
  count(quadrante, grupo_nt4, eh_energia, name = "n_setores")

tab_quadrante_resumo <- lig %>%
  count(quadrante, name = "n_setores") %>%
  mutate(pct = round(n_setores / sum(n_setores) * 100, 1))


# =============================================================================
# 9. DEMANDA FINAL — long format
# =============================================================================

tab_demanda_long <- demanda_final %>%
  pivot_longer(
    cols      = c(Exportacoes, Gov, ISFLSF, Familias, FBCF, Var_Estoque),
    names_to  = "componente",
    values_to = "valor_milhoes"
  ) %>%
  left_join(tab_setores %>%
              select(cod_setor, nome_setor, grupo_nt4, grupo_7g, eh_energia),
            by = "cod_setor") %>%
  mutate(valor_milhoes = round(valor_milhoes, 2),
         valor_bilhoes = round(valor_milhoes / 1e3, 4))


# =============================================================================
# 10. METADATA & DATA DICTIONARY
# =============================================================================

tab_meta <- data.frame(
  item = c(
    "Fonte dos dados", "Ano base", "Numero de setores",
    "Data de execucao", "Arquivo de entrada",
    "Unidade monetaria", "Unidade energia",
    "Grupos NT4", "Grupos 7G",
    "Exercicio 1", "Exercicio 2",
    "Setores energeticos (9)", "Setores fosseis (4)", "Setores renovaveis (5)",
    "Validacao GDP Ex1", "Validacao Energia Ex1", "Validacao Choque Ex1"
  ),
  valor = c(
    FONTE, ANO_BASE, N,
    DATA_EXEC, "48008000008202670_Camila_Anexo 2.xlsx",
    "R$ milhoes correntes 2018", "ktep (tonelada equivalente de petroleo)",
    paste(names(grupos_nt4), collapse = " | "),
    paste(names(grupos_7g),  collapse = " | "),
    "+5% na demanda de exportacao em todos os setores",
    "+5% no consumo de familias Geracao Centralizada EE (S40)",
    paste(energy_sectors,   collapse = " "),
    paste(fossil_sectors,   collapse = " "),
    paste(renewable_sectors, collapse = " "),
    "delta VA = R$ 38.5 bi (NT: R$ 38.5 bi)", "delta E = 1768 ktep (NT: 1768 ktep)",
    "choque = R$ 51.3 bi (NT: R$ 51.2 bi)"
  ),
  stringsAsFactors = FALSE
)

tab_dicionario <- data.frame(
  tabela    = c(
    rep("Setores", 9),
    rep("Baseline_Setorial", 10),
    rep("Multiplicadores_Ligacoes", 9),
    rep("Demanda_Final_Long", 5),
    rep("Energia_Long", 5),
    rep("Choques_Long", 9),
    rep("Energia_Choques", 3)
  ),
  variavel  = c(
    "cod_setor","id_setor","nome_setor","grupo_nt4","grupo_7g",
    "eh_energia","eh_fossil","eh_renovavel","nome_energia",
    "vbp_milhoes","va_milhoes","va_share_vbp_pct",
    "eob_milhoes","remuner_milhoes","salarios_milhoes",
    "ocupacoes_pessoas","ocupacoes_por_milhao",
    "CI_comprado_milhoes","CI_vendido_milhoes",
    "mult_producao","mult_emprego","mult_renda",
    "ligacao_tras","ligacao_frente","quadrante",
    "rank_mult_producao","rank_mult_emprego","acima_media_tras","acima_media_frente",
    "cod_setor","componente","valor_milhoes","valor_bilhoes","grupo_nt4",
    "cod_setor","fonte","ktep","intensidade","grupo_nt4",
    "exercicio","cod_setor","grupo_nt4","vbp_base_milhoes",
    "delta_prod_milhoes","delta_va_milhoes","delta_emp_pessoas",
    "variacao_prod_pct","va_share_delta_pct",
    "exercicio","fonte","delta","unidade"
  ),
  descricao = c(
    "Codigo do setor (S01-S73)",
    "ID numerico do setor (1-73)",
    "Nome completo do setor",
    "Grupo NT4: Agropecuaria | Industria | Servicos | Energeticos",
    "Grupo 7G: Agro | Extrativa | Fossil | Renov | Transform | Infra | Servicos",
    "TRUE = setor pertence ao subsistema energetico (9 setores)",
    "TRUE = setor de energia fossil (S05 S19 S21 S43)",
    "TRUE = setor de energia renovavel (S20 S22 S40 S41 S42)",
    "Nome abreviado do setor energetico",
    "Valor Bruto da Producao (R$ milhoes, 2018)",
    "Valor Adicionado Bruto / PIB (R$ milhoes)",
    "Participacao do VA no VBP (%)",
    "Excedente Operacional Bruto (R$ milhoes)",
    "Remuneracoes totais (R$ milhoes)",
    "Salarios (R$ milhoes)",
    "Total de pessoal ocupado (pessoas)",
    "Ocupacoes por R$ milhao de producao (coeficiente de emprego)",
    "Consumo intermediario comprado de outros setores (R$ milhoes)",
    "Consumo intermediario vendido para outros setores (R$ milhoes)",
    "Multiplicador de producao tipo 1 (soma coluna da Leontief)",
    "Multiplicador de emprego tipo 1 (ocupacoes por R$ milhao de demanda final)",
    "Multiplicador de renda tipo 1 (remuneracoes por R$ milhao de demanda final)",
    "Ligacao para tras de Rasmussen-Hirschman (Uj)",
    "Ligacao para frente de Rasmussen-Hirschman (Ui)",
    "Quadrante Rasmussen: Setor-Chave | Demanda | Oferta | Independente",
    "Ranking por multiplicador de producao (1 = maior)",
    "Ranking por multiplicador de emprego (1 = maior)",
    "Uj >= 1: ligacao para tras acima da media da economia",
    "Ui >= 1: ligacao para frente acima da media da economia",
    "Codigo do setor (chave de join)",
    "Componente de demanda final (Exportacoes/Gov/ISFLSF/Familias/FBCF/Var_Estoque)",
    "Valor em R$ milhoes (correntes 2018)",
    "Valor em R$ bilhoes (correntes 2018)",
    "Grupo NT4",
    "Codigo do setor (chave de join)",
    "Fonte de energia (Derivados/Biodiesel/Etanol/EE_Central/EE_Distrib/Gas_Natural)",
    "Consumo fisico de energia (ktep/ano, 2018)",
    "Intensidade energetica (ktep por R$ milhao de producao = ALPHA)",
    "Grupo NT4",
    "Identificador do exercicio (Ex1/Ex2)",
    "Codigo do setor (chave de join)",
    "Grupo NT4",
    "VBP base pre-choque (R$ milhoes)",
    "Variacao de producao induzida pelo choque (R$ milhoes)",
    "Variacao de VA induzida (R$ milhoes)",
    "Variacao de emprego induzida (pessoas)",
    "Variacao percentual de producao sobre VBP base (%)",
    "Variacao percentual de VA sobre VA base (%)",
    "Identificador do exercicio",
    "Fonte de energia ou 'Transmissao'",
    "Variacao na fonte energetica (ktep) ou no setor S42 (R$ milhoes)",
    "Unidade de medida da linha"
  ),
  stringsAsFactors = FALSE
)


# =============================================================================
# 11. WRITE FILES
# =============================================================================

cat("\nWriting Excel outputs...\n")

# ── File 1: Wide / analyst format ────────────────────────────────────────────
wide_path <- file.path(OUTDIR, "mip_energia_dashboard.xlsx")

write_xlsx(
  list(
    "META"               = tab_meta,
    "Dicionario"         = tab_dicionario,
    "Setores"            = tab_setores,
    "Baseline_Setorial"  = tab_baseline,
    "Demanda_Final"      = demanda_final %>%
                             left_join(tab_setores %>%
                                         select(cod_setor, nome_setor, grupo_nt4),
                                       by = "cod_setor") %>%
                             select(cod_setor, nome_setor, grupo_nt4, everything()) %>%
                             mutate(across(where(is.numeric), ~ round(., 2))),
    "Energia_Fluxos"     = tab_energia_wide,
    "Multiplicadores_Lig" = tab_multiplic,
    "Choque_Ex1_Setorial" = tab_choque1 %>% select(-exercicio, -descricao),
    "Choque_Ex2_Setorial" = tab_choque2 %>% select(-exercicio, -descricao),
    "Energia_Choques"    = tab_energia_choques,
    "Agregados_NT4"      = bind_rows(agg_baseline_nt4) %>% select(-esquema),
    "Agregados_7G"       = bind_rows(agg_baseline_7g)  %>% select(-esquema),
    "Choques_NT4"        = agg_choques_nt4,
    "Choques_7G"         = agg_choques_7g,
    "Energia_NT4"        = agg_energia_nt4,
    "Quadrantes"         = tab_quadrante_resumo
  ),
  path = wide_path
)
cat("Saved:", wide_path, "\n")

# ── File 2: Long / BI format (Power BI / Tableau) ────────────────────────────
flat_path <- file.path(OUTDIR, "mip_energia_flat.xlsx")

write_xlsx(
  list(
    "Setores_Dim"        = tab_setores,
    "Baseline_Long"      = tab_baseline %>%
                             pivot_longer(
                               cols      = where(is.numeric),
                               names_to  = "indicador",
                               values_to = "valor"
                             ) %>%
                             filter(!is.na(valor)) %>%
                             select(cod_setor, nome_setor, grupo_nt4, grupo_7g,
                                    eh_energia, indicador, valor),
    "Demanda_Final_Long" = tab_demanda_long,
    "Energia_Long"       = tab_energia_long,
    "Choques_Long"       = tab_choques_long,
    "Energia_Choques"    = tab_energia_choques
  ),
  path = flat_path
)
cat("Saved:", flat_path, "\n")


# =============================================================================
# 12. CONSOLE SUMMARY
# =============================================================================

cat("\n")
cat("=== EXPORT COMPLETE ===\n")
cat(sprintf("  Wide file:  %s  (%d sheets)\n", wide_path, 16))
cat(sprintf("  Flat file:  %s  (%d sheets)\n", flat_path, 6))
cat(sprintf("  Sectors: %d | Energy sectors: %d | Exercises: 2\n",
            N, length(energy_sectors)))
cat(sprintf("  Baseline indicators: %d cols | Labor shares: 8 groups\n",
            ncol(tab_baseline)))
cat(sprintf("  Leontief multipliers: production, employment, income\n"))
cat(sprintf("  Energy sources: %s\n", paste(fontes_energia, collapse = " | ")))
cat(sprintf("  Sector groups: NT4 (%d) | 7G (%d)\n",
            length(grupos_nt4), length(grupos_7g)))
cat(sprintf("\n  Ex1 total delta_prod: R$ %.1f bi | delta_VA: R$ %.1f bi | emp: %.0f mil\n",
            sum(tab_choque1$delta_prod_milhoes) / 1e3,
            sum(tab_choque1$delta_va_milhoes)   / 1e3,
            sum(tab_choque1$delta_emp_pessoas)  / 1e3))
cat(sprintf("  Ex2 total delta_prod: R$ %.2f bi | delta_VA: R$ %.2f bi | emp: %.1f mil\n",
            sum(tab_choque2$delta_prod_milhoes) / 1e3,
            sum(tab_choque2$delta_va_milhoes)   / 1e3,
            sum(tab_choque2$delta_emp_pessoas)  / 1e3))
