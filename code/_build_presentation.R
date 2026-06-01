# =============================================================================
# BUILD PPE PRESENTATION — MIP×MMA Model
# Creates: docs/MIP_MMA_PPE_apresentacao.pptx
# =============================================================================
library(officer)
library(dplyr)

setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
d <- readRDS("data/processed/mma_shocks.rds")

# ── Palette ────────────────────────────────────────────────────────────────────
DARK  <- "#1C2B4A"; GREEN <- "#1D9E75"; LGREE <- "#3DC494"; AMBER <- "#F39C12"
WHITE <- "#FFFFFF"; LGRAY <- "#E8ECF0"; MGRAY <- "#8A9BB0"; DKGN  <- "#0D5C3A"
DKBL  <- "#1A2840"; DKAM  <- "#3D2A00"

# ── Create a tiny 1×1 pixel PNG of solid color → embed as background fill ─────
# external_img embeds image data into PPTX so temp files are self-contained.
solid_png <- function(hex_color) {
  tmp <- tempfile(fileext = ".png")
  png(tmp, width = 20, height = 20, bg = "transparent")
  par(mar = c(0,0,0,0), xaxs = "i", yaxs = "i")
  plot.new()
  rect(0, 0, 1, 1, col = hex_color, border = NA)
  dev.off()
  tmp
}

# Pre-generate background colors used across slides
bg_files <- list()
for (col in c(DARK, DKBL, DKGN, "#2A3F6A", "#1D5C46", "#1A4A7A", "#6B4C1A",
              "#1D5038", "#0D1F3C", "#2A2A1A", "#1A2A3A", "#1A3A2A",
              AMBER, GREEN, "#378ADD", LGREE, MGRAY)) {
  bg_files[[col]] <- solid_png(col)
}
get_bg <- function(col) {
  if (is.null(bg_files[[col]])) bg_files[[col]] <<- solid_png(col)
  bg_files[[col]]
}

# ── Helper functions ───────────────────────────────────────────────────────────
fp    <- function(col=WHITE, sz=14, b=FALSE, it=FALSE)
          fp_text(color=col, font.size=sz, bold=b, italic=it, font.family="Calibri")
para  <- function(txt, col=WHITE, sz=14, b=FALSE, it=FALSE, align="left")
          fpar(ftext(txt, fp(col,sz,b,it)), fp_p=fp_par(text.align=align))
blist <- function(items, col=LGRAY, sz=11, bullet="▸  ", indent=7) {
  do.call(block_list, lapply(items, function(x)
    fpar(ftext(paste0(bullet, x), fp(col, sz)),
         fp_p=fp_par(text.align="left", padding.left=indent))))
}
add_blank <- function(prs) add_slide(prs, layout="Blank", master="Office Theme")

# Add a filled rectangle (uses embedded PNG image)
box <- function(sl, col, l, t, w, h) {
  ph_with(sl,
    external_img(get_bg(col), width=w, height=h),
    ph_location(left=l, top=t, width=w, height=h, bg="transparent"))
}
# Text box
tb <- function(sl, txt, l, t, w, h, col=WHITE, sz=13, b=FALSE, it=FALSE, align="left")
  ph_with(sl, para(txt,col,sz,b,it,align), ph_location(left=l,top=t,width=w,height=h))
# Bullet list block
bl <- function(sl, items, l, t, w, h, col=LGRAY, sz=11, bullet="▸  ", indent=7)
  ph_with(sl, blist(items,col,sz,bullet,indent), ph_location(left=l,top=t,width=w,height=h))
# Thin horizontal rule (1px tall image)
rule <- function(sl, col, l, t, w=2.0) {
  ph_with(sl, external_img(get_bg(col), width=w, height=0.06),
          ph_location(left=l, top=t, width=w, height=0.06))
}
# Thin vertical rule
vrule <- function(sl, col, l, t, h=2.0, w=0.07) {
  ph_with(sl, external_img(get_bg(col), width=w, height=h),
          ph_location(left=l, top=t, width=w, height=h))
}
# Slide background + header bar
bg    <- function(sl, col=DARK) box(sl, col, 0, 0, 10, 7.5)
hdr   <- function(sl, txt, col=GREEN) {
  sl <- box(sl, col, 0, 0, 10, 0.9)
  tb(sl, txt, 0.4, 0.1, 9, 0.7, WHITE, 22, b=TRUE)
}

