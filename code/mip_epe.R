# =============================================================================
# MODELO INSUMO-PRODUTO COM DETALHAMENTO ENERGÉTICO - BRASIL 2018
# EPE / FIPE - Nota Técnica EPE/DEA/SEE/013/2023
#
# Script:  mip_energia_brasil.R
# Dados:   Anexo 2 (48008000008202670_Camila_Anexo 2.xlsx)


# 1. PACOTES
{
# =============================================================================

pacotes <- c("readxl", "dplyr", "tidyr", "ggplot2", "scales",
             "writexl", "stringr", "RColorBrewer", "ggrepel")

instalar_se_necessario <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

invisible(lapply(pacotes, instalar_se_necessario))

# Configuracoes para Windows (evita erros de encoding no print)
options(OutDec = ".")
if (.Platform$OS.type == "windows") {
  options(encoding = "native.enc")
}

cat("Pacotes carregados com sucesso.\n")
}

# 2. LEITURA E PREPARAÇÃO DOS DADOS
{
# =============================================================================

# --- Caminho do arquivo (ajuste se necessário) ---
ARQUIVO <- "48008000008202670_Camila_Anexo 2.xlsx"

if (!file.exists(ARQUIVO)) {
  candidatos <- list.files(pattern = "Anexo.?2", ignore.case = TRUE)
  if (length(candidatos) > 0) {
    ARQUIVO <- candidatos[1]
    cat("Arquivo encontrado automaticamente:", ARQUIVO, "\n")
  } else {
    stop(paste("Arquivo nao encontrado:", ARQUIVO,
               "\nArquivos xlsx disponiveis:",
               paste(list.files(pattern = "\\.xlsx$"), collapse = ", ")))
  }
}

cat("Lendo:", ARQUIVO, "\n")

# ── 2.1  Lista de setores (S01-S73) -----------------------------------------
lista_raw <- read_excel(ARQUIVO, sheet = "Lista PS",
                        col_names = FALSE, range = cell_cols("A:M"))

setores <- lista_raw %>%
  select(cod_setor = 12, nome_setor = 13) %>%
  filter(!is.na(cod_setor),
         grepl("^S", as.character(cod_setor))) %>%
  mutate(
    cod_setor  = as.character(cod_setor),
    nome_setor = as.character(nome_setor),
    id_setor   = as.integer(gsub("\\D", "", cod_setor))
  )

N <- nrow(setores)
cat(sprintf("%d setores identificados.\n", N))

# ── 2.2  Matriz de Coeficientes Técnicos (A) — N x N ------------------------
coef_raw <- read_excel(ARQUIVO, sheet = "Coeficientes Tecnicos",
                       col_names = FALSE)

A <- coef_raw[5:(4 + N), 4:(3 + N)] %>%
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) %>%
  as.matrix()

dimnames(A) <- list(setores$cod_setor, setores$cod_setor)
cat(sprintf("Matriz A: %d x %d\n", nrow(A), ncol(A)))

# ── 2.3  Inversa de Leontief (L) — N x N ------------------------------------
leontief_raw <- read_excel(ARQUIVO, sheet = "Leontief", col_names = FALSE)

L <- leontief_raw[5:(4 + N), 4:(3 + N)] %>%
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) %>%
  as.matrix()

dimnames(L) <- list(setores$cod_setor, setores$cod_setor)
cat(sprintf("Matriz L (Leontief): %d x %d\n", nrow(L), ncol(L)))

# ── 2.4  Usos SxS — consumo intermediário + demanda final -------------------
usos_raw <- read_excel(ARQUIVO, sheet = "Usos SxS", col_names = FALSE)

Z <- usos_raw[5:(4 + N), 4:(3 + N)] %>%
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0"))))) %>%
  as.matrix()
dimnames(Z) <- list(setores$cod_setor, setores$cod_setor)

# Demanda final: cols 78-83
# 78=Exportacoes, 79=Governo, 80=ISFLSF, 81=Familias, 82=FBCF, 83=Var.Estoque
demanda_final <- usos_raw[5:(4 + N), 78:83] %>%
  mutate(across(everything(),
                ~ suppressWarnings(as.numeric(replace_na(as.character(.), "0")))))

colnames(demanda_final) <- c("Exportacoes", "Gov", "ISFLSF",
                             "Familias", "FBCF", "Var_Estoque")
