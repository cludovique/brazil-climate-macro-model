# =============================================================================
# generate_validation_dashboard.R
# Sanity-check / cross-validation: EPE 2018 (73 sec) vs GIC-UFRJ 2021 (67 sec)
# Outputs: outputs/validation_dashboard.html
# =============================================================================
library(readxl); library(dplyr); library(jsonlite)

setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")
if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)

# ── 1. READ ───────────────────────────────────────────────────────────────────
GIC <- "data/processed/Resultados - GIC - 2021.xlsx"
EPE <- "data/raw/mip_epe_replication_results.xlsx"

se_e  <- read_excel(EPE, sheet = "Setores")
mp_e  <- read_excel(EPE, sheet = "Mult_Producao")
me_e  <- read_excel(EPE, sheet = "Mult_Emprego")
mr_e  <- read_excel(EPE, sheet = "Mult_Renda")
il_e  <- read_excel(EPE, sheet = "Ind_Ligacao")
ip_e  <- read_excel(EPE, sheet = "Ind_Puros")
ex_e  <- read_excel(EPE, sheet = "Extr_Hipotetica")

mp_g  <- read_excel(GIC, sheet = "MP")
me_g  <- read_excel(GIC, sheet = "ME")
mr_g  <- read_excel(GIC, sheet = "MR")
ih_g  <- read_excel(GIC, sheet = "IndHR")
ip_g  <- read_excel(GIC, sheet = "IPLN")
ex_g  <- read_excel(GIC, sheet = "ExtHipo")

n_gic <- nrow(mp_g)   # 67
n_epe <- nrow(mp_e)   # 73

# ── 2. CROSSWALK ──────────────────────────────────────────────────────────────
# Both models follow the IBGE sector order. Match first 67 by position.
epe_ord <- se_e %>% arrange(id)

pair <- epe_ord[1:n_gic, ] %>%
  left_join(mp_e %>% select(cod, MP_E=MP, MPT_E=MPT, MPTT_E=MPTT,
                             direct_E=direct, indirect_E=indirect, induced_E=induced), by="cod") %>%
  left_join(me_e %>% select(cod, ME_E=ME, MEI_E=MEI, MET_E=MET, MEII_E=MEII), by="cod") %>%
  left_join(mr_e %>% select(cod, MR_E=MR, MRI_E=MRI, MRT_E=MRT, MRII_E=MRII), by="cod") %>%
  left_join(il_e %>% select(cod, BL_E=BL, FL_E=FL, FLG_E=FLG, Vj_E=Vj, Vi_E=Vi, quad=quadrante), by="cod") %>%
  left_join(ip_e %>% select(cod, PBLN_E=PBLN, PFLN_E=PFLN, PTLN_E=PTLN), by="cod") %>%
  left_join(ex_e %>% select(cod, BLpct_E=BL_pct, FLpct_E=FL_pct), by="cod") %>%
  mutate(
    gic_nome  = mp_g$Setores,
    MP_G      = as.numeric(mp_g$MP),
    MPT_G     = as.numeric(mp_g$MPT),
    MPTT_G    = as.numeric(mp_g$MPTT),
    ME_G      = as.numeric(me_g$ME),
    MEI_G     = as.numeric(me_g$MEI),
    MET_G     = as.numeric(me_g$MET),
    MEII_G    = as.numeric(me_g$MEII),
    MR_G      = as.numeric(mr_g$MR),
    MRI_G     = as.numeric(mr_g$MRI),
    MRT_G     = as.numeric(mr_g$MRT),
    MRII_G    = as.numeric(mr_g$MRII),
    BL_G      = as.numeric(ih_g$BL),
    FL_G      = as.numeric(ih_g$FL),
    FLG_G     = as.numeric(ih_g$FLG),
    PBLN_G    = as.numeric(ip_g$PBLN),
    PFLN_G    = as.numeric(ip_g$PFLN),
    BLpct_G   = as.numeric(ex_g$`BL%`),
    FLpct_G   = as.numeric(ex_g$`FL%`)
  )

# EPE-only unmatched (S68-S73)
epe_only <- epe_ord[(n_gic+1):n_epe, ] %>%
  left_join(mp_e %>% select(cod, MP=MP, MPT=MPT), by="cod") %>%
  left_join(il_e %>% select(cod, BL=BL, FL=FL, FLG=FLG), by="cod") %>%
  select(cod, nome, grupo, MP, MPT, BL, FL, FLG)

# Summary stats
summ <- function(x) {
  x <- as.numeric(x[!is.na(x) & is.finite(x)])
  if(length(x)==0) return(list(min=NA,q1=NA,median=NA,mean=NA,q3=NA,max=NA))
  list(min=round(min(x),4), q1=round(quantile(x,.25),4),
       median=round(median(x),4), mean=round(mean(x),4),
       q3=round(quantile(x,.75),4), max=round(max(x),4))
}

