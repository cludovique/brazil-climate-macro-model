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
/* ── FILTER BAR ── */
.filter-bar{background:#13151f;border-bottom:1px solid var(--c-border);
  padding:7px 24px;display:flex;align-items:center;gap:10px;flex-wrap:wrap;
  position:sticky;top:84px;z-index:98}
/* scheme segmented control */
.scheme-ctrl{display:flex;border:1px solid var(--c-border);border-radius:7px;overflow:hidden;flex-shrink:0}
.scheme-btn{background:none;border:none;border-right:1px solid var(--c-border);
  color:var(--c-muted);padding:4px 13px;font-size:11px;font-weight:500;
  cursor:pointer;transition:.15s;white-space:nowrap}
.scheme-btn:last-child{border-right:none}
.scheme-btn.active{background:var(--c-accent);color:#fff}
.scheme-btn:hover:not(.active){background:#1f2233;color:var(--c-text)}
.scheme-btn:disabled{opacity:.3;cursor:not-allowed}
/* separator */
.fsep{width:1px;background:var(--c-border);height:18px;flex-shrink:0}
/* group chips */
.filter-label{font-size:9px;font-weight:700;color:var(--c-muted);
  text-transform:uppercase;letter-spacing:.1em;white-space:nowrap}
.chips-row{display:flex;flex-wrap:wrap;gap:4px;flex:1}
.chip{border:1px solid currentColor;padding:2px 10px;border-radius:12px;
  font-size:11px;cursor:pointer;transition:opacity .18s,background .18s;
  background:transparent;white-space:nowrap}
.chip.active{opacity:1}
.chip:not(.active){opacity:.22;border-style:dashed}
.chip:hover{opacity:.82!important}
.btn-rst{background:none;border:1px dashed var(--c-border);color:var(--c-muted);
  padding:2px 9px;border-radius:12px;font-size:11px;cursor:pointer;white-space:nowrap}
.btn-rst:hover{border-color:var(--c-text);color:var(--c-text)}
#filter-badge{font-size:10px;color:var(--c-accent);font-weight:600;white-space:nowrap;
  padding:2px 8px;border-radius:8px;background:rgba(55,138,221,.13);
  border:1px solid rgba(55,138,221,.28)}
/* ── EXERCISE FILTER (Tab 5) ── */
.ex-bar{display:flex;align-items:center;gap:6px;flex-wrap:wrap;
  background:#13151f;border:1px solid var(--c-border);border-radius:7px;
  padding:7px 12px;margin-bottom:12px}
.ex-toggle{border:1px solid currentColor;padding:3px 12px;border-radius:10px;
  font-size:11px;cursor:pointer;transition:opacity .18s,background .18s;
  background:transparent;white-space:nowrap}
.ex-toggle.active{opacity:1}
.ex-toggle:not(.active){opacity:.22;border-style:dashed}
.ex-toggle:hover{opacity:.82!important}
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

<!-- ══ FILTER BAR: scheme switcher + group chips ═════════════════════════ -->
<div class="filter-bar" id="filterBar">
  <!-- LEFT: grouping scheme (segmented control) -->
  <div class="scheme-ctrl" id="schemeCtrl"></div>
  <div class="fsep"></div>
  <!-- MIDDLE: group chips (changes with scheme) -->
  <span class="filter-label">Filtro:</span>
  <div class="chips-row" id="groupChips"></div>
  <span id="filter-badge" style="display:none"></span>
  <button class="btn-rst" onclick="resetGroups()" title="Mostrar todos">&#10005;&nbsp;Todos</button>
</div>

<!-- ═══════════════════════ TAB 0: VISÃO GERAL ══════════════════════════════ -->
<div class="tab-panel active" id="tab0">
  <div class="grid-4">
    <div class="card kpi"><div class="val" id="kpi-vbp">—</div><div class="lbl">VBP Total</div><div class="sub">grupos seleccionados</div></div>
    <div class="card kpi"><div class="val" id="kpi-va">—</div><div class="lbl">VA / PIB</div><div class="sub">grupos seleccionados</div></div>
    <div class="card kpi"><div class="val" id="kpi-emp">—</div><div class="lbl">Pessoal Ocupado</div><div class="sub">grupos seleccionados</div></div>
    <div class="card kpi"><div class="val" id="kpi-nsect">—</div><div class="lbl">Setores Activos</div><div class="sub">de 73 totais</div></div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="title-vbp-group">VBP por Grupo (R$ bilh&otilde;es)</div>
      <div class="chart-wrap"><canvas id="ch-vbp-group"></canvas></div>
    </div>
    <div class="card"><div class="card-title">Comparativo de Choques — &Delta;VA (R$ bilh&otilde;es)</div><div class="chart-wrap"><canvas id="ch-shock-va"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 12 Multiplicadores de Produ&ccedil;&atilde;o (setores activos)</div><div class="chart-wrap"><canvas id="ch-mp-top"></canvas></div></div>
    <div class="card">
      <div class="card-title">Resumo dos Exerc&iacute;cios de Choque</div>
      <table class="dt" id="tbl-shock-summary"><thead><tr>
        <th>Exerc&iacute;cio</th><th>&Delta;X (bi)</th><th>&Delta;VA (bi)</th><th>&Delta;Emp (mil)</th><th>&Delta;E (ktep)</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 1: ESTRUTURA ECONÓMICA ══════════════════════ -->
<div class="tab-panel" id="tab1">
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="title-va-decomp">Valor Adicionado por Grupo (R$ bi)</div>
      <div class="chart-wrap"><canvas id="ch-va-decomp"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title" id="title-emp-group">Pessoal Ocupado por Grupo (milhares)</div>
      <div class="chart-wrap"><canvas id="ch-emp-group"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="title-df-group">Demanda Final por Componente (R$ bi)</div>
      <div class="chart-wrap"><canvas id="ch-df-group"></canvas></div>
    </div>
    <div class="card"><div class="card-title">Top 15 Setores por VBP (activos)</div><div class="chart-wrap"><canvas id="ch-vbp-top"></canvas></div></div>
  </div>
  <div class="card" style="margin-bottom:14px">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Todos os Setores Activos — Indicadores de Base</div>
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
    <div class="card"><div class="card-title">Efeito Direto vs Indireto vs Induzido (Top 15 activos)</div><div class="chart-wrap"><canvas id="ch-mp-decomp"></canvas></div></div>
    <div class="card"><div class="card-title">Multiplicadores de Renda — Energ&eacute;ticos (MR, MRI, MRT, MRII)</div><div class="chart-wrap"><canvas id="ch-mr-energy"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Tabela de Multiplicadores (setores activos)</div>
      <input class="search-box" id="search-mult" placeholder="Buscar setor..." oninput="filterTable('tbl-mult',this.value)">
    </div>
    <div style="overflow-x:auto;max-height:340px;overflow-y:auto">
      <table class="dt" id="tbl-mult"><thead><tr>
        <th onclick="sortTable('tbl-mult',0)">C&oacute;d</th>
        <th onclick="sortTable('tbl-mult',1)">Setor</th>
        <th onclick="sortTable('tbl-mult',2)">MP</th><th onclick="sortTable('tbl-mult',3)">MPT</th>
        <th onclick="sortTable('tbl-mult',4)">MPTT</th><th onclick="sortTable('tbl-mult',5)">Direto</th>
        <th onclick="sortTable('tbl-mult',6)">Indireto</th><th onclick="sortTable('tbl-mult',7)">Induzido</th>
        <th onclick="sortTable('tbl-mult',8)">ME</th><th onclick="sortTable('tbl-mult',9)">MEI</th>
        <th onclick="sortTable('tbl-mult',10)">MR</th><th onclick="sortTable('tbl-mult',11)">MRI</th>
        <th onclick="sortTable('tbl-mult',12)">Grupo</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 3: ÍNDICES DE LIGAÇÃO ═══════════════════════ -->
<div class="tab-panel" id="tab3">
  <div class="grid-2">
    <div class="card full"><div class="card-title">Diagrama de Rasmussen-Hirschman (BL &times; FLG) — setores activos</div><div class="chart-wrap tall"><canvas id="ch-rasmussen"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 20 Liga&ccedil;&atilde;o para Tr&aacute;s (BL) — setores activos</div><div class="chart-wrap"><canvas id="ch-bl-top"></canvas></div></div>
    <div class="card"><div class="card-title">Top 20 Liga&ccedil;&atilde;o para Frente (FLG) — setores activos</div><div class="chart-wrap"><canvas id="ch-flg-top"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Distribui&ccedil;&atilde;o por Quadrante (setores activos)</div><div class="chart-wrap" style="height:240px"><canvas id="ch-quadrant-pie"></canvas></div></div>
    <div class="card"><div class="card-title">Coeficientes de Varia&ccedil;&atilde;o (Vj &times; Vi) — setores activos</div><div class="chart-wrap"><canvas id="ch-cv-scatter"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════════════ TAB 4: ENERGIA ══════════════════════════════════ -->
<div class="tab-panel" id="tab4">
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="title-e-group">Uso de Energia por Fonte e Grupo (ktep)</div>
      <div class="chart-wrap"><canvas id="ch-e-group"></canvas></div>
    </div>
    <div class="card"><div class="card-title">Distribui&ccedil;&atilde;o das Fontes Energ&eacute;ticas (ktep) — activos</div><div class="chart-wrap" style="height:260px"><canvas id="ch-e-pie"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 15 Setores por Consumo Total (ktep) — activos</div><div class="chart-wrap"><canvas id="ch-e-top-sectors"></canvas></div></div>
    <div class="card"><div class="card-title">Intensidade Energ&eacute;tica — Setores Energ&eacute;ticos (ktep / R$M)</div><div class="chart-wrap"><canvas id="ch-alpha-energy"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════════════ TAB 5: CHOQUES DE DEMANDA ═══════════════════════ -->
<div class="tab-panel" id="tab5">
  <div class="ex-bar">
    <span class="filter-label">Exerc&iacute;cios:</span>
    <div id="exToggles" style="display:flex;gap:5px;flex-wrap:wrap"></div>
    <button class="btn-rst" onclick="resetExercises()" style="margin-left:4px">&#10005;&nbsp;Todos</button>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="title-shock-va">&#916;Valor Adicionado por Grupo — exerc&iacute;cios seleccionados (R$ bi)</div>
      <div class="chart-wrap tall"><canvas id="ch-shock-va-groups"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title" id="title-shock-emp">&#916;Emprego por Grupo — exerc&iacute;cios seleccionados (mil)</div>
      <div class="chart-wrap tall"><canvas id="ch-shock-emp-groups"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">&Delta;Energia por Fonte (ktep) — exerc&iacute;cios seleccionados</div><div class="chart-wrap"><canvas id="ch-shock-energy"></canvas></div></div>
    <div class="card"><div class="card-title">&Delta;Emprego por Categoria de M&atilde;o-de-Obra</div><div class="chart-wrap"><canvas id="ch-shock-labor"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 15 Setores por &Delta;VA (activos) — 1&ordm; exerc&iacute;cio activo</div><div class="chart-wrap"><canvas id="ch-shock-ex1-sectors"></canvas></div></div>
    <div class="card"><div class="card-title">Ex3 vs Ex4 — Setores Energ&eacute;ticos: &Delta;Produ&ccedil;&atilde;o (R$M)</div><div class="chart-wrap"><canvas id="ch-shock-ex34-energy"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Detalhamento Setorial (activos)</div>
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
        <th onclick="sortTable('tbl-shock',3)">&#9889;</th>
        <th onclick="sortTable('tbl-shock',4)">&Delta;Produ&ccedil;&atilde;o</th>
        <th onclick="sortTable('tbl-shock',5)">&Delta;VA</th>
        <th onclick="sortTable('tbl-shock',6)">&Delta;Emprego</th>
        <th onclick="sortTable('tbl-shock',7)">Var% X</th>
        <th onclick="sortTable('tbl-shock',8)">Var% VA</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 6: EXTRAÇÃO & ÍND. PUROS ════════════════════ -->
<div class="tab-panel" id="tab6">
  <div class="grid-2">
    <div class="card"><div class="card-title">Extra&ccedil;&atilde;o Hipot&eacute;tica — Top 20 BL (demanda)</div><div class="chart-wrap"><canvas id="ch-extrac-bl"></canvas></div></div>
    <div class="card"><div class="card-title">Extra&ccedil;&atilde;o Hipot&eacute;tica — Top 20 FL (oferta)</div><div class="chart-wrap"><canvas id="ch-extrac-fl"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card full"><div class="card-title">PBLN &times; PFLN — &Iacute;ndices Puros Normalizados (setores activos)</div><div class="chart-wrap tall"><canvas id="ch-ipln"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">&Iacute;ndices Puros de Liga&ccedil;&atilde;o (setores activos)</div>
      <input class="search-box" id="search-ipln" placeholder="Buscar..." oninput="filterTable('tbl-ipln',this.value)">
    </div>
    <div style="overflow-x:auto;max-height:320px;overflow-y:auto">
      <table class="dt" id="tbl-ipln"><thead><tr>
        <th onclick="sortTable('tbl-ipln',0)">C&oacute;d</th><th onclick="sortTable('tbl-ipln',1)">Setor</th>
        <th onclick="sortTable('tbl-ipln',2)">PBL</th><th onclick="sortTable('tbl-ipln',3)">PFL</th>
        <th onclick="sortTable('tbl-ipln',4)">PTL</th><th onclick="sortTable('tbl-ipln',5)">PBLN</th>
        <th onclick="sortTable('tbl-ipln',6)">PFLN</th><th onclick="sortTable('tbl-ipln',7)">PTLN</th>
        <th onclick="sortTable('tbl-ipln',8)">Grupo</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<script>
// ═══════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════
const D = ]", js_data, r"[;

// ═══════════════════════════════════════════════════════════════════════════
// COLOUR SYSTEM — single gc() with hash fallback for unknown groups
// ═══════════════════════════════════════════════════════════════════════════
const NAMED_COLORS = {
  // 7G
  Agropecuaria:"#3B6D11", Ind_Extrativa:"#888780",
  Energia_Fossil:"#E24B4A", Energia_Renov:"#1D9E75",
  Ind_Transform:"#378ADD", Infraestrutura:"#534AB7", Servicos:"#B4B2A9",
  // NT4 typical names
  Energeticos:"#F39C12", Industria:"#378ADD", Industrias:"#378ADD",
  // generic
  Agro:"#3B6D11", Energia:"#F39C12"
};
const FONTE_COLORS = {
  Derivados:"#E24B4A", Biodiesel:"#1D9E75", Etanol:"#3B6D11",
  EE_Central:"#F39C12", EE_Distrib:"#F8C471", Gas_Natural:"#8E44AD"
};
const EX_COLOR = {
  "Choque_Ex1_NT":"#378ADD","Choque_Ex2_NT":"#888780",
  "Choque_Ex3_Fossil":"#E24B4A","Choque_Ex4_Renov":"#1D9E75","Choque_Ex5_Trans":"#F39C12"
};
const EX_LABEL = {
  "Choque_Ex1_NT":"+5% Exportações","Choque_Ex2_NT":"+5% Famílias S40",
  "Choque_Ex3_Fossil":"Fóssil -20%","Choque_Ex4_Renov":"Renov +30%","Choque_Ex5_Trans":"Transição"
};
const ALL_EX_KEYS = ["Choque_Ex1_NT","Choque_Ex2_NT","Choque_Ex3_Fossil","Choque_Ex4_Renov","Choque_Ex5_Trans"];

// deterministic hue from group name string
function hashColor(s){
  let h=0; for(let i=0;i<s.length;i++) h=s.charCodeAt(i)+((h<<5)-h);
  return `hsl(${Math.abs(h)%360},48%,52%)`;
}
function gc(g){ return NAMED_COLORS[g] || hashColor(g||""); }
function alpha(hex,a){
  if(hex.startsWith("hsl")) return hex.replace("hsl","hsla").replace(")",`,${a})`);
  const r=parseInt(hex.slice(1,3),16),g=parseInt(hex.slice(3,5),16),b=parseInt(hex.slice(5,7),16);
  return `rgba(${r},${g},${b},${a})`;
}
function fmtN(v,d=2){ return v==null?"—":Number(v).toFixed(d); }

// ═══════════════════════════════════════════════════════════════════════════
// GROUPING SCHEMES
// ═══════════════════════════════════════════════════════════════════════════
// Detect which columns exist in D.Setores
const _s0 = D.Setores[0] || {};
const SCHEMES = [
  { id:"nt4",  col:"grupo_nt4",   label:"NT4",       available: "grupo_nt4"  in _s0 },
  { id:"7g",   col:"grupo",       label:"7 Grupos",  available: "grupo"      in _s0 },
  { id:"ibge", col:"grupo_ibge",  label:"IBGE",      available: "grupo_ibge" in _s0 },
  { id:"sec",  col:"cod",         label:"73 Setores",available: true }
].filter(s=>s.available || s.id==="sec");  // always include sector mode

// ═══════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════
const STATE = {
  schemeId:    "7g",          // active scheme id
  activeLabels: null,         // Set of active label values (null = all)
  exercises:   new Set(ALL_EX_KEYS),
  tab:         0,
  filterVer:   1,
  builtVer:    {}
};

// ═══════════════════════════════════════════════════════════════════════════
// SCHEME HELPERS
// ═══════════════════════════════════════════════════════════════════════════
function currentScheme(){ return SCHEMES.find(s=>s.id===STATE.schemeId) || SCHEMES[0]; }
function schemeCol(){ return currentScheme().col; }

// all unique label values for the current scheme in a dataset
function allLabels(data){
  const col = schemeCol();
  return [...new Set(data.map(r=>r[col]).filter(x=>x!=null&&x!==""))];
}

// active label values (all if no filter set)
function activeLabels(data){
  const all = allLabels(data);
  if(!STATE.activeLabels || STATE.activeLabels.size===0) return all;
  return all.filter(l=>STATE.activeLabels.has(l));
}

// filter a data array to rows whose scheme column is in activeLabels
function filterActive(data){
  if(!STATE.activeLabels || STATE.activeLabels.size===0) return data;
  const col = schemeCol();
  return data.filter(r=>STATE.activeLabels.has(r[col]));
}

// active sector codes = sectors whose scheme-column label is active
function activeCodes(){
  const col = schemeCol();
  const actSet = STATE.activeLabels;
  if(!actSet || actSet.size===0) return new Set(D.Setores.map(r=>r.cod));
  return new Set(D.Setores.filter(r=>actSet.has(r[col])).map(r=>r.cod));
}

// aggregate a numeric column by active labels
function aggBy(data, valueCol, labels){
  const col = schemeCol();
  return labels.map(lbl=>{
    const rows = data.filter(r=>r[col]===lbl);
    return rows.reduce((s,r)=>s+(Number(r[valueCol])||0),0);
  });
}

// colour for a label in the current scheme
function labelColor(lbl, row){
  // in sector mode (col=cod), colour by 7G group of that sector
  if(schemeCol()==="cod"){
    const sec = D.Setores.find(s=>s.cod===lbl);
    return gc(sec ? sec.grupo : lbl);
  }
  return gc(lbl);
}

// colour array for a label list (with optional row lookup)
function labelColors(labels, dataArr){
  return labels.map(lbl=>{
    if(schemeCol()==="cod"){
      const sec = D.Setores.find(s=>s.cod===lbl);
      return gc(sec ? sec.grupo : lbl);
    }
    return gc(lbl);
  });
}

// scheme-aware chart title suffix
function schemeSuffix(){
  const s = currentScheme();
  if(s.id==="sec") return "— 73 setores";
  return `— agrupamento ${s.label}`;
}

// ═══════════════════════════════════════════════════════════════════════════
// CHART REGISTRY
// ═══════════════════════════════════════════════════════════════════════════
const CHARTS = {};
function destroyChart(id){ if(CHARTS[id]){ CHARTS[id].destroy(); delete CHARTS[id]; } }
const CD = {
  responsive:true, maintainAspectRatio:false,
  plugins:{ legend:{ labels:{ color:"#8892a4", font:{size:11} } } },
  scales:{
    x:{ ticks:{color:"#8892a4",font:{size:10}}, grid:{color:"#1f2233"} },
    y:{ ticks:{color:"#8892a4",font:{size:10}}, grid:{color:"#1f2233"} }
  }
};
function mkBar(id,labels,datasets,opts={}){
  destroyChart(id);
  const el=document.getElementById(id); if(!el) return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"bar",data:{labels,datasets},
    options:Object.assign({},CD,opts)}); return CHARTS[id];
}
function mkHBar(id,labels,datasets,opts={}){
  destroyChart(id);
  const el=document.getElementById(id); if(!el) return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"bar",data:{labels,datasets},
    options:Object.assign({},CD,{indexAxis:"y"},opts)}); return CHARTS[id];
}
function mkXY(id,datasets,opts={}){
  destroyChart(id);
  const el=document.getElementById(id); if(!el) return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"scatter",data:{datasets},
    options:Object.assign({},CD,opts)}); return CHARTS[id];
}
function mkDoughnut(id,labels,data,colors){
  destroyChart(id);
  const el=document.getElementById(id); if(!el) return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"doughnut",
    data:{labels,datasets:[{data,backgroundColor:colors,borderWidth:1,borderColor:"#0f1117"}]},
    options:{responsive:true,maintainAspectRatio:false,
      plugins:{legend:{position:"right",labels:{color:"#8892a4",font:{size:11}}}}}}); return CHARTS[id];
}
function clearTbody(id){ const t=document.querySelector("#"+id+" tbody"); if(t) t.innerHTML=""; }
function clearTabTables(n){ document.querySelectorAll(`#tab${n} table.dt tbody`).forEach(t=>t.innerHTML=""); }
function setTitle(id,txt){ const el=document.getElementById(id); if(el) el.textContent=txt; }