demanda_final$cod_setor <- setores$cod_setor

# Vetor de producao total (x)
x <- rowSums(Z) + rowSums(demanda_final[, 1:6])
names(x) <- setores$cod_setor

cat("Dados de demanda final e producao calculados.\n")
}

# 3. FUNÇÕES AUXILIARES
{
# =============================================================================

# Multiplicadores de producao (soma das colunas de L)
multiplicadores_producao <- function(L) colSums(L)

# Indices de ligacao de Rasmussen-Hirschman
indices_ligacao <- function(L) {
  l_bar <- mean(L)
  Uj    <- colMeans(L) / l_bar
  Ui    <- rowMeans(L) / l_bar
  data.frame(cod_setor      = colnames(L),
             ligacao_tras   = Uj,
             ligacao_frente = Ui,
             row.names      = NULL)
}

# Simulacao de choque na demanda final
simular_choque <- function(L, delta_f) as.vector(L %*% delta_f)

# Classificacao de quadrante (Rasmussen)
classificar_setor <- function(uj, ui) {
  dplyr::case_when(
    uj >= 1 & ui >= 1 ~ "Setor-Chave",
    uj >= 1 & ui <  1 ~ "Demanda acima da media",
    uj <  1 & ui >= 1 ~ "Oferta acima da media",
    TRUE               ~ "Independente"
  )
}

# Impressao segura: converte UTF-8 para ASCII e usa data.frame
imprimir <- function(df) {
  df %>%
    mutate(across(where(is.character),
                  ~ iconv(., from = "UTF-8", to = "ASCII//TRANSLIT"))) %>%
    as.data.frame() %>%
    print()
}

# Separador de secoes no console
sep <- function(titulo = "") {
  cat("\n", paste(rep("-", 60), collapse = ""), "\n", sep = "")
  if (nchar(titulo) > 0) cat(" ", titulo, "\n", sep = "")
  cat(paste(rep("-", 60), collapse = ""), "\n", sep = "")
}

}

# 4. ANÁLISE DESCRITIVA — SETORES ENERGÉTICOS
{
# =============================================================================

# 9 setores energeticos (NT EPE/FIPE 2023)
cod_energia <- c("S05", "S19", "S20", "S21", "S22",
                 "S40", "S41", "S42", "S43")

nomes_energia_legenda <- c(
  "S05" = "Extracao Petroleo/Gas",
  "S19" = "Derivados de Petroleo",
  "S20" = "Biodiesel",
  "S21" = "Coquerias",
  "S22" = "Biocombustiveis (Etanol)",
  "S40" = "Geracao Centralizada",
  "S41" = "Geracao Distribuida",
  "S42" = "Transmissao",
  "S43" = "Gas Natural"
)

CI_setor <- colSums(Z)

participacao_CI <- data.frame(
  cod_setor  = names(CI_setor),
  CI_bilhoes = round(CI_setor / 1e3, 2),
  stringsAsFactors = FALSE
) %>%
  left_join(setores %>% select(cod_setor, nome_setor), by = "cod_setor") %>%
  arrange(desc(CI_bilhoes)) %>%
  mutate(
    participacao_pct = round(CI_bilhoes / sum(CI_bilhoes) * 100, 2),
    eh_energia       = cod_setor %in% cod_energia,
    nome_curto       = substr(nome_setor, 1, 40)
  )

sep("TOP 15 - CONSUMO INTERMEDIARIO (R$ bilhoes, 2018)")
imprimir(participacao_CI %>%
           head(15) %>%
           select(cod_setor, nome_curto, CI_bilhoes, participacao_pct))

}

# 5. MULTIPLICADORES DE PRODUÇÃO
{
# =============================================================================

mp <- multiplicadores_producao(L)

mult_df <- data.frame(
  cod_setor     = names(mp),
  multiplicador = round(mp, 4),
  stringsAsFactors = FALSE
) %>%
  left_join(setores %>% select(cod_setor, nome_setor), by = "cod_setor") %>%
  mutate(
    eh_energia = cod_setor %in% cod_energia,
    nome_curto = substr(nome_setor, 1, 40)
  ) %>%
  arrange(desc(multiplicador))

sep("MULTIPLICADORES DE PRODUCAO - SETORES ENERGETICOS")
imprimir(mult_df %>%
           filter(eh_energia) %>%
           select(cod_setor, nome_curto, multiplicador))

}