# ── 3. BUILD JSON ─────────────────────────────────────────────────────────────
D <- list(
  meta = list(epe_n=n_epe, gic_n=n_gic, matched_n=n_gic, epe_year=2018, gic_year=2021),
  pairs = pair %>% select(
    cod, epe_nome=nome, gic_nome, grupo,
    MP_E, MPT_E, MPTT_E, direct_E, indirect_E, induced_E,
    MP_G, MPT_G, MPTT_G,
    ME_E, MEI_E, MET_E, MEII_E,
    ME_G, MEI_G, MET_G, MEII_G,
    MR_E, MRI_E, MRT_E, MRII_E,
    MR_G, MRI_G, MRT_G, MRII_G,
    BL_E, FL_E, FLG_E, Vj_E, Vi_E,
    BL_G, FL_G, FLG_G,
    PBLN_E, PFLN_E, PTLN_E,
    PBLN_G, PFLN_G,
    BLpct_E, FLpct_E,
    BLpct_G, FLpct_G,
    quad
  ) %>% as.data.frame(),
  epe_only = epe_only %>% as.data.frame(),
  summary = list(
    MP    = list(epe=summ(pair$MP_E),    gic=summ(pair$MP_G)),
    MPT   = list(epe=summ(pair$MPT_E),   gic=summ(pair$MPT_G)),
    MPTT  = list(epe=summ(pair$MPTT_E),  gic=summ(pair$MPTT_G)),
    MEI   = list(epe=summ(pair$MEI_E),   gic=summ(pair$MEI_G)),
    MEII  = list(epe=summ(pair$MEII_E),  gic=summ(pair$MEII_G)),
    MRI   = list(epe=summ(pair$MRI_E),   gic=summ(pair$MRI_G)),
    MRII  = list(epe=summ(pair$MRII_E),  gic=summ(pair$MRII_G)),
    BL    = list(epe=summ(pair$BL_E),    gic=summ(pair$BL_G)),
    FLG   = list(epe=summ(pair$FLG_E),   gic=summ(pair$FLG_G)),
    PBLN  = list(epe=summ(pair$PBLN_E),  gic=summ(pair$PBLN_G)),
    PFLN  = list(epe=summ(pair$PFLN_E),  gic=summ(pair$PFLN_G)),
    BLpct = list(epe=summ(pair$BLpct_E), gic=summ(pair$BLpct_G)),
    FLpct = list(epe=summ(pair$FLpct_E), gic=summ(pair$FLpct_G))
  )
)

js_data <- toJSON(D, digits=6, na="null", auto_unbox=TRUE)
cat("JSON size:", round(nchar(js_data)/1024,1), "KB\n")