// ═══════════════════════════════════════════════════════════════════════════
// SCHEME SWITCHER UI
// ═══════════════════════════════════════════════════════════════════════════
function buildSchemeSwitcher(){
  const ctrl = document.getElementById("schemeCtrl");
  ctrl.innerHTML = "";
  SCHEMES.forEach(s=>{
    const btn = document.createElement("button");
    btn.className = "scheme-btn" + (s.id===STATE.schemeId?" active":"");
    btn.id = "sch-"+s.id;
    btn.textContent = s.label;
    if(!s.available){ btn.disabled=true; btn.title="Coluna não disponível nos dados"; }
    else btn.onclick = ()=>onSchemeChange(s.id);
    ctrl.appendChild(btn);
  });
}

function onSchemeChange(id){
  STATE.schemeId = id;
  // reset active labels to ALL for the new scheme
  STATE.activeLabels = null;
  // update scheme button highlight
  SCHEMES.forEach(s=>{
    const b=document.getElementById("sch-"+s.id);
    if(b) b.classList.toggle("active",s.id===id);
  });
  buildGroupChips();
  onFilterChange();
}

// ═══════════════════════════════════════════════════════════════════════════
// GROUP CHIP FILTER (adapts to current scheme)
// ═══════════════════════════════════════════════════════════════════════════
function buildGroupChips(){
  const container = document.getElementById("groupChips");
  container.innerHTML = "";
  // in sector mode, chips show 7G groups as colour filters
  const col     = schemeCol()==="cod" ? "grupo" : schemeCol();
  const labels  = [...new Set(D.Setores.map(r=>r[col]).filter(Boolean))].sort();
  const actSet  = STATE.activeLabels;

  labels.forEach(lbl=>{
    const c  = gc(lbl);
    const on = !actSet || actSet.has(lbl);
    const btn= document.createElement("button");
    btn.id   = "chip-"+lbl;
    btn.className="chip"+(on?" active":"");
    btn.style.color=c; btn.style.borderColor=c;
    if(on) btn.style.background=alpha(c,0.15);
    btn.innerHTML = "&#9679; "+lbl.replace(/_/g," ");
    btn.onclick   = ()=>toggleGroup(lbl);
    container.appendChild(btn);
  });
  updateFilterBadge();
}