# ── Key numbers from model ─────────────────────────────────────────────────────
resumo <- d$resumo
r100_50 <- resumo[resumo$cenario=="100D" & resumo$ano==2050, ]
r100_30 <- resumo[resumo$cenario=="100D" & resumo$ano==2030, ]
VA_BASE <- 6011.1; EMP_BASE <- 104340275
pib_100_50   <- round((VA_BASE + r100_50$delta_va_bi) / 1000, 1)
prem_pib_50  <- round(r100_50$delta_va_transition_bi / 1000, 2)
emp_100_50   <- round((EMP_BASE + r100_50$delta_emp_total) / 1e6, 1)
emp_trans_50 <- round(r100_50$delta_emp_transition / 1e6, 2)
emp_trans_30 <- round(r100_30$delta_emp_transition / 1e6, 2)
inv_bi_50    <- round(r100_50$inv_shock_bi, 0)

prs <- read_pptx()

# ============================================================================
# SLIDE 1 — CAPA
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(1)
sl <- bg(sl)
sl <- vrule(sl, GREEN, 0.38, 1.55, h=4.3)
sl <- tb(sl, "MIP × MMA",                                         0.7, 1.55, 9, 1.1, GREEN, 40, b=TRUE)
sl <- tb(sl, "Avaliando os Impactos Macroeconômicos\nda Transição Energética Brasileira",
             0.7, 2.75, 8.5, 1.5, WHITE, 26)
sl <- tb(sl, "Modelo de Insumo-Produto EPE/FIPE (73 setores)  ×  Cenários MMA-SMC v3 AR5 (2024)",
             0.7, 4.35, 9, 0.5, MGRAY, 13, it=TRUE)
sl <- tb(sl, "Reunião Técnica PPE  ·  Junho 2025",
             0.7, 6.4, 5, 0.4, MGRAY, 12)
sl <- tb(sl, "cludovique.github.io/brazil-climate-macro-model",
             5.0, 6.4, 4.7, 0.4, LGREE, 11, it=TRUE, align="right")

# ============================================================================
# SLIDE 2 — MOTIVAÇÃO
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(2)
sl <- bg(sl)
sl <- hdr(sl, "Por que este modelo?")

cols3  <- c(AMBER, "#378ADD", GREEN)
titles <- c("O Brasil tem metas ambiciosas",
            "A lacuna analítica",
            "A ponte: MIP × MMA")
items3 <- list(
  c("Cenário 100D (MMA-SMC v3): descarbonização total até 2050",
    "Setores: Energia, Indústria, Transporte, Cidades, Agropecuária",
    "Plano de R$1+ tri em investimentos de transição",
    "Mas: quais são os impactos econômicos setoriais?"),
  c("Cenários MMA expressos em unidades físicas (TWh, Mt, kbep)",
    "Não há tradução automática para R$, empregos e PIB",
    "Multiplicadores setoriais variam 2×–12× entre setores",
    "Decisões de política precisam de números econômicos"),
  c("MIP-EPE 2018: modelo Leontief de 73 setores",
    "3 engines: Demanda Final, Coef. Técnicos, Produção Física",
    "Mapeia targets físicos → ΔProdução, ΔPIB, ΔEmprego",
    "Dashboard interativo para exploração de cenários"))

for (i in 1:3) {
  xl <- 0.2 + (i-1)*3.27
  sl <- box(sl, DKBL, xl, 1.05, 3.15, 5.7)
  sl <- rule(sl, cols3[i], xl+0.12, 1.12, w=2.9)
  sl <- tb(sl, titles[i], xl+0.15, 1.22, 2.9, 0.55, WHITE, 12, b=TRUE)
  sl <- bl(sl, items3[[i]], xl+0.15, 1.82, 2.9, 4.7)
}
sl <- tb(sl, "Abordagem macroeconômica setorial, compatível com BLUES/EPE e metodologia IPCC AR5.",
             0.3, 6.9, 9.4, 0.4, MGRAY, 10, it=TRUE, align="center")

# ============================================================================
# SLIDE 3 — ARQUITETURA
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(3)
sl <- bg(sl)
sl <- hdr(sl, "Arquitetura do Modelo")

