
###########################################################
#   Análise de Insumo-produto #


{
  # Passos iniciais
  
  # Definição do Diretório de Trabalho 
  setwd("C:/Users/Camila Ludovique/Desktop/Profissional/Politica Industrial Verde/Perobelli Curso")
  
  # Verificar o diretório de trabalho
  getwd()
  
  # Remover todos objetos do Environment
  rm(list = ls())

} # 1. Passos iniciais
{
  # Pacotes
  
  # Para instalar os pacotes abaixo, retire o # de cada linha:
   install.packages("openxlsx")
   install.packages("knitr")
   install.packages("kableExtra")
   install.packages("dplyr")
   install.packages("ggplot2")
   install.packages("scales")
   install.packages("ggrepel")
   install.packages("tibble")
   install.package("gridExtra")
  
  # Leitura dos pacotes
  library(openxlsx)
  library(knitr)
  library(kableExtra)
  library(dplyr)
  library(ggplot2)
  library(scales)
  library(ggrepel)
  library(tibble)
  library(gridExtra)
  
} # 2. Pacotes
{
  # Base de Dados
  
  {
    # Descrição
    
    # Matriz de Insumo-Produto (MIP) 2015 do Brasil disponibilizada pelo
    # IBGE com abertura para 12 atividades produtivas (setores). Os cálculos 
    # podem ser facilmente replicados com outras matrizes de insumo-produto,
    # inclusive com a MIP brasileira com 67 atividades produtivas.
    
    # Link para download da base de dados:
    # http://www.nedur.ufpr.br/portal/cursos/insumo-produto-r/
    
  } # Descrição
  {
    # Importando dados 
    
    # Importando doados com o pacote openxls
    Z = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "Z", colNames = FALSE) # Consumo intermediário 
    y = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "y", colNames = FALSE) # Demanda final
    x = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "x", colNames = FALSE) # Valor Bruto da Produção (VBP)
    v = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "v", colNames = FALSE) # Valor adicionado
    r = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "r", colNames = FALSE) # Remunerações
    e = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "e", colNames = FALSE) # Pessoal ocupado
    c = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "c", colNames = FALSE) # Consumo das famílias
    sp = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "sp", colNames = FALSE) # Setor de Pagamentos
    Setores = read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "set", colNames = FALSE) # Setores
    
  } # Importando dados
  {
    # Classe dos objetos
    
    class(Z) # Verificar classe do objeto Z
    class(y) # Verificar classe do objeto y
    
    # Mudar classe dos objetos
    Z = data.matrix(Z) # Consumo intermediário
    y = data.matrix(y) # Demanda final
    x = data.matrix(x) # Valor Bruto da Produção
    x = as.vector(x)   # Valor Bruto da Produção
    v = data.matrix(v) # Valor adicionado
    r = data.matrix(r) # Remunerações
    e = data.matrix(e) # Pessoal ocupado
    c = data.matrix(c) # Consumo das famílas
    sp = data.matrix(sp) # Setor de Pagamentos
  
  } # Classe dos objetos
  {
    # Exportando dados
    
    # Salvar base de dados no formato RData
    save(Z, y, x, v, r, e, c, file = "MIP_2021_67_qudrada_GIC.RData")
    
    # Importação de dados no formato RData
    load("MIP_2021_67_qudrada_GIC.RData")
    
    # Salvar dados no enviroment
    save.image(file = "IP_Obj.RData")
    
  } # Exportando dados
  
} # 3. Base de Dados
{
  # Insumo-Produto
  
  {
    # Modelo aberto
    
    A = Z %*% diag(1 / x) # Matriz de coeficientes técnicos
    View(A) # Matriz de coeficientes técnicos
    n = length(x) # Número de setores
    I = diag(n) # Matriz identidade
    View(I) # Matriz identidade
    B = solve(I - A) # Matriz inversa de Leontief
    View(B) # Matriz inversa de Leontief
    
    # Visualização de elementos específicos da matriz A e B
    A[1, 1]
    A[2, 1]
    B[1, 1]
    B[2, 1]
    
  } # Modelo aberto
  {
    # Modelo fechado
    
    hc = c / sum(r) # Coeficientes de consumo
    hr = r / x # Coeficientes de remuneração do trabalho (renda)
    hr = t(hr) # Coeficientes de remuneração do trabalho (renda) transposto
    AF = matrix(NA, ncol = n + 1, nrow = n + 1)  # Criação da matriz A do modelo fechado
    AF = rbind(cbind(A, hc), cbind(hr, 0)) # Matriz de coeficientes técnicos
    View(AF) # Matriz de coeficientes técnicos
    IF = diag(n + 1) # Matriz identidade (n+1)x(n+1)
    View(IF) # Matriz identidade (n+1)x(n+1)
    BF = solve(IF - AF) # Matriz inversa de Leontief no modelo fechado
    View(BF) # Matriz inversa de Leontief
    
    # Visualização de elementos específicosda matriz B
    BF[1, 1]
    
  } # Modelo fechado
  {
    # Modelo pelo lado da oferta
    
    F = diag(1 / x) %*% Z # Matriz de coeficientes técnicos pelo lado da oferta
    View(F) # Matriz de coeficientes técnicos pelo lado da oferta
    G = solve(I - F) # Matriz inversa de Ghosh
    View(G) # Matriz inversa de Ghosh
    
  } # Modelo pelo lado da oferta
  
} # 4. Insumo-Produto
{
  # Multiplicadores
  
  {
    # Multiplicadores de produção
    
    MP = colSums(B) # Multiplicadores Simples de Produção
    View(MP) # Multiplicadores Simples de Produção
    MPT = colSums(BF[, 1:n]) # Multiplicadores Totais de Produção
    View(MPT) # Multiplicadores Totais de Produção
    MPTT = colSums(BF[1:n, 1:n]) # Multiplicadores Totais de Produção Truncados
    View(MPTT) # Multiplicadores Totais de Produção Truncados
    
    # Tabela de dados (data frame) com os multiplicadores
    MultProd = cbind(Setores, MP, MPT, MPTT)
    MultProd = as.data.frame(MultProd)
    colnames(MultProd) = c("Setores", "MP", "MPT", "MPTT")
    
    MultProd$MP = as.numeric(as.character(MultProd$MP))
    MultProd$MPT = as.numeric(as.character(MultProd$MPT))
    MultProd$MPTT = as.numeric(as.character(MultProd$MPTT))
    
    MultProd # Visualização do objeto (data.frame com os multiplicadores)
    
    # Tabela com os multiplicadores
    kable(MultProd, caption = "Multiplicadores de Produção", align = "lccc") %>%
      kable_styling(bootstrap_options = "striped", full_width = FALSE) %>% 
      footnote(general = "Elaboração própria com dados da MIP do GIC.",
               general_title = "Fonte:",
               footnote_as_chunk = TRUE, title_format = c("bold"))
    
    # Multiplicador Total de Produção do Setor 1:
    format(round(sum(BF[, 1]), digits = 4), nsmall = 4) # Efeito Total no modelo fechado
    format(round(sum(B[, 1]), digits = 4), nsmall = 4) # Efeito Total no modelo aberto
    format(round(sum(BF[, 1]) - sum(B[, 1]), digits = 4), nsmall = 4) # Efeito Induzido
    format(round(sum(A[, 1]), digits = 4), nsmall = 4) # Efeito Direto
    format(round(sum(B[, 1]) - sum(A[, 1]), digits = 4), nsmall = 4) # Efeito Indireto
    
    # Multiplicador Total de Produção Truncado do Setor 1:
    format(round(sum(BF[1:n, 1]), digits = 4), nsmall = 4) # Efeito Total no modelo fechado
    format(round(sum(B[, 1]), digits = 4), nsmall = 4) # Efeito Total no modelo aberto
    format(round(sum(BF[1:n, 1]) - sum(B[, 1]), digits = 4), nsmall = 4) # Efeito Induzido
    format(round(sum(A[, 1]), digits = 4), nsmall = 4) # Efeito Direto
    format(round(sum(B[, 1]) - sum(A[, 1]), digits = 4), nsmall = 4) # Efeito Indireto
    
    # Graficos
    
    # Multiplicadores Simples de Produção
    ggplot(MultProd, aes(x = factor(Setores, levels = unique(Setores)), y = MP)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores Simples de Produção") +
      labs(subtitle = "2021",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MP, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0, 2.5),
                         breaks = seq(from = 0.0, to = 2.5, by = 0.5))
    
    
    # Multiplicadores Totais de Produção
    ggplot(MultProd, aes(x = factor(Setores, levels = unique(Setores)), y = MPT)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores Totais de Produção") +
      labs(subtitle = "2015") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MPT, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0, 5.5),
                         breaks = seq(from = 0.0, to = 5.5, by = 0.5))
    
    
    # Multiplicadores Totais de Produção Truncados
    ggplot(MultProd, aes(x = factor(Setores, levels = unique(Setores)), y = MPTT)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores Totais de Produção Truncados") +
      labs(subtitle = "2015") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MPTT, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0, 4.5),
                         breaks = seq(from = 0.0, to = 4.5, by = 0.5))

  } # Multiplicadores de produção
  {
    # Multiplicadores de emprego
    
    ce = e / x # Coeficientes de emprego
    ce = as.vector(ce) # Coeficientes de emprego
    Cehat = diag(ce) # Matriz com os coeficientes de emprego
    E = Cehat %*% B # Matriz geradora de empregos
    
    ME = colSums(E) # Multiplicadores Simples de Emprego
    View(ME) # Multiplicadores Simples de Emprego
    MEI = ME / ce # Multiplicadores de Emprego (Tipo I)
    View(MEI) # Multiplicadores de Emprego (Tipo I)
    
    EF = Cehat %*% BF[1:n, 1:n] # Matriz geradora de empregos com modelo fechado
    
    MET = colSums(EF) # Multiplicadores Totais de Emprego (truncados)
    View(MET) # Multiplicadores Totais de Emprego (truncados)
    MEII = MET / ce # Multiplicadores de Emprego (Tipo II)
    View(MEII) # Multiplicadores de Emprego (Tipo II)
    
    # Tabela de dados (data frame) com os multiplicadores
    MultEmp = cbind(Setores, ME, MEI, MET, MEII)
    MultEmp = as.data.frame(MultEmp)
    colnames(MultEmp) = c("Setores", "ME", "MEI", "MET", "MEII")
    
    MultEmp$ME = as.numeric(as.character(MultEmp$ME))
    MultEmp$MEI = as.numeric(as.character(MultEmp$MEI))
    MultEmp$MET = as.numeric(as.character(MultEmp$MET))
    MultEmp$MEII = as.numeric(as.character(MultEmp$MEII))
    
    MultEmp # Visualização do objeto (data.frame com os multiplicadores)
    
    # Tabela com os multiplicadores
    kable(MultEmp, caption = "Multiplicadores de Emprego", align = "lcccc") %>%
      kable_styling(bootstrap_options = "striped", full_width = FALSE) %>% 
      footnote(general = "Elaboração própria com dados da MIP do IBGE (2015).",
               general_title = "Fonte:",
               alphabet = "ME e MET por 1.000.000 R$.",
               alphabet_title = "Nota:",
               footnote_as_chunk = TRUE, title_format = c("bold"))
    
    # Gráficos
    
    # Multiplicadores Simples de Emprego
    ggplot(MultEmp, aes(x = factor(Setores, levels = unique(Setores)), y = ME)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores Simples de Emprego") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).\nNota: Por 1.000.000 R$.") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(ME, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01), 
                         limits = c(0,35),
                         breaks = seq(from = 0.0, to = 35.0, by = 5))
    
    
    # Multiplicadores de Emprego (Tipo I)
    ggplot(MultEmp, aes(x = factor(Setores, levels = unique(Setores)), y = MEI)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores de Emprego (Tipo I)") +
      labs(subtitle = "2015") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MEI, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0,8),
                         breaks = seq(from = 0.0, to = 8, by = 1))
    
    
    # Multiplicadores Totais de Emprego (truncados)
    ggplot(MultEmp, aes(x = factor(Setores, levels = unique(Setores)), y = MET)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores Totais de Emprego (truncados)") +
      labs(subtitle = "2015") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).\nNota: Por 1.000.000 R$.") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MET, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0,45),
                         breaks = seq(from = 0, to = 45, by = 5))
    
    
    # Multiplicadores de Emprego (Tipo II)
    ggplot(MultEmp, aes(x = factor(Setores, levels = unique(Setores)), y = MEII)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores de Emprego (Tipo II)") +
      labs(subtitle = "2015") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MEII, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0,20),
                         breaks = seq(from = 0, to = 20, by = 5))
    
  } # Multiplicadores de emprego
  {
    # Multiplicadores de renda
    
    cr = r / x # Coeficientes de renda
    cr = as.vector(cr) # Coeficientes de renda
    Crhat = diag(cr) # Matriz com os coeficientes de renda
    R = Crhat %*% B # Matriz geradora de renda
    
    MR = colSums(R) # Multiplicadores Simples de Renda
    View(MR) # Multiplicadores Simples de Renda
    MRI = MR / cr # Multiplicadores de Renda (Tipo I)
    View(MRI) #Multiplicadores de Renda (Tipo I)
    
    RF = Crhat %*% BF[1:n, 1:n] # Matriz geradora de renda com modelo fechado
    
    MRT = colSums(RF) # Multiplicadores Totais de Renda (truncados)
    View(MRT) # Multiplicadores Totais de Renda (truncados)
    MRII = MRT / cr # Multiplicadores de Renda (Tipo II)
    View(MRII) # Multiplicadores de Renda (Tipo II)
    
    # Tabela de dados (data frame) com os multiplicadores
    MultRen = cbind(Setores, MR, MRI, MRT, MRII)
    MultRen = as.data.frame(MultRen)
    colnames(MultRen) = c("Setores", "MR", "MRI", "MRT", "MRII")
    
    MultRen$MR = as.numeric(as.character(MultRen$MR))
    MultRen$MRI = as.numeric(as.character(MultRen$MRI))
    MultRen$MRT = as.numeric(as.character(MultRen$MRT))
    MultRen$MRII = as.numeric(as.character(MultRen$MRII))
    
    MultRen #Visualização do objeto (data.frame com os multiplicadores)
    
    # Tabela com os multiplicadores
    kable(MultRen, caption = "Multiplicadores de Renda", align = "lcccc") %>%
      kable_styling(bootstrap_options = "striped", full_width = FALSE) %>% 
      footnote(general = "Elaboração própria com dados da MIP do IBGE (2015).",
               general_title = "Fonte:",
               footnote_as_chunk = TRUE, title_format = c("bold"))
    
    # Gráficos
    
    # Multiplicadores Simples de Renda
    ggplot(MultRen, aes(x = factor(Setores, levels = unique(Setores)), y = MR)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores Simples de Renda") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MR, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01), 
                         limits = c(0,1),
                         breaks = seq(from = 0, to = 1, by = 0.25))
    
    
    # Multiplicadores de Renda (Tipo I)
    ggplot(MultRen, aes(x = factor(Setores, levels = unique(Setores)), y = MRI)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores de Renda (Tipo I)") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MRI, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0,3.5),
                         breaks = seq(from = 0, to = 3.5, by = 0.5))
    
    
    # Multiplicadores Totais de Renda (truncados)
    ggplot(MultRen, aes(x = factor(Setores, levels = unique(Setores)), y = MRT)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores Totais de Renda (truncados)") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MRT, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0,1.5),
                         breaks = seq(from = 0, to = 1.5, by = 0.25))
    
      # Multiplicadores de Renda (Tipo II)
    ggplot(MultRen, aes(x = factor(Setores, levels = unique(Setores)), y = MRII)) +
      geom_col() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab("Setores") +
      ylab(" ") +
      ggtitle("Multiplicadores de Renda (Tipo II)") +
      labs(subtitle = "2015",
           caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text(aes(label = round(MRII, digits = 2)), vjust = -0.5, size = 3) +
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                         limits = c(0,6),
                         breaks = seq(from = 0, to = 6, by = 0.5))

  } # Multiplicadores de renda
  
} # 5. Multiplicadores
{
  # Índices de Ligação
  
  {
    # Índices de Ligação HR
    
    SC = colSums(B) # Soma dos elementos de B nas colunas
    SL = rowSums(B) # Soma dos elementos de B nas linhas
    MC = SC / n # Valor médio dos elementos nas colunas
    ML = SL / n # Valor médio dos elementos nas linhas
    Bstar = sum(B) / n ** 2 # Valor médio dos elementos de B
    
    BL = MC / Bstar # Índices de Ligação para trás (BL)
    FL = ML / Bstar # Índices de Ligação para frente (FL)
    
    SLG = rowSums(G) # Soma dos elementos de G nas linhas
    MLG = SLG / n # Valor médio dos elementos nas linhas
    Gstar = sum(G) / n ** 2 # Valor médio dos elementos de G
    FLG = MLG / Gstar # Índices de Ligação para frente (FLG) com modelo pelo lado da oferta
    
    # Tabela de dados (data frame) com os índices
    IndLig = cbind(Setores, BL, FL, FLG)
    IndLig = as.data.frame(IndLig)
    colnames(IndLig) = c("Setores", "BL", "FL", "FLG")
    
    IndLig$BL = as.numeric(as.character(IndLig$BL))
    IndLig$FL = as.numeric(as.character(IndLig$FL))
    IndLig$FLG = as.numeric(as.character(IndLig$FLG))
    
    IndLig # Visualização do objeto (data.frame com os índices)
    
    # Setores-chave
    IndLig = mutate(IndLig, Setores.Chave = ifelse(BL > 1 &
                                                     FLG > 1, "Setor-Chave", "-"))
    
    IndLig # Visualização do objeto (data.frame com os índices)
    
    # Tabela com os índices
    kable(IndLig, caption = "Índices de Ligação e Setores-Chave", align = "lcccc") %>%
      kable_styling(bootstrap_options = "striped", full_width = FALSE) %>% 
      footnote(general = "Elaboração própria com dados da MIP do IBGE (2015).",
               general_title = "Fonte:",
               alphabet = "Setores-Chave definidos com base nos índices BL e FLG.",
               alphabet_title = "Nota:",
               footnote_as_chunk = TRUE, title_format = c("bold"))
    
    # Gráfico
    ggplot(IndLig, aes(x = FLG, y = BL)) +
      geom_point() +
      theme_bw() +
      theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
      xlab(expression("Índice de ligação para frente"~"("*U[i]*")")) +
      ylab(expression("Índice de ligação para trás"~"("*U[j]*")")) +
      ggtitle("Índices de Ligação e Setores-Chave") +
      labs(subtitle = "2021",
           caption = "Fonte: Elaboração própria com dados do GIC.\nNota: Índices de ligação para frente calculados com a matriz inversa de Ghosh.") +
      theme(plot.title = element_text(hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.caption = element_text(hjust = 0)) +
      geom_text_repel(aes(label = Setores), vjust = 0.8, size = 2.5)+
      scale_y_continuous(labels = scales::number_format(accuracy = 0.01), 
                         limits = c(0.5,1.5),
                         breaks = seq(from = 0.5, to = 2, by = 0.25)) +
      scale_x_continuous(labels = scales::number_format(accuracy = 0.01), 
                         limits = c(0.5,1.5),
                         breaks = seq(from = 0.5, to = 1.5, by = 0.25)) +
      geom_hline(yintercept=1, linetype="dashed", color = "black") +
      geom_vline(xintercept=1, linetype="dashed", color = "black") +
      annotate("text", x=1.42, y=1.5, 
               label= "Setor-Chave", colour='black', size=3) +
      annotate('text', x=0.65, y=1.5, 
               label='Forte encadeamento para trás', colour='black', size=3) +
      annotate('text', x=0.60, y=0.5, 
               label='Fraco encadeamento', colour='black', size=3) +
      annotate('text', x=1.35, y=0.5, 
               label='Forte encadeamento para frente', colour='black', size=3)
    
    # Coeficientes de variação
    Vj = (((1 / (n - 1)) * (rowSums((B - MC) ** 2))) ** 0.5) / MC
    Vi = (((1 / (n - 1)) * (colSums((B - ML) ** 2))) ** 0.5) / ML
    
    # Tabela de dados (data frame) com os coeficientes de variação
    CoefVar = cbind(Setores, Vj, Vi)
    CoefVar = as.data.frame(CoefVar)
    colnames(CoefVar) = c("Setores", "Vj", "Vi")
    
    CoefVar$Vj = as.numeric(as.character(CoefVar$Vj))
    CoefVar$Vi = as.numeric(as.character(CoefVar$Vi))
    
    CoefVar # Visualização do objeto (data.frame com os coeficientes)
    
    # Tabela com os coeficientes de variação
    kable(CoefVar, caption = "Coeficientes de Variação", align = "lcc") %>%
      kable_styling(bootstrap_options = "striped", full_width = FALSE) %>% 
      footnote(general = "Elaboração própria com dados da MIP do IBGE (2015).",
               general_title = "Fonte:",
               footnote_as_chunk = TRUE, title_format = c("bold"))
    
  } # Índices de Ligação HR
  {
    # Índices Puros de Ligação
    
    IPL = matrix(NA, ncol=3, nrow=n) # Criação da matriz IPL para receber os resultados do loop
    
    # Loop Índices Puros de Ligação
    for (s in 1:n) {
      for (i in 1:n) {
        for (j in 1:n) {
          if (s==i) {
            if (i==j) {
              yj  = y[i]
              yr  = y[-i]
              Ajj = A[i, j]
              DJ  = solve(1 - Ajj)
              Ajr = A[i, -j]
              Arj = A[-i, j]
              Arr = A[-i, -j]
              DR  = solve(diag(n - 1) - Arr)
              PBL = sum (DR %*% Arj %*% DJ %*% yj)
              PFL = DJ %*% Ajr %*% DR %*% yr
              PTL = PBL + PFL
              IPuros = c(PBL, PFL, PTL)
            }}}}
      IPL[s, ] = IPuros
      }    

    IPL # Visualização do objeto
    
    # Índices Puros de Ligação Normalizados
    IPLm = (colSums(IPL) / n)
    IPLm = as.vector(IPLm)
    
    IPLN = IPL %*% (diag(1 / IPLm))
    
    # Tabela de dados (data frame) com os Índices Puros de Ligação Normalizados
    IPLN = as.data.frame(IPLN)
    IPLN = cbind(Setores, IPLN)
    colnames(IPLN) = c("Setores", "PBLN", "PFLN", "PTL")
    
    IPLN # Visualização do objeto
    
    # Tabela com os Índices Puros de Ligação Normalizados
    kable(IPLN, caption = "Índices Puros de Ligação Normalizados", align = "lccc") %>%
      kable_styling(bootstrap_options = "striped", full_width = FALSE) %>% 
      footnote(general = "Elaboração própria com dados da MIP do IBGE (2015).",
               general_title = "Fonte:",
               footnote_as_chunk = TRUE, title_format = c("bold"))
    
  } # Índices Puros de Ligação HR
  
} # 6. Índices de Ligação
{
  # Campo de Influência
  
  ee = 0.001 # Incremento
  E = matrix(0, ncol = n, nrow = n) # Matriz de variações incrementais (será preenchida no loop)
  SI = matrix(0, ncol = n, nrow = n) # Matriz de campo de influência (será preenchida no loop)
  
  # Loop Campo de Influência
  for (i in 1:n) {
    for (j in 1:n) {
      E[i, j] = ee
      AE = A + E
      BE = solve(I - AE)
      FE = (BE - B) / ee
      FEq = FE * FE
      S = sum(FEq)
      SI[i, j] = S
      E[i, j] = 0
    }
  }
  
  # Gráficos

  sx = Setores[1:n, ]
  sy = Setores[1:n, ]
  data = expand.grid(X = sx, Y = sy)
  
  ggplot(data,aes(X, Y, fill = SI)) + 
    geom_tile() +
    theme_bw() +
    theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
    xlab("Setores") +
    ylab("Setores") +
    ggtitle("Campo de Influência") +
    labs(subtitle = "2015",
         caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
    theme(plot.title = element_text(hjust = 0.5),
          plot.subtitle = element_text(hjust = 0.5),
          plot.caption = element_text(hjust = 0)) +
    theme(axis.text.x = element_text(angle=35, vjust = 0.7),
          axis.text.y = element_text(angle=35, hjust = 0.7)) +
    theme(legend.position = "none") +
    scale_fill_distiller(palette = "Greys", trans = "reverse")
  
  
  # Tipologia com base na média
  SI2 = as_tibble(SI) %>% 
    mutate_all(funs(case_when(. < mean(SI) ~ 1,
                              . >= mean(SI) & . < (mean(SI) + sd(SI)) ~ 2,
                              . >= (mean(SI) + sd(SI)) & . < (mean(SI) + 2 * sd(SI)) ~ 3,
                              . >= (mean(SI) + 2 * sd(SI)) ~ 4)))
  
  SI2 = as.factor(as.matrix(SI2))
  
  # Gráfico
  ggplot(data,aes(X, Y)) + 
    geom_tile(aes(fill= SI2)) +
    theme_bw() +
    theme(plot.background = element_rect(fill = "#e6f2ff", colour = "#e6f2ff")) +
    xlab("Setores") +
    ylab("Setores") +
    ggtitle("Campo de Influência") +
    labs(subtitle = "2015",
         caption = "Fonte: Elaboração própria com dados da MIP do IBGE (2015).") +
    theme(plot.title = element_text(hjust = 0.5),
          plot.subtitle = element_text(hjust = 0.5),
          plot.caption = element_text(hjust = 0)) +
    theme(axis.text.x = element_text(angle=35, vjust = 0.7),
          axis.text.y = element_text(angle=35, hjust = 0.7)) +
    scale_fill_manual(name = "SI",
                      values=c("#e9e9e9", "#a9a9a9", "#3f3f3f", "#191919"),
                      labels = c ("< Média", "< Média + DP", "< Média + 2DP", "> Média + 2DP"))
  
} # 7. Campo de Influência
{
  # Extração Hipotética
  
  # 0) Pré-checagens e objetos

  n <- length(x)
  
  # Checa dimensões básicas
  stopifnot(all(dim(Z) == c(n, n)))
  stopifnot(all(dim(A) == c(n, n)))
  stopifnot(all(dim(F) == c(n, n)))
  stopifnot(all(dim(I) == c(n, n)))
  stopifnot(length(y) == n)
  
  # ---------------------------
  # 1) Consertar/validar Setores
  #    (evita aparecer c("A","B",...) repetido em todas as linhas)
  # ---------------------------
  
  # Se Setores vier como lista (muito comum), "desembrulha"
  if (is.list(Setores)) {
    # caso típico: lista com 1 elemento que é o vetor de setores
    if (length(Setores) == 1 && (is.atomic(Setores[[1]]) || is.character(Setores[[1]]))) {
      Setores <- Setores[[1]]
    } else {
      Setores <- unlist(Setores, use.names = FALSE)
    }
  }
  
  Setores <- as.character(Setores)
  
  # Se ainda estiver errado, para aqui com erro claro
  stopifnot(length(Setores) == n)
  
  # ---------------------------
  # 2) Vetor sp (oferta primária por setor)
  #    ATENÇÃO: seu sp estava 1x1; aqui vira n
  # ---------------------------
  
  # Para MIP quadrada: oferta primária por coluna (setor produtor)
  # sp_j = x_j - sum_i Z_ij  (valor adicionado / oferta primária)
  sp <- as.numeric(x) - colSums(Z)
  stopifnot(length(sp) == n)
  
  # ---------------------------
  # 3) Inicializar vetores de resultados
  # ---------------------------
  
  BLextrac <- rep(NA_real_, n)  # extração pelo lado da demanda (coluna j)
  FLextrac <- rep(NA_real_, n)  # extração pelo lado da oferta  (linha i)
  
  # (opcional) guardar também xbl e xfl se quiser debugar:
  # XBL_all <- matrix(NA_real_, nrow = n, ncol = n)
  # XFL_all <- matrix(NA_real_, nrow = n, ncol = n)
  
  # ---------------------------
  # 4) Extração Hipotética - BL (Leontief)
  #    remove a coluna j de A (setor j "não compra insumos" / extração)
  # ---------------------------
  
  for (j in 1:n) {
    ABL <- A
    ABL[, j] <- 0
    
    # Inversa de Leontief com a extração
    BBL <- solve(I - ABL)
    
    # produção com extração
    xbl <- as.numeric(BBL %*% y)
    
    # impacto total (diferença no total da produção)
    BLextrac[j] <- sum(x) - sum(xbl)
    
    # (opcional) XBL_all[, j] <- xbl
  }
  
  # ---------------------------
  # 5) Extração Hipotética - FL (Ghosh / oferta)
  #    remove a linha i de F (setor i "não vende insumos" / extração)
  #    produção-oferta resultante: xfl = t(sp) %*% G
  # ---------------------------
  
  for (i in 1:n) {
    FFL <- F
    FFL[i, ] <- 0
    
    # Inversa de Ghosh com a extração
    GFL <- solve(I - FFL)
    
    # produção pela ótica da oferta (1 x n)
    xfl <- as.numeric(t(sp) %*% GFL)
    
    # impacto total
    FLextrac[i] <- sum(x) - sum(xfl)
    
    # (opcional) XFL_all[i, ] <- xfl
  }
  
  # ---------------------------
  # 6) Percentuais
  # ---------------------------
  
  BLextracp <- BLextrac / sum(x) * 100
  FLextracp <- FLextrac / sum(x) * 100
  
  # ---------------------------
  # 7) Tabela final
  # ---------------------------
  
  Extrac <- data.frame(
    Setores = Setores,
    BL      = BLextrac,
    FL      = FLextrac,
    `BL%`   = BLextracp,
    `FL%`   = FLextracp,
    check.names = FALSE
  )
  
  # Visualizar
  Extrac
  
  # ---------------------------
  # 8) kable (com & sem escapar HTML)
  # ---------------------------
  
  kable(Extrac, caption = "Extração Hipotética", align = "lcccc", escape = FALSE) %>%
    kable_styling(bootstrap_options = "striped", full_width = FALSE) %>%
    footnote(
      general = "Elaboração própria com dados da MIP do IBGE (2015).",
      general_title = "Fonte:",
      footnote_as_chunk = TRUE,
      title_format = c("bold")
    )
  
} # 8. Extração Hipotética
{
  # Decomposição Estrutural
  
  # Leitura do pacote
  library(openxlsx)
  
  ## Ano: 2015
  
  # Consumo Intermediário: 
  Z15 = data.matrix(read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "Z", colNames = FALSE))
  
  # Demanda Final:
  y15 = data.matrix(read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "y", colNames = FALSE))
  
  # Valor Bruto da Produção:
  x15 = data.matrix(read.xlsx("MIP_2021_67_qudrada_GIC.xlsx", sheet = "x", colNames = FALSE))
  x15 = as.vector(x15)
  
  ## Ano: 2010
  
  # Consumo Intermediário: 
  Z10 = data.matrix(read.xlsx("MIP2010_12s.xlsx", sheet = "Z", colNames = FALSE))
  
  # Demanda Final:
  y10 = data.matrix(read.xlsx("MIP2010_12s.xlsx", sheet = "y", colNames = FALSE))
  
  # Valor Bruto da Produção:
  x10 = data.matrix(read.xlsx("MIP2010_12s.xlsx", sheet = "x", colNames = FALSE))
  x10 = as.vector(x10)
  
  
  ## Ano: 2010
  ## Atualização
  Z10 = Z10 / 71.13 * 100 # Consumo Intermediário 
  y10 = y10 / 71.13 * 100 # Demanda Final
  x10 = x10 / 71.13 * 100 # Valor Bruto da Produção
  
  ## Auxiliares
  n = length(x15) # Número de setores (o mesmo nos dois anos)
  I = diag(n)     # Matriz Identidade
  
  ## Ano: 2015
  
  A15 = Z15 %*% diag(1 / x15) # Matriz de Coeficientes Técnicos
  B15 = solve(I - A15)        # Matriz Inversa de Leontief
  
  ## Ano: 2010
  
  A10 = Z10 %*% diag(1 / x10) # Matriz de Coeficientes Técnicos
  B10 = solve(I - A10)        # Matriz Inversa de Leontief
  
  deltax = x15 - x10 # Variação produto
  
  MUD_TEC = 0.5 *((B15 - B10) %*% (y10 + y15)) # Mudança tcnológica
  MUD_DF = 0.5 *((B10 + B15) %*% (y15 - y10)) # Mudança na demanda
  
  # Tabela com os resultados
  Decomp = cbind(Setores, deltax, MUD_TEC, MUD_DF)
  
  colnames(Decomp) = c("Setores", "Var. x", "Var. Tecnológica", "Var. Demanda Final")
  
  Decomp = rbind(Decomp, c("Total", colSums(Decomp[, 2:4])))
  
  Decomp$`Var. x` = as.numeric(Decomp$`Var. x`)
  Decomp$`Var. Tecnológica` = as.numeric(Decomp$`Var. Tecnológica`)
  Decomp$`Var. Demanda Final` = as.numeric(Decomp$`Var. Demanda Final`)
  
  Decomp
  
  # Leitura dos pacotes
  library(knitr)
  library(kableExtra)
  library(dplyr)
  
  # Tabela
  kable(Decomp, caption = "Decomposição Estrutural", align = "lccc") %>%
    kable_styling(bootstrap_options = "striped", full_width = FALSE) %>% 
    footnote(general = "Elaboração própria com dados da MIP do IBGE (2015/10).",
             general_title = "Fonte:",
             footnote_as_chunk = TRUE, title_format = c("bold"))
  
  # Gráfico
  
  # Leitura dos pacotes
  library(ggplot2)
  library(scales)
  
  # Seleção apenas dos n setores (exclui a linha com o total)
  Decomp_set = Decomp[-13,]
  
  # Variação de x
  g1 = ggplot(Decomp_set) +
    geom_col(aes(x = factor(Setores, levels = unique(Setores)), y = `Var. x`), 
             fill = "blue4") +
    theme_bw() +
    xlab("Setores") +
    ylab(" ") +
    ggtitle("Decomposição Estrutural") +
    labs(subtitle = "2015-2010\nVariação do Produto") +
    theme(plot.title = element_text(hjust = 0.5),
          plot.subtitle = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle=35, vjust = 0.7)) +
    scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                       limits = c(-50000, 250000),
                       breaks = seq(from = -50000, to = 250000, by = 50000))
  
  # Variação Tecnológica
  g2 = ggplot(Decomp_set) +
    geom_col(aes(x = factor(Setores, levels = unique(Setores)), y = `Var. Tecnológica`), 
             fill = "firebrick") +
    theme_bw() +
    xlab("Setores") +
    ylab(" ") +
    ggtitle("Variação Tecnológica") +
    theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) +
    scale_y_continuous(labels = scales::number_format(accuracy = 0.01))
  
  # Variação na Demanda Final
  g3 =  ggplot(Decomp_set) +
    geom_col(aes(x = factor(Setores, levels = unique(Setores)), y = `Var. Demanda Final`),
             fill = "deepskyblue3") +
    theme_bw() +
    xlab("Setores") +
    ylab(" ") +
    ggtitle("Variação na Demanda Final") +
    theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) +
    scale_y_continuous(labels = scales::number_format(accuracy = 0.01))
  
  # Grid com os três gráficos
  library(gridExtra)
  grid.arrange(g1, arrangeGrob(g2, g3, ncol = 2), ncol = 1,
               bottom = "Fonte: Elaboração própria com dados da MIP do IBGE (2015/2010).")
  
} # 9. Decomposição Estrutural
{
  # Exportando Resultados
  
  # Criando o "workbooK" para receber os resultados
  wb = createWorkbook()
  
  # Definindo as abas
  addWorksheet(wb, "MP")
  addWorksheet(wb, "ME")
  addWorksheet(wb, "MR")
  addWorksheet(wb, "IndHR")
  addWorksheet(wb, "CV")
  addWorksheet(wb, "IPLN")
  addWorksheet(wb, "SI")
  addWorksheet(wb, "ExtHipo")
  #addWorksheet(wb, "Decomp")
  
  # Salvando os resultados nas abas
  writeDataTable(wb, "MP", x = MultProd)
  writeDataTable(wb, "ME", x = MultEmp)
  writeDataTable(wb, "MR", x = MultRen)
  writeDataTable(wb, "IndHR", x = IndLig)
  writeDataTable(wb, "CV", x = CoefVar)
  writeDataTable(wb, "IPLN", x = IPLN)
  writeData(wb, "SI", x = SI, colNames = FALSE)
  writeDataTable(wb, "ExtHipo", x = Extrac)
  #writeDataTable(wb, "Decomp", x = Decomp)
  
  # Exportando como arquivo XLSX
  saveWorkbook(wb, file = "Resultados.xlsx", overwrite = TRUE)
  
} # 10. Exportanto Resultados