function updateChip(lbl){
  const col= schemeCol()==="cod"?"grupo":schemeCol();
  const allL=[...new Set(D.Setores.map(r=>r[col]).filter(Boolean))];
  const c  = gc(lbl);
  const on = !STATE.activeLabels || STATE.activeLabels.has(lbl);
  const btn= document.getElementById("chip-"+lbl);
  if(!btn) return;
  btn.className="chip"+(on?" active":"");
  btn.style.color=c; btn.style.borderColor=c;
  btn.style.background=on?alpha(c,0.15):"transparent";
}

function toggleGroup(lbl){
  // Determine full label set for current chips
  const col     = schemeCol()==="cod"?"grupo":schemeCol();
  const allLbls = [...new Set(D.Setores.map(r=>r[col]).filter(Boolean))];
  // initialise activeLabels if needed (null means all active)
  if(!STATE.activeLabels) STATE.activeLabels=new Set(allLbls);
  if(STATE.activeLabels.has(lbl)){
    if(STATE.activeLabels.size<=1) return;   // keep ≥ 1
    STATE.activeLabels.delete(lbl);
  } else {
    STATE.activeLabels.add(lbl);
  }
  updateChip(lbl);
  onFilterChange();
}

function resetGroups(){
  STATE.activeLabels = null;   // null = all active
  buildGroupChips();
  onFilterChange();
}