for (h_info in list(c("ENTRADAS",0.15,2.6), c("ENGINES",3.0,4.3), c("RESULTADOS",7.6,2.1))) {
  sl <- tb(sl, h_info[1], as.numeric(h_info[2]), 1.08, as.numeric(h_info[3]), 0.35,
               MGRAY, 10, b=TRUE, align="center")
}
# MMA box
sl <- box(sl, "#2A3F6A", 0.15, 1.5, 2.6, 2.2)
sl <- tb(sl, "Cenários MMA-SMC\nv3 AR5 (2024)", 0.15, 1.6, 2.6, 0.65, GREEN, 13, b=TRUE, align="center")
sl <- bl(sl, c("Mix energético 2025–2050","Volumes físicos (TWh, Mt)","Investimentos (bi USD)","GHG por setor"),
             0.2, 2.3, 2.5, 1.3, col=LGRAY, sz=10, bullet="• ")
# MIP box
sl <- box(sl, "#2A3F6A", 0.15, 3.9, 2.6, 2.2)
sl <- tb(sl, "MIP-EPE 2018\n73 Setores", 0.15, 4.0, 2.6, 0.65, AMBER, 13, b=TRUE, align="center")
sl <- bl(sl, c("Matriz A (coef. técnicos)","Leontief L = (I-A)⁻¹","Satélites: VA, Empregos","ALPHA: ktep/R$M (6 fontes)"),
             0.2, 4.65, 2.5, 1.35, col=LGRAY, sz=10, bullet="• ")
# Arrows
sl <- tb(sl, "→", 2.78, 2.35, 0.3, 0.45, MGRAY, 22, b=TRUE, align="center")
sl <- tb(sl, "→", 2.78, 3.9,  0.3, 0.45, MGRAY, 22, b=TRUE, align="center")
sl <- tb(sl, "→", 7.3,  3.3,  0.3, 0.5,  MGRAY, 22, b=TRUE, align="center")
# Engine boxes
for (en in list(
  list(1.5,  "#1D5C46", "Engine 1: Demanda Final (Δf)",
       c("1a: Escala do PIB (gdp_idx × f_base)","1b: Investimento de transição (ALOC_INV)")),
  list(3.05, "#1A4A7A", "Engine 2: Coef. Técnicos (ΔA)",
       c("BLUES-style: sc = share_novo / share_base","6 grupos: Indústria, Transporte, Cidades, Geração…")),
  list(4.6,  "#6B4C1A", "Engine 3: Produção Física (Δx)",
       c("Volumes MMA → calibração R$ setorial","Petróleo, Eletricidade, Biocomb., Siderurgia")))) {
  sl <- box(sl, en[[2]], 3.0, en[[1]], 4.3, 1.35)
  sl <- tb(sl, en[[3]], 3.15, en[[1]]+0.08, 4.1, 0.5, WHITE, 12, b=TRUE)
  sl <- bl(sl, en[[4]], 3.15, en[[1]]+0.6, 4.1, 0.65, col=LGRAY, sz=10)
}
# Results box
sl <- box(sl, "#1D5038", 7.6, 1.5, 2.2, 5.1)
sl <- tb(sl, "RESULTADOS", 7.6, 1.6, 2.2, 0.4, GREEN, 11, b=TRUE, align="center")
sl <- bl(sl, c("Δ Produção (R$ tri)","Δ PIB / VA (R$ bi)","Δ Empregos (mi)",
               "Δ Renda salarial","Prêmio da Transição","Mix energético A*","Multiplicadores L*","GHG induzido"),
             7.65, 2.1, 2.1, 4.2, col=LGRAY, sz=10, bullet="• ")

# ============================================================================
# SLIDE 4 — BASE MIP-EPE
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(4)
sl <- bg(sl)
sl <- hdr(sl, "Base: MIP-EPE 2018 (73 setores)")

kpis <- list(
  list("R$ 10,7 tri", "Produção Total Bruta",  "VBP a preços básicos · 2018",  GREEN),
  list("R$ 6,0 tri",  "Valor Adicionado (PIB)", "VA a preços básicos · 2018",   AMBER),
  list("104,3 mi",    "Postos de Trabalho",     "Ocupações formais + informais","#378ADD"),
  list("73 setores",  "Setores da Economia",    "Classificação EPE/FIPE · IBGE", LGREE))