# ── 4. HTML TEMPLATE ──────────────────────────────────────────────────────────
html <- paste0(r"[<!DOCTYPE html>
<html lang="pt">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Validação MIP — EPE 2018 vs GIC-UFRJ 2021</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.min.js"></script>
<style>
:root{
  --bg:#0f1117;--surface:#181c27;--card:#1e2330;--border:#2d3448;
  --text:#e2e8f0;--muted:#8892a4;
  --epe:#378ADD;--gic:#F39C12;--both:#8E44AD;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:'Segoe UI',system-ui,sans-serif;font-size:13px}
header{background:var(--surface);border-bottom:1px solid var(--border);padding:14px 20px;display:flex;align-items:center;gap:10px;flex-wrap:wrap}
header h1{font-size:15px;font-weight:700}
.badge{background:var(--card);border:1px solid var(--border);border-radius:4px;padding:2px 9px;font-size:11px;color:var(--muted)}
.badge.epe{border-color:var(--epe);color:var(--epe)}.badge.gic{border-color:var(--gic);color:var(--gic)}
.badge.both{border-color:var(--both);color:var(--both)}
nav.tabs{background:var(--surface);border-bottom:1px solid var(--border);padding:0 16px;display:flex;gap:2px}
nav.tabs button{background:none;border:none;color:var(--muted);padding:10px 15px;cursor:pointer;font-size:12px;border-bottom:2px solid transparent}
nav.tabs button.active{color:var(--epe);border-bottom-color:var(--epe)}
.leg-bar{display:flex;gap:18px;align-items:center;padding:7px 16px;background:var(--surface);border-bottom:1px solid var(--border);font-size:11px;flex-wrap:wrap}
.dot{width:9px;height:9px;border-radius:50%;display:inline-block;margin-right:4px;vertical-align:middle}
main{padding:14px 16px}
.tab-panel{display:none}.tab-panel.active{display:block}
.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px}
.grid-3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;margin-bottom:12px}
.card{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:14px;margin-bottom:0}
.card-title{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);margin-bottom:10px}
.chart-wrap{position:relative;height:270px}
.chart-wrap.tall{height:380px}
.chart-wrap.short{height:190px}
.kpi-row{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:12px}
.kpi{background:var(--card);border:1px solid var(--border);border-radius:8px;padding:12px 14px}
.kpi-val{font-size:22px;font-weight:700;margin-bottom:2px}
.kpi-lbl{font-size:10px;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
.kpi-sub{font-size:10px;color:var(--muted);margin-top:1px}
.info-box{background:var(--surface);border:1px solid var(--border);border-radius:6px;padding:10px 14px;font-size:11px;color:var(--muted);margin-bottom:12px;line-height:1.6}
.info-box strong{color:var(--text)}
.r2b{display:inline-block;background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:1px 7px;font-size:10px;margin-left:5px;color:var(--both)}
/* Summary table */
table.st{width:100%;border-collapse:collapse;font-size:11px;margin-top:4px}
table.st th{background:var(--surface);color:var(--muted);font-weight:600;text-align:center;padding:5px 6px;border-bottom:1px solid var(--border)}
table.st th:first-child{text-align:left}
table.st td{padding:4px 6px;border-bottom:1px solid var(--border);text-align:center}
table.st td:first-child,table.st td:nth-child(2){text-align:left}
table.st tr:last-child td{border-bottom:none}
table.st .ve{color:var(--epe)}.ve strong{color:var(--epe)}
table.st .vg{color:var(--gic)}.vg strong{color:var(--gic)}
table.st .ok{color:#1D9E75}.table.st .warn{color:#F39C12}.table.st .bad{color:#E24B4A}
/* Sector table */
.dt{width:100%;border-collapse:collapse;font-size:11px}
.dt th{position:sticky;top:0;background:var(--surface);color:var(--muted);font-weight:600;text-align:left;padding:5px 7px;border-bottom:1px solid var(--border);cursor:pointer;white-space:nowrap}
.dt td{padding:4px 7px;border-bottom:1px solid var(--border);white-space:nowrap}
.dt tr:hover td{background:rgba(255,255,255,.03)}
.ok{color:#1D9E75}.warn{color:#F39C12}.bad{color:#E24B4A}
.epe-c{color:var(--epe)}.gic-c{color:var(--gic)}
.search-box{background:var(--surface);border:1px solid var(--border);color:var(--text);padding:4px 10px;border-radius:4px;font-size:11px;width:240px}
</style>
</head>
<body>

<header>
  <h1>&#9878; Validação Cruzada — MIP-EPE 2018 &nbsp;vs&nbsp; GIC-UFRJ 2021</h1>
  <span class="badge epe">&#9632; EPE/FIPE 2018 &bull; 73 setores</span>
  <span class="badge gic">&#9632; GIC-UFRJ 2021 &bull; 67 setores</span>
  <span class="badge both" id="matchBadge"></span>
</header>

<nav class="tabs" id="mainTabs">
  <button class="active" onclick="showTab(0)">&#128202; Resumo Geral</button>
  <button onclick="showTab(1)">&#128200; Multiplicadores</button>
  <button onclick="showTab(2)">&#128279; Índices de Ligação</button>
  <button onclick="showTab(3)">&#128300; Extração &amp; Índ. Puros</button>
  <button onclick="showTab(4)">&#128203; Tabela Completa</button>
</nav>

<div class="leg-bar">
  <span><span class="dot" style="background:var(--epe)"></span><strong style="color:var(--epe)">EPE 2018</strong> — MIP Energia EPE/FIPE, 73 setores</span>
  <span><span class="dot" style="background:var(--gic)"></span><strong style="color:var(--gic)">GIC-UFRJ 2021</strong> — MIP IBGE 67 setores via IP-GIC</span>
  <span style="margin-left:auto;color:var(--muted);font-size:10px">Pareamento posicional pela ordem IBGE (S01↔Agriculture … S67↔Domestic services) &nbsp;|&nbsp; S68–S73 EPE sem par GIC</span>
</div>

<!-- ══ TAB 0: RESUMO ══════════════════════════════════════════════════════════ -->
<div class="tab-panel active" id="tab0"><main>
  <div class="info-box">
    <strong>Objetivo:</strong> Verificar se os resultados EPE são racionais comparando ordens de grandeza, rankings setoriais e correlações com o modelo GIC-UFRJ aplicado à MIP 2021. As matrizes são de fontes e anos distintos — diferenças esperadas de ≤15% nas médias indicam consistência metodológica. Diferenças maiores em setores específicos podem indicar particularidades da MIP-Energia EPE ou setores merecedores de revisão.
  </div>
  <div class="kpi-row" id="kpiRow"></div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Distribuição — Multiplicador Simples de Produção (MP)</div>
      <div class="chart-wrap short"><canvas id="ch-dist-mp"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">Distribuição — Índice de Ligação para Trás (BL Rasmussen)</div>
      <div class="chart-wrap short"><canvas id="ch-dist-bl"></canvas></div>
    </div>
  </div>
  <div class="card" style="margin-bottom:12px">
    <div class="card-title">Estatísticas Resumo — EPE 2018 vs GIC-UFRJ 2021 (67 setores pareados)</div>
    <table class="st" id="summTable"></table>
  </div>
</main></div>

<!-- ══ TAB 1: MULTIPLICADORES ════════════════════════════════════════════════ -->
<div class="tab-panel" id="tab1"><main>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">MP Simples — Scatter EPE vs GIC <span class="r2b" id="r2-mp"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-mp"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">MPT (modelo fechado) — Scatter <span class="r2b" id="r2-mpt"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-mpt"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Top 15 MP — EPE (azul) vs GIC (laranja), ranked por EPE</div>
      <div class="chart-wrap tall"><canvas id="ch-top-mp"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">Top 15 MPT — EPE vs GIC</div>
      <div class="chart-wrap tall"><canvas id="ch-top-mpt"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Mult. Emprego Tipo I (MEI) — Scatter <span class="r2b" id="r2-mei"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-mei"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">Mult. Renda Tipo I (MRI) — Scatter <span class="r2b" id="r2-mri"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-mri"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Top 15 MEI — EPE vs GIC</div>
      <div class="chart-wrap tall"><canvas id="ch-top-mei"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">Top 15 MRI — EPE vs GIC</div>
      <div class="chart-wrap tall"><canvas id="ch-top-mri"></canvas></div>
    </div>
  </div>
</main></div>

<!-- ══ TAB 2: ÍNDICES DE LIGAÇÃO ══════════════════════════════════════════════ -->
<div class="tab-panel" id="tab2"><main>
  <div class="info-box">
    <strong>Leitura:</strong> Setores-chave têm BL&gt;1 (forte encadeamento para trás, demanda) E FLG&gt;1 (forte encadeamento para frente, oferta). Os dois modelos devem classificar setores de indústria de base (química, metalurgia, refino) como chave em ambas as matrizes.
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">BL vs FLG — EPE 2018 (setores coloridos por grupo)</div>
      <div class="chart-wrap tall"><canvas id="ch-cv-epe"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">BL vs FLG — GIC-UFRJ 2021</div>
      <div class="chart-wrap tall"><canvas id="ch-cv-gic"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">BL Rasmussen — Scatter EPE vs GIC <span class="r2b" id="r2-bl"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-bl"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">FLG Ghosh — Scatter EPE vs GIC <span class="r2b" id="r2-flg"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-flg"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Top 15 BL — EPE vs GIC</div>
      <div class="chart-wrap tall"><canvas id="ch-top-bl"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">Top 15 FLG — EPE vs GIC</div>
      <div class="chart-wrap tall"><canvas id="ch-top-flg"></canvas></div>
    </div>
  </div>
</main></div>

<!-- ══ TAB 3: EXTRAÇÃO & IPLN ══════════════════════════════════════════════════ -->
<div class="tab-panel" id="tab3"><main>
  <div class="info-box">
    <strong>Extração Hipotética BL%</strong>: impacto da remoção do setor na produção total (demanda). <strong>FL%</strong>: impacto pelo lado da oferta. <strong>PBLN/PFLN</strong>: Índices Puros de Ligação Normalizados — medem contribuição absoluta do setor ao produto total.
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Extração BL% — Scatter EPE vs GIC <span class="r2b" id="r2-blpct"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-blpct"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">Extração FL% — Scatter EPE vs GIC <span class="r2b" id="r2-flpct"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-flpct"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Top 15 Extração BL% — EPE vs GIC</div>
      <div class="chart-wrap tall"><canvas id="ch-top-blpct"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">Top 15 Extração FL% — EPE vs GIC</div>
      <div class="chart-wrap tall"><canvas id="ch-top-flpct"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">PBLN — Scatter EPE vs GIC <span class="r2b" id="r2-pbln"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-pbln"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title">PFLN — Scatter EPE vs GIC <span class="r2b" id="r2-pfln"></span></div>
      <div class="chart-wrap"><canvas id="ch-sc-pfln"></canvas></div>
    </div>
  </div>
</main></div>

<!-- ══ TAB 4: TABELA ═══════════════════════════════════════════════════════════ -->
<div class="tab-panel" id="tab4"><main>
  <div style="display:flex;gap:8px;margin-bottom:10px;align-items:center;flex-wrap:wrap">
    <input class="search-box" placeholder="Buscar setor (cod, nome, grupo)..." oninput="filterTbl(this.value)">
    <span style="color:var(--muted);font-size:10px">&#9650;&#9660; cabeçalho para ordenar &nbsp;|&nbsp; verde=Δ&lt;5% &nbsp; laranja=5-15% &nbsp; vermelho=&gt;15%</span>
  </div>
  <div style="overflow-x:auto;max-height:78vh;overflow-y:auto">
  <table class="dt" id="tblS">
    <thead><tr>
      <th onclick="sortT(0)">Cod</th>
      <th onclick="sortT(1)">Setor EPE</th>
      <th onclick="sortT(2)">Setor GIC</th>
      <th onclick="sortT(3)" class="epe-c">MP_E</th>
      <th onclick="sortT(4)" class="gic-c">MP_G</th>
      <th onclick="sortT(5)">Δ%</th>
      <th onclick="sortT(6)" class="epe-c">MPT_E</th>
      <th onclick="sortT(7)" class="gic-c">MPT_G</th>
      <th onclick="sortT(8)" class="epe-c">MEI_E</th>
      <th onclick="sortT(9)" class="gic-c">MEI_G</th>
      <th onclick="sortT(10)" class="epe-c">MRI_E</th>
      <th onclick="sortT(11)" class="gic-c">MRI_G</th>
      <th onclick="sortT(12)" class="epe-c">BL_E</th>
      <th onclick="sortT(13)" class="gic-c">BL_G</th>
      <th onclick="sortT(14)" class="epe-c">FLG_E</th>
      <th onclick="sortT(15)" class="gic-c">FLG_G</th>
      <th onclick="sortT(16)" class="epe-c">BLext_E%</th>
      <th onclick="sortT(17)" class="gic-c">BLext_G%</th>
    </tr></thead>
    <tbody id="tblSbody"></tbody>
  </table>
  </div>
</main></div>

<script>
// ── DATA ──────────────────────────────────────────────────────────────────────
const D = ]",
js_data,
r"[;

// ── COLOURS ───────────────────────────────────────────────────────────────────
const C_EPE="#378ADD", C_GIC="#F39C12", C_BOTH="#8E44AD";
const NAMED={Agropecuaria:"#3B6D11",Ind_Extrativa:"#888780",Energia_Fossil:"#E24B4A",
  Energia_Renov:"#1D9E75",Ind_Transform:"#378ADD",Infraestrutura:"#534AB7",
  Servicos:"#B4B2A9",Energeticos:"#F39C12"};
function gc(g){return NAMED[g]||"#6c7a9c";}

// ── CHART DEFAULTS ────────────────────────────────────────────────────────────
const CDx={color:"#8892a4",grid:{color:"rgba(255,255,255,.05)"},ticks:{color:"#8892a4",font:{size:10}}};
const PLG={legend:{labels:{color:"#e2e8f0",font:{size:11},boxWidth:11}},
           tooltip:{backgroundColor:"#1e2330",titleColor:"#e2e8f0",bodyColor:"#8892a4",borderColor:"#2d3448",borderWidth:1}};

const _charts={};
function mkC(id,type,labels,datasets,opts){
  const el=document.getElementById(id); if(!el) return;
  if(_charts[id]) _charts[id].destroy();
  _charts[id]=new Chart(el,{type,data:{labels,datasets},
    options:Object.assign({responsive:true,maintainAspectRatio:false,plugins:PLG,
      scales:type==="scatter"||type==="bar"?{x:CDx,y:CDx}:{}},opts||{})});
}

// ── STATS HELPERS ─────────────────────────────────────────────────────────────
function r(xs,ys){
  const v=(a,m)=>a.reduce((s,x)=>s+(x-m)**2,0);
  const cov=(a,b,ma,mb)=>a.reduce((s,x,i)=>s+(x-ma)*(b[i]-mb),0);
  const n=xs.length; if(n<3) return 0;
  const mx=xs.reduce((a,b)=>a+b,0)/n, my=ys.reduce((a,b)=>a+b,0)/n;
  const denom=Math.sqrt(v(xs,mx)*v(ys,my));
  return denom?cov(xs,ys,mx,my)/denom:0;
}
function setR2(id,xs,ys){
  const rc=r(xs.filter((_,i)=>ys[i]!=null),ys.filter(v=>v!=null));
  const el=document.getElementById(id);
  if(el) el.textContent=`r=${rc.toFixed(3)} R²=${(rc*rc).toFixed(3)}`;
}
function histBins(vals,nbins=14){
  vals=vals.filter(v=>v!=null&&isFinite(v));
  const mn=Math.min(...vals),mx=Math.max(...vals),w=(mx-mn)/nbins||1;
  const bins=Array.from({length:nbins},(_,i)=>({x:mn+i*w,y:0}));
  vals.forEach(v=>{const i=Math.min(Math.floor((v-mn)/w),nbins-1);bins[i].y++;});
  return {labels:bins.map(b=>b.x.toFixed(2)),counts:bins.map(b=>b.y)};
}

// ── TAB SYSTEM ────────────────────────────────────────────────────────────────
const INITS=[initSummary,initMult,initLinkage,initExtraction,initTable];
const ST={tab:0,built:{}};
function showTab(n){
  document.querySelectorAll(".tab-panel").forEach(p=>p.classList.remove("active"));
  document.getElementById("tab"+n).classList.add("active");
  document.querySelectorAll("#mainTabs button").forEach((b,i)=>b.classList.toggle("active",i===n));
  if(!ST.built[n]){INITS[n]();ST.built[n]=true;}
  ST.tab=n;
}

// tooltip for scatter
function tipPair(xk,yk){
  return {callbacks:{label:ctx=>{
    const p=D.pairs[ctx.dataIndex];
    return [`${p.cod} — ${(p.epe_nome||"").substring(0,30)}`,
            `EPE: ${(p[xk]??0).toFixed(4)}   GIC: ${(p[yk]??0).toFixed(4)}`];
  }}};
}

function scatter(id,xk,yk,xlab,ylab,r2id){
  const p=D.pairs;
  mkC(id,"scatter",null,
    [{label:"Setores",data:p.map(r2=>({x:r2[xk]??0,y:r2[yk]??0})),
      backgroundColor:p.map(r2=>gc(r2.grupo)+"bb"),pointRadius:5,pointHoverRadius:7}],
    {plugins:{...PLG,tooltip:{...PLG.tooltip,...tipPair(xk,yk)}},
     scales:{x:{...CDx,title:{display:true,text:xlab,color:"#8892a4"}},
             y:{...CDx,title:{display:true,text:ylab,color:"#8892a4"}}}});
  if(r2id) setR2(r2id,p.map(r2=>r2[xk]??0),p.map(r2=>r2[yk]??0));
}

function topBar(id,sortKey_E,sortKey_G,lbl,n=15){
  const p=[...D.pairs].filter(r2=>r2[sortKey_E]!=null).sort((a,b)=>(b[sortKey_E]??0)-(a[sortKey_E]??0)).slice(0,n);
  mkC(id,"bar",p.map(r2=>r2.cod),
    [{label:`${lbl} EPE`,data:p.map(r2=>r2[sortKey_E]??0),backgroundColor:C_EPE+"cc",borderRadius:2},
     {label:`${lbl} GIC`,data:p.map(r2=>r2[sortKey_G]??0),backgroundColor:C_GIC+"cc",borderRadius:2}],
    {indexAxis:"y",
     plugins:{...PLG,tooltip:{...PLG.tooltip,callbacks:{label:ctx=>{
       const r2=p[ctx.dataIndex];return `${r2.epe_nome?.substring(0,32)}: ${ctx.parsed.x?.toFixed(3)}`;}}}},
     scales:{x:{...CDx,title:{display:true,text:lbl,color:"#8892a4"}},y:{...CDx}}});
}

// ── TAB 0: SUMMARY ────────────────────────────────────────────────────────────
function initSummary(){
  const p=D.pairs;
  document.getElementById("matchBadge").textContent=
    `${D.meta.matched_n} pares | ${D.meta.epe_n} EPE | ${D.meta.gic_n} GIC`;

  // KPIs
  const avg=(arr,k)=>arr.reduce((s,r)=>s+(r[k]??0),0)/arr.length;
  const rc_mp=r(p.map(r2=>r2.MP_E),p.map(r2=>r2.MP_G));
  const rc_bl=r(p.map(r2=>r2.BL_E),p.map(r2=>r2.BL_G));
  const nke=p.filter(r2=>r2.BL_E>1&&r2.FLG_E>1).length;
  const nkg=p.filter(r2=>r2.BL_G>1&&r2.FLG_G>1).length;
  const kpis=[
    {l:"MP Médio — EPE",v:avg(p,"MP_E").toFixed(3),s:"Mult. Simples Produção 2018",c:C_EPE},
    {l:"MP Médio — GIC",v:avg(p,"MP_G").toFixed(3),s:"Mult. Simples Produção 2021",c:C_GIC},
    {l:"Correlação MP",v:rc_mp.toFixed(3),s:`R² = ${(rc_mp**2).toFixed(3)}`,c:C_BOTH},
    {l:"Correlação BL",v:rc_bl.toFixed(3),s:`R² = ${(rc_bl**2).toFixed(3)}`,c:C_BOTH},
    {l:"Setores-chave EPE",v:nke,s:"BL>1 e FLG>1",c:C_EPE},
    {l:"Setores-chave GIC",v:nkg,s:"BL>1 e FLG>1",c:C_GIC},
    {l:"BL Médio — EPE",v:avg(p,"BL_E").toFixed(3),s:"Rasmussen backward 2018",c:C_EPE},
    {l:"BL Médio — GIC",v:avg(p,"BL_G").toFixed(3),s:"Rasmussen backward 2021",c:C_GIC},
  ];
  document.getElementById("kpiRow").innerHTML=kpis.map(k=>
    `<div class="kpi"><div class="kpi-val" style="color:${k.c}">${k.v}</div>
     <div class="kpi-lbl">${k.l}</div><div class="kpi-sub">${k.s}</div></div>`).join("");

  // Histograms
  const hE=histBins(p.map(r2=>r2.MP_E)), hG=histBins(p.map(r2=>r2.MP_G));
  mkC("ch-dist-mp","bar",hE.labels,
    [{label:"EPE 2018",data:hE.counts,backgroundColor:C_EPE+"aa",borderRadius:2},
     {label:"GIC 2021",data:hG.counts,backgroundColor:C_GIC+"aa",borderRadius:2}],
    {scales:{x:{...CDx,title:{display:true,text:"MP",color:"#8892a4"}},
             y:{...CDx,title:{display:true,text:"Nº setores",color:"#8892a4"}}}});

  const bE=histBins(p.map(r2=>r2.BL_E)), bG=histBins(p.map(r2=>r2.BL_G));
  mkC("ch-dist-bl","bar",bE.labels,
    [{label:"EPE 2018",data:bE.counts,backgroundColor:C_EPE+"aa",borderRadius:2},
     {label:"GIC 2021",data:bG.counts,backgroundColor:C_GIC+"aa",borderRadius:2}],
    {scales:{x:{...CDx,title:{display:true,text:"BL",color:"#8892a4"}},
             y:{...CDx,title:{display:true,text:"Nº setores",color:"#8892a4"}}}});

  // Summary stats table
  const ROWS=[
    ["Mult. Produção Simples (MP)","MP"],["Mult. Produção Total (MPT)","MPT"],
    ["Mult. Produção Total Truncado (MPTT)","MPTT"],
    ["Mult. Emprego Tipo I (MEI)","MEI"],["Mult. Emprego Tipo II (MEII)","MEII"],
    ["Mult. Renda Tipo I (MRI)","MRI"],["Mult. Renda Tipo II (MRII)","MRII"],
    ["BL Rasmussen","BL"],["FLG Ghosh","FLG"],
    ["PBLN (Índ. Puro Ligação Trás)","PBLN"],["PFLN (Índ. Puro Ligação Frente)","PFLN"],
    ["Extração BL%","BLpct"],["Extração FL%","FLpct"]
  ];
  const f4=(v)=>v==null||isNaN(v)?"—":v.toFixed(4);
  const diffCls=(a,b)=>{const d=Math.abs((a-b)/((a+b)/2||1))*100; return d<5?"ok":d<15?"warn":"bad";};
  let h=`<tr><th>Indicador</th><th>Modelo</th><th>Mín</th><th>Q1</th><th>Mediana</th><th>Média</th><th>Q3</th><th>Máx</th></tr>`;
  ROWS.forEach(([lbl,key])=>{
    const se=D.summary[key]?.epe, sg=D.summary[key]?.gic;
    if(!se||!sg) return;
    const cls=diffCls(se.mean,sg.mean);
    h+=`<tr><td rowspan="2" style="font-weight:600">${lbl}</td>
      <td class="ve">EPE 2018</td>
      <td>${f4(se.min)}</td><td>${f4(se.q1)}</td><td>${f4(se.median)}</td>
      <td><strong>${f4(se.mean)}</strong></td><td>${f4(se.q3)}</td><td>${f4(se.max)}</td></tr>
    <tr><td class="vg">GIC 2021</td>
      <td>${f4(sg.min)}</td><td>${f4(sg.q1)}</td><td>${f4(sg.median)}</td>
      <td><strong class="${cls}">${f4(sg.mean)}</strong></td><td>${f4(sg.q3)}</td><td>${f4(sg.max)}</td></tr>`;
  });
  document.getElementById("summTable").innerHTML=h;
}

// ── TAB 1: MULTIPLICADORES ────────────────────────────────────────────────────
function initMult(){
  scatter("ch-sc-mp", "MP_E","MP_G", "MP EPE 2018","MP GIC 2021","r2-mp");
  scatter("ch-sc-mpt","MPT_E","MPT_G","MPT EPE","MPT GIC","r2-mpt");
  scatter("ch-sc-mei","MEI_E","MEI_G","MEI EPE","MEI GIC","r2-mei");
  scatter("ch-sc-mri","MRI_E","MRI_G","MRI EPE","MRI GIC","r2-mri");
  topBar("ch-top-mp", "MP_E", "MP_G", "MP");
  topBar("ch-top-mpt","MPT_E","MPT_G","MPT");
  topBar("ch-top-mei","MEI_E","MEI_G","MEI");
  topBar("ch-top-mri","MRI_E","MRI_G","MRI");
}

// ── TAB 2: ÍNDICES DE LIGAÇÃO ─────────────────────────────────────────────────
function initLinkage(){
  const p=D.pairs;
  // BL vs FLG scatter — EPE
  mkC("ch-cv-epe","scatter",null,
    [{label:"Setores EPE",data:p.map(r2=>({x:r2.FLG_E,y:r2.BL_E})),
      backgroundColor:p.map(r2=>gc(r2.grupo)+"bb"),pointRadius:4,pointHoverRadius:7}],
    {plugins:{...PLG,tooltip:{...PLG.tooltip,callbacks:{label:ctx=>{
      const p2=p[ctx.dataIndex];
      return [`${p2.cod} ${(p2.epe_nome||"").substring(0,25)}`,
              `BL=${p2.BL_E?.toFixed(3)} FLG=${p2.FLG_E?.toFixed(3)}`];}}}},
     scales:{
       x:{...CDx,min:0.4,max:2.5,title:{display:true,text:"FLG Ghosh",color:"#8892a4"}},
       y:{...CDx,min:0.4,max:2.5,title:{display:true,text:"BL Rasmussen",color:"#8892a4"}}}});

  // BL vs FLG scatter — GIC
  mkC("ch-cv-gic","scatter",null,
    [{label:"Setores GIC",data:p.map(r2=>({x:r2.FLG_G,y:r2.BL_G})),
      backgroundColor:p.map(r2=>gc(r2.grupo)+"bb"),pointRadius:4,pointHoverRadius:7}],
    {plugins:{...PLG,tooltip:{...PLG.tooltip,callbacks:{label:ctx=>{
      const p2=p[ctx.dataIndex];
      return [`${p2.cod} ${p2.gic_nome||""}`,
              `BL=${p2.BL_G?.toFixed(3)} FLG=${p2.FLG_G?.toFixed(3)}`];}}}},
     scales:{
       x:{...CDx,min:0.4,max:2.5,title:{display:true,text:"FLG Ghosh",color:"#8892a4"}},
       y:{...CDx,min:0.4,max:2.5,title:{display:true,text:"BL Rasmussen",color:"#8892a4"}}}});

  scatter("ch-sc-bl", "BL_E","BL_G",  "BL EPE",  "BL GIC",  "r2-bl");
  scatter("ch-sc-flg","FLG_E","FLG_G","FLG EPE","FLG GIC","r2-flg");
  topBar("ch-top-bl", "BL_E", "BL_G", "BL");
  topBar("ch-top-flg","FLG_E","FLG_G","FLG");
}

// ── TAB 3: EXTRAÇÃO & IPLN ────────────────────────────────────────────────────
function initExtraction(){
  scatter("ch-sc-blpct","BLpct_E","BLpct_G","BLext% EPE","BLext% GIC","r2-blpct");
  scatter("ch-sc-flpct","FLpct_E","FLpct_G","FLext% EPE","FLext% GIC","r2-flpct");
  scatter("ch-sc-pbln", "PBLN_E", "PBLN_G", "PBLN EPE",  "PBLN GIC",  "r2-pbln");
  scatter("ch-sc-pfln", "PFLN_E", "PFLN_G", "PFLN EPE",  "PFLN GIC",  "r2-pfln");
  topBar("ch-top-blpct","BLpct_E","BLpct_G","BL Ext%");
  topBar("ch-top-flpct","FLpct_E","FLpct_G","FL Ext%");
}

// ── TAB 4: TABLE ──────────────────────────────────────────────────────────────
let _td=[];
function initTable(){
  _td=D.pairs.map(r2=>({
    cod:r2.cod, epe:r2.epe_nome||"", gic:r2.gic_nome||"", grp:r2.grupo||"",
    mp_e:r2.MP_E, mp_g:r2.MP_G,
    dmp:r2.MP_E&&r2.MP_G?((r2.MP_E-r2.MP_G)/((r2.MP_E+r2.MP_G)/2)*100):null,
    mpt_e:r2.MPT_E, mpt_g:r2.MPT_G,
    mei_e:r2.MEI_E, mei_g:r2.MEI_G,
    mri_e:r2.MRI_E, mri_g:r2.MRI_G,
    bl_e:r2.BL_E,   bl_g:r2.BL_G,
    flg_e:r2.FLG_E, flg_g:r2.FLG_G,
    blx_e:r2.BLpct_E, blx_g:r2.BLpct_G
  }));
  renderT();
}
function renderT(data){
  data=data||_td;
  const f=(v,d=3)=>v==null||isNaN(v)?"—":Number(v).toFixed(d);
  const dc=d=>d==null?"":Math.abs(d)<5?"ok":Math.abs(d)<15?"warn":"bad";
  document.getElementById("tblSbody").innerHTML=data.map(r2=>`<tr>
    <td>${r2.cod}</td>
    <td style="max-width:190px;overflow:hidden;text-overflow:ellipsis" title="${r2.epe}">${r2.epe.substring(0,30)}</td>
    <td style="max-width:150px;overflow:hidden;text-overflow:ellipsis" title="${r2.gic}">${r2.gic}</td>
    <td class="epe-c">${f(r2.mp_e)}</td><td class="gic-c">${f(r2.mp_g)}</td>
    <td class="${dc(r2.dmp)}">${r2.dmp!=null?r2.dmp.toFixed(1)+"%":"—"}</td>
    <td class="epe-c">${f(r2.mpt_e)}</td><td class="gic-c">${f(r2.mpt_g)}</td>
    <td class="epe-c">${f(r2.mei_e)}</td><td class="gic-c">${f(r2.mei_g)}</td>
    <td class="epe-c">${f(r2.mri_e)}</td><td class="gic-c">${f(r2.mri_g)}</td>
    <td class="epe-c">${f(r2.bl_e)}</td><td class="gic-c">${f(r2.bl_g)}</td>
    <td class="epe-c">${f(r2.flg_e)}</td><td class="gic-c">${f(r2.flg_g)}</td>
    <td class="epe-c">${f(r2.blx_e)}</td><td class="gic-c">${f(r2.blx_g)}</td>
  </tr>`).join("");
}
function filterTbl(q){
  q=q.toLowerCase();
  renderT(_td.filter(r2=>[r2.cod,r2.epe,r2.gic,r2.grp].some(s=>(s||"").toLowerCase().includes(q))));
}
let _tSort={col:0,asc:true};
function sortT(col){
  _tSort.asc=_tSort.col===col?!_tSort.asc:true; _tSort.col=col;
  const ks=["cod","epe","gic","mp_e","mp_g","dmp","mpt_e","mpt_g","mei_e","mei_g",
             "mri_e","mri_g","bl_e","bl_g","flg_e","flg_g","blx_e","blx_g"];
  const k=ks[col];
  _td.sort((a,b)=>{const va=a[k]??"",vb=b[k]??"";
    return(typeof va==="number"?(va-vb):((""+va)<(""+vb)?-1:(""+va)>(""+vb)?1:0))*(_tSort.asc?1:-1);});
  renderT();
}

// ── BOOT ─────────────────────────────────────────────────────────────────────
showTab(0);
</script>
</body>
</html>
]")

# ── 5. WRITE ──────────────────────────────────────────────────────────────────
out <- "outputs/validation_dashboard.html"
writeLines(html, out, useBytes=FALSE)
cat("Validation dashboard written:", out, "\n")
cat("File size:", round(file.size(out)/1024), "KB\n")
