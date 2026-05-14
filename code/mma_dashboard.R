# =============================================================================
# MMA SHOCK ENGINES — Dashboard Interativo
# Lê outputs/tables/mma_shock_results.xlsx e gera outputs/mma_dashboard.html
# =============================================================================
pkgs <- c("readxl","jsonlite","dplyr")
for (p in pkgs) { if (!requireNamespace(p,quietly=TRUE)) install.packages(p); library(p,character.only=TRUE) }

XLS_IN  <- "outputs/tables/mma_shock_results.xlsx"
HTML_OUT <- "outputs/mma_dashboard.html"
if (!dir.exists("outputs")) dir.create("outputs", recursive=TRUE)
stopifnot(file.exists(XLS_IN))
cat("Lendo", XLS_IN, "\n")

resumo     <- suppressMessages(read_excel(XLS_IN, sheet="Resumo"))
top15      <- suppressMessages(read_excel(XLS_IN, sheet="Top15_por_Setor"))
completo   <- suppressMessages(read_excel(XLS_IN, sheet="Resultados_Completos"))
emissoes   <- suppressMessages(read_excel(XLS_IN, sheet="Emissoes_Setoriais"))
delta_f    <- suppressMessages(read_excel(XLS_IN, sheet="Delta_F_Componentes"))
premissas  <- suppressMessages(read_excel(XLS_IN, sheet="Premissas"))
mapeamento <- suppressMessages(read_excel(XLS_IN, sheet="Mapeamento_Setores"))

js <- toJSON(list(
  resumo     = resumo,
  top15      = top15,
  completo   = completo,
  emissoes   = emissoes,
  delta_f    = delta_f,
  premissas  = premissas,
  mapeamento = mapeamento
), na="null", digits=4, auto_unbox=TRUE)

cat("JSON:", round(nchar(js)/1e3,1), "KB\n")