for (i in 1:4) {
  k <- kpis[[i]]; row <- ceiling(i/2); ci <- ((i-1)%%2)
  xl <- 0.3 + ci*2.45; yt <- 1.1 + (row-1)*1.9
  sl <- box(sl, DKBL, xl, yt, 2.3, 1.65)
  sl <- vrule(sl, k[[4]], xl+0.07, yt+0.15, h=1.3)
  sl <- tb(sl, k[[1]], xl+0.25, yt+0.15, 2.0, 0.55, k[[4]], 20, b=TRUE)
  sl <- tb(sl, k[[2]], xl+0.25, yt+0.72, 2.0, 0.38, WHITE,  11, b=TRUE)
  sl <- tb(sl, k[[3]], xl+0.25, yt+1.1,  2.0, 0.38, MGRAY,  9, it=TRUE)
}
# ALPHA panel
sl <- box(sl, DKBL, 5.25, 1.1, 4.55, 5.9)
sl <- tb(sl, "Satélite Energético — Matriz ALPHA", 5.45, 1.2, 4.2, 0.45, GREEN, 13, b=TRUE)
sl <- tb(sl, "ktep por R$ Milhão de produção  ×  73 setores  ×  6 fontes",
             5.45, 1.65, 4.2, 0.35, LGRAY, 10, it=TRUE)
for (i_f in 1:6) {
  fo <- list(list("Derivados de Petróleo",    AMBER,    "Transporte, Refino"),
             list("Gás Natural",              "#F0A050","Indústria pesada, edificações"),
             list("Biodiesel / HVO",          GREEN,    "Transporte rodoviário pesado"),
             list("Etanol / Biocombustíveis", LGREE,    "Flex, aviação, naval"),
             list("EE Centralizada (S40)",    "#378ADD","Geração e distribuidoras"),
             list("EE Distribuída (S41)",     "#6AADF5","Solar FV, micro-hidro"))[[i_f]]
  yt <- 2.1 + (i_f-1)*0.77
  sl <- vrule(sl, fo[[2]], 5.47, yt, h=0.5)
  sl <- tb(sl, fo[[1]], 5.65, yt,      2.6, 0.3,  WHITE, 11, b=TRUE)
  sl <- tb(sl, fo[[3]], 5.65, yt+0.3,  2.6, 0.28, MGRAY, 9, it=TRUE)
}
sl <- tb(sl, "Uso: ALPHA × Δx = variação no consumo de energia por fonte (ktep)",
             5.45, 6.7, 4.1, 0.3, LGREE, 10, it=TRUE)

# ============================================================================
# SLIDE 5 — ENGINE 1
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(5)
sl <- bg(sl)
sl <- hdr(sl, "Engine 1  —  Demanda Final (Δf)", AMBER)

sl <- box(sl, DKBL, 0.2,  1.1, 4.55, 5.8)
sl <- tb(sl, "1a  •  Escala do PIB", 0.4, 1.2, 4.2, 0.5, AMBER, 14, b=TRUE)
sl <- bl(sl, c("Fonte: Planilha PIB_Pop do MMA (índice por ano)",
               "Δf_PIB = f_base × (gdp_idx × 0,97 − 1)",
               "Escala todos os componentes da demanda final",
               "CAGR implícito: ~2,4% a.a. (2018–2050)",
               "Setores Engine 3 recebem Δf=0 (evita dupla contagem)",
               "E3: S05 petróleo, S19 refino, S40 geração, S42 transmissão"),
             0.4, 1.8, 4.2, 4.8)

sl <- box(sl, DKBL, 5.05, 1.1, 4.75, 5.8)
sl <- tb(sl, "1b  •  Investimento de Transição (FBCF)", 5.25, 1.2, 4.4, 0.5, AMBER, 14, b=TRUE)
sl <- bl(sl, c("Fonte: Aba Custos MMA — Custo Anual Equivalente (CAE)",
               "Conversão: bi USD2023 → R$2018 (fator 2,92)",
               sprintf("100D: ~R$%d bi/ano em investimentos de transição", abs(inv_bi_50)),
               "Adicionado como FBCF setorial (formação bruta de capital fixo)",
               "ALOC_INV: pesos por setor IO — premissa a calibrar com dados MMA",
               "Maiores receptores: geração, construção, biocomb., veículos"),
             5.25, 1.8, 4.4, 4.8)