# 6. ÍNDICES DE LIGAÇÃO — SETORES-CHAVE
{
# =============================================================================

lig <- indices_ligacao(L) %>%
  left_join(setores %>% select(cod_setor, nome_setor), by = "cod_setor") %>%
  mutate(
    quadrante  = classificar_setor(ligacao_tras, ligacao_frente),
    eh_energia = cod_setor %in% cod_energia,
    nome_curto = substr(nome_setor, 1, 38)
  )

sep("INDICES DE LIGACAO - SETORES ENERGETICOS")
imprimir(lig %>%
           filter(eh_energia) %>%
           select(cod_setor, nome_curto, ligacao_tras, ligacao_frente, quadrante) %>%
           mutate(across(ligacao_tras:ligacao_frente, ~ round(., 3))))

sep("CONTAGEM POR QUADRANTE")
print(table(lig$quadrante))

}

# 7. SIMULAÇÕES DE CHOQUE
{
# =============================================================================

# ── 7.1  Choque 1: +5% nas exportações totais --------------------------------
sep("SIMULACAO 1: +5% nas exportacoes totais")

delta_exp          <- demanda_final$Exportacoes * 0.05
names(delta_exp)   <- setores$cod_setor
delta_x_exp        <- simular_choque(L, delta_exp)
names(delta_x_exp) <- setores$cod_setor

choque1 <- data.frame(
  cod_setor  = setores$cod_setor,
  nome_setor = setores$nome_setor,
  delta_prod = round(delta_x_exp, 2),
  x_base     = round(x, 2),
  var_pct    = round(delta_x_exp / x * 100, 3),
  eh_energia = setores$cod_setor %in% cod_energia,
  stringsAsFactors = FALSE
)

cat(sprintf("Delta Producao total:  R$ %.1f bilhoes (+%.2f%%)\n",
            sum(choque1$delta_prod) / 1e3,
            sum(choque1$delta_prod) / sum(x) * 100))

cat("\nTop 10 setores mais impactados:\n")
imprimir(choque1 %>%
           arrange(desc(delta_prod)) %>%
           head(10) %>%
           mutate(nome_curto = substr(nome_setor, 1, 38)) %>%
           select(cod_setor, nome_curto, delta_prod, var_pct))

cat("\nSetores energeticos:\n")
imprimir(choque1 %>%
           filter(eh_energia) %>%
           arrange(desc(delta_prod)) %>%
           mutate(nome_curto = substr(nome_setor, 1, 38)) %>%
           select(cod_setor, nome_curto, delta_prod, var_pct))


# ── 7.2  Choque 2: +5% consumo famílias por eletricidade (S40) ---------------
sep("SIMULACAO 2: +5% consumo familias por eletricidade (S40)")

delta_elet          <- numeric(N)
names(delta_elet)   <- setores$cod_setor
idx_s40             <- which(setores$cod_setor == "S40")
delta_elet[idx_s40] <- demanda_final$Familias[idx_s40] * 0.05

delta_x_elet        <- simular_choque(L, delta_elet)
names(delta_x_elet) <- setores$cod_setor

choque2 <- data.frame(
  cod_setor  = setores$cod_setor,
  nome_setor = setores$nome_setor,
  delta_prod = round(delta_x_elet, 3),
  x_base     = round(x, 2),
  var_pct    = round(delta_x_elet / x * 100, 4),
  eh_energia = setores$cod_setor %in% cod_energia,
  stringsAsFactors = FALSE
)

cat(sprintf("Delta Producao total:  R$ %.2f bilhoes (+%.4f%%)\n",
            sum(choque2$delta_prod) / 1e3,
            sum(choque2$delta_prod) / sum(x) * 100))

cat("\nSetores energeticos:\n")
imprimir(choque2 %>%
           filter(eh_energia) %>%
           arrange(desc(delta_prod)) %>%
           mutate(nome_curto = substr(nome_setor, 1, 38)) %>%
           select(cod_setor, nome_curto, delta_prod, var_pct))


# ── 7.3  Função genérica reutilizável ----------------------------------------
# Exemplos de uso:
#   simular_cenario("S22", "Familias",    variacao = 0.10)
#   simular_cenario("S40", "Exportacoes", variacao = 0.20)
#   simular_cenario("S19", "FBCF",        variacao = -0.05)

simular_cenario <- function(setor, componente, variacao, verbose = TRUE) {
  delta          <- numeric(N)
  names(delta)   <- setores$cod_setor
  idx            <- which(setores$cod_setor == setor)
  
  if (length(idx) == 0) stop(paste("Setor nao encontrado:", setor))
  
  base_val    <- demanda_final[[componente]][idx]
  delta[idx]  <- base_val * variacao
  delta_x     <- simular_choque(L, delta)
  names(delta_x) <- setores$cod_setor
  
  resultado <- data.frame(
    cod_setor  = setores$cod_setor,
    nome_setor = setores$nome_setor,
    delta_prod = round(delta_x, 3),
    x_base     = round(x, 2),
    var_pct    = round(delta_x / x * 100, 4),
    eh_energia = setores$cod_setor %in% cod_energia,
    stringsAsFactors = FALSE
  )
  
  if (verbose) {
    cat(sprintf("\nChoque: %+.0f%% em '%s' do setor %s\n",
                variacao * 100, componente, setor))
    cat(sprintf("Delta base:     R$ %.1f M\n", base_val * variacao))
    cat(sprintf("Delta Producao: R$ %.1f M\n", sum(delta_x)))
    cat("Top 5 impactados:\n")
    imprimir(resultado %>%
               arrange(desc(delta_prod)) %>%
               head(5) %>%
               mutate(nome_curto = substr(nome_setor, 1, 38)) %>%
               select(cod_setor, nome_curto, delta_prod, var_pct))
  }
  
  invisible(resultado)
}

# Exemplo: +10% exportacoes de Derivados de Petroleo (S19)
sep("SIMULACAO 3 (EXEMPLO): +10% exportacoes S19 Derivados de Petroleo")
res3 <- simular_cenario("S19", "Exportacoes", variacao = 0.10)
}