# ─────────────────────────────────────────────────────────────────────────────
html <- paste0('<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MMA Cenários Climáticos — Impactos Macroeconômicos</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.min.js"></script>
<style>
:root{
  --bg:#0f1117;--card:#1a1d27;--border:#2a2d3e;--text:#e2e8f0;
  --muted:#8892a4;--accent:#378ADD;
  --c0d:#E24B4A;--c25d:#F59E0B;--c100d:#1D9E75;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:"Segoe UI","Inter",sans-serif;font-size:13px}
/* TOP BAR */
.topbar{background:#13151f;border-bottom:1px solid var(--border);
  padding:10px 24px;display:flex;align-items:center;gap:16px;
  position:sticky;top:0;z-index:110}
.topbar h1{font-size:15px;font-weight:700;color:#fff;letter-spacing:.02em}
.topbar span{font-size:11px;color:var(--muted)}
.badge-pill{font-size:10px;padding:2px 8px;border-radius:10px;font-weight:600;border:1px solid}
.badge-0d{color:var(--c0d);border-color:var(--c0d)}
.badge-25d{color:var(--c25d);border-color:var(--c25d)}
.badge-100d{color:var(--c100d);border-color:var(--c100d)}
/* TABS */
nav.tabs{background:#13151f;border-bottom:1px solid var(--border);
  padding:0 24px;display:flex;gap:2px;overflow-x:auto;
  position:sticky;top:44px;z-index:100}
nav.tabs button{background:none;border:none;color:var(--muted);
  padding:9px 16px;font-size:12px;cursor:pointer;
  border-bottom:2px solid transparent;white-space:nowrap;transition:.15s}
nav.tabs button.active{color:#fff;border-bottom-color:var(--accent)}
nav.tabs button:hover:not(.active){color:var(--text)}
/* FILTERS BAR */
.fbar{background:#13151f;border-bottom:1px solid var(--border);
  padding:7px 24px;display:flex;align-items:center;gap:14px;flex-wrap:wrap;
  position:sticky;top:84px;z-index:99}
.fl{font-size:9px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.1em}
.btn-grp{display:flex;border:1px solid var(--border);border-radius:6px;overflow:hidden}
.btn-grp button{background:none;border:none;border-right:1px solid var(--border);
  color:var(--muted);padding:4px 12px;font-size:11px;font-weight:500;cursor:pointer;transition:.15s}
.btn-grp button:last-child{border-right:none}
.btn-grp button.active{background:var(--accent);color:#fff}
.btn-grp button:hover:not(.active){background:#1f2233;color:var(--text)}
.sel-wrap select{background:#1a1d27;border:1px solid var(--border);color:var(--text);
  padding:4px 10px;border-radius:6px;font-size:11px;cursor:pointer}
/* CONTENT */
.page{display:none;padding:20px 24px}
.page.active{display:block}
/* KPI CARDS */
.kpi-row{display:flex;gap:14px;flex-wrap:wrap;margin-bottom:20px}
.kpi{background:var(--card);border:1px solid var(--border);border-radius:10px;
  padding:14px 18px;min-width:170px;flex:1}
.kpi .label{font-size:10px;color:var(--muted);text-transform:uppercase;letter-spacing:.08em;margin-bottom:4px}
.kpi .val{font-size:22px;font-weight:700;color:#fff;line-height:1.1}
.kpi .sub{font-size:10px;color:var(--muted);margin-top:3px}
.kpi.green .val{color:var(--c100d)}
.kpi.amber .val{color:var(--c25d)}
.kpi.red   .val{color:var(--c0d)}
/* CHART CARDS */
.chart-row{display:grid;gap:14px;margin-bottom:14px}
.chart-row.cols2{grid-template-columns:1fr 1fr}
.chart-row.cols3{grid-template-columns:1fr 1fr 1fr}
.chart-row.full{grid-template-columns:1fr}
.chart-card{background:var(--card);border:1px solid var(--border);
  border-radius:10px;padding:16px 18px}
.chart-card h3{font-size:12px;font-weight:600;color:var(--text);margin-bottom:12px}
.chart-card .sub-label{font-size:10px;color:var(--muted);margin-bottom:10px}
.chart-wrap{position:relative}
/* TABLE */
.tbl-wrap{overflow-x:auto;max-height:420px;overflow-y:auto}
table{width:100%;border-collapse:collapse;font-size:11.5px}
thead th{background:#13151f;color:var(--muted);font-weight:600;
  padding:7px 10px;text-align:left;position:sticky;top:0;
  border-bottom:1px solid var(--border);white-space:nowrap}
tbody tr:hover{background:#1f2233}
tbody td{padding:5px 10px;border-bottom:1px solid #1f2233;color:var(--text)}
/* SCENARIO LEGEND */
.leg{display:flex;gap:16px;flex-wrap:wrap;margin-bottom:12px}
.leg-item{display:flex;align-items:center;gap:5px;font-size:11px;color:var(--muted)}
.leg-dot{width:10px;height:10px;border-radius:50%}
/* SCENARIO description box */
.scen-box{background:var(--card);border:1px solid var(--border);border-radius:10px;
  padding:14px 18px;margin-bottom:14px;font-size:11.5px;line-height:1.6}
.scen-box strong{color:#fff}
@media(max-width:700px){.chart-row.cols2,.chart-row.cols3{grid-template-columns:1fr}}
</style>
</head>
<body>

<!-- TOP BAR -->
<div class="topbar">
  <h1>🌱 MMA Cenários Climáticos &mdash; Impactos Macroeconômicos</h1>
  <span>MMA-SMC v3 AR5 &times; EPE/FIPE MIP 2018 &bull; 73 setores</span>
  <span style="margin-left:auto;display:flex;gap:6px">
    <span class="badge-pill badge-0d">0D TRF</span>
    <span class="badge-pill badge-25d">25D TRS</span>
    <span class="badge-pill badge-100d">100D MCI</span>
  </span>
</div>

<!-- TABS -->
<nav class="tabs">
  <button class="active" onclick="setTab(0)">Visão Geral</button>
  <button onclick="setTab(1)">Produção &amp; PIB</button>
  <button onclick="setTab(2)">Emissões</button>
  <button onclick="setTab(3)">Setores</button>
  <button onclick="setTab(4)">Componentes ∆f</button>
  <button onclick="setTab(5)">Dados</button>
</nav>

<!-- FILTERS BAR -->
<div class="fbar" id="fbar">
  <span class="fl">Cenário</span>
  <div class="btn-grp" id="scen-btns">
    <button class="active" data-s="25D" onclick="setScen(this)">25D TRS</button>
    <button data-s="100D" onclick="setScen(this)">100D MCI</button>
    <button data-s="0D"   onclick="setScen(this)">0D TRF</button>
  </div>
  <span class="fl" style="margin-left:8px">Ano</span>
  <div class="btn-grp" id="ano-btns">
    <button class="active" data-a="2025" onclick="setAno(this)">2025</button>
    <button data-a="2030" onclick="setAno(this)">2030</button>
    <button data-a="2035" onclick="setAno(this)">2035</button>
    <button data-a="2040" onclick="setAno(this)">2040</button>
    <button data-a="2045" onclick="setAno(this)">2045</button>
    <button data-a="2050" onclick="setAno(this)">2050</button>
  </div>
</div>

<!-- ============================================================ TAB 0: VISÃO GERAL -->
<div class="page active" id="tab0">
  <div class="kpi-row" id="kpi-row"></div>
  <div class="scen-box" id="scen-desc"></div>
  <div class="chart-row cols2">
    <div class="chart-card">
      <h3>Variação da Produção Total (∆x, R$ bi) — trajetórias</h3>
      <div class="leg">
        <span class="leg-item"><span class="leg-dot" style="background:var(--c0d)"></span>0D TRF</span>
        <span class="leg-item"><span class="leg-dot" style="background:var(--c25d)"></span>25D TRS</span>
        <span class="leg-item"><span class="leg-dot" style="background:var(--c100d)"></span>100D MCI</span>
      </div>
      <div class="chart-wrap" style="height:220px"><canvas id="ch-prod"></canvas></div>
    </div>
    <div class="chart-card">
      <h3>Emissões GHG Induzidas (MtCO₂e) vs Cenário MMA</h3>
      <div class="leg">
        <span class="leg-item"><span class="leg-dot" style="background:var(--c0d)"></span>0D TRF</span>
        <span class="leg-item"><span class="leg-dot" style="background:var(--c25d)"></span>25D TRS</span>
        <span class="leg-item"><span class="leg-dot" style="background:var(--c100d)"></span>100D MCI</span>
      </div>
      <div class="chart-wrap" style="height:220px"><canvas id="ch-ghg"></canvas></div>
    </div>
  </div>
  <div class="chart-row cols3">
    <div class="chart-card">
      <h3>Choque de Investimento (R$ bi/ano)</h3>
      <div class="chart-wrap" style="height:180px"><canvas id="ch-inv"></canvas></div>
    </div>
    <div class="chart-card">
      <h3>Escalonamento PIB (R$ bi)</h3>
      <div class="chart-wrap" style="height:180px"><canvas id="ch-gdp"></canvas></div>
    </div>
    <div class="chart-card">
      <h3>Choque de Produção Física (R$ bi)</h3>
      <div class="chart-wrap" style="height:180px"><canvas id="ch-prod2"></canvas></div>
    </div>
  </div>
</div>

<!-- ============================================================ TAB 1: PRODUÇÃO & PIB -->
<div class="page" id="tab1">
  <div class="chart-row full">
    <div class="chart-card">
      <h3>Top 15 Setores — Variação de Produção (∆x total, R$ mi) no cenário/ano selecionado</h3>
      <div class="chart-wrap" style="height:360px"><canvas id="ch-top15"></canvas></div>
    </div>
  </div>
  <div class="chart-row cols2">
    <div class="chart-card">
      <h3>Comparação entre cenários — Top 10 setores (ano selecionado)</h3>
      <div class="chart-wrap" style="height:280px"><canvas id="ch-cmp"></canvas></div>
    </div>
    <div class="chart-card">
      <h3>Variação % da Produção — Maiores ganhos (cenário/ano)</h3>
      <div class="chart-wrap" style="height:280px"><canvas id="ch-pct"></canvas></div>
    </div>
  </div>
</div>

<!-- ============================================================ TAB 2: EMISSÕES -->
<div class="page" id="tab2">
  <div class="chart-row cols2">
    <div class="chart-card">
      <h3>GHG Induzido MIP (MtCO₂e) — todos os cenários</h3>
      <div class="chart-wrap" style="height:240px"><canvas id="ch-ghg2"></canvas></div>
    </div>
    <div class="chart-card">
      <h3>GHG Total Cenário MMA vs Induzido MIP</h3>
      <div class="chart-wrap" style="height:240px"><canvas id="ch-ghg3"></canvas></div>
    </div>
  </div>
  <div class="chart-row full">
    <div class="chart-card">
      <h3>Top 15 Setores — GHG Induzido (MtCO₂e) no cenário/ano selecionado</h3>
      <div class="chart-wrap" style="height:300px"><canvas id="ch-ghg4"></canvas></div>
    </div>
  </div>
</div>

<!-- ============================================================ TAB 3: SETORES -->
<div class="page" id="tab3">
  <div class="chart-row full">
    <div class="chart-card">
      <h3>Todos os 73 Setores — ∆x Total (R$ mi) — cenário/ano selecionado</h3>
      <div class="chart-wrap" style="height:480px"><canvas id="ch-all73"></canvas></div>
    </div>
  </div>
</div>

<!-- ============================================================ TAB 4: COMPONENTES ∆f -->
<div class="page" id="tab4">
  <div class="chart-row full">
    <div class="chart-card">
      <h3>Decomposição do Choque de Demanda Final (∆f) — Top 20 Setores (cenário/ano)</h3>
      <div class="chart-wrap" style="height:360px"><canvas id="ch-df"></canvas></div>
    </div>
  </div>
  <div class="chart-row cols2">
    <div class="chart-card">
      <h3>Evolução ∆f por Componente — cenário selecionado (R$ bi)</h3>
      <div class="chart-wrap" style="height:240px"><canvas id="ch-df2"></canvas></div>
    </div>
    <div class="chart-card">
      <h3>Participação % dos Componentes — cenário/ano</h3>
      <div class="chart-wrap" style="height:240px"><canvas id="ch-df3"></canvas></div>
    </div>
  </div>
</div>

<!-- ============================================================ TAB 5: DADOS -->
<div class="page" id="tab5">
  <div class="chart-card" style="margin-bottom:14px">
    <h3 style="margin-bottom:10px">Resumo — 18 simulações (cenário × ano)</h3>
    <div class="tbl-wrap"><table id="tbl-resumo"></table></div>
  </div>
  <div class="chart-card">
    <h3 style="margin-bottom:10px">Resultados Setoriais — cenário/ano selecionado</h3>
    <div class="tbl-wrap"><table id="tbl-setor"></table></div>
  </div>
</div>

<script>
// ─────────────────────── DATA ──────────────────────────────────────
const DATA = ', js, ';

// ─────────────────────── STATE ─────────────────────────────────────
let selScen = "25D", selAno = 2025, selTab = 0;
const ANOS = [2025,2030,2035,2040,2045,2050];
const CENS = ["0D","25D","100D"];
const C = {"0D":"#E24B4A","25D":"#F59E0B","100D":"#1D9E75"};
const CL = {"0D":"rgba(226,75,74,.15)","25D":"rgba(245,158,11,.15)","100D":"rgba(29,158,117,.15)"};

// ─────────────────────── HELPERS ───────────────────────────────────
const fmt1 = v => v==null?"—":v.toLocaleString("pt-BR",{maximumFractionDigits:1});
const fmt0 = v => v==null?"—":v.toLocaleString("pt-BR",{maximumFractionDigits:0});
const fmtPct = v => v==null?"—":v.toFixed(1)+"%";

function byScenAno(arr,s,a){ return arr.filter(r=>r.cenario===s && +r.ano===+a) }
function byScen(arr,s){ return arr.filter(r=>r.cenario===s).sort((a,b)=>+a.ano - +b.ano) }
function resumoRow(s,a){ return DATA.resumo.find(r=>r.cenario===s && +r.ano===+a)||{} }

// ─────────────────────── CHART REGISTRY ────────────────────────────
const CHARTS = {};
function destroyChart(id){ if(CHARTS[id]){CHARTS[id].destroy();delete CHARTS[id];} }
function mkChart(id, cfg){
  destroyChart(id);
  const ctx = document.getElementById(id);
  if(!ctx) return;
  CHARTS[id] = new Chart(ctx, cfg);
}

const BASE_OPTS = {
  responsive:true, maintainAspectRatio:false,
  plugins:{ legend:{display:false}, tooltip:{callbacks:{}} },
  scales:{
    x:{ ticks:{color:"#8892a4",font:{size:10}}, grid:{color:"#1f2233"} },
    y:{ ticks:{color:"#8892a4",font:{size:10}}, grid:{color:"#1f2233"} }
  }
};
function deepMerge(a,b){
  const r = Object.assign({},a);
  for(const k in b){
    if(b[k]&&typeof b[k]==="object"&&!Array.isArray(b[k])) r[k]=deepMerge(a[k]||{},b[k]);
    else r[k]=b[k];
  }
  return r;
}

// ─────────────────────── TAB LOGIC ─────────────────────────────────
function setTab(i){
  selTab = i;
  document.querySelectorAll(".page").forEach((p,j)=>p.classList.toggle("active",j===i));
  document.querySelectorAll("nav.tabs button").forEach((b,j)=>b.classList.toggle("active",j===i));
  renderAll();
}
function setScen(btn){
  selScen = btn.dataset.s;
  document.querySelectorAll("#scen-btns button").forEach(b=>b.classList.toggle("active",b===btn));
  renderAll();
}
function setAno(btn){
  selAno = +btn.dataset.a;
  document.querySelectorAll("#ano-btns button").forEach(b=>b.classList.toggle("active",b===btn));
  renderAll();
}

// ─────────────────────── RENDER ────────────────────────────────────
function renderAll(){
  if(selTab===0) renderOverview();
  if(selTab===1) renderProd();
  if(selTab===2) renderEmis();
  if(selTab===3) renderSetores();
  if(selTab===4) renderDeltaF();
  if(selTab===5) renderDados();
}

// ── TAB 0: VISÃO GERAL ──────────────────────────────────────────────
function renderOverview(){
  const r = resumoRow(selScen, selAno);
  // KPI
  document.getElementById("kpi-row").innerHTML = `
    <div class="kpi"><div class="label">∆ Produção Total</div>
      <div class="val">R$ ${fmt0(r.delta_prod_bi)} bi</div>
      <div class="sub">variação acumulada 2018→${selAno}</div></div>
    <div class="kpi amber"><div class="label">GHG Induzido MIP</div>
      <div class="val">${fmt1(r.ghg_induzido_mt)} Mt</div>
      <div class="sub">CO₂e AR5 — imputado via L*</div></div>
    <div class="kpi red"><div class="label">GHG Total Cenário</div>
      <div class="val">${fmt1(r.ghg_cenario_mt)} Mt</div>
      <div class="sub">MMA-SMC v3 AR5</div></div>
    <div class="kpi green"><div class="label">Choque de Investimento</div>
      <div class="val">R$ ${fmt0(r.inv_shock_bi)} bi</div>
      <div class="sub">CapEx transição energética</div></div>
    <div class="kpi"><div class="label">Escalonamento PIB</div>
      <div class="val">R$ ${fmt0(r.gdp_scaling_bi)} bi</div>
      <div class="sub">crescimento 2018→${selAno}</div></div>
    <div class="kpi"><div class="label">Choque Produção Física</div>
      <div class="val">R$ ${fmt0(r.prod_shock_bi)} bi</div>
      <div class="sub">volumes físicos → R$ via Engine 3</div></div>`;

  // Scenario desc
  const DESC = {
    "0D":"<strong>0D / TRF — Tendência de Referência (BAU):</strong> Nenhuma redução adicional do desmatamento. Trajetória de emissões mais alta, sem grandes incentivos à transição energética acelerada.",
    "25D":"<strong>25D / TRS — Transição Sustentável:</strong> Redução de 25% no desmatamento frente ao BAU. Expansão moderada de energias renováveis, eletrificação do transporte e indústria, com investimentos significativos em low-carbon.",
    "100D":"<strong>100D / MCI — Máxima Credibilidade Internacional:</strong> Eliminação total do desmatamento ilegal. Transição energética acelerada com máxima eletrificação, biocombustíveis avançados e neutralidade de carbono próxima a 2050."
  };
  document.getElementById("scen-desc").innerHTML = DESC[selScen];

  // LINE — produção
  const datasets1 = CENS.map(s=>{
    const rows = byScen(DATA.resumo, s);
    return {
      label:s,
      data: rows.map(r=>r.delta_prod_bi),
      borderColor: C[s], backgroundColor: CL[s],
      borderWidth:2, pointRadius:4, tension:.3, fill:false
    };
  });
  mkChart("ch-prod",{type:"line",data:{labels:ANOS.map(String),datasets:datasets1},
    options:deepMerge(BASE_OPTS,{plugins:{legend:{display:false}},
      scales:{y:{title:{display:true,text:"R$ bi",color:"#8892a4"}}}})});

  // LINE — GHG induzido
  const datasets2 = CENS.map(s=>{
    const rows = byScen(DATA.resumo, s);
    return {label:s,data:rows.map(r=>r.ghg_induzido_mt),
      borderColor:C[s],backgroundColor:CL[s],
      borderWidth:2,pointRadius:4,tension:.3,fill:false};
  });
  // GHG cenário dashed
  const datasets2b = CENS.map(s=>{
    const rows = byScen(DATA.resumo, s);
    return {label:s+" (total)",data:rows.map(r=>r.ghg_cenario_mt),
      borderColor:C[s],borderDash:[4,4],pointRadius:2,tension:.3,
      borderWidth:1,fill:false};
  });
  mkChart("ch-ghg",{type:"line",data:{labels:ANOS.map(String),datasets:[...datasets2,...datasets2b]},
    options:deepMerge(BASE_OPTS,{plugins:{legend:{display:false}},
      scales:{y:{title:{display:true,text:"MtCO₂e",color:"#8892a4"}}}})});

  // BARS — inv, gdp, prod2 per scenario
  const invD = CENS.map(s=>({
    label:s,data:byScen(DATA.resumo,s).map(r=>r.inv_shock_bi),
    backgroundColor:C[s],borderRadius:3
  }));
  mkChart("ch-inv",{type:"bar",data:{labels:ANOS.map(String),datasets:invD},
    options:deepMerge(BASE_OPTS,{plugins:{legend:{display:false}},
      scales:{x:{stacked:false},y:{stacked:false,title:{display:true,text:"R$ bi",color:"#8892a4"}}}})});

  const gdpD = CENS.map(s=>({
    label:s,data:byScen(DATA.resumo,s).map(r=>r.gdp_scaling_bi),
    backgroundColor:C[s],borderRadius:3
  }));
  mkChart("ch-gdp",{type:"bar",data:{labels:ANOS.map(String),datasets:gdpD},
    options:deepMerge(BASE_OPTS,{plugins:{legend:{display:false}},
      scales:{x:{stacked:false},y:{stacked:false,title:{display:true,text:"R$ bi",color:"#8892a4"}}}})});

  const prdD = CENS.map(s=>({
    label:s,data:byScen(DATA.resumo,s).map(r=>r.prod_shock_bi),
    backgroundColor:C[s],borderRadius:3
  }));
  mkChart("ch-prod2",{type:"bar",data:{labels:ANOS.map(String),datasets:prdD},
    options:deepMerge(BASE_OPTS,{plugins:{legend:{display:false}},
      scales:{x:{stacked:false},y:{stacked:false,title:{display:true,text:"R$ bi",color:"#8892a4"}}}})});
}

// ── TAB 1: PRODUÇÃO ─────────────────────────────────────────────────
function renderProd(){
  const rows = byScenAno(DATA.top15, selScen, selAno)
    .sort((a,b)=>b.delta_x_total - a.delta_x_total).slice(0,15);
  const labels = rows.map(r=>shortName(r.nome));
  const vals   = rows.map(r=>r.delta_x_total);
  const colors = vals.map(v=>v>=0?"rgba(55,138,221,.8)":"rgba(226,75,74,.8)");
  mkChart("ch-top15",{type:"bar",
    data:{labels,datasets:[{data:vals,backgroundColor:colors,borderRadius:4}]},
    options:deepMerge(BASE_OPTS,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>"R$ "+fmt0(ctx.parsed.x)+" mi"}}},
      scales:{x:{title:{display:true,text:"R$ mi",color:"#8892a4"}},
              y:{ticks:{font:{size:10}}}}})});

  // comparison across scenarios — top 10 by abs value from any scenario
  const all10 = [...new Set(
    CENS.flatMap(s=>byScenAno(DATA.top15,s,selAno).sort((a,b)=>Math.abs(b.delta_x_total)-Math.abs(a.delta_x_total)).slice(0,10).map(r=>r.cod))
  )].slice(0,10);
  const names10 = all10.map(c=>{const r=DATA.completo.find(x=>x.cod===c);return r?shortName(r.nome):c});
  const cmpDs = CENS.map(s=>({
    label:s,
    data:all10.map(c=>{
      const r=byScenAno(DATA.completo,s,selAno).find(x=>x.cod===c);
      return r?r.delta_x_total:0;
    }),
    backgroundColor:C[s],borderRadius:3
  }));
  mkChart("ch-cmp",{type:"bar",data:{labels:names10,datasets:cmpDs},
    options:deepMerge(BASE_OPTS,{indexAxis:"y",
      plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{x:{title:{display:true,text:"R$ mi",color:"#8892a4"}},
              y:{ticks:{font:{size:9}}}}})});

  // % variation
  const pctRows = byScenAno(DATA.completo, selScen, selAno)
    .filter(r=>r.delta_x_pct!=null && r.x_base > 500)
    .sort((a,b)=>b.delta_x_pct - a.delta_x_pct).slice(0,15);
  mkChart("ch-pct",{type:"bar",
    data:{labels:pctRows.map(r=>shortName(r.nome)),
      datasets:[{data:pctRows.map(r=>r.delta_x_pct),
        backgroundColor:"rgba(29,158,117,.75)",borderRadius:4}]},
    options:deepMerge(BASE_OPTS,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>fmtPct(ctx.parsed.x)}}},
      scales:{x:{title:{display:true,text:"%",color:"#8892a4"}},
              y:{ticks:{font:{size:10}}}}})});
}

// ── TAB 2: EMISSÕES ─────────────────────────────────────────────────
function renderEmis(){
  // line ghg induzido
  const ds1 = CENS.map(s=>({label:s,
    data:byScen(DATA.resumo,s).map(r=>r.ghg_induzido_mt),
    borderColor:C[s],backgroundColor:CL[s],
    borderWidth:2,pointRadius:4,tension:.3,fill:true}));
  mkChart("ch-ghg2",{type:"line",data:{labels:ANOS.map(String),datasets:ds1},
    options:deepMerge(BASE_OPTS,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{y:{title:{display:true,text:"MtCO₂e",color:"#8892a4"}}}})});

  // grouped bar: total vs induzido
  const ds2 = CENS.flatMap(s=>[
    {label:s+" Total",data:byScen(DATA.resumo,s).map(r=>r.ghg_cenario_mt),
      backgroundColor:C[s],borderRadius:2,stack:s},
    {label:s+" MIP",data:byScen(DATA.resumo,s).map(r=>r.ghg_induzido_mt),
      backgroundColor:CL[s].replace("15)","60)"),borderRadius:2,stack:s}
  ]);
  mkChart("ch-ghg3",{type:"bar",data:{labels:ANOS.map(String),datasets:ds2},
    options:deepMerge(BASE_OPTS,{plugins:{legend:{display:false}},
      scales:{x:{stacked:true},y:{stacked:true,title:{display:true,text:"MtCO₂e",color:"#8892a4"}}}})});

  // top 15 setores ghg
  const rows = byScenAno(DATA.emissoes, selScen, selAno)
    .filter(r=>r.ghg_induzido_mt>0).sort((a,b)=>b.ghg_induzido_mt-a.ghg_induzido_mt).slice(0,15);
  mkChart("ch-ghg4",{type:"bar",
    data:{labels:rows.map(r=>shortName(r.nome)),
      datasets:[{data:rows.map(r=>r.ghg_induzido_mt),
        backgroundColor:"rgba(226,75,74,.75)",borderRadius:4}]},
    options:deepMerge(BASE_OPTS,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>fmt1(ctx.parsed.x)+" MtCO₂e"}}},
      scales:{x:{title:{display:true,text:"MtCO₂e",color:"#8892a4"}},
              y:{ticks:{font:{size:10}}}}})});
}