# ============================================================================
# SLIDE 6 — ENGINE 2
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(6)
sl <- bg(sl)
sl <- hdr(sl, "Engine 2  —  Substituição Energética (ΔA)", "#378ADD")
sl <- tb(sl, "sc_combustível = share_cenário(t) / share_base(2020)",
             0.5, 1.0, 9, 0.45, "#378ADD", 14, b=TRUE, align="center")
sl <- tb(sl, "A*(j,t) = A(j) × sc    →    L*(t) = (I − A*)⁻¹    →    Δx = L* × Δf",
             0.5, 1.45, 9, 0.4, LGRAY, 12, it=TRUE, align="center")

g2_data <- list(
  list("Ferro e Aço (S29)",     AMBER,    "Foss+H₂ → eletricidade",         "Foss 61,9% | Bio 29% | Elec 9,1%"),
  list("Cimento (S28)",         AMBER,    "Coque → biomassa + clínquer",     "Foss 67,4% | Bio 18,3% | Elec 14,4%"),
  list("Químico (S24-26)",      AMBER,    "Nafta → bioquímicos",             "Foss 66,6% | Bio 2,3% | Elec 31,2%"),
  list("Outros Indústria",      AMBER,    "25 setores manufatureiros",        "Mix diverso BLUES-style"),
  list("Transporte (S48-52)",   "#378ADD","Eletrificação + biocombustíveis", "Elec 0,4%→17% | Bio 30,3%→?"),
  list("Cidades/Edifícios",     GREEN,    "S52/53/59/S66-70",               "Elec 62,5%→95% | Gás 26%→5%"),
  list("Geração Elétrica (S40)",LGREE,    "Fóssil 14,6%→0,7% (2050)",      "normalize=FALSE: redução genuína"),
  list("Refino/Gás (S19/43)",   LGREE,    "Coprocessamento + biometano",    "S43: 0→~780 PJ biometano 2050"))
for (i in 1:8) {
  g <- g2_data[[i]]; ci <- ((i-1)%%4); ri <- ceiling(i/4)
  xl <- 0.15 + ci*2.47; yt <- 2.05 + (ri-1)*2.5
  sl <- box(sl, DKBL, xl, yt, 2.35, 2.25)
  sl <- rule(sl, g[[2]], xl+0.1, yt+0.07, w=2.15)
  sl <- tb(sl, g[[1]], xl+0.12, yt+0.18, 2.15, 0.5,  WHITE, 11, b=TRUE)
  sl <- tb(sl, g[[3]], xl+0.12, yt+0.72, 2.15, 0.65, LGRAY, 9.5)
  sl <- tb(sl, g[[4]], xl+0.12, yt+1.45, 2.15, 0.55, MGRAY, 9, it=TRUE)
}
sl <- tb(sl, "normalize=TRUE preserva intensidade energética total (transporte, indústria)  |  normalize=FALSE permite redução genuína (geração elétrica −95% fóssil)",
             0.2, 7.1, 9.6, 0.35, MGRAY, 9, it=TRUE, align="center")

# ============================================================================
# SLIDE 7 — ENGINE 3
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(7)
sl <- bg(sl)
sl <- hdr(sl, "Engine 3  —  Calibração por Volume Físico (Δx)", AMBER)
sl <- tb(sl, "Para setores energéticos-chave, a produção é ancorada em metas físicas do MMA — não apenas escala PIB.",
             0.3, 1.0, 9.5, 0.45, LGRAY, 12)

e3 <- list(
  list("S05 — Petróleo bruto",   "MMA R37: produção kbep",                      "Pico 2030, declínio 58% até 2050"),
  list("S19 — Refino/Derivados", "MMA R40+R41: derivados dom. + exp. (ktep)",    "Permanece +6% com coprocessamento"),
  list("S40/S42 — Geração/Transm.","MMA R49: geração total TWh (base 679 TWh)", "Transmissão proporcional à geração"),
  list("S22 — Biocomb. Avançados","Etanol+CCS + Gasolina Verde + BioQAV + Bunker","Base 1020 PJ + incremento cenário"),
  list("S20 — Biodiesel / HVO",  "MMA R78: Diesel Verde PJ + base 230 PJ",       "Substitui diesel mineral em frotas"),
  list("S29/S28 — Sid./Cimento", "MMA R27 aço (Mt) + R41 clínquer (Mt)",          "Razão vs 2020 × VBP setorial 2018"))