# 8. VISUALIZAÇÕES
{
# =============================================================================

cores_energia <- c(
  "S05" = "#1B4F72", "S19" = "#2E86C1", "S20" = "#27AE60",
  "S21" = "#717D7E", "S22" = "#229954", "S40" = "#F39C12",
  "S41" = "#F8C471", "S42" = "#E74C3C", "S43" = "#8E44AD"
)

nomes_grafico <- c(
  "S05" = "Extracao\nPetroleo/Gas",
  "S19" = "Derivados\nPetroleo",
  "S20" = "Biodiesel",
  "S21" = "Coquerias",
  "S22" = "Biocombust.\n(Etanol)",
  "S40" = "Geracao\nCentralizada",
  "S41" = "Geracao\nDistribuida",
  "S42" = "Transmissao",
  "S43" = "Gas Natural"
)

# ── Gráfico 1: Multiplicadores -----------------------------------------------
dados_g1 <- mult_df %>%
  filter(eh_energia) %>%
  mutate(nome_graf = nomes_grafico[cod_setor])

p1 <- ggplot(dados_g1,
             aes(x = reorder(nome_graf, multiplicador),
                 y = multiplicador, fill = cod_setor)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = round(multiplicador, 2)),
            hjust = -0.15, size = 3.5, fontface = "bold") +
  geom_hline(yintercept = mean(mp), linetype = "dashed",
             color = "gray40", linewidth = 0.8) +
  annotate("text", x = 0.7, y = mean(mp) + 0.04,
           label = paste0("Media: ", round(mean(mp), 2)),
           color = "gray40", size = 3.2) +
  scale_fill_manual(values = cores_energia) +
  scale_y_continuous(limits = c(0, max(dados_g1$multiplicador) * 1.15),
                     expand = c(0, 0)) +
  coord_flip() +
  labs(title    = "Multiplicadores de Producao - Setores Energeticos",
       subtitle = "R$ de producao total por R$ 1 de demanda final",
       x = NULL, y = "Multiplicador",
       caption  = "Fonte: MIP EPE/FIPE (2018)") +
  theme_minimal(base_size = 12) +
  theme(plot.title         = element_text(face = "bold", size = 13),
        plot.subtitle      = element_text(color = "gray40", size = 10),
        panel.grid.major.y = element_blank())