// ── TAB 3: SETORES ──────────────────────────────────────────────────
function renderSetores(){
  const rows = byScenAno(DATA.completo, selScen, selAno)
    .sort((a,b)=>b.delta_x_total - a.delta_x_total);
  const colors = rows.map(r=>r.delta_x_total>=0?"rgba(55,138,221,.7)":"rgba(226,75,74,.7)");
  mkChart("ch-all73",{type:"bar",
    data:{labels:rows.map(r=>shortName(r.nome)),
      datasets:[{data:rows.map(r=>r.delta_x_total),backgroundColor:colors,borderRadius:3}]},
    options:deepMerge(BASE_OPTS,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>"R$ "+fmt0(ctx.parsed.x)+" mi"}}},
      scales:{x:{title:{display:true,text:"R$ mi",color:"#8892a4"}},
              y:{ticks:{font:{size:8},maxTicksLimit:80}}}})});
}

// ── TAB 4: ∆f ───────────────────────────────────────────────────────
function renderDeltaF(){
  const rows = byScenAno(DATA.delta_f, selScen, selAno)
    .sort((a,b)=>Math.abs(b.delta_f_total)-Math.abs(a.delta_f_total)).slice(0,20);
  const lbls = rows.map(r=>shortName(r.nome));
  mkChart("ch-df",{type:"bar",data:{labels:lbls,datasets:[
    {label:"PIB",data:rows.map(r=>r.delta_f_gdp),backgroundColor:"rgba(55,138,221,.8)",borderRadius:3,stack:"s"},
    {label:"Investimento",data:rows.map(r=>r.delta_f_inv),backgroundColor:"rgba(29,158,117,.8)",borderRadius:3,stack:"s"},
    {label:"Produção Física",data:rows.map(r=>r.delta_f_prod),backgroundColor:"rgba(245,158,11,.8)",borderRadius:3,stack:"s"}
  ]},options:deepMerge(BASE_OPTS,{indexAxis:"y",
    plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
    scales:{x:{stacked:true,title:{display:true,text:"R$ mi",color:"#8892a4"}},
            y:{stacked:true,ticks:{font:{size:9}}}}})});

  // evolution over time stacked
  const totals = {gdp:[],inv:[],prod:[]};
  ANOS.forEach(a=>{
    const rs = byScenAno(DATA.delta_f, selScen, a);
    totals.gdp.push(rs.reduce((s,r)=>s+(r.delta_f_gdp||0),0)/1e6);
    totals.inv.push(rs.reduce((s,r)=>s+(r.delta_f_inv||0),0)/1e6);
    totals.prod.push(rs.reduce((s,r)=>s+(r.delta_f_prod||0),0)/1e6);
  });
  mkChart("ch-df2",{type:"bar",data:{labels:ANOS.map(String),datasets:[
    {label:"PIB",data:totals.gdp,backgroundColor:"rgba(55,138,221,.8)",borderRadius:3,stack:"s"},
    {label:"Investimento",data:totals.inv,backgroundColor:"rgba(29,158,117,.8)",borderRadius:3,stack:"s"},
    {label:"Prod. Física",data:totals.prod,backgroundColor:"rgba(245,158,11,.8)",borderRadius:3,stack:"s"}
  ]},options:deepMerge(BASE_OPTS,{
    plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
    scales:{x:{stacked:true},y:{stacked:true,title:{display:true,text:"R$ tri",color:"#8892a4"}}}})});

  // doughnut share for selected year
  const r = resumoRow(selScen, selAno);
  const tot = (r.gdp_scaling_bi||0)+(r.inv_shock_bi||0)+(r.prod_shock_bi||0);
  mkChart("ch-df3",{type:"doughnut",
    data:{labels:["PIB","Investimento","Prod. Física"],
      datasets:[{data:[r.gdp_scaling_bi,r.inv_shock_bi,r.prod_shock_bi],
        backgroundColor:["rgba(55,138,221,.8)","rgba(29,158,117,.8)","rgba(245,158,11,.8)"],
        borderWidth:0}]},
    options:{responsive:true,maintainAspectRatio:false,
      plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:11}}},
        tooltip:{callbacks:{label:ctx=>{
          const v=ctx.parsed; const pct=(v/tot*100).toFixed(1);
          return `R$ ${fmt0(v)} bi (${pct}%)`;
        }}}}}});
}