for (i in 1:6) {
  it <- e3[[i]]; ci <- ((i-1)%%3); ri <- ceiling(i/3)
  xl <- 0.2 + ci*3.27; yt <- 1.65 + (ri-1)*2.6
  sl <- box(sl, DKBL, xl, yt, 3.1, 2.4)
  sl <- tb(sl, it[[1]], xl+0.15, yt+0.12, 2.9, 0.55, AMBER, 11, b=TRUE)
  sl <- tb(sl, it[[2]], xl+0.15, yt+0.72, 2.9, 0.65, LGRAY, 10)
  sl <- tb(sl, it[[3]], xl+0.15, yt+1.42, 2.9, 0.70, MGRAY, 9.5, it=TRUE)
}

# ============================================================================
# SLIDE 8 — RESULTADOS
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(8)
sl <- bg(sl)
sl <- hdr(sl, "Resultados — Prêmio da Transição 100D")
sl <- tb(sl, "Prêmio = efeito líquido 100D vs. crescimento de base (PIB sem transição — apenas escala GDP)",
             0.3, 0.95, 9.4, 0.4, LGRAY, 11, it=TRUE)

res_kpis <- list(
  list(sprintf("R$ %.1f tri", pib_100_50),   "PIB — Nível 100D",    "Valor Adicionado 2050",    GREEN),
  list(sprintf("+R$ %.2f tri", prem_pib_50), "Prêmio PIB 2050",     "100D vs. Linha de Base",   AMBER),
  list(sprintf("%.1f mi", emp_100_50),        "Empregos 100D",       "Postos de trabalho 2050", "#378ADD"),
  list(sprintf("+%.2f mi", emp_trans_50),    "Prêmio Emprego 2050", "Empregos líquidos transição",LGREE),
  list(sprintf("+%.2f mi", emp_trans_30),    "Prêmio Emprego 2030", "Horizonte intermediário",  "#F0A050"))
for (i in 1:5) {
  k <- res_kpis[[i]]; xl <- 0.15 + (i-1)*1.97
  sl <- box(sl, DKBL, xl, 1.45, 1.85, 1.6)
  sl <- tb(sl, k[[1]], xl+0.05, 1.52, 1.75, 0.55, k[[4]], 15, b=TRUE, align="center")
  sl <- tb(sl, k[[2]], xl+0.05, 2.09, 1.75, 0.35, WHITE,   9, b=TRUE, align="center")
  sl <- tb(sl, k[[3]], xl+0.05, 2.44, 1.75, 0.45, MGRAY,   8, it=TRUE, align="center")
}

sl <- tb(sl, "Trajetória por Cenário — Variação de Produção (ΔR$ bi vs. 2018)",
             0.3, 3.25, 9.4, 0.42, WHITE, 12, b=TRUE)
anos_sel <- c(2025,2030,2035,2040,2045,2050)
cens_sel <- c("0D","25D","100D")
col_w <- c(1.1, rep(1.48, 6)); col_x <- cumsum(c(0.25, col_w[-7]))
for (j in 1:7) {
  sl <- box(sl, "#0D1F3C", col_x[j], 3.7, col_w[j], 0.38)
  sl <- tb(sl, c("Cenário", as.character(anos_sel))[j],
               col_x[j]+0.03, 3.73, col_w[j]-0.06, 0.32, GREEN, 10, b=TRUE, align="center")
}
row_bg <- list("0D"="#2A2A1A","25D"="#1A2A3A","100D"="#1A3A2A")
row_fc <- list("0D"=LGRAY,    "25D"=LGRAY,    "100D"=LGREE)
for (ri in seq_along(cens_sel)) {
  cn <- cens_sel[ri]; yt <- 4.1 + (ri-1)*0.62
  cr <- resumo[resumo$cenario==cn, ]
  vals <- sapply(anos_sel, function(a) { rv <- cr[cr$ano==a,"delta_prod_bi"]; sprintf("%.0f",rv) })
  for (j in 1:7) {
    sl <- box(sl, row_bg[[cn]], col_x[j], yt, col_w[j], 0.57)
    fc <- if(j==1) WHITE else row_fc[[cn]]
    sl <- tb(sl, c(cn, vals)[j], col_x[j]+0.03, yt+0.1, col_w[j]-0.06, 0.38,
                 fc, if(j==1) 11 else 10, b=(j==1), align="center")
  }
}
sl <- tb(sl, "R$ bilhões — variação acumulada vs. 2018 · diretos + indiretos via multiplicador Leontief",
             0.25, 6.0, 9.5, 0.35, MGRAY, 9, it=TRUE)