ggsave("grafico_multiplicadores.png", p1, width = 10, height = 6, dpi = 150)
cat("\nSalvo: grafico_multiplicadores.png\n")

# ── Gráfico 2: Diagrama de Rasmussen -----------------------------------------
p2 <- ggplot(lig,
             aes(x = ligacao_frente, y = ligacao_tras,
                 color = quadrante, shape = eh_energia)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray60") +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray60") +
  geom_point(aes(size = eh_energia), alpha = 0.75) +
  geom_text_repel(data       = filter(lig, eh_energia),
                  aes(label  = cod_setor),
                  size        = 3, fontface = "bold",
                  max.overlaps = 20, show.legend = FALSE) +
  scale_size_manual(values  = c("FALSE" = 1.8, "TRUE" = 4),
                    labels  = c("Outros", "Energia"), name = "Tipo") +
  scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 17),
                     labels = c("Outros", "Energia"), name = "Tipo") +
  scale_color_brewer(palette = "Set1", name = "Quadrante") +
  annotate("text", x = 3.2, y = 1.42,
           label = "Setor-Chave", color = "gray30",
           size = 3.2, fontface = "italic") +
  labs(title    = "Diagrama de Rasmussen-Hirschman",
       subtitle = "Ligacao para tras (Uj) x Ligacao para frente (Ui)",
       x = "Ligacao para frente (Ui)", y = "Ligacao para tras (Uj)",
       caption  = "Fonte: MIP EPE/FIPE (2018) | triangulo = setor energetico") +
  theme_minimal(base_size = 12) +
  theme(plot.title    = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(color = "gray40", size = 10))

ggsave("grafico_setores_chave.png", p2, width = 10, height = 7, dpi = 150)
cat("Salvo: grafico_setores_chave.png\n")

# ── Gráfico 3: Impacto Choque 1 nos setores energéticos ----------------------
dados_g3 <- choque1 %>%
  filter(eh_energia) %>%
  mutate(nome_graf = nomes_grafico[cod_setor])

p3 <- ggplot(dados_g3,
             aes(x = reorder(nome_graf, delta_prod),
                 y = delta_prod / 1e3, fill = cod_setor)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = paste0("R$", round(delta_prod / 1e3, 1),
                               "bi (", round(var_pct, 2), "%)")),
            hjust = -0.05, size = 3) +
  scale_fill_manual(values = cores_energia) +
  scale_y_continuous(labels = label_number(suffix = " bi"),
                     limits = c(0, max(dados_g3$delta_prod / 1e3) * 1.4),
                     expand = c(0, 0)) +
  coord_flip() +
  labs(title    = "Impacto nos Setores Energeticos - Choque +5% Exportacoes",
       subtitle = "Variacao na producao (R$ bilhoes e %)",
       x = NULL, y = "Delta Producao (R$ bilhoes)",
       caption  = "Fonte: Simulacao MIP EPE/FIPE (2018)") +
  theme_minimal(base_size = 12) +
  theme(plot.title         = element_text(face = "bold", size = 13),
        plot.subtitle      = element_text(color = "gray40", size = 10),
        panel.grid.major.y = element_blank())

ggsave("grafico_choque_exportacoes.png", p3, width = 10, height = 6, dpi = 150)
cat("Salvo: grafico_choque_exportacoes.png\n")

}

# 9. EXPORTAR RESULTADOS
{
# =============================================================================

write_xlsx(
  list(
    "Multiplicadores"     = mult_df %>%
      select(cod_setor, nome_setor, multiplicador),
    "Indices_Ligacao"     = lig %>%
      select(cod_setor, nome_setor,
             ligacao_tras, ligacao_frente, quadrante) %>%
      mutate(across(ligacao_tras:ligacao_frente,
                    ~ round(., 4))),
    "Choque_Exportacoes"  = choque1 %>%
      select(cod_setor, nome_setor,
             delta_prod, x_base, var_pct),
    "Choque_Eletricidade" = choque2 %>%
      select(cod_setor, nome_setor,
             delta_prod, x_base, var_pct),
    "Demanda_Final"       = demanda_final %>%
      mutate(across(where(is.numeric), ~ round(., 2)))
  ),
  path = "resultados_mip_energia.xlsx"
)

cat("Salvo: resultados_mip_energia.xlsx\n")

}