function updateFilterBadge(){
  const badge = document.getElementById("filter-badge");
  if(!badge) return;
  const col   = schemeCol()==="cod"?"grupo":schemeCol();
  const total = [...new Set(D.Setores.map(r=>r[col]).filter(Boolean))].length;
  const n     = STATE.activeLabels ? STATE.activeLabels.size : total;
  if(n===total){ badge.textContent=""; badge.style.display="none"; }
  else { badge.textContent=n+"/"+total+" visíveis"; badge.style.display="inline"; }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXERCISE TOGGLES (Tab 5)
// ═══════════════════════════════════════════════════════════════════════════
function buildExToggles(){
  const container=document.getElementById("exToggles"); if(!container) return;
  container.innerHTML="";
  ALL_EX_KEYS.forEach(k=>{
    const c=EX_COLOR[k]; const on=STATE.exercises.has(k);
    const btn=document.createElement("button");
    btn.id="extog-"+k; btn.className="ex-toggle"+(on?" active":"");
    btn.style.color=c; btn.style.borderColor=c;
    if(on) btn.style.background=alpha(c,0.15);
    btn.textContent=EX_LABEL[k];
    btn.onclick=()=>toggleExercise(k);
    container.appendChild(btn);
  });
}
function updateExToggle(k){
  const c=EX_COLOR[k]; const on=STATE.exercises.has(k);
  const btn=document.getElementById("extog-"+k); if(!btn) return;
  btn.className="ex-toggle"+(on?" active":"");
  btn.style.color=c; btn.style.borderColor=c;
  btn.style.background=on?alpha(c,0.15):"transparent";
}
function toggleExercise(k){
  if(STATE.exercises.has(k)){
    if(STATE.exercises.size<=1) return;
    STATE.exercises.delete(k);
  } else { STATE.exercises.add(k); }
  updateExToggle(k);
  rebuildShockCharts();
  renderShockTable();
}
function resetExercises(){
  ALL_EX_KEYS.forEach(k=>STATE.exercises.add(k));
  buildExToggles(); rebuildShockCharts(); renderShockTable();
}
function activeEx(){ return ALL_EX_KEYS.filter(k=>STATE.exercises.has(k)); }

// ═══════════════════════════════════════════════════════════════════════════
// TAB NAVIGATION & LAZY REBUILD
// ═══════════════════════════════════════════════════════════════════════════
const INIT_FNS=[initOverview,initBaseline,initMultipliers,initLinkages,initEnergy,initShocks,initExtraction];

function showTab(n){
  document.querySelectorAll(".tab-panel").forEach((p,i)=>p.classList.toggle("active",i===n));
  document.querySelectorAll("#mainTabs button").forEach((b,i)=>b.classList.toggle("active",i===n));
  STATE.tab=n;
  if(!(n in STATE.builtVer)||STATE.builtVer[n]!==STATE.filterVer){
    clearTabTables(n); INIT_FNS[n](); STATE.builtVer[n]=STATE.filterVer;
  }
}
function onFilterChange(){
  STATE.filterVer++;
  updateFilterBadge();
  clearTabTables(STATE.tab);
  INIT_FNS[STATE.tab]();
  STATE.builtVer[STATE.tab]=STATE.filterVer;
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLE UTILITIES
// ═══════════════════════════════════════════════════════════════════════════
function filterTable(id,q){
  const rows=document.querySelectorAll("#"+id+" tbody tr");
  const lq=q.toLowerCase();
  rows.forEach(r=>r.style.display=r.textContent.toLowerCase().includes(lq)?"":"none");
}
let sortDir={};
function sortTable(id,col){
  const tb=document.getElementById(id);
  const rows=Array.from(tb.querySelectorAll("tbody tr"));
  const asc=(sortDir[id+col]=!sortDir[id+col]);
  rows.sort((a,b)=>{
    const va=a.cells[col].textContent.trim(),vb=b.cells[col].textContent.trim();
    const na=parseFloat(va),nb=parseFloat(vb);
    if(!isNaN(na)&&!isNaN(nb)) return asc?na-nb:nb-na;
    return asc?va.localeCompare(vb):vb.localeCompare(va);
  });
  rows.forEach(r=>tb.querySelector("tbody").appendChild(r));
}
function grupoColorBadge(g){
  const c=gc(g);
  return `<span class="badge-g" style="background:${alpha(c,0.22)};color:${c}">${g||"—"}</span>`;
}

// ═══════════════════════════════════════════════════════════════════════════
// OVERVIEW (Tab 0)
// ═══════════════════════════════════════════════════════════════════════════
function initOverview(){
  const ac    = activeCodes();
  const bl    = D.Baseline.filter(r=>ac.has(r.cod));
  const totVBP= bl.reduce((s,r)=>s+(r.vbp||0),0);
  const totVA = bl.reduce((s,r)=>s+(r.va_pib||0),0);
  const totEmp= bl.reduce((s,r)=>s+(r.ocupacoes||0),0);
  document.getElementById("kpi-vbp").textContent =(totVBP/1e6).toFixed(2)+" T";
  document.getElementById("kpi-va").textContent  =(totVA /1e6).toFixed(2)+" T";
  document.getElementById("kpi-emp").textContent =(totEmp/1e6).toFixed(1)+" M";
  document.getElementById("kpi-nsect").textContent=ac.size+" / 73";

  const sch=currentScheme();
  const isSec=sch.id==="sec";
  setTitle("title-vbp-group","VBP por "+(isSec?"Setor (top 30)":sch.label)+" (R$ bi)");

  if(isSec){
    // sector mode: individual bars top-30 by VBP
    const top=bl.sort((a,b)=>b.vbp-a.vbp).slice(0,30);
    mkHBar("ch-vbp-group",top.map(r=>r.cod),
      [{label:"VBP (R$ bi)",data:top.map(r=>r.vbp/1e3),
        backgroundColor:top.map(r=>gc(r.grupo)),borderRadius:3}],
      {plugins:{...CD.plugins,legend:{display:false}}}
    );
  } else {
    const lbls=activeLabels(D.Baseline);
    mkBar("ch-vbp-group",lbls,
      [{label:"VBP (R$ bi)",data:aggBy(D.Baseline,"vbp",lbls).map(v=>v/1e3),
        backgroundColor:labelColors(lbls),borderRadius:4}],
      {plugins:{...CD.plugins,legend:{display:false}}}
    );
  }

  // Shock VA overview (always exercise summary — no group filter)
  const sr=D.Choques_Resumo;
  mkBar("ch-shock-va",sr.map(r=>r.exercicio.slice(0,28)),
    [{label:"ΔVA (R$ bi)",data:sr.map(r=>r.dVA_bi),
      backgroundColor:sr.map(r=>r.dVA_bi>=0?"#1D9E75":"#E24B4A"),borderRadius:4}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  // Top 12 MP — active sectors
  const mp=[...D.Mult_Producao].filter(r=>ac.has(r.cod)).sort((a,b)=>b.MP-a.MP).slice(0,12);
  mkHBar("ch-mp-top",mp.map(r=>r.cod+" "+r.nome.slice(0,22)),
    [{label:"MP",data:mp.map(r=>r.MP),backgroundColor:mp.map(r=>gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}},scales:{x:{...CD.scales.x,min:1},y:CD.scales.y}}
  );

  // Shock summary table
  clearTbody("tbl-shock-summary");
  const tb=document.querySelector("#tbl-shock-summary tbody");
  sr.forEach(r=>{
    const tr=document.createElement("tr"); tr.innerHTML=
      `<td>${r.exercicio}</td><td>${(r.dx_bi||0).toFixed(1)}</td><td>${(r.dVA_bi||0).toFixed(1)}</td><td>${(r.demp_mil||0).toFixed(1)}</td><td>${(r.dE_ktep||0).toFixed(0)}</td>`;
    tb.appendChild(tr);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// BASELINE (Tab 1)
// ═══════════════════════════════════════════════════════════════════════════
function initBaseline(){
  const ac   = activeCodes();
  const bl   = D.Baseline.filter(r=>ac.has(r.cod));
  const dfAll= D.Demanda_Final;
  const sch  = currentScheme();
  const isSec= sch.id==="sec";
  const suffix=sch.id==="sec"?" (top 20 por VA)":" ("+sch.label+")";

  setTitle("title-va-decomp",  "Valor Adicionado por Grupo"+suffix);
  setTitle("title-emp-group",  "Pessoal Ocupado por Grupo"+suffix);
  setTitle("title-df-group",   "Demanda Final por Componente"+suffix);

  if(isSec){
    // sort by VA desc, show top 20
    const topVA=[...bl].sort((a,b)=>b.va_pib-a.va_pib).slice(0,20);
    mkBar("ch-va-decomp",topVA.map(r=>r.cod),[
      {label:"VA/PIB",  data:topVA.map(r=>r.va_pib/1e3),  backgroundColor:"#378ADD",borderRadius:3},
      {label:"Salários",data:topVA.map(r=>r.salarios/1e3), backgroundColor:"#1D9E75",borderRadius:3},
      {label:"EOB",     data:topVA.map(r=>r.eob/1e3),      backgroundColor:"#F39C12",borderRadius:3}
    ]);
    const topEmp=[...bl].sort((a,b)=>b.ocupacoes-a.ocupacoes).slice(0,20);
    mkBar("ch-emp-group",topEmp.map(r=>r.cod),[
      {label:"Ocupações (mil)",data:topEmp.map(r=>r.ocupacoes/1e3),
       backgroundColor:topEmp.map(r=>gc(r.grupo)),borderRadius:4}
    ],{plugins:{...CD.plugins,legend:{display:false}}});
    // DF — show top 20 sectors by total final demand
    const df=dfAll.filter(r=>ac.has(r.cod));
    const dfComps=["Export","Gov","ISFLSF","Families","GFCF","DeltaStock"];
    const dfColors=["#378ADD","#534AB7","#888780","#1D9E75","#F39C12","#E24B4A"];
    const withTot=df.map(r=>({...r,tot:dfComps.reduce((s,c)=>s+(r[c]||0),0)}));
    const topDF=[...withTot].sort((a,b)=>b.tot-a.tot).slice(0,20);
    mkBar("ch-df-group",topDF.map(r=>r.cod),
      dfComps.map((c,i)=>({label:c,backgroundColor:dfColors[i],borderRadius:2,stack:"s",
        data:topDF.map(r=>r[c]||0)})),
      {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}}
    );
  } else {
    const lbls=activeLabels(D.Baseline);
    mkBar("ch-va-decomp",lbls,[
      {label:"VA/PIB",   data:aggBy(D.Baseline,"va_pib",lbls).map(v=>v/1e3),  backgroundColor:"#378ADD",borderRadius:3},
      {label:"Salários", data:aggBy(D.Baseline,"salarios",lbls).map(v=>v/1e3),backgroundColor:"#1D9E75",borderRadius:3},
      {label:"EOB",      data:aggBy(D.Baseline,"eob",lbls).map(v=>v/1e3),     backgroundColor:"#F39C12",borderRadius:3}
    ]);
    mkBar("ch-emp-group",lbls,
      [{label:"Ocupações (mil)",data:aggBy(D.Baseline,"ocupacoes",lbls).map(v=>v/1e3),
        backgroundColor:labelColors(lbls),borderRadius:4}],
      {plugins:{...CD.plugins,legend:{display:false}}}
    );
    const df=dfAll; const col=schemeCol();
    const dfComps=["Export","Gov","ISFLSF","Families","GFCF","DeltaStock"];
    const dfColors=["#378ADD","#534AB7","#888780","#1D9E75","#F39C12","#E24B4A"];
    mkBar("ch-df-group",lbls,
      dfComps.map((c,i)=>({label:c,backgroundColor:dfColors[i],borderRadius:2,stack:"s",
        data:lbls.map(lbl=>df.filter(r=>r[col]===lbl).reduce((s,r)=>s+(r[c]||0),0)/1e3)})),
      {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}}
    );
  }

  // Top 15 sectors by VBP — always individual
  const top15=[...bl].sort((a,b)=>b.vbp-a.vbp).slice(0,15);
  mkHBar("ch-vbp-top",top15.map(r=>r.cod),
    [{label:"VBP (R$ bi)",data:top15.map(r=>r.vbp/1e3),
      backgroundColor:top15.map(r=>gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  // Table
  const tb=document.querySelector("#tbl-baseline tbody");
  bl.forEach(r=>{
    const tr=document.createElement("tr"); tr.innerHTML=
      `<td>${r.cod}</td><td>${r.nome.slice(0,38)}</td><td>${grupoColorBadge(r.grupo)}</td>
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
  const ac  =activeCodes();
  const mp  =D.Mult_Producao.filter(r=>ac.has(r.cod)).sort((a,b)=>b.MP-a.MP);
  const me  =D.Mult_Emprego; const mr=D.Mult_Renda;
  const setE=D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);

  mkHBar("ch-mp-all",mp.map(r=>r.cod),
    [{label:"MP",data:mp.map(r=>r.MP),
      backgroundColor:mp.map(r=>setE.includes(r.cod)?"#F39C12":gc(r.grupo)),borderRadius:2}],
    {plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:{...CD.scales.x,min:1},y:{...CD.scales.y,ticks:{font:{size:9}}}}}
  );

  const mpE=D.Mult_Producao.filter(r=>setE.includes(r.cod));
  mkBar("ch-mp-energy",mpE.map(r=>r.cod),[
    {label:"MP",  data:mpE.map(r=>r.MP),  backgroundColor:"#378ADD",borderRadius:3},
    {label:"MPT", data:mpE.map(r=>r.MPT), backgroundColor:"#1D9E75",borderRadius:3},
    {label:"MPTT",data:mpE.map(r=>r.MPTT),backgroundColor:"#F39C12",borderRadius:3}
  ]);
  const meE=me.filter(r=>setE.includes(r.cod));
  mkBar("ch-me-energy",meE.map(r=>r.cod),[
    {label:"ME",  data:meE.map(r=>r.ME),  backgroundColor:"#378ADD",borderRadius:3},
    {label:"MEI", data:meE.map(r=>r.MEI), backgroundColor:"#1D9E75",borderRadius:3},
    {label:"MET", data:meE.map(r=>r.MET), backgroundColor:"#F39C12",borderRadius:3},
    {label:"MEII",data:meE.map(r=>r.MEII),backgroundColor:"#E24B4A",borderRadius:3}
  ]);
  const top15=mp.slice(0,15);
  mkBar("ch-mp-decomp",top15.map(r=>r.cod),[
    {label:"Direto",  data:top15.map(r=>r.direct),  backgroundColor:"#378ADD",borderRadius:2,stack:"s"},
    {label:"Indireto",data:top15.map(r=>r.indirect),backgroundColor:"#534AB7",borderRadius:2,stack:"s"},
    {label:"Induzido",data:top15.map(r=>r.induced), backgroundColor:"#1D9E75",borderRadius:2,stack:"s"}
  ],{scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}});
  const mrE=mr.filter(r=>setE.includes(r.cod));
  mkBar("ch-mr-energy",mrE.map(r=>r.cod),[
    {label:"MR",  data:mrE.map(r=>r.MR),  backgroundColor:"#378ADD",borderRadius:3},
    {label:"MRI", data:mrE.map(r=>r.MRI), backgroundColor:"#1D9E75",borderRadius:3},
    {label:"MRT", data:mrE.map(r=>r.MRT), backgroundColor:"#F39C12",borderRadius:3},
    {label:"MRII",data:mrE.map(r=>r.MRII),backgroundColor:"#E24B4A",borderRadius:3}
  ]);

  const meByCode=Object.fromEntries(me.map(r=>[r.cod,r]));
  const mrByCode=Object.fromEntries(mr.map(r=>[r.cod,r]));
  const tb=document.querySelector("#tbl-mult tbody");
  mp.forEach(r=>{
    const m=meByCode[r.cod]||{},n=mrByCode[r.cod]||{};
    const tr=document.createElement("tr"); tr.innerHTML=
      `<td>${r.cod}</td><td>${r.nome.slice(0,32)}</td>
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
  const ac  =activeCodes();
  const lig =D.Ind_Ligacao.filter(r=>ac.has(r.cod));
  const QCOL={"Setor-Chave":"#F39C12","Demanda acima da media":"#1D9E75",
               "Oferta acima da media":"#378ADD","Independente":"#888780"};

  const datasets=Object.entries(QCOL).map(([q,c])=>{
    const pts=lig.filter(r=>r.quadrante===q);
    return{label:q,
      data:pts.map(r=>({x:r.FLG,y:r.BL,cod:r.cod,isE:r.eh_energia})),
      backgroundColor:pts.map(r=>r.eh_energia?alpha(c,0.95):alpha(c,0.45)),
      pointRadius:pts.map(r=>r.eh_energia?8:4),
      pointStyle:pts.map(r=>r.eh_energia?"triangle":"circle")};
  });
  mkXY("ch-rasmussen",datasets,{
    plugins:{legend:{labels:{color:"#8892a4",font:{size:11}}},
      tooltip:{callbacks:{label:ctx=>`${ctx.raw.cod}: BL=${ctx.raw.y.toFixed(3)} FLG=${ctx.raw.x.toFixed(3)}${ctx.raw.isE?" ⚡":""}`}}},
    scales:{x:{...CD.scales.x,title:{display:true,text:"FLG",color:"#8892a4"}},
            y:{...CD.scales.y,title:{display:true,text:"BL",color:"#8892a4"}}}
  });

  const blTop=[...lig].sort((a,b)=>b.BL-a.BL).slice(0,20);
  mkHBar("ch-bl-top",blTop.map(r=>r.cod),
    [{label:"BL",data:blTop.map(r=>r.BL),
      backgroundColor:blTop.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}},scales:{x:{...CD.scales.x,min:0.8},y:CD.scales.y}}
  );
  const flgTop=[...lig].sort((a,b)=>b.FLG-a.FLG).slice(0,20);
  mkHBar("ch-flg-top",flgTop.map(r=>r.cod),
    [{label:"FLG",data:flgTop.map(r=>r.FLG),
      backgroundColor:flgTop.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}},scales:{x:{...CD.scales.x,min:0.5},y:CD.scales.y}}
  );

  const qC={};  lig.forEach(r=>{qC[r.quadrante]=(qC[r.quadrante]||0)+1;});
  mkDoughnut("ch-quadrant-pie",Object.keys(qC),Object.values(qC),Object.keys(qC).map(q=>QCOL[q]||"#888"));

  mkXY("ch-cv-scatter",[{label:"Setores",
    data:lig.map(r=>({x:r.Vi,y:r.Vj,cod:r.cod,isE:r.eh_energia})),
    backgroundColor:lig.map(r=>r.eh_energia?"#F39C12":alpha(gc(r.grupo),0.5)),
    pointRadius:lig.map(r=>r.eh_energia?7:3)}],
    {plugins:{legend:{display:false},tooltip:{callbacks:{label:ctx=>`${ctx.raw.cod}: Vj=${ctx.raw.y.toFixed(2)} Vi=${ctx.raw.x.toFixed(2)}`}}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"Vi (Dispersão para Frente)",color:"#8892a4"}},
             y:{...CD.scales.y,title:{display:true,text:"Vj (Dispersão para Trás)",color:"#8892a4"}}}}
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ENERGY (Tab 4)
// ═══════════════════════════════════════════════════════════════════════════
function initEnergy(){
  const ac    =activeCodes();
  const ef    =D.Energia_Fluxos_ktep.filter(r=>ac.has(r.cod));
  const fontes=["Derivados","Biodiesel","Etanol","EE_Central","EE_Distrib","Gas_Natural"];
  const sch   =currentScheme(); const isSec=sch.id==="sec";
  setTitle("title-e-group","Energia por Fonte e "+(isSec?"Setor (top 20)":sch.label)+" (ktep)");

  if(isSec){
    const withTot=ef.map(r=>({...r,tot:fontes.reduce((s,f)=>s+(r[f]||0),0)}));
    const top20=[...withTot].sort((a,b)=>b.tot-a.tot).slice(0,20);
    mkBar("ch-e-group",top20.map(r=>r.cod),
      fontes.map(f=>({label:f,backgroundColor:FONTE_COLORS[f]||"#888",borderRadius:2,stack:"s",
        data:top20.map(r=>r[f]||0)})),
      {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}}
    );
  } else {
    const lbls=activeLabels(ef); const col=schemeCol();
    mkBar("ch-e-group",lbls,
      fontes.map(f=>({label:f,backgroundColor:FONTE_COLORS[f]||"#888",borderRadius:2,stack:"s",
        data:lbls.map(lbl=>ef.filter(r=>r[col]===lbl).reduce((s,r)=>s+(r[f]||0),0)/1e3)})),
      {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}}
    );
  }

  const totByF=fontes.map(f=>ef.reduce((s,r)=>s+(r[f]||0),0));
  mkDoughnut("ch-e-pie",fontes,totByF,fontes.map(f=>FONTE_COLORS[f]||"#888"));

  const withTot2=ef.map(r=>({...r,tot:fontes.reduce((s,f)=>s+(r[f]||0),0)}));
  const top15=[...withTot2].sort((a,b)=>b.tot-a.tot).slice(0,15);
  mkHBar("ch-e-top-sectors",top15.map(r=>r.cod),
    [{label:"Total (ktep)",data:top15.map(r=>r.tot),
      backgroundColor:top15.map(r=>gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  const al=D.Energia_Alpha;
  const setE=D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);
  const alE=al.filter(r=>setE.includes(r.cod));
  mkBar("ch-alpha-energy",alE.map(r=>r.cod),
    fontes.map(f=>({label:f,data:alE.map(r=>r[f]||0),backgroundColor:FONTE_COLORS[f]||"#888",
      borderRadius:2,stack:"s"})),
    {scales:{x:{...CD.scales.x,stacked:true},
             y:{...CD.scales.y,stacked:true,title:{display:true,text:"ktep / R$M",color:"#8892a4"}}}}
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SHOCKS (Tab 5)
// ═══════════════════════════════════════════════════════════════════════════
function initShocks(){ buildExToggles(); rebuildShockCharts(); renderShockTable(); }

function rebuildShockCharts(){
  const ac    =activeCodes();
  const exKeys=activeEx();
  const cg    =D.Choques_Grupos;
  const ce    =D.Choques_Energia;
  const cl    =D.Choques_Labor;
  const sch   =currentScheme(); const isSec=sch.id==="sec";
  const col   =schemeCol();

  setTitle("title-shock-va",   "ΔVA por "+(isSec?"Setor (top 20)":sch.label)+" (R$ bi)");
  setTitle("title-shock-emp",  "ΔEmprego por "+(isSec?"Setor (top 20)":sch.label)+" (mil)");

  if(isSec){
    // sector mode — use individual shock sheets, top 20 by |ΔVA| across first active ex
    const exDatas=exKeys.map(k=>(D[k]||[]).filter(r=>ac.has(r.cod)));
    // collect all sector codes appearing in any active exercise, sort by first ex ΔVA
    const ref=exDatas[0]||[]; const top20=[...ref].sort((a,b)=>b.delta_va-a.delta_va).slice(0,20);
    const cods=top20.map(r=>r.cod);
    mkBar("ch-shock-va-groups",cods,
      exKeys.map((k,i)=>{
        const rows=Object.fromEntries((D[k]||[]).map(r=>[r.cod,r]));
        return{label:EX_LABEL[k],data:cods.map(c=>(rows[c]?.delta_va||0)/1e3),
          backgroundColor:EX_COLOR[k],borderRadius:3};
      })
    );
    mkBar("ch-shock-emp-groups",cods,
      exKeys.map((k,i)=>{
        const rows=Object.fromEntries((D[k]||[]).map(r=>[r.cod,r]));
        return{label:EX_LABEL[k],data:cods.map(c=>(rows[c]?.delta_emp||0)/1e3),
          backgroundColor:EX_COLOR[k],borderRadius:3};
      })
    );
  } else {
    // grouped mode — use pre-aggregated Choques_Grupos
    const lbls=activeLabels(cg);
    mkBar("ch-shock-va-groups",lbls,
      exKeys.map(k=>({label:EX_LABEL[k],backgroundColor:EX_COLOR[k],borderRadius:3,
        data:lbls.map(g=>{const r=cg.find(x=>x[col]===g&&x.exercicio===k); return r?(r.delta_va||0)/1e3:0;})}))
    );
    mkBar("ch-shock-emp-groups",lbls,
      exKeys.map(k=>({label:EX_LABEL[k],backgroundColor:EX_COLOR[k],borderRadius:3,
        data:lbls.map(g=>{const r=cg.find(x=>x[col]===g&&x.exercicio===k); return r?(r.delta_emp||0)/1e3:0;})}))
    );
  }

  // Δenergy — always by exercise × source
  const fontes=[...new Set(ce.map(r=>r.fonte))];
  mkBar("ch-shock-energy",exKeys.map(k=>EX_LABEL[k]),
    fontes.map(f=>({label:f,backgroundColor:FONTE_COLORS[f]||"#888",borderRadius:2,stack:"s",
      data:exKeys.map(k=>{const r=ce.find(x=>x.exercicio===k&&x.fonte===f); return r?(r.delta_ktep||0):0;})})),
    {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}}
  );

  // Δemp labor
  const laborG=[...new Set(cl.map(r=>r.grupo_lab))];
  mkBar("ch-shock-labor",laborG,
    exKeys.map(k=>({label:EX_LABEL[k],backgroundColor:EX_COLOR[k],borderRadius:3,
      data:laborG.map(g=>{const r=cl.find(x=>x.exercicio===k&&x.grupo_lab===g); return r?(r.delta_emp||0)/1e3:0;})}))
  );

  // Top 15 ΔVA first active exercise
  const firstEx=exKeys[0];
  const exData=firstEx?(D[firstEx]||[]).filter(r=>ac.has(r.cod)):[];
  const top15VA=[...exData].sort((a,b)=>b.delta_va-a.delta_va).slice(0,15);
  mkHBar("ch-shock-ex1-sectors",top15VA.map(r=>r.cod),
    [{label:`ΔVA — ${firstEx?EX_LABEL[firstEx]:"—"}`,data:top15VA.map(r=>r.delta_va),
      backgroundColor:top15VA.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  // Ex3 vs Ex4 energy sectors
  const setE=D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);
  const ex3=(D.Choque_Ex3_Fossil||[]).filter(r=>setE.includes(r.cod));
  const ex4=(D.Choque_Ex4_Renov||[]).filter(r=>setE.includes(r.cod));
  mkBar("ch-shock-ex34-energy",setE,[
    {label:"Ex3 Fóssil -20%",data:setE.map(c=>{const r=ex3.find(x=>x.cod===c);return r?(r.delta_x||0):0;}),backgroundColor:"#E24B4A",borderRadius:3},
    {label:"Ex4 Renov +30%", data:setE.map(c=>{const r=ex4.find(x=>x.cod===c);return r?(r.delta_x||0):0;}),backgroundColor:"#1D9E75",borderRadius:3}
  ]);
}

function renderShockTable(){
  const ac =activeCodes();
  const key=document.getElementById("sel-exercise").value;
  const rows=(D[key]||[]).filter(r=>ac.has(r.cod));
  clearTbody("tbl-shock");
  const tb=document.querySelector("#tbl-shock tbody");
  rows.forEach(r=>{
    const tr=document.createElement("tr"); tr.innerHTML=
      `<td>${r.cod}</td><td>${r.nome.slice(0,32)}</td>
       <td>${grupoColorBadge(r.grupo||r.grupo_nt4)}</td>
       <td>${r.eh_energia?'<span class="tag-renov">&#9889;</span>':""}</td>
       <td style="color:${(r.delta_x||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_x||0).toFixed(1)}</td>
       <td style="color:${(r.delta_va||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_va||0).toFixed(1)}</td>
       <td style="color:${(r.delta_emp||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_emp||0).toFixed(0)}</td>
       <td>${(r.var_x_pct||0).toFixed(2)}%</td><td>${(r.var_va_pct||0).toFixed(2)}%</td>`;
    tb.appendChild(tr);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTRACTION & PURE LINKAGES (Tab 6)
// ═══════════════════════════════════════════════════════════════════════════
function initExtraction(){
  const ac  =activeCodes();
  const ext =(D.Extr_Hipotetica||[]).filter(r=>ac.has(r.cod));
  const ipl =(D.Ind_Puros||[]).filter(r=>ac.has(r.cod));
  const setE=D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);

  const blTop=[...ext].sort((a,b)=>b.BL_abs-a.BL_abs).slice(0,20);
  mkHBar("ch-extrac-bl",blTop.map(r=>r.cod),
    [{label:"BL (R$M)",data:blTop.map(r=>r.BL_abs),
      backgroundColor:blTop.map(r=>setE.includes(r.cod)?"#F39C12":gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );
  const flTop=[...ext].sort((a,b)=>b.FL_abs-a.FL_abs).slice(0,20);
  mkHBar("ch-extrac-fl",flTop.map(r=>r.cod),
    [{label:"FL (R$M)",data:flTop.map(r=>r.FL_abs),
      backgroundColor:flTop.map(r=>setE.includes(r.cod)?"#F39C12":gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}}}
  );

  const iplWrap=document.getElementById("ch-ipln");
  if(ipl.length>0&&iplWrap){
    mkXY("ch-ipln",[{label:"Setores",
      data:ipl.map(r=>({x:r.PFLN,y:r.PBLN,cod:r.cod,isE:setE.includes(r.cod)})),
      backgroundColor:ipl.map(r=>setE.includes(r.cod)?"#F39C12":alpha(gc(r.grupo),0.55)),
      pointRadius:ipl.map(r=>setE.includes(r.cod)?8:4)}],
      {plugins:{legend:{display:false},tooltip:{callbacks:{label:ctx=>`${ctx.raw.cod}: PBLN=${ctx.raw.y.toFixed(2)} PFLN=${ctx.raw.x.toFixed(2)}`}}},
       scales:{x:{...CD.scales.x,title:{display:true,text:"PFLN",color:"#8892a4"}},
               y:{...CD.scales.y,title:{display:true,text:"PBLN",color:"#8892a4"}}}}
    );
    const tb=document.querySelector("#tbl-ipln tbody");
    [...ipl].sort((a,b)=>b.PBLN-a.PBLN).forEach(r=>{
      const tr=document.createElement("tr"); tr.innerHTML=
        `<td>${r.cod}</td><td>${r.nome.slice(0,34)}</td>
         <td>${(r.PBL||0).toFixed(1)}</td><td>${(r.PFL||0).toFixed(1)}</td><td>${(r.PTL||0).toFixed(1)}</td>
         <td>${(r.PBLN||0).toFixed(3)}</td><td>${(r.PFLN||0).toFixed(3)}</td><td>${(r.PTLN||0).toFixed(3)}</td>
         <td>${grupoColorBadge(r.grupo)}</td>`;
      tb.appendChild(tr);
    });
  } else if(iplWrap){
    iplWrap.parentElement.innerHTML="<p style='color:#8892a4;text-align:center;padding:40px'>Índices puros não disponíveis (COMPUTE_SLOW=FALSE)</p>";
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOOTSTRAP
// ═══════════════════════════════════════════════════════════════════════════
buildSchemeSwitcher();
buildGroupChips();
showTab(0);
</script>
</body></html>]")

writeLines(html, HTML_OUT, useBytes = FALSE)
cat("Dashboard written:", HTML_OUT, "\n")
cat("File size:", round(file.size(HTML_OUT) / 1e3), "KB\n")