sl <- tb(sl, "Decomposição: GDP scaling (Base)  +  Investimento (E1b)  +  Eficiência energética (E2)  +  Produção física (E3)",
             0.25, 6.4, 9.5, 0.35, AMBER, 10)

# ============================================================================
# SLIDE 9 — DASHBOARD
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(9)
sl <- bg(sl)
sl <- hdr(sl, "Dashboard Interativo — Exploração de Cenários", LGREE)
sl <- box(sl, "#0D2A1E", 0.3, 1.0, 9.4, 0.55)
sl <- tb(sl, "cludovique.github.io/brazil-climate-macro-model/mma_scenarios_dashboard.html",
             0.3, 1.07, 9.4, 0.4, LGREE, 12, b=TRUE, align="center")

tabs <- list(
  list("Tab 1","Produção Total",    GREEN,    c("Trajetória R$ tri: Base vs 25D vs 100D","KPIs nível absoluto + prêmio ± %","Toggle R$ tri ou % vs 2018","Decomp. por grupo setorial (GRP7)")),
  list("Tab 2","PIB e Emprego",     "#378ADD",c("VA (PIB) total e prêmio de transição","Emprego: base + 100D + prêmio dir./ind.","Nível empregos setores de energia","Decomposição por fonte de choque")),
  list("Tab 3","Análise Setorial",  AMBER,    c("Top 15 setores por ΔProdução","Tabela 73 setores filtrável","Linkages: BL/FL antes e após 100D","Coef. técnicos A* por setor")),
  list("Tab 4","Mix Energético",    LGREE,    c("Trajetória % elec/bio/fóssil","Por sub-setor MMA (Ferro, Cimento…)","Coef. A* base vs cenário","ALPHA: impacto ktep por fonte")),
  list("Tab 5","Premissas & Dados", MGRAY,    c("Produção física por produto","Decomposição demanda final","Multiplicadores Type I/II","Mapeamento setorial e premissas")))
for (i in 1:5) {
  tb2 <- tabs[[i]]; xl <- 0.2 + (i-1)*1.95
  sl <- box(sl, DKBL, xl, 1.65, 1.85, 5.45)
  sl <- rule(sl, tb2[[3]], xl+0.1, 1.7, w=1.65)
  sl <- tb(sl, tb2[[1]], xl+0.05, 1.78, 1.75, 0.32, MGRAY, 9, b=TRUE, align="center")
  sl <- tb(sl, tb2[[2]], xl+0.05, 2.12, 1.75, 0.5, WHITE, 11, b=TRUE, align="center")
  sl <- bl(sl, tb2[[4]], xl+0.12, 2.7, 1.65, 4.2, col=LGRAY, sz=9, bullet="• ")
}

# ============================================================================
# SLIDE 10 — AGENDA DE PESQUISA & COLABORAÇÃO
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(10)
sl <- bg(sl)
sl <- hdr(sl, "Agenda de Pesquisa & Colaboração", AMBER)

lacunas <- list(
  list("Calibração ALOC_INV",
       "Pesos de FBCF são premissas manuais. Precisam ser derivados do detalhamento por tema/tecnologia do Plano MMA (eólica, solar, VEs, biocombustíveis) e mapeados para códigos IO."),
  list("Coeficiente A[S22, S43]",
       "Aumento de insumos de biomassa na produção de biometano não implementado. Requer coef. técnico (ktep biomassa / PJ biometano). Fonte: EPE BEN ou ANP."),
  list("Engine 4 — Satélite de Emissões",
       "Conta satélite de MtCO₂e por setor está desativada. Requer coef. de intensidade de carbono por fonte × setor, calibrados com inventário SEEG/MCTI."),
  list("Componente residencial (Cidades)",
       "Uso energético domiciliar é demanda final (famílias), não insumo intermediário. Modelagem correta requer choque no vetor f (coluna Famílias)."),
  list("Validação com EPE BEN",
       "Coef. ALPHA construídos com dados EPE 2018. Recomenda-se confronto com série histórica BEN/BEU setorial para confirmar consistência."))