// ── TAB 5: DADOS ────────────────────────────────────────────────────
function renderDados(){
  // resumo table
  const cols = ["cenario","ano","delta_prod_bi","ghg_induzido_mt","ghg_cenario_mt","inv_shock_bi","gdp_scaling_bi","prod_shock_bi"];
  const heads = ["Cenário","Ano","∆ Prod (R$ bi)","GHG Induzido (Mt)","GHG Total (Mt)","Inv (R$ bi)","PIB (R$ bi)","Prod Fís (R$ bi)"];
  let ht = "<thead><tr>"+heads.map(h=>`<th>${h}</th>`).join("")+"</tr></thead><tbody>";
  DATA.resumo.sort((a,b)=>a.cenario.localeCompare(b.cenario)||+a.ano-+b.ano).forEach(r=>{
    ht += "<tr>"+cols.map((c,i)=>`<td>${i>=2?fmt1(r[c]):r[c]}</td>`).join("")+"</tr>";
  });
  ht += "</tbody>";
  document.getElementById("tbl-resumo").innerHTML = ht;

  // sector table
  const scols = ["cod","nome","x_base","delta_f_total","delta_x_total","delta_x_pct","e_coef","ghg_induzido_mt"];
  const sheads = ["Cód","Setor","x Base (R$ mi)","∆f Total (R$ mi)","∆x Total (R$ mi)","∆x %","e (MtCO₂e/R$M)","GHG (MtCO₂e)"];
  const srows = byScenAno(DATA.completo, selScen, selAno).sort((a,b)=>b.delta_x_total-a.delta_x_total);
  let st = "<thead><tr>"+sheads.map(h=>`<th>${h}</th>`).join("")+"</tr></thead><tbody>";
  srows.forEach(r=>{
    st += "<tr>"+scols.map((c,i)=>{
      if(i===0) return `<td>${r[c]}</td>`;
      if(i===1) return `<td>${shortName(r[c],40)}</td>`;
      const v = r[c];
      if(v==null) return "<td>—</td>";
      if(c==="delta_x_pct") return `<td>${fmtPct(v)}</td>`;
      if(c==="e_coef") return `<td>${v.toExponential(2)}</td>`;
      return `<td>${fmt1(v)}</td>`;
    }).join("")+"</tr>";
  });
  st += "</tbody>";
  document.getElementById("tbl-setor").innerHTML = st;
}

// ── UTILS ────────────────────────────────────────────────────────────
function shortName(n, max=28){
  if(!n) return "";
  const s = n.split(",")[0].trim().split(";")[0].trim();
  return s.length>max ? s.slice(0,max-1)+"…" : s;
}

// ─────────────────────── INIT ───────────────────────────────────────
renderOverview();
</script>
</body></html>')

writeLines(html, HTML_OUT, useBytes=FALSE)
cat("Dashboard gerado:", HTML_OUT, "\n")
cat("Tamanho:", round(file.size(HTML_OUT)/1e3,1), "KB\n")
