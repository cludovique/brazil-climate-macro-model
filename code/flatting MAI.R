# ============================================================
# Transformar MAI do GIC/IE (arquivo "MAIs - Ref. 2010.xlsx")
# em formato LONG (flat) para usar no Tableau
# ============================================================

# Se já estiver com o setwd certo, não precisa mexer aqui
# setwd("C:/Users/Camila Ludovique/Desktop/Profissional/Politica Industrial Verde/GIC_Data - MAI/Dados")

# ------------------------------
# 1. Carregar pacotes
# ------------------------------
library(readxl)   # ler Excel
library(dplyr)    # manipulação de dados
library(tidyr)    # pivot_longer
library(stringr)  # regex, str_detect, str_match
library(purrr)    # map_dfr
library(readr)    # write_csv

# ------------------------------
# 2. Caminho do arquivo
# ------------------------------
arquivo_mai <- "MAIs - Ref. 2010.xlsx"  # ajuste o nome se estiver diferente

# ------------------------------
# 3. Função para processar UMA aba (ex.: "MAI ON (2010)")
# ------------------------------
processar_aba_mai <- function(sheet_name) {
  message("Processando aba: ", sheet_name)
  
  # extrair tipo (ON/OI/OT) e ano do nome da aba
  m <- stringr::str_match(sheet_name, "^MAI\\s+(ON|OI|OT)\\s*\\((\\d{4})\\)$")
  tipo_mai <- m[2]
  ano      <- as.integer(m[3])
  
  # ler a aba SEM cabeçalho (para pegar linha 1 e 2 manualmente)
  df_raw <- readxl::read_excel(arquivo_mai, sheet = sheet_name, col_names = FALSE)
  
  # linha 1: códigos dos setores (0101, 0102, ...)
  cod_setor_row <- df_raw[1, ]
  # linha 2: nomes das colunas (Código GIC..., Descrição..., nomes dos setores, TOTAL)
  header_row    <- df_raw[2, ]
  
  # dados a partir da linha 3
  dados <- df_raw[-c(1, 2), ]
  
  # -------- arrumar cabeçalho (evitar NA / "") --------
  header_vec <- header_row %>%
    unlist() %>%
    as.character() %>%
    stringr::str_trim()
  
  # onde for NA ou "", cria um nome genérico (V1, V2, ...)
  idx_bad <- is.na(header_vec) | header_vec == ""
  header_vec[idx_bad] <- paste0("V", which(idx_bad))
  
  colnames(dados) <- header_vec
  
  # remover linhas totalmente vazias
  dados <- dados[rowSums(is.na(dados)) < ncol(dados), ]
  
  # identificar nome da coluna TOTAL (pode ser "TOTAL" ou "Total")
  col_total <- names(dados)[stringr::str_detect(names(dados),
                                                stringr::regex("^TOTAL$", ignore_case = TRUE))]
  if (length(col_total) == 0) {
    col_total <- NA_character_
  }
  
  # garantir que as colunas de código e descrição existem
  # (ajuste aqui se o nome tiver um espacinho diferente)
  nome_cod  <- "Código GIC Produto 91"
  nome_desc <- "Descrição Código GIC Produto 91"
  
  # manter apenas linhas com código de produto válido
  dados <- dados %>%
    dplyr::filter(
      !is.na(.data[[nome_cod]]),
      .data[[nome_cod]] != "Total"
    )
  
  # identificar colunas de setores:
  # todas exceto código, descrição e TOTAL
  col_excluir <- c(nome_cod, nome_desc, col_total)
  col_excluir <- col_excluir[!is.na(col_excluir)]
  
  col_setores <- setdiff(colnames(dados), col_excluir)
  col_setores <- col_setores[col_setores != ""]
  
  # dicionário de códigos de setor:
  cod_setor_vec <- cod_setor_row %>%
    unlist() %>%
    as.character()
  names(cod_setor_vec) <- header_vec
  
  dict_setor <- tibble::tibble(
    setor_nome   = col_setores,
    setor_codigo = cod_setor_vec[col_setores]
  )
  
  # wide → long
  dados_long <- dados %>%
    tidyr::pivot_longer(
      cols      = dplyr::all_of(col_setores),
      names_to  = "setor_nome",
      values_to = "valor"
    )
  
  # limpar valores e transformar em número (formato tipo 7,368.2)
  dados_long <- dados_long %>%
    dplyr::mutate(
      valor = ifelse(valor %in% c("-", "–", ""), NA, valor),
      valor = gsub(" ", "", valor),     # tira espaços
      valor = gsub(",", "", valor),     # remove vírgula (milhar)
      valor = as.numeric(valor)         # converte mantendo o ponto como decimal
    )
  
  
  
  # juntar códigos de setor + metadata
  dados_long <- dados_long %>%
    dplyr::left_join(dict_setor, by = "setor_nome") %>%
    dplyr::mutate(
      tipo_mai = tipo_mai,
      ano      = ano,
      unidade  = "R$ 1.000.000 - Unidades de Volume"
    ) %>%
    dplyr::rename(
      cod_produto_gic  = !!nome_cod,
      desc_produto_gic = !!nome_desc
    ) %>%
    dplyr::select(
      ano,
      tipo_mai,
      cod_produto_gic,
      desc_produto_gic,
      setor_codigo,
      setor_nome,
      valor,
      unidade
    )
  
  return(dados_long)
}


# ------------------------------
# 4. Listar abas relevantes e aplicar a função
# ------------------------------
todas_abas <- readxl::excel_sheets(arquivo_mai)

# só abas do tipo "MAI ON (2010)", "MAI OI (2010)", "MAI OT (2010)"
abas_mai_ano <- todas_abas[stringr::str_detect(
  todas_abas,
  "^MAI\\s+(ON|OI|OT)\\s*\\([0-9]{4}\\)$"
)]

# (opcional) ver quais abas vão ser usadas
print(abas_mai_ano)

# aplicar a função em cada aba e empilhar
mai_flat <- purrr::map_dfr(abas_mai_ano, processar_aba_mai)

summary(mai_flat$valor)


# ------------------------------
# 5. Salvar base final para o Tableau
# ------------------------------
readr::write_csv(mai_flat, "MAI_flat_todos_tipos_anos.csv")

message("Concluído! Arquivo 'MAI_flat_todos_tipos_anos.csv' gerado no diretório de trabalho.")