colabs <- list(
  list("Dados EPE BEN setoriais",
       "Série histórica de consumo energético por setor e por fonte, para calibrar e validar a matriz ALPHA de intensidade energética."),
  list("Coeficientes de processo industrial",
       "Coef. técnicos de entrada de biomassa/H₂ para siderurgia e cimento (EPE, IPT, IABR, SNIC) para Engine 2 desagregado."),
  list("Confronto com BLUES / MAED-BR",
       "Validação cruzada das trajetórias de mix setorial com resultados BLUES/EPE para checar coerência dos scale factors do Engine 2."),
  list("Extensão: LULUCF e Agropecuária",
       "Modelos biofísicos de uso da terra → choques IO em S01-S09 com dados de área e produtividade do Plano MMA."),
  list("Análise de sensibilidade",
       "Sensibilidade dos prêmios de PIB e emprego às premissas de ALOC_INV, taxas de crescimento e trajetórias de mix (análise paramétrica)."))
for (panel in list(list(lacunas, 0.2, "Lacunas do Modelo", AMBER),
                   list(colabs,  5.1, "Como Colaborar",   GREEN))) {
  sl <- box(sl, DKBL, panel[[2]], 1.0, 4.7, 6.25)
  sl <- tb(sl, panel[[3]], panel[[2]]+0.2, 1.08, 4.3, 0.45, panel[[4]], 14, b=TRUE)
  for (j in seq_along(panel[[1]])) {
    it <- panel[[1]][[j]]; yt <- 1.65 + (j-1)*1.1
    sl <- tb(sl, it[[1]], panel[[2]]+0.25, yt,      4.2, 0.35, WHITE, 10, b=TRUE)
    sl <- tb(sl, it[[2]], panel[[2]]+0.25, yt+0.33, 4.2, 0.7,  LGRAY, 9)
  }
}

# ============================================================================
# SLIDE 11 — FECHAMENTO
# ============================================================================
prs <- add_blank(prs); sl <- prs |> on_slide(11)
sl <- bg(sl)
sl <- vrule(sl, GREEN, 0.35, 2.0, h=3.5)
sl <- tb(sl, "Obrigada!", 0.7, 2.1, 9, 1.0, GREEN, 40, b=TRUE)
sl <- tb(sl, "Código aberto — comentários, críticas e contribuições são bem-vindos.",
             0.7, 3.2, 8.5, 0.6, WHITE, 15)
for (i in seq_along(list(
  list("🔗 GitHub (código e dados):", "github.com/cludovique/brazil-climate-macro-model"),
  list("🌐 Dashboard interativo:",     "cludovique.github.io/brazil-climate-macro-model/"),
  list("📊 Cenários MMA:",              "MMA-SMC v3 AR5 (07/10/2024)")))) {
  lk <- list(list("🔗 GitHub (código e dados):", "github.com/cludovique/brazil-climate-macro-model"),
             list("🌐 Dashboard interativo:",     "cludovique.github.io/brazil-climate-macro-model/"),
             list("📊 Cenários MMA:",              "MMA-SMC v3 AR5 (07/10/2024)"))[[i]]
  yt <- 3.95 + (i-1)*0.7
  sl <- tb(sl, lk[[1]], 0.7, yt, 2.9, 0.45, MGRAY, 12)
  sl <- tb(sl, lk[[2]], 3.7, yt, 5.9, 0.45, LGREE, 12)
}

# ============================================================================
# SAVE
# ============================================================================
out <- "docs/MIP_MMA_PPE_apresentacao.pptx"
print(prs, target=out)
cat(sprintf("\nPresentação salva: %s  (%s KB)\n", out,
            round(file.info(out)$size/1024)))
cat(sprintf("Total slides: %d\n", length(prs)))
