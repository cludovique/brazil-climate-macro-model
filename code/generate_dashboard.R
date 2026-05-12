# =============================================================================
# GENERATE DASHBOARD — MIP-EPE Energia Brasil 2018
# Reads mip_epe_replication_results.xlsx and writes a self-contained HTML
# Output: outputs/mip_epe_dashboard.html
# =============================================================================

library(readxl); library(jsonlite); library(dplyr)

XLS  <- if (file.exists("data/raw/mip_epe_replication_results.xlsx"))
           "data/raw/mip_epe_replication_results.xlsx" else
           "outputs/mip_epe_replication_results.xlsx"

HTML_OUT <- "outputs/mip_epe_dashboard.html"
if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)

cat("Reading:", XLS, "\n")
sheets <- excel_sheets(XLS)
dat    <- lapply(sheets, function(s) suppressMessages(read_excel(XLS, sheet = s)))
names(dat) <- sheets

js_data <- toJSON(dat, na = "null", digits = 4, auto_unbox = TRUE)
cat("JSON size:", round(nchar(js_data) / 1e3, 1), "KB\n")

# ─────────────────────────────────────────────────────────────────────────────
html <- paste0(r"[<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MIP-EPE Dashboard — Brasil 2018</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.min.js"></script>
<style>
:root{
  --c-bg:#0f1117;--c-card:#1a1d27;--c-border:#2a2d3e;--c-text:#e2e8f0;
  --c-muted:#8892a4;--c-accent:#378ADD;--c-fossil:#E24B4A;--c-renov:#1D9E75;
}
*{box-sizing:border-box}
body{background:var(--c-bg);color:var(--c-text);font-family:"Inter","Segoe UI",sans-serif;font-size:13px;margin:0}
/* ── TOP BAR ── */
.top-bar{background:#13151f;border-bottom:1px solid var(--c-border);padding:10px 24px;
  display:flex;align-items:center;gap:16px;position:sticky;top:0;z-index:100}
.top-bar h1{font-size:15px;font-weight:600;color:#fff;margin:0}
.top-bar span{font-size:11px;color:var(--c-muted)}
/* ── TAB NAV ── */
nav.tabs{background:#13151f;border-bottom:1px solid var(--c-border);
  padding:0 24px;display:flex;gap:2px;overflow-x:auto;position:sticky;top:44px;z-index:99}
nav.tabs button{background:none;border:none;color:var(--c-muted);padding:9px 14px;
  font-size:12px;cursor:pointer;border-bottom:2px solid transparent;white-space:nowrap;transition:.15s}
nav.tabs button.active{color:#fff;border-bottom-color:var(--c-accent)}
nav.tabs button:hover:not(.active){color:var(--c-text)}
/* ── GROUP FILTER BAR (sticky, acts as colour legend) ── */
.filter-bar{background:#13151f;border-bottom:1px solid var(--c-border);
  padding:6px 24px;display:flex;align-items:center;gap:8px;flex-wrap:wrap;
  position:sticky;top:84px;z-index:98}
.filter-label{font-size:9px;font-weight:700;color:var(--c-muted);
  text-transform:uppercase;letter-spacing:.1em;white-space:nowrap}
.chips-row{display:flex;flex-wrap:wrap;gap:4px;flex:1}
.chip{border:1px solid currentColor;padding:2px 10px;border-radius:12px;font-size:11px;
  cursor:pointer;transition:opacity .18s,background .18s;background:transparent;white-space:nowrap}
.chip.active{opacity:1}
.chip:not(.active){opacity:.22;border-style:dashed}
.chip:hover{opacity:.8!important}
.btn-rst{background:none;border:1px dashed var(--c-border);color:var(--c-muted);
  padding:2px 9px;border-radius:12px;font-size:11px;cursor:pointer;white-space:nowrap}
.btn-rst:hover{border-color:var(--c-text);color:var(--c-text)}
/* ── EXERCISE FILTER (Tab 5) ── */
.ex-bar{display:flex;align-items:center;gap:6px;flex-wrap:wrap;
  background:#13151f;border:1px solid var(--c-border);border-radius:7px;
  padding:7px 12px;margin-bottom:12px}
.ex-toggle{border:1px solid currentColor;padding:3px 12px;border-radius:10px;
  font-size:11px;cursor:pointer;transition:opacity .18s,background .18s;
  background:transparent;white-space:nowrap}
.ex-toggle.active{opacity:1}
.ex-toggle:not(.active){opacity:.22;border-style:dashed}
.ex-toggle:hover{opacity:.8!important}
/* ── LAYOUT ── */
.tab-panel{display:none;padding:18px 24px}
.tab-panel.active{display:block}
.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px}
.grid-3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;margin-bottom:14px}
.grid-4{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:14px}
.full{grid-column:1/-1}
.card{background:var(--c-card);border:1px solid var(--c-border);border-radius:8px;padding:14px}
.card-title{font-size:11px;font-weight:600;color:var(--c-muted);text-transform:uppercase;
  letter-spacing:.06em;margin-bottom:10px}
.kpi{text-align:center;padding:16px 10px}
.kpi .val{font-size:24px;font-weight:700;color:#fff;line-height:1}
.kpi .lbl{font-size:11px;color:var(--c-muted);margin-top:4px}
.kpi .sub{font-size:10px;color:var(--c-muted);margin-top:2px}
.chart-wrap{position:relative;height:268px}
.chart-wrap.tall{height:370px}
.chart-wrap.xtall{height:490px}
/* ── TABLES ── */
table.dt{width:100%;border-collapse:collapse;font-size:11.5px}
table.dt th{background:#1f2233;color:var(--c-muted);font-weight:500;padding:6px 10px;
  text-align:left;border-bottom:1px solid var(--c-border);cursor:pointer;white-space:nowrap}
table.dt th:hover{color:#fff}
table.dt td{padding:5px 10px;border-bottom:1px solid #1a1d2a;color:var(--c-text)}
table.dt tr:hover td{background:#1f2233}
.badge-g{display:inline-block;padding:2px 7px;border-radius:3px;font-size:10px;font-weight:500}
.search-box{background:#1f2233;border:1px solid var(--c-border);color:var(--c-text);
  border-radius:5px;padding:5px 10px;font-size:12px;width:200px;outline:none}
.search-box:focus{border-color:var(--c-accent)}
.sel-ex{background:#1f2233;border:1px solid var(--c-border);color:var(--c-text);
  border-radius:5px;padding:5px 10px;font-size:12px;outline:none;cursor:pointer}
.tag-fossil{color:var(--c-fossil);font-weight:600}
.tag-renov{color:var(--c-renov);font-weight:600}
@media(max-width:900px){.grid-2,.grid-3,.grid-4{grid-template-columns:1fr}.full{grid-column:1}}
</style>
</head>
<body>

<div class="top-bar">
  <h1>MIP-EPE Energia &mdash; Brasil 2018</h1>
  <span>NT EPE/DEA/SEE/013/2023 &nbsp;&bull;&nbsp; 73 setores &nbsp;&bull;&nbsp; Modelo de insumo-produto</span>
</div>

<nav class="tabs" id="mainTabs">
  <button class="active" onclick="showTab(0)">&#127760; Vis&atilde;o Geral</button>
  <button onclick="showTab(1)">&#127970; Estrutura Econ&ocirc;mica</button>
  <button onclick="showTab(2)">&#128200; Multiplicadores</button>
  <button onclick="showTab(3)">&#128279; &Iacute;ndices de Liga&ccedil;&atilde;o</button>
  <button onclick="showTab(4)">&#9889; Matriz Energ&eacute;tica</button>
  <button onclick="showTab(5)">&#128293; Choques de Demanda</button>
  <button onclick="showTab(6)">&#128300; Extra&ccedil;&atilde;o &amp; &Iacute;nd. Puros</button>
</nav>

<!-- ═══ GROUP FILTER BAR — visible on all tabs, doubles as colour legend ════ -->
<div class="filter-bar" id="filterBar">
  <span class="filter-label">Grupos:</span>
  <div class="chips-row" id="groupChips"></div>
  <button class="btn-rst" onclick="resetGroups()" title="Activar todos">&#10005;&nbsp;Todos</button>
</div>

<!-- ═══════════════════════ TAB 0: VISÃO GERAL ══════════════════════════════ -->
<div class="tab-panel active" id="tab0">
  <div class="grid-4">
    <div class="card kpi"><div class="val" id="kpi-vbp">—</div><div class="lbl">VBP Total</div><div class="sub">R$ trilh&otilde;es, 2018</div></div>
    <div class="card kpi"><div class="val" id="kpi-va">—</div><div class="lbl">VA / PIB</div><div class="sub">R$ trilh&otilde;es, 2018</div></div>
    <div class="card kpi"><div class="val" id="kpi-emp">—</div><div class="lbl">Pessoal Ocupado</div><div class="sub">grupos seleccionados</div></div>
    <div class="card kpi"><div class="val" id="kpi-nsect">—</div><div class="lbl">Setores Activos</div><div class="sub">de 73 totais</div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">VBP por Grupo (R$ bilh&otilde;es)</div><div class="chart-wrap"><canvas id="ch-vbp-group"></canvas></div></div>
    <div class="card"><div class="card-title">Comparativo de Choques — &Delta;VA (R$ bilh&otilde;es)</div><div class="chart-wrap"><canvas id="ch-shock-va"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 12 Multiplicadores de Produ&ccedil;&atilde;o (MP) — grupos activos</div><div class="chart-wrap"><canvas id="ch-mp-top"></canvas></div></div>
    <div class="card">
      <div class="card-title">Resumo dos Exerc&iacute;cios de Choque</div>
      <table class="dt" id="tbl-shock-summary"><thead><tr>
        <th>Exerc&iacute;cio</th><th>&Delta;Produ&ccedil;&atilde;o (bi)</th><th>&Delta;VA (bi)</th><th>&Delta;Emprego (mil)</th><th>&Delta;Energia (ktep)</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 1: ESTRUTURA ECONÓMICA ══════════════════════ -->
<div class="tab-panel" id="tab1">
  <div class="grid-2">
    <div class="card"><div class="card-title">Decomposi&ccedil;&atilde;o do Valor Adicionado por Grupo (R$ bi)</div><div class="chart-wrap"><canvas id="ch-va-decomp"></canvas></div></div>
    <div class="card"><div class="card-title">Pessoal Ocupado por Grupo (milhares)</div><div class="chart-wrap"><canvas id="ch-emp-group"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Demanda Final por Componente e Grupo (R$ bi)</div><div class="chart-wrap"><canvas id="ch-df-group"></canvas></div></div>
    <div class="card"><div class="card-title">Top 15 Setores por VBP (grupos activos)</div><div class="chart-wrap"><canvas id="ch-vbp-top"></canvas></div></div>
  </div>
  <div class="card" style="margin-bottom:14px">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Todos os Setores — Indicadores de Base</div>
      <input class="search-box" id="search-baseline" placeholder="Buscar setor..." oninput="filterTable('tbl-baseline',this.value)">
    </div>
    <div style="overflow-x:auto;max-height:360px;overflow-y:auto">
      <table class="dt" id="tbl-baseline"><thead><tr>
        <th onclick="sortTable('tbl-baseline',0)">C&oacute;d</th>
        <th onclick="sortTable('tbl-baseline',1)">Setor</th>
        <th onclick="sortTable('tbl-baseline',2)">Grupo</th>
        <th onclick="sortTable('tbl-baseline',3)">VBP (R$M)</th>
        <th onclick="sortTable('tbl-baseline',4)">VA/PIB (R$M)</th>
        <th onclick="sortTable('tbl-baseline',5)">Remuner. (R$M)</th>
        <th onclick="sortTable('tbl-baseline',6)">Sal&aacute;rios (R$M)</th>
        <th onclick="sortTable('tbl-baseline',7)">EOB (R$M)</th>
        <th onclick="sortTable('tbl-baseline',8)">Ocupa&ccedil;&otilde;es</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 2: MULTIPLICADORES ══════════════════════════ -->
<div class="tab-panel" id="tab2">
  <div class="grid-2">
    <div class="card full"><div class="card-title">Multiplicadores de Produ&ccedil;&atilde;o — Setores Activos (MP, ordenado)</div><div class="chart-wrap xtall"><canvas id="ch-mp-all"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">MP vs MPT vs MPTT — Setores Energ&eacute;ticos</div><div class="chart-wrap tall"><canvas id="ch-mp-energy"></canvas></div></div>
    <div class="card"><div class="card-title">Multiplicadores de Emprego — Energ&eacute;ticos (ME, MEI, MET, MEII)</div><div class="chart-wrap tall"><canvas id="ch-me-energy"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Efeito Direto vs Indireto vs Induzido (Top 15 por MP — activos)</div><div class="chart-wrap"><canvas id="ch-mp-decomp"></canvas></div></div>
    <div class="card"><div class="card-title">Multiplicadores de Renda — Energ&eacute;ticos (MR, MRI, MRT, MRII)</div><div class="chart-wrap"><canvas id="ch-mr-energy"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Tabela Completa de Multiplicadores (grupos activos)</div>
      <input class="search-box" id="search-mult" placeholder="Buscar setor..." oninput="filterTable('tbl-mult',this.value)">
    </div>
    <div style="overflow-x:auto;max-height:340px;overflow-y:auto">
      <table class="dt" id="tbl-mult"><thead><tr>
        <th onclick="sortTable('tbl-mult',0)">C&oacute;d</th>
        <th onclick="sortTable('tbl-mult',1)">Setor</th>
        <th onclick="sortTable('tbl-mult',2)">MP</th>
        <th onclick="sortTable('tbl-mult',3)">MPT</th>
        <th onclick="sortTable('tbl-mult',4)">MPTT</th>
        <th onclick="sortTable('tbl-mult',5)">Direto</th>
        <th onclick="sortTable('tbl-mult',6)">Indireto</th>
        <th onclick="sortTable('tbl-mult',7)">Induzido</th>
        <th onclick="sortTable('tbl-mult',8)">ME</th>
        <th onclick="sortTable('tbl-mult',9)">MEI</th>
        <th onclick="sortTable('tbl-mult',10)">MR</th>
        <th onclick="sortTable('tbl-mult',11)">MRI</th>
        <th onclick="sortTable('tbl-mult',12)">Grupo</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 3: ÍNDICES DE LIGAÇÃO ═══════════════════════ -->
<div class="tab-panel" id="tab3">
  <div class="grid-2">
    <div class="card full"><div class="card-title">Diagrama de Rasmussen-Hirschman (BL &times; FLG) — grupos activos em destaque</div><div class="chart-wrap tall"><canvas id="ch-rasmussen"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 20 Liga&ccedil;&atilde;o para Tr&aacute;s (BL) — grupos activos</div><div class="chart-wrap"><canvas id="ch-bl-top"></canvas></div></div>
    <div class="card"><div class="card-title">Top 20 Liga&ccedil;&atilde;o para Frente via Ghosh (FLG) — grupos activos</div><div class="chart-wrap"><canvas id="ch-flg-top"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Distribui&ccedil;&atilde;o por Quadrante (setores activos)</div><div class="chart-wrap" style="height:240px"><canvas id="ch-quadrant-pie"></canvas></div></div>
    <div class="card"><div class="card-title">Coeficientes de Varia&ccedil;&atilde;o (Vj &times; Vi) — grupos activos</div><div class="chart-wrap"><canvas id="ch-cv-scatter"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════════════ TAB 4: ENERGIA ══════════════════════════════════ -->
<div class="tab-panel" id="tab4">
  <div class="grid-2">
    <div class="card"><div class="card-title">Uso de Energia por Fonte e Grupo NT4 (ktep) — activos</div><div class="chart-wrap"><canvas id="ch-e-group"></canvas></div></div>
    <div class="card"><div class="card-title">Distribui&ccedil;&atilde;o das Fontes Energ&eacute;ticas — grupos activos (ktep)</div><div class="chart-wrap" style="height:260px"><canvas id="ch-e-pie"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 15 Setores por Consumo Total (ktep) — activos</div><div class="chart-wrap"><canvas id="ch-e-top-sectors"></canvas></div></div>
    <div class="card"><div class="card-title">Intensidade Energ&eacute;tica — Setores Energ&eacute;ticos (ktep / R$M)</div><div class="chart-wrap"><canvas id="ch-alpha-energy"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════════════ TAB 5: CHOQUES DE DEMANDA ═══════════════════════ -->
<div class="tab-panel" id="tab5">
  <!-- EXERCISE FILTER -->
  <div class="ex-bar">
    <span class="filter-label">Exerc&iacute;cios:</span>
    <div id="exToggles" style="display:flex;gap:5px;flex-wrap:wrap"></div>
    <button class="btn-rst" onclick="resetExercises()" style="margin-left:4px">&#10005;&nbsp;Todos</button>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">&Delta;Valor Adicionado por Grupo — exerc&iacute;cios seleccionados (R$ bi)</div><div class="chart-wrap tall"><canvas id="ch-shock-va-groups"></canvas></div></div>
    <div class="card"><div class="card-title">&Delta;Emprego por Grupo — exerc&iacute;cios seleccionados (mil pessoas)</div><div class="chart-wrap tall"><canvas id="ch-shock-emp-groups"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">&Delta;Energia por Fonte (ktep) — exerc&iacute;cios seleccionados</div><div class="chart-wrap"><canvas id="ch-shock-energy"></canvas></div></div>
    <div class="card"><div class="card-title">&Delta;Emprego por Categoria de M&atilde;o-de-Obra</div><div class="chart-wrap"><canvas id="ch-shock-labor"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 15 Setores por &Delta;VA (grupos activos) — exerc&iacute;cio seleccionado</div><div class="chart-wrap"><canvas id="ch-shock-ex1-sectors"></canvas></div></div>
    <div class="card"><div class="card-title">Ex3 vs Ex4 — Setores Energ&eacute;ticos: &Delta;Produ&ccedil;&atilde;o (R$M)</div><div class="chart-wrap"><canvas id="ch-shock-ex34-energy"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Detalhamento Setorial (grupos activos)</div>
      <div style="display:flex;gap:8px">
        <select class="sel-ex" id="sel-exercise" onchange="renderShockTable()">
          <option value="Choque_Ex1_NT">Ex1: +5% Exporta&ccedil;&otilde;es</option>
          <option value="Choque_Ex2_NT">Ex2: +5% Fam&iacute;lias S40</option>
          <option value="Choque_Ex3_Fossil">Ex3: Cont. F&oacute;ssil</option>
          <option value="Choque_Ex4_Renov">Ex4: Exp. Renov&aacute;vel</option>
          <option value="Choque_Ex5_Trans">Ex5: Transi&ccedil;&atilde;o</option>
        </select>
        <input class="search-box" id="search-shock" placeholder="Buscar setor..." oninput="filterTable('tbl-shock',this.value)">
      </div>
    </div>
    <div style="overflow-x:auto;max-height:340px;overflow-y:auto">
      <table class="dt" id="tbl-shock"><thead><tr>
        <th onclick="sortTable('tbl-shock',0)">C&oacute;d</th>
        <th onclick="sortTable('tbl-shock',1)">Setor</th>
        <th onclick="sortTable('tbl-shock',2)">Grupo</th>
        <th onclick="sortTable('tbl-shock',3)">Energia?</th>
        <th onclick="sortTable('tbl-shock',4)">&Delta;Produ&ccedil;&atilde;o (R$M)</th>
        <th onclick="sortTable('tbl-shock',5)">&Delta;VA (R$M)</th>
        <th onclick="sortTable('tbl-shock',6)">&Delta;Emprego</th>
        <th onclick="sortTable('tbl-shock',7)">Var% Prod</th>
        <th onclick="sortTable('tbl-shock',8)">Var% VA</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 6: EXTRAÇÃO & ÍND. PUROS ════════════════════ -->
<div class="tab-panel" id="tab6">
  <div class="grid-2">
    <div class="card"><div class="card-title">Extra&ccedil;&atilde;o Hipot&eacute;tica — Top 20 por BL (demanda): perda de produ&ccedil;&atilde;o</div><div class="chart-wrap"><canvas id="ch-extrac-bl"></canvas></div></div>
    <div class="card"><div class="card-title">Extra&ccedil;&atilde;o Hipot&eacute;tica — Top 20 por FL (oferta): perda de produ&ccedil;&atilde;o</div><div class="chart-wrap"><canvas id="ch-extrac-fl"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card full"><div class="card-title">Diagrama de &Iacute;ndices Puros Normalizados (PBLN &times; PFLN) — grupos activos</div><div class="chart-wrap tall"><canvas id="ch-ipln"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">&Iacute;ndices Puros de Liga&ccedil;&atilde;o Normalizados (grupos activos)</div>
      <input class="search-box" id="search-ipln" placeholder="Buscar..." oninput="filterTable('tbl-ipln',this.value)">
    </div>
    <div style="overflow-x:auto;max-height:320px;overflow-y:auto">
      <table class="dt" id="tbl-ipln"><thead><tr>
        <th onclick="sortTable('tbl-ipln',0)">C&oacute;d</th>
        <th onclick="sortTable('tbl-ipln',1)">Setor</th>
        <th onclick="sortTable('tbl-ipln',2)">PBL</th>
        <th onclick="sortTable('tbl-ipln',3)">PFL</th>
        <th onclick="sortTable('tbl-ipln',4)">PTL</th>
        <th onclick="sortTable('tbl-ipln',5)">PBLN</th>
        <th onclick="sortTable('tbl-ipln',6)">PFLN</th>
        <th onclick="sortTable('tbl-ipln',7)">PTLN</th>
        <th onclick="sortTable('tbl-ipln',8)">Grupo</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<script>
// ═══════════════════════════════════════════════════════════════════════════
// DATA (embedded from mip_epe_replication_results.xlsx)
// ═══════════════════════════════════════════════════════════════════════════
const D = ]", js_data, r"[;

// ═══════════════════════════════════════════════════════════════════════════
// COLOURS
// ═══════════════════════════════════════════════════════════════════════════
const GRUPO_COLORS = {
  Agropecuaria:"#3B6D11", Ind_Extrativa:"#888780",
  Energia_Fossil:"#E24B4A", Energia_Renov:"#1D9E75",
  Ind_Transform:"#378ADD", Infraestrutura:"#534AB7", Servicos:"#B4B2A9",
  Industria:"#378ADD", Energeticos:"#1D9E75"
};
const FONTE_COLORS = {
  Derivados:"#E24B4A", Biodiesel:"#1D9E75", Etanol:"#3B6D11",
  EE_Central:"#F39C12", EE_Distrib:"#F8C471", Gas_Natural:"#8E44AD"
};
const LABOR_COLORS = {
  Informal:"#E24B4A", Formal:"#378ADD", PPI:"#888780", Branca:"#B4B2A9",
  Homem:"#534AB7", Mulher:"#1D9E75", Baixo_Med:"#BA7517", Superior:"#F39C12"
};
const ALL_EX_KEYS  = ["Choque_Ex1_NT","Choque_Ex2_NT","Choque_Ex3_Fossil","Choque_Ex4_Renov","Choque_Ex5_Trans"];
const EX_LABEL = {
  "Choque_Ex1_NT":"+5% Exportações",
  "Choque_Ex2_NT":"+5% Famílias S40",
  "Choque_Ex3_Fossil":"Fóssil -20%",
  "Choque_Ex4_Renov":"Renov +30%",
  "Choque_Ex5_Trans":"Transição"
};
const EX_COLOR = {
  "Choque_Ex1_NT":"#378ADD","Choque_Ex2_NT":"#888780",
  "Choque_Ex3_Fossil":"#E24B4A","Choque_Ex4_Renov":"#1D9E75","Choque_Ex5_Trans":"#F39C12"
};

function gc(g){ return GRUPO_COLORS[g]||"#aaa"; }
function fmtN(v,d=2){ return v==null?"—":Number(v).toFixed(d); }
function alpha(hex,a){
  const r=parseInt(hex.slice(1,3),16),g=parseInt(hex.slice(3,5),16),b=parseInt(hex.slice(5,7),16);
  return `rgba(${r},${g},${b},${a})`;
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE & FILTER
// ═══════════════════════════════════════════════════════════════════════════
const ALL_GROUPS = [...new Set(D.Setores.map(r=>r.grupo).filter(Boolean))];

const STATE = {
  groups:    new Set(ALL_GROUPS),
  exercises: new Set(ALL_EX_KEYS),
  tab: 0,
  filterVer: 0,          // bumped on every filter change
  builtVer:  {}          // tab -> filterVer when last built
};

// filter array by active groups
function fg(arr, key='grupo'){
  if (STATE.groups.size === ALL_GROUPS.length) return arr;
  return arr.filter(r => STATE.groups.has(r[key]));
}
// set of active sector codes
function activeCodes(){
  return new Set(fg(D.Setores).map(r=>r.cod));
}
// active exercise keys (preserving canonical order)
function activeEx(){
  return ALL_EX_KEYS.filter(k=>STATE.exercises.has(k));
}

// ═══════════════════════════════════════════════════════════════════════════
// CHART REGISTRY
// ═══════════════════════════════════════════════════════════════════════════
const CHARTS = {};
function destroyChart(id){
  if(CHARTS[id]){ CHARTS[id].destroy(); delete CHARTS[id]; }
}
const CD = {   // common chart defaults
  responsive:true, maintainAspectRatio:false,
  plugins:{ legend:{ labels:{ color:"#8892a4", font:{size:11} } } },
  scales:{
    x:{ ticks:{color:"#8892a4",font:{size:10}}, grid:{color:"#1f2233"} },
    y:{ ticks:{color:"#8892a4",font:{size:10}}, grid:{color:"#1f2233"} }
  }
};
function mkBar(id, labels, datasets, opts={}){
  destroyChart(id);
  const ctx = document.getElementById(id); if(!ctx) return;
  CHARTS[id] = new Chart(ctx.getContext("2d"),{
    type:"bar", data:{labels,datasets},
    options: Object.assign({},CD,opts)
  }); return CHARTS[id];
}
function mkHBar(id, labels, datasets, opts={}){
  destroyChart(id);
  const ctx = document.getElementById(id); if(!ctx) return;
  CHARTS[id] = new Chart(ctx.getContext("2d"),{
    type:"bar", data:{labels,datasets},
    options: Object.assign({},CD,{indexAxis:"y"},opts)
  }); return CHARTS[id];
}
function mkScatterCustom(id, datasets, opts={}){
  destroyChart(id);
  const ctx = document.getElementById(id); if(!ctx) return;
  CHARTS[id] = new Chart(ctx.getContext("2d"),{
    type:"scatter", data:{datasets},
    options: Object.assign({},CD,opts)
  }); return CHARTS[id];
}
function mkDoughnut(id, labels, data, colors){
  destroyChart(id);
  const ctx = document.getElementById(id); if(!ctx) return;
  CHARTS[id] = new Chart(ctx.getContext("2d"),{
    type:"doughnut",
    data:{labels,datasets:[{data,backgroundColor:colors,borderWidth:1,borderColor:"#0f1117"}]},
    options:{responsive:true,maintainAspectRatio:false,
      plugins:{legend:{position:"right",labels:{color:"#8892a4",font:{size:11}}}}}
  }); return CHARTS[id];
}
function clearTbody(id){ const t=document.querySelector("#"+id+" tbody"); if(t) t.innerHTML=""; }

// ═══════════════════════════════════════════════════════════════════════════
// GROUP CHIP FILTER
// ═══════════════════════════════════════════════════════════════════════════
function buildGroupChips(){
  const container = document.getElementById("groupChips");
  container.innerHTML = "";
  ALL_GROUPS.forEach(g => {
    const c  = gc(g);
    const on = STATE.groups.has(g);
    const btn = document.createElement("button");
    btn.id = "chip-" + g;
    btn.className = "chip" + (on ? " active" : "");
    btn.style.color = c;
    btn.style.borderColor = c;
    if(on) btn.style.background = alpha(c, 0.15);
    btn.innerHTML = "&#9679; " + g.replace(/_/g," ");
    btn.onclick = () => toggleGroup(g);
    container.appendChild(btn);
  });
}
function updateChip(g){
  const c   = gc(g);
  const on  = STATE.groups.has(g);
  const btn = document.getElementById("chip-"+g);
  if(!btn) return;
  btn.className = "chip" + (on ? " active" : "");
  btn.style.color = c;
  btn.style.borderColor = c;
  btn.style.background = on ? alpha(c, 0.15) : "transparent";
}
function toggleGroup(g){
  if(STATE.groups.has(g)){
    if(STATE.groups.size <= 1) return;   // keep ≥ 1 active
    STATE.groups.delete(g);
  } else {
    STATE.groups.add(g);
  }
  updateChip(g);
  onFilterChange();
}
function resetGroups(){
  ALL_GROUPS.forEach(g => STATE.groups.add(g));
  buildGroupChips();
  onFilterChange();
}

// ═══════════════════════════════════════════════════════════════════════════
// EXERCISE TOGGLE FILTER
// ═══════════════════════════════════════════════════════════════════════════
function buildExToggles(){
  const container = document.getElementById("exToggles");
  if(!container) return;
  container.innerHTML = "";
  ALL_EX_KEYS.forEach(k => {
    const c  = EX_COLOR[k];
    const on = STATE.exercises.has(k);
    const btn = document.createElement("button");
    btn.id = "extog-" + k;
    btn.className = "ex-toggle" + (on ? " active" : "");
    btn.style.color = c;
    btn.style.borderColor = c;
    if(on) btn.style.background = alpha(c, 0.15);
    btn.textContent = EX_LABEL[k];
    btn.onclick = () => toggleExercise(k);
    container.appendChild(btn);
  });
}
function updateExToggle(k){
  const c   = EX_COLOR[k];
  const on  = STATE.exercises.has(k);
  const btn = document.getElementById("extog-"+k);
  if(!btn) return;
  btn.className = "ex-toggle" + (on ? " active" : "");
  btn.style.color = c;
  btn.style.borderColor = c;
  btn.style.background = on ? alpha(c, 0.15) : "transparent";
}
function toggleExercise(k){
  if(STATE.exercises.has(k)){
    if(STATE.exercises.size <= 1) return;
    STATE.exercises.delete(k);
  } else {
    STATE.exercises.add(k);
  }
  updateExToggle(k);
  // Rebuild only shock charts (fast — no group filter loop needed)
  rebuildShockCharts();
}
function resetExercises(){
  ALL_EX_KEYS.forEach(k => STATE.exercises.add(k));
  buildExToggles();
  rebuildShockCharts();
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB NAVIGATION & LAZY REBUILD
// ═══════════════════════════════════════════════════════════════════════════
const INIT_FNS = [initOverview,initBaseline,initMultipliers,initLinkages,initEnergy,initShocks,initExtraction];

function showTab(n){
  document.querySelectorAll(".tab-panel").forEach((p,i)=>p.classList.toggle("active",i===n));
  document.querySelectorAll("#mainTabs button").forEach((b,i)=>b.classList.toggle("active",i===n));
  STATE.tab = n;
  if((STATE.builtVer[n]||0) !== STATE.filterVer){
    clearTabTables(n);
    INIT_FNS[n]();
    STATE.builtVer[n] = STATE.filterVer;
  }
}
function clearTabTables(n){
  document.querySelectorAll(`#tab${n} table.dt tbody`).forEach(tb=>tb.innerHTML="");
}
function onFilterChange(){
  STATE.filterVer++;
  clearTabTables(STATE.tab);
  INIT_FNS[STATE.tab]();
  STATE.builtVer[STATE.tab] = STATE.filterVer;
  // mark all other tabs as stale (no version bump needed — showTab checks)
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLE UTILITIES
// ═══════════════════════════════════════════════════════════════════════════
function filterTable(id, q){
  const rows = document.querySelectorAll("#"+id+" tbody tr");
  const lq = q.toLowerCase();
  rows.forEach(r => r.style.display = r.textContent.toLowerCase().includes(lq) ? "" : "none");
}
let sortDir = {};
function sortTable(id, col){
  const tb   = document.getElementById(id);
  const rows = Array.from(tb.querySelectorAll("tbody tr"));
  const asc  = (sortDir[id+col] = !sortDir[id+col]);
  rows.sort((a,b)=>{
    const va=a.cells[col].textContent.trim(), vb=b.cells[col].textContent.trim();
    const na=parseFloat(va), nb=parseFloat(vb);
    if(!isNaN(na)&&!isNaN(nb)) return asc?na-nb:nb-na;
    return asc?va.localeCompare(vb):vb.localeCompare(va);
  });
  rows.forEach(r=>tb.querySelector("tbody").appendChild(r));
}
function grupoColorBadge(g){
  const c = gc(g);
  return `<span class="badge-g" style="background:${alpha(c,0.22)};color:${c}">${g||"—"}</span>`;
}

// ═══════════════════════════════════════════════════════════════════════════
// OVERVIEW (Tab 0)
// ═══════════════════════════════════════════════════════════════════════════
function initOverview(){
  const bl   = fg(D.Baseline);
  const ac   = activeCodes();
  const totVBP = bl.reduce((s,r)=>s+(r.vbp||0),0);
  const totVA  = bl.reduce((s,r)=>s+(r.va_pib||0),0);
  const totEmp = bl.reduce((s,r)=>s+(r.ocupacoes||0),0);
  document.getElementById("kpi-vbp").textContent  = (totVBP/1e6).toFixed(2)+" T";
  document.getElementById("kpi-va").textContent   = (totVA /1e6).toFixed(2)+" T";
  document.getElementById("kpi-emp").textContent  = (totEmp/1e6).toFixed(1)+" M";
  document.getElementById("kpi-nsect").textContent = ac.size + " / 73";

  // VBP by group (active groups only)
  const gLabels = [...STATE.groups];
  mkBar("ch-vbp-group", gLabels,
    [{label:"VBP (R$ bi)", data:gLabels.map(g=>bl.filter(r=>r.grupo===g).reduce((s,r)=>s+(r.vbp||0),0)/1e3),
      backgroundColor:gLabels.map(gc), borderRadius:4}],
    {plugins:{...CD.plugins, legend:{display:false}}}
  );

  // Shock VA comparison — all 5 exercises (overview doesn't filter by exercise)
  const sr = D.Choques_Resumo;
  mkBar("ch-shock-va", sr.map(r=>r.exercicio.slice(0,28)),
    [{label:"ΔVA (R$ bi)", data:sr.map(r=>r.dVA_bi),
      backgroundColor:sr.map(r=>r.dVA_bi>=0?"#1D9E75":"#E24B4A"), borderRadius:4}],
    {plugins:{...CD.plugins, legend:{display:false}}}
  );

  // Top 12 MP — active sectors
  const mp = D.Mult_Producao.filter(r=>ac.has(r.cod)).sort((a,b)=>b.MP-a.MP).slice(0,12);
  mkHBar("ch-mp-top", mp.map(r=>r.cod+" "+r.nome.slice(0,22)),
    [{label:"MP", data:mp.map(r=>r.MP), backgroundColor:mp.map(r=>gc(r.grupo)), borderRadius:3}],
    {plugins:{...CD.plugins, legend:{display:false}}, scales:{x:{...CD.scales.x,min:1},y:CD.scales.y}}
  );

  // Shock summary table (always all 5)
  clearTbody("tbl-shock-summary");
  const tb = document.querySelector("#tbl-shock-summary tbody");
  sr.forEach(r=>{
    const tr = document.createElement("tr");
    tr.innerHTML = `<td>${r.exercicio}</td><td>${(r.dx_bi||0).toFixed(1)}</td><td>${(r.dVA_bi||0).toFixed(1)}</td><td>${(r.demp_mil||0).toFixed(1)}</td><td>${(r.dE_ktep||0).toFixed(0)}</td>`;
    tb.appendChild(tr);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// BASELINE (Tab 1)
// ═══════════════════════════════════════════════════════════════════════════
function initBaseline(){
  const bl = fg(D.Baseline);
  const df = fg(D.Demanda_Final);
  const gLabels = [...STATE.groups];

  // VA decomp
  mkBar("ch-va-decomp", gLabels, [
    {label:"VA/PIB",   data:gLabels.map(g=>bl.filter(r=>r.grupo===g).reduce((s,r)=>s+(r.va_pib||0),0)/1e3),  backgroundColor:"#378ADD", borderRadius:3},
    {label:"Salários", data:gLabels.map(g=>bl.filter(r=>r.grupo===g).reduce((s,r)=>s+(r.salarios||0),0)/1e3), backgroundColor:"#1D9E75", borderRadius:3},
    {label:"EOB",      data:gLabels.map(g=>bl.filter(r=>r.grupo===g).reduce((s,r)=>s+(r.eob||0),0)/1e3),     backgroundColor:"#F39C12", borderRadius:3}
  ]);

  // Employment by group
  mkBar("ch-emp-group", gLabels,
    [{label:"Ocupações (mil)", data:gLabels.map(g=>bl.filter(r=>r.grupo===g).reduce((s,r)=>s+(r.ocupacoes||0),0)/1e3),
      backgroundColor:gLabels.map(gc), borderRadius:4}],
    {plugins:{...CD.plugins, legend:{display:false}}}
  );

  // Final demand stacked
  const dfComps  = ["Export","Gov","ISFLSF","Families","GFCF","DeltaStock"];
  const dfColors = ["#378ADD","#534AB7","#888780","#1D9E75","#F39C12","#E24B4A"];
  mkBar("ch-df-group", gLabels,
    dfComps.map((c,i) => ({
      label:c, backgroundColor:dfColors[i], borderRadius:2, stack:"s",
      data:gLabels.map(g=>df.filter(r=>r.grupo===g).reduce((s,r)=>s+(r[c]||0),0)/1e3)
    })),
    {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}}
  );

  // Top 15 VBP — active sectors
  const top15 = [...bl].sort((a,b)=>b.vbp-a.vbp).slice(0,15);
  mkHBar("ch-vbp-top", top15.map(r=>r.cod),
    [{label:"VBP (R$ bi)", data:top15.map(r=>r.vbp/1e3), backgroundColor:top15.map(r=>gc(r.grupo)), borderRadius:3}],
    {plugins:{...CD.plugins, legend:{display:false}}}
  );

  // Table (active sectors)
  const tb = document.querySelector("#tbl-baseline tbody");
  bl.forEach(r=>{
    const tr = document.createElement("tr");
    tr.innerHTML = `<td>${r.cod}</td><td>${r.nome.slice(0,38)}</td>
      <td>${grupoColorBadge(r.grupo)}</td>
      <td>${(r.vbp||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
      <td>${(r.va_pib||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
      <td>${(r.remuner||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
      <td>${(r.salarios||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
      <td>${(r.eob||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
      <td>${(r.ocupacoes||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>`;
    tb.appendChild(tr);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// MULTIPLIERS (Tab 2)
// ═══════════════════════════════════════════════════════════════════════════
function initMultipliers(){
  const ac   = activeCodes();
  const mp   = D.Mult_Producao.filter(r=>ac.has(r.cod)).sort((a,b)=>b.MP-a.MP);
  const me   = D.Mult_Emprego;
  const mr   = D.Mult_Renda;
  const setE = D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);

  // All active sorted by MP
  mkHBar("ch-mp-all", mp.map(r=>r.cod),
    [{label:"MP", data:mp.map(r=>r.MP),
      backgroundColor:mp.map(r=> setE.includes(r.cod)?"#F39C12":gc(r.grupo)), borderRadius:2}],
    {plugins:{...CD.plugins, legend:{display:false}},
     scales:{x:{...CD.scales.x,min:1},y:{...CD.scales.y,ticks:{font:{size:9}}}}}
  );

  // Energy sectors (always shown regardless of group filter — they are a specific subset)
  const mpE = D.Mult_Producao.filter(r=>setE.includes(r.cod));
  mkBar("ch-mp-energy", mpE.map(r=>r.cod), [
    {label:"MP",   data:mpE.map(r=>r.MP),   backgroundColor:"#378ADD", borderRadius:3},
    {label:"MPT",  data:mpE.map(r=>r.MPT),  backgroundColor:"#1D9E75", borderRadius:3},
    {label:"MPTT", data:mpE.map(r=>r.MPTT), backgroundColor:"#F39C12", borderRadius:3}
  ]);

  const meE = me.filter(r=>setE.includes(r.cod));
  mkBar("ch-me-energy", meE.map(r=>r.cod), [
    {label:"ME",   data:meE.map(r=>r.ME),   backgroundColor:"#378ADD", borderRadius:3},
    {label:"MEI",  data:meE.map(r=>r.MEI),  backgroundColor:"#1D9E75", borderRadius:3},
    {label:"MET",  data:meE.map(r=>r.MET),  backgroundColor:"#F39C12", borderRadius:3},
    {label:"MEII", data:meE.map(r=>r.MEII), backgroundColor:"#E24B4A", borderRadius:3}
  ]);

  // Decomp: top 15 active sectors
  const top15 = mp.slice(0,15);
  mkBar("ch-mp-decomp", top15.map(r=>r.cod), [
    {label:"Direto",   data:top15.map(r=>r.direct),   backgroundColor:"#378ADD", borderRadius:2, stack:"s"},
    {label:"Indireto", data:top15.map(r=>r.indirect), backgroundColor:"#534AB7", borderRadius:2, stack:"s"},
    {label:"Induzido", data:top15.map(r=>r.induced),  backgroundColor:"#1D9E75", borderRadius:2, stack:"s"}
  ], {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}});

  const mrE = mr.filter(r=>setE.includes(r.cod));
  mkBar("ch-mr-energy", mrE.map(r=>r.cod), [
    {label:"MR",   data:mrE.map(r=>r.MR),   backgroundColor:"#378ADD", borderRadius:3},
    {label:"MRI",  data:mrE.map(r=>r.MRI),  backgroundColor:"#1D9E75", borderRadius:3},
    {label:"MRT",  data:mrE.map(r=>r.MRT),  backgroundColor:"#F39C12", borderRadius:3},
    {label:"MRII", data:mrE.map(r=>r.MRII), backgroundColor:"#E24B4A", borderRadius:3}
  ]);

  // Multiplier table — active sectors
  const meByCode = Object.fromEntries(me.map(r=>[r.cod,r]));
  const mrByCode = Object.fromEntries(mr.map(r=>[r.cod,r]));
  const tb = document.querySelector("#tbl-mult tbody");
  mp.forEach(r=>{
    const m=meByCode[r.cod]||{}, n=mrByCode[r.cod]||{};
    const tr = document.createElement("tr");
    tr.innerHTML = `<td>${r.cod}</td><td>${r.nome.slice(0,32)}</td>
      <td>${fmtN(r.MP)}</td><td>${fmtN(r.MPT)}</td><td>${fmtN(r.MPTT)}</td>
      <td>${fmtN(r.direct)}</td><td>${fmtN(r.indirect)}</td><td>${fmtN(r.induced)}</td>
      <td>${fmtN(m.ME)}</td><td>${fmtN(m.MEI)}</td>
      <td>${fmtN(n.MR)}</td><td>${fmtN(n.MRI)}</td>
      <td>${grupoColorBadge(r.grupo)}</td>`;
    tb.appendChild(tr);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// LINKAGES (Tab 3)
// ═══════════════════════════════════════════════════════════════════════════
function initLinkages(){
  const ac   = activeCodes();
  const lig  = D.Ind_Ligacao.filter(r=>ac.has(r.cod));
  const QCOLORS = {
    "Setor-Chave":"#F39C12",
    "Demanda acima da media":"#1D9E75",
    "Oferta acima da media":"#378ADD",
    "Independente":"#888780"
  };

  // Rasmussen scatter — active groups only, coloured by quadrant, energy highlighted
  const datasets = Object.entries(QCOLORS).map(([q,c])=>{
    const pts = lig.filter(r=>r.quadrante===q);
    return {
      label: q,
      data:  pts.map(r=>({x:r.FLG,y:r.BL,cod:r.cod,nome:r.nome,isE:r.eh_energia})),
      backgroundColor: pts.map(r=> r.eh_energia ? alpha(c,0.95) : alpha(c,0.45)),
      pointRadius:  pts.map(r=> r.eh_energia ? 8 : 4),
      pointStyle:   pts.map(r=> r.eh_energia ? "triangle" : "circle")
    };
  });
  mkScatterCustom("ch-rasmussen", datasets, {
    plugins:{
      legend:{labels:{color:"#8892a4",font:{size:11}}},
      tooltip:{callbacks:{label:ctx=>{const d=ctx.raw; return `${d.cod}: BL=${d.y.toFixed(3)} FLG=${d.x.toFixed(3)}${d.isE?" ⚡":""}`;  }}}
    },
    scales:{
      x:{...CD.scales.x, title:{display:true,text:"FLG (Ligação para Frente — Ghosh)",color:"#8892a4"}},
      y:{...CD.scales.y, title:{display:true,text:"BL (Ligação para Trás)",color:"#8892a4"}}
    }
  });

  // Top 20 BL — active sectors
  const blTop = [...lig].sort((a,b)=>b.BL-a.BL).slice(0,20);
  mkHBar("ch-bl-top", blTop.map(r=>r.cod),
    [{label:"BL", data:blTop.map(r=>r.BL),
      backgroundColor:blTop.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)), borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:{...CD.scales.x,min:0.8},y:CD.scales.y}}
  );

  // Top 20 FLG
  const flgTop = [...lig].sort((a,b)=>b.FLG-a.FLG).slice(0,20);
  mkHBar("ch-flg-top", flgTop.map(r=>r.cod),
    [{label:"FLG", data:flgTop.map(r=>r.FLG),
      backgroundColor:flgTop.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)), borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:{...CD.scales.x,min:0.5},y:CD.scales.y}}
  );

  // Quadrant donut — active sectors
  const qC = {};
  lig.forEach(r=>{ qC[r.quadrante]=(qC[r.quadrante]||0)+1; });
  mkDoughnut("ch-quadrant-pie", Object.keys(qC), Object.values(qC),
    Object.keys(qC).map(q=>QCOLORS[q]||"#888"));

  // Vj × Vi scatter — active sectors
  mkScatterCustom("ch-cv-scatter", [{
    label:"Setores",
    data: lig.map(r=>({x:r.Vi,y:r.Vj,cod:r.cod,nome:r.nome,isE:r.eh_energia})),
    backgroundColor: lig.map(r=>r.eh_energia?"#F39C12":alpha(gc(r.grupo),0.5)),
    pointRadius: lig.map(r=>r.eh_energia?7:3)
  }], {
    plugins:{legend:{display:false},
      tooltip:{callbacks:{label:ctx=>`${ctx.raw.cod}: Vj=${ctx.raw.y.toFixed(2)} Vi=${ctx.raw.x.toFixed(2)}`}}},
    scales:{
      x:{...CD.scales.x,title:{display:true,text:"Vi (Dispersão para Frente)",color:"#8892a4"}},
      y:{...CD.scales.y,title:{display:true,text:"Vj (Dispersão para Trás)",color:"#8892a4"}}
    }
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// ENERGY (Tab 4)
// ═══════════════════════════════════════════════════════════════════════════
function initEnergy(){
  const ef     = fg(D.Energia_Fluxos_ktep);
  const gLabels = [...STATE.groups];
  const fontes  = ["Derivados","Biodiesel","Etanol","EE_Central","EE_Distrib","Gas_Natural"];

  // Stacked energy by source and group
  mkBar("ch-e-group", gLabels,
    fontes.map(f=>({
      label:f, backgroundColor:FONTE_COLORS[f]||"#888", borderRadius:2, stack:"s",
      data:gLabels.map(g=>ef.filter(r=>r.grupo===g).reduce((s,r)=>s+(r[f]||0),0)/1e3)
    })),
    {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}}
  );

  // Energy source donut — active groups total
  const totByF = fontes.map(f=>ef.reduce((s,r)=>s+(r[f]||0),0));
  mkDoughnut("ch-e-pie", fontes, totByF, fontes.map(f=>FONTE_COLORS[f]||"#888"));

  // Top 15 sectors — active groups
  const withTot = ef.map(r=>({...r, total:fontes.reduce((s,f)=>s+(r[f]||0),0)}));
  const top15 = [...withTot].sort((a,b)=>b.total-a.total).slice(0,15);
  mkHBar("ch-e-top-sectors", top15.map(r=>r.cod),
    [{label:"Total (ktep)", data:top15.map(r=>r.total),
      backgroundColor:top15.map(r=>gc(r.grupo)), borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  // Energy intensity — always energy sectors
  const al   = D.Energia_Alpha;
  const setE = D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);
  const alE  = al.filter(r=>setE.includes(r.cod));
  mkBar("ch-alpha-energy", alE.map(r=>r.cod),
    fontes.map(f=>({
      label:f, data:alE.map(r=>r[f]||0),
      backgroundColor:FONTE_COLORS[f]||"#888", borderRadius:2, stack:"s"
    })),
    {scales:{x:{...CD.scales.x,stacked:true},
             y:{...CD.scales.y,stacked:true,title:{display:true,text:"ktep / R$M produção",color:"#8892a4"}}}}
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SHOCKS (Tab 5)
// ═══════════════════════════════════════════════════════════════════════════
function initShocks(){
  buildExToggles();
  rebuildShockCharts();
  renderShockTable();
}

function rebuildShockCharts(){
  const ac      = activeCodes();
  const exKeys  = activeEx();
  const cg      = D.Choques_Grupos;
  const ce      = D.Choques_Energia;
  const cl      = D.Choques_Labor;
  const gLabels = [...STATE.groups];

  // ΔVA by group — stacked, one dataset per active exercise
  mkBar("ch-shock-va-groups", gLabels,
    exKeys.map(k=>({
      label: EX_LABEL[k],
      data:  gLabels.map(g=>{ const r=cg.find(x=>x.grupo===g&&x.exercicio===k); return r?(r.delta_va||0)/1e3:0; }),
      backgroundColor: EX_COLOR[k], borderRadius:3
    }))
  );

  // Δemp by group
  mkBar("ch-shock-emp-groups", gLabels,
    exKeys.map(k=>({
      label: EX_LABEL[k],
      data:  gLabels.map(g=>{ const r=cg.find(x=>x.grupo===g&&x.exercicio===k); return r?(r.delta_emp||0)/1e3:0; }),
      backgroundColor: EX_COLOR[k], borderRadius:3
    }))
  );

  // Δenergy by source — x axis = active exercises
  const fontes = [...new Set(ce.map(r=>r.fonte))];
  mkBar("ch-shock-energy", exKeys.map(k=>EX_LABEL[k]),
    fontes.map(f=>({
      label:f, backgroundColor:FONTE_COLORS[f]||"#888", borderRadius:2, stack:"s",
      data:exKeys.map(k=>{ const r=ce.find(x=>x.exercicio===k&&x.fonte===f); return r?(r.delta_ktep||0):0; })
    })),
    {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}}
  );

  // Δemp labor categories — datasets = active exercises
  const laborG = [...new Set(cl.map(r=>r.grupo_lab))];
  mkBar("ch-shock-labor", laborG,
    exKeys.map(k=>({
      label: EX_LABEL[k], backgroundColor: EX_COLOR[k], borderRadius:3,
      data: laborG.map(g=>{ const r=cl.find(x=>x.exercicio===k&&x.grupo_lab===g); return r?(r.delta_emp||0)/1e3:0; })
    }))
  );

  // Top 15 ΔVA in first active exercise (active sectors)
  const firstEx = exKeys[0];
  const exData  = firstEx ? (D[firstEx]||[]).filter(r=>ac.has(r.cod)) : [];
  const top15VA = [...exData].sort((a,b)=>b.delta_va-a.delta_va).slice(0,15);
  mkHBar("ch-shock-ex1-sectors",
    top15VA.map(r=>r.cod),
    [{label:`ΔVA (R$ M) — ${firstEx ? EX_LABEL[firstEx] : "—"}`,
      data:top15VA.map(r=>r.delta_va),
      backgroundColor:top15VA.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)), borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  // Ex3 vs Ex4 energy sectors (always shown regardless of group filter)
  const setE = D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);
  const ex3 = D.Choque_Ex3_Fossil||[];
  const ex4 = D.Choque_Ex4_Renov||[];
  const ex3E = ex3.filter(r=>setE.includes(r.cod));
  const ex4E = ex4.filter(r=>setE.includes(r.cod));
  mkBar("ch-shock-ex34-energy", setE, [
    {label:"Ex3 Fóssil -20%", data:setE.map(c=>{ const r=ex3E.find(x=>x.cod===c); return r?(r.delta_x||0):0; }), backgroundColor:"#E24B4A", borderRadius:3},
    {label:"Ex4 Renov +30%",  data:setE.map(c=>{ const r=ex4E.find(x=>x.cod===c); return r?(r.delta_x||0):0; }), backgroundColor:"#1D9E75", borderRadius:3}
  ]);
}

function renderShockTable(){
  const ac  = activeCodes();
  const key = document.getElementById("sel-exercise").value;
  const rows = (D[key]||[]).filter(r=>ac.has(r.cod));
  clearTbody("tbl-shock");
  const tb = document.querySelector("#tbl-shock tbody");
  rows.forEach(r=>{
    const tr = document.createElement("tr");
    tr.innerHTML = `<td>${r.cod}</td><td>${r.nome.slice(0,32)}</td>
      <td>${grupoColorBadge(r.grupo||r.grupo_nt4)}</td>
      <td>${r.eh_energia ? '<span class="tag-renov">&#9889;</span>' : ""}</td>
      <td style="color:${(r.delta_x||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_x||0).toFixed(1)}</td>
      <td style="color:${(r.delta_va||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_va||0).toFixed(1)}</td>
      <td style="color:${(r.delta_emp||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_emp||0).toFixed(0)}</td>
      <td>${(r.var_x_pct||0).toFixed(2)}%</td>
      <td>${(r.var_va_pct||0).toFixed(2)}%</td>`;
    tb.appendChild(tr);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTRACTION & PURE LINKAGES (Tab 6)
// ═══════════════════════════════════════════════════════════════════════════
function initExtraction(){
  const ac   = activeCodes();
  const ext  = (D.Extr_Hipotetica||[]).filter(r=>ac.has(r.cod));
  const ipl  = (D.Ind_Puros||[]).filter(r=>ac.has(r.cod));
  const setE = D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);

  const blTop = [...ext].sort((a,b)=>b.BL_abs-a.BL_abs).slice(0,20);
  mkHBar("ch-extrac-bl", blTop.map(r=>r.cod),
    [{label:"BL Extração (R$ M)", data:blTop.map(r=>r.BL_abs),
      backgroundColor:blTop.map(r=>setE.includes(r.cod)?"#F39C12":gc(r.grupo)), borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  const flTop = [...ext].sort((a,b)=>b.FL_abs-a.FL_abs).slice(0,20);
  mkHBar("ch-extrac-fl", flTop.map(r=>r.cod),
    [{label:"FL Extração (R$ M)", data:flTop.map(r=>r.FL_abs),
      backgroundColor:flTop.map(r=>setE.includes(r.cod)?"#F39C12":gc(r.grupo)), borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  const iplWrap = document.getElementById("ch-ipln");
  if(ipl.length > 0 && iplWrap){
    mkScatterCustom("ch-ipln", [{
      label:"Setores",
      data: ipl.map(r=>({x:r.PFLN,y:r.PBLN,cod:r.cod,nome:r.nome,isE:setE.includes(r.cod)})),
      backgroundColor: ipl.map(r=>setE.includes(r.cod)?"#F39C12":alpha(gc(r.grupo),0.55)),
      pointRadius: ipl.map(r=>setE.includes(r.cod)?8:4)
    }], {
      plugins:{legend:{display:false},
        tooltip:{callbacks:{label:ctx=>`${ctx.raw.cod}: PBLN=${ctx.raw.y.toFixed(2)} PFLN=${ctx.raw.x.toFixed(2)}`}}},
      scales:{
        x:{...CD.scales.x,title:{display:true,text:"PFLN (Índice Puro Norm. — Oferta)",color:"#8892a4"}},
        y:{...CD.scales.y,title:{display:true,text:"PBLN (Índice Puro Norm. — Demanda)",color:"#8892a4"}}
      }
    });

    const tb = document.querySelector("#tbl-ipln tbody");
    [...ipl].sort((a,b)=>b.PBLN-a.PBLN).forEach(r=>{
      const tr=document.createElement("tr");
      tr.innerHTML=`<td>${r.cod}</td><td>${r.nome.slice(0,34)}</td>
        <td>${(r.PBL||0).toFixed(1)}</td><td>${(r.PFL||0).toFixed(1)}</td><td>${(r.PTL||0).toFixed(1)}</td>
        <td>${(r.PBLN||0).toFixed(3)}</td><td>${(r.PFLN||0).toFixed(3)}</td><td>${(r.PTLN||0).toFixed(3)}</td>
        <td>${grupoColorBadge(r.grupo)}</td>`;
      tb.appendChild(tr);
    });
  } else if(iplWrap) {
    iplWrap.parentElement.innerHTML = "<p style='color:#8892a4;text-align:center;padding:40px'>Índices puros não disponíveis (COMPUTE_SLOW=FALSE)</p>";
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOOTSTRAP
// ═══════════════════════════════════════════════════════════════════════════
buildGroupChips();
showTab(0);   // builds overview immediately; other tabs built lazily on first visit
</script>
</body></html>]")

writeLines(html, HTML_OUT, useBytes = FALSE)
cat("Dashboard written:", HTML_OUT, "\n")
cat("File size:", round(file.size(HTML_OUT) / 1e3), "KB\n")
