# =============================================================================
# GENERATE DASHBOARD — MIP-EPE Energia Brasil 2018
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
cat("JSON size:", round(nchar(js_data)/1e3,1), "KB\n")

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
:root{--c-bg:#0f1117;--c-card:#1a1d27;--c-border:#2a2d3e;--c-text:#e2e8f0;
      --c-muted:#8892a4;--c-accent:#378ADD;--c-fossil:#E24B4A;--c-renov:#1D9E75;}
*{box-sizing:border-box}
body{background:var(--c-bg);color:var(--c-text);font-family:"Inter","Segoe UI",sans-serif;font-size:13px;margin:0}
/* TOP BAR */
.top-bar{background:#13151f;border-bottom:1px solid var(--c-border);padding:10px 24px;
  display:flex;align-items:center;gap:16px;position:sticky;top:0;z-index:100}
.top-bar h1{font-size:15px;font-weight:600;color:#fff;margin:0}
.top-bar span{font-size:11px;color:var(--c-muted)}
/* TABS */
nav.tabs{background:#13151f;border-bottom:1px solid var(--c-border);padding:0 24px;
  display:flex;gap:2px;overflow-x:auto;position:sticky;top:44px;z-index:99}
nav.tabs button{background:none;border:none;color:var(--c-muted);padding:9px 14px;
  font-size:12px;cursor:pointer;border-bottom:2px solid transparent;white-space:nowrap;transition:.15s}
nav.tabs button.active{color:#fff;border-bottom-color:var(--c-accent)}
nav.tabs button:hover:not(.active){color:var(--c-text)}
/* SCHEME BAR — sticky, groups the aggregation switcher */
.scheme-bar{background:#13151f;border-bottom:1px solid var(--c-border);padding:7px 24px;
  display:flex;align-items:center;gap:10px;flex-wrap:wrap;position:sticky;top:84px;z-index:98}
.scheme-label{font-size:9px;font-weight:700;color:var(--c-muted);text-transform:uppercase;letter-spacing:.1em;white-space:nowrap}
.scheme-ctrl{display:flex;border:1px solid var(--c-border);border-radius:7px;overflow:hidden}
.sch-btn{background:none;border:none;border-right:1px solid var(--c-border);
  color:var(--c-muted);padding:4px 14px;font-size:11px;font-weight:500;cursor:pointer;transition:.15s;white-space:nowrap}
.sch-btn:last-child{border-right:none}
.sch-btn.active{background:var(--c-accent);color:#fff}
.sch-btn:hover:not(.active){background:#1f2233;color:var(--c-text)}
.sch-btn:disabled{opacity:.28;cursor:not-allowed}
/* IN-CARD GROUP FILTER CHIPS */
.gf-row{display:flex;flex-wrap:wrap;gap:4px;margin-bottom:9px;min-height:20px}
.gfc{border:1px solid currentColor;padding:2px 9px;border-radius:10px;font-size:10.5px;
  font-weight:500;cursor:pointer;transition:opacity .15s,background .15s;background:transparent;white-space:nowrap}
.gfc.on{opacity:1}
.gfc:not(.on){opacity:.2;border-style:dashed}
.gfc:hover{opacity:.8!important}
/* EXERCISE FILTER */
.ex-bar{display:flex;align-items:center;gap:6px;flex-wrap:wrap;
  background:#13151f;border:1px solid var(--c-border);border-radius:7px;
  padding:7px 12px;margin-bottom:12px}
.ex-toggle{border:1px solid currentColor;padding:3px 12px;border-radius:10px;font-size:11px;
  cursor:pointer;transition:opacity .18s,background .18s;background:transparent;white-space:nowrap}
.ex-toggle.active{opacity:1}
.ex-toggle:not(.active){opacity:.22;border-style:dashed}
.ex-toggle:hover{opacity:.8!important}
/* LAYOUT */
.tab-panel{display:none;padding:18px 24px}.tab-panel.active{display:block}
.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px}
.grid-3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;margin-bottom:14px}
.grid-4{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:14px}
.full{grid-column:1/-1}
.card{background:var(--c-card);border:1px solid var(--c-border);border-radius:8px;padding:14px}
.card-title{font-size:11px;font-weight:600;color:var(--c-muted);text-transform:uppercase;
  letter-spacing:.06em;margin-bottom:8px}
.kpi{text-align:center;padding:16px 10px}
.kpi .val{font-size:24px;font-weight:700;color:#fff;line-height:1}
.kpi .lbl{font-size:11px;color:var(--c-muted);margin-top:4px}
.kpi .sub{font-size:10px;color:var(--c-muted);margin-top:2px}
.chart-wrap{position:relative;height:260px}.chart-wrap.tall{height:360px}.chart-wrap.xtall{height:480px}
/* TABLES */
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
/* ⓘ icon on every chart title; brighter + cursor:help when a definition is set */
.card-title::after{content:" ⓘ";font-size:9px;color:var(--c-muted);vertical-align:middle;opacity:.28;pointer-events:none}
.card-title[title]{cursor:help}
.card-title[title]::after{opacity:.65}
@media(max-width:900px){.grid-2,.grid-3,.grid-4{grid-template-columns:1fr}.full{grid-column:1}}
</style></head>
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
  <button onclick="showTab(5)">&#128300; Extra&ccedil;&atilde;o &amp; &Iacute;nd. Puros</button>
  <button onclick="showTab(6)">&#128293; Choques de Demanda</button>
</nav>

<!-- SCHEME BAR: controls aggregation level for all group charts -->
<div class="scheme-bar">
  <span class="scheme-label">Agrupamento:</span>
  <div class="scheme-ctrl" id="schemeCtrl"></div>
  <span style="font-size:10px;color:var(--c-muted);margin-left:6px" id="scheme-hint">Selecione o n&iacute;vel de agrupamento para todos os gr&aacute;ficos</span>
</div>

<!-- ══ TAB 0: VISÃO GERAL ═══════════════════════════════════════════════════ -->
<div class="tab-panel active" id="tab0">
  <div class="grid-3">
    <div class="card kpi"><div class="val" id="kpi-vbp">—</div><div class="lbl">VBP Total (R$ T)</div><div class="sub">grupos vis&iacute;veis</div></div>
    <div class="card kpi"><div class="val" id="kpi-va">—</div><div class="lbl">VA / PIB (R$ T)</div><div class="sub">grupos vis&iacute;veis</div></div>
    <div class="card kpi"><div class="val" id="kpi-emp">—</div><div class="lbl">Ocupados (M)</div><div class="sub">grupos vis&iacute;veis</div></div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="ttl-vbp-group">VBP por Grupo (R$ bilh&otilde;es)</div>
      <div class="gf-row" id="gf-ch-vbp-group"></div>
      <div class="chart-wrap"><canvas id="ch-vbp-group"></canvas></div>
    </div>
    <div class="card"><div class="card-title">Comparativo de Choques — &Delta;VA (R$ bi)</div>
      <div class="chart-wrap"><canvas id="ch-shock-va"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 12 MP — setores activos</div>
      <div class="chart-wrap"><canvas id="ch-mp-top"></canvas></div></div>
    <div class="card"><div class="card-title">Resumo dos Exerc&iacute;cios de Choque</div>
      <table class="dt" id="tbl-shock-summary"><thead><tr>
        <th>Exerc&iacute;cio</th><th>&Delta;X (bi)</th><th>&Delta;VA (bi)</th><th>&Delta;Emp (mil)</th><th>&Delta;E (ktep)</th>
      </tr></thead><tbody></tbody></table></div>
  </div>
</div>

<!-- ══ TAB 1: ESTRUTURA ECONÓMICA ══════════════════════════════════════════ -->
<div class="tab-panel" id="tab1">
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="ttl-va-decomp">Valor Adicionado por Grupo (R$ bi)</div>
      <div class="chart-wrap"><canvas id="ch-va-decomp"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title" id="ttl-emp-group">Pessoal Ocupado por Grupo (milh&otilde;es)</div>
      <div class="chart-wrap"><canvas id="ch-emp-group"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="ttl-df-group">Demanda Final por Componente e Grupo (R$ bi)</div>
      <div class="chart-wrap"><canvas id="ch-df-group"></canvas></div>
    </div>
    <div class="card"><div class="card-title">Top 15 Setores por VBP</div>
      <div class="chart-wrap"><canvas id="ch-vbp-top"></canvas></div></div>
  </div>
  <div class="card" style="margin-bottom:14px">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Todos os Setores — Indicadores de Base</div>
      <input class="search-box" placeholder="Buscar setor..." oninput="filterTable('tbl-baseline',this.value)">
    </div>
    <div style="overflow-x:auto;max-height:360px;overflow-y:auto">
      <table class="dt" id="tbl-baseline"><thead><tr>
        <th onclick="sortTable('tbl-baseline',0)">C&oacute;d</th>
        <th onclick="sortTable('tbl-baseline',1)">Setor</th>
        <th onclick="sortTable('tbl-baseline',2)">Grupo</th>
        <th onclick="sortTable('tbl-baseline',3)">VBP</th>
        <th onclick="sortTable('tbl-baseline',4)">VA/PIB</th>
        <th onclick="sortTable('tbl-baseline',5)">Remuner.</th>
        <th onclick="sortTable('tbl-baseline',6)">Sal&aacute;rios</th>
        <th onclick="sortTable('tbl-baseline',7)">EOB</th>
        <th onclick="sortTable('tbl-baseline',8)">Ocupa&ccedil;&otilde;es</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ══ TAB 2: MULTIPLICADORES ═══════════════════════════════════════════════ -->
<div class="tab-panel" id="tab2">
  <div class="grid-2">
    <div class="card full"><div class="card-title">Multiplicadores de Produ&ccedil;&atilde;o — todos os setores activos (MP, ordenado)</div>
      <div class="chart-wrap xtall"><canvas id="ch-mp-all"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">MP vs MPT vs MPTT — Setores Energ&eacute;ticos</div>
      <div class="chart-wrap tall"><canvas id="ch-mp-energy"></canvas></div></div>
    <div class="card"><div class="card-title">Multiplicadores de Emprego — Energ&eacute;ticos</div>
      <div class="chart-wrap tall"><canvas id="ch-me-energy"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Efeito Direto vs Indireto vs Induzido (Top 15)</div>
      <div class="chart-wrap"><canvas id="ch-mp-decomp"></canvas></div></div>
    <div class="card"><div class="card-title">Multiplicadores de Renda — Energ&eacute;ticos</div>
      <div class="chart-wrap"><canvas id="ch-mr-energy"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Tabela de Multiplicadores (setores activos)</div>
      <input class="search-box" placeholder="Buscar setor..." oninput="filterTable('tbl-mult',this.value)">
    </div>
    <div style="overflow-x:auto;max-height:340px;overflow-y:auto">
      <table class="dt" id="tbl-mult"><thead><tr>
        <th onclick="sortTable('tbl-mult',0)">C&oacute;d</th><th onclick="sortTable('tbl-mult',1)">Setor</th>
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

<!-- ══ TAB 3: ÍNDICES DE LIGAÇÃO ════════════════════════════════════════════ -->
<div class="tab-panel" id="tab3">
  <div class="grid-2">
    <div class="card full"><div class="card-title">Rasmussen-Hirschman (BL &times; FLG) — todos os setores</div>
      <div class="chart-wrap tall"><canvas id="ch-rasmussen"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 20 BL (Ligação para Trás)</div>
      <div class="chart-wrap"><canvas id="ch-bl-top"></canvas></div></div>
    <div class="card"><div class="card-title">Top 20 FLG (Ligação para Frente)</div>
      <div class="chart-wrap"><canvas id="ch-flg-top"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Distribui&ccedil;&atilde;o por Quadrante</div>
      <div class="chart-wrap" style="height:240px"><canvas id="ch-quadrant-pie"></canvas></div></div>
    <div class="card"><div class="card-title">Coeficientes de Varia&ccedil;&atilde;o (Vj &times; Vi)</div>
      <div class="chart-wrap"><canvas id="ch-cv-scatter"></canvas></div></div>
  </div>
</div>

<!-- ══ TAB 4: ENERGIA ═══════════════════════════════════════════════════════ -->
<div class="tab-panel" id="tab4">
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="ttl-e-group">Energia por Fonte e Grupo (ktep)</div>
      <div class="gf-row" id="gf-ch-e-group"></div>
      <div class="chart-wrap"><canvas id="ch-e-group"></canvas></div>
    </div>
    <div class="card"><div class="card-title">Fontes Energ&eacute;ticas — totais (ktep)</div>
      <div class="chart-wrap" style="height:260px"><canvas id="ch-e-pie"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 15 Setores por Consumo Total (ktep)</div>
      <div class="chart-wrap"><canvas id="ch-e-top-sectors"></canvas></div></div>
    <div class="card"><div class="card-title">Intensidade Energ&eacute;tica — Setores Energ&eacute;ticos (ktep/R$M)</div>
      <div class="chart-wrap"><canvas id="ch-alpha-energy"></canvas></div></div>
  </div>
</div>

<!-- ══ TAB 5: CHOQUES ═══════════════════════════════════════════════════════ -->
<div class="tab-panel" id="tab6">
  <div class="ex-bar">
    <span class="scheme-label">Exerc&iacute;cios:</span>
    <div id="exToggles" style="display:flex;gap:5px;flex-wrap:wrap"></div>
    <button style="background:none;border:1px dashed var(--c-border);color:var(--c-muted);padding:2px 9px;border-radius:10px;font-size:11px;cursor:pointer;margin-left:4px" onclick="resetExercises()">&#10005; Todos</button>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title" id="ttl-shock-va">&Delta;Valor Adicionado por Grupo (R$ bi)</div>
      <div class="gf-row" id="gf-ch-shock-va-groups"></div>
      <div class="chart-wrap tall"><canvas id="ch-shock-va-groups"></canvas></div>
    </div>
    <div class="card">
      <div class="card-title" id="ttl-shock-emp">&Delta;Emprego por Grupo (mil pessoas)</div>
      <div class="gf-row" id="gf-ch-shock-emp-groups"></div>
      <div class="chart-wrap tall"><canvas id="ch-shock-emp-groups"></canvas></div>
    </div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">&Delta;Energia por Fonte (ktep)</div>
      <div class="chart-wrap"><canvas id="ch-shock-energy"></canvas></div></div>
    <div class="card"><div class="card-title">&Delta;Emprego por Categoria</div>
      <div class="chart-wrap"><canvas id="ch-shock-labor"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card"><div class="card-title">Top 15 Setores &Delta;VA — 1&ordm; exerc&iacute;cio activo</div>
      <div class="chart-wrap"><canvas id="ch-shock-ex1-sectors"></canvas></div></div>
    <div class="card"><div class="card-title">Ex3 vs Ex4 — Setores Energ&eacute;ticos &Delta;Produ&ccedil;&atilde;o</div>
      <div class="chart-wrap"><canvas id="ch-shock-ex34-energy"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">Detalhamento Setorial</div>
      <div style="display:flex;gap:8px">
        <select class="sel-ex" id="sel-exercise" onchange="renderShockTable()">
          <option value="Choque_Ex1_NT">Ex1: +5% Exporta&ccedil;&otilde;es</option>
          <option value="Choque_Ex2_NT">Ex2: +5% Fam&iacute;lias S40</option>
          <option value="Choque_Ex3_Fossil">Ex3: Cont. F&oacute;ssil</option>
          <option value="Choque_Ex4_Renov">Ex4: Exp. Renov&aacute;vel</option>
          <option value="Choque_Ex5_Trans">Ex5: Transi&ccedil;&atilde;o</option>
        </select>
        <input class="search-box" placeholder="Buscar setor..." oninput="filterTable('tbl-shock',this.value)">
      </div>
    </div>
    <div style="overflow-x:auto;max-height:340px;overflow-y:auto">
      <table class="dt" id="tbl-shock"><thead><tr>
        <th onclick="sortTable('tbl-shock',0)">C&oacute;d</th><th onclick="sortTable('tbl-shock',1)">Setor</th>
        <th onclick="sortTable('tbl-shock',2)">Grupo</th><th>&#9889;</th>
        <th onclick="sortTable('tbl-shock',4)">&Delta;X (R$M)</th><th onclick="sortTable('tbl-shock',5)">&Delta;VA (R$M)</th>
        <th onclick="sortTable('tbl-shock',6)">&Delta;Emp</th><th onclick="sortTable('tbl-shock',7)">Var% X</th>
        <th onclick="sortTable('tbl-shock',8)">Var% VA</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>
</div>

<!-- ══ TAB 5: EXTRAÇÃO ══════════════════════════════════════════════════════ -->
<div class="tab-panel" id="tab5">
  <div class="grid-2">
    <div class="card"><div class="card-title">Extra&ccedil;&atilde;o Hipot&eacute;tica — Top 20 BL (demanda)</div>
      <div class="chart-wrap"><canvas id="ch-extrac-bl"></canvas></div></div>
    <div class="card"><div class="card-title">Extra&ccedil;&atilde;o Hipot&eacute;tica — Top 20 FL (oferta)</div>
      <div class="chart-wrap"><canvas id="ch-extrac-fl"></canvas></div></div>
  </div>
  <div class="grid-2">
    <div class="card full"><div class="card-title">PBLN &times; PFLN — &Iacute;ndices Puros Normalizados</div>
      <div class="chart-wrap tall"><canvas id="ch-ipln"></canvas></div></div>
  </div>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
      <div class="card-title" style="margin:0">&Iacute;ndices Puros de Liga&ccedil;&atilde;o</div>
      <input class="search-box" placeholder="Buscar..." oninput="filterTable('tbl-ipln',this.value)">
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
// ════════════════════════════════════════════════════════════════════════════
// DATA
// ════════════════════════════════════════════════════════════════════════════
const D = ]", js_data, r"[;

// ════════════════════════════════════════════════════════════════════════════
// COLOURS
// ════════════════════════════════════════════════════════════════════════════
const NAMED = {
  Agropecuaria:"#3B6D11",Ind_Extrativa:"#888780",Energia_Fossil:"#E24B4A",
  Energia_Renov:"#1D9E75",Ind_Transform:"#378ADD",Infraestrutura:"#534AB7",Servicos:"#B4B2A9",
  Energeticos:"#F39C12",Industria:"#378ADD",Industrias:"#378ADD",Agro:"#3B6D11"
};
const FONTE_C={Derivados:"#E24B4A",Biodiesel:"#1D9E75",Etanol:"#3B6D11",
  EE_Central:"#F39C12",EE_Distrib:"#F8C471",Gas_Natural:"#8E44AD"};
const EX_COLOR={"Choque_Ex1_NT":"#378ADD","Choque_Ex2_NT":"#888780",
  "Choque_Ex3_Fossil":"#E24B4A","Choque_Ex4_Renov":"#1D9E75","Choque_Ex5_Trans":"#F39C12"};
const EX_LABEL={"Choque_Ex1_NT":"+5% Exportações","Choque_Ex2_NT":"+5% Famílias S40",
  "Choque_Ex3_Fossil":"Fóssil -20%","Choque_Ex4_Renov":"Renov +30%","Choque_Ex5_Trans":"Transição"};
const ALL_EX=["Choque_Ex1_NT","Choque_Ex2_NT","Choque_Ex3_Fossil","Choque_Ex4_Renov","Choque_Ex5_Trans"];

// Map sheet-key → exercicio string used in aggregated sheets (Choques_Grupos, Choques_Energia, Choques_Labor)
// The aggregated sheets store long descriptive strings; sector-level sheets use the sheet key as the name.
const _cgExStr=[...new Set((D.Choques_Grupos||[]).map(r=>r.exercicio))];
const EX_STR=Object.fromEntries(ALL_EX.map((k,i)=>[k,_cgExStr[i]||k]));

function hashColor(s){let h=0;for(let i=0;i<s.length;i++)h=s.charCodeAt(i)+((h<<5)-h);return `hsl(${Math.abs(h)%360},48%,52%)`;}
function gc(g){return NAMED[g]||hashColor(g||"");}
function alpha(hex,a){
  if(!hex||hex.startsWith("hsl"))return (hex||"#888").replace(/\)$/,`,${a})`).replace("hsl","hsla");
  const r=parseInt(hex.slice(1,3),16),g=parseInt(hex.slice(3,5),16),b=parseInt(hex.slice(5,7),16);
  return `rgba(${r},${g},${b},${a})`;}
function fmtN(v,d=2){return v==null?"—":Number(v).toFixed(d);}

// full name lookup
function secName(cod){const s=D.Setores.find(x=>x.cod===cod);return s?s.nome:cod;}

// Short definitions shown as a second tooltip line for known indicator labels
const IND_DEF={
  // Production multipliers
  "MP"   :"Multiplicador de Produção: impacto total na produção da economia por R$1 de demanda final",
  "MPT"  :"MP Truncado: efeito direto + indireto (sem induzido de renda)",
  "MPTT" :"MP Tipo I: apenas efeitos direto e indireto intra-setoriais",
  // Employment multipliers
  "ME"   :"Multiplicador de Emprego: total de empregos gerados por R$1M de demanda final",
  "MEI"  :"ME Tipo I: empregos diretos e indiretos (sem efeitos induzidos)",
  "MET"  :"ME Total (Tipo II): inclui efeitos induzidos via renda das famílias",
  "MEII" :"ME Tipo II estendido: inclui efeitos de renda e consumo",
  // Income multipliers
  "MR"   :"Multiplicador de Renda: renda das famílias gerada por R$1M de demanda final",
  "MRI"  :"MR Tipo I: renda direta e indireta (sem induzida)",
  "MRT"  :"MR Total (Tipo II): inclui efeitos induzidos de consumo das famílias",
  "MRII" :"MR Tipo II estendido: inclui efeitos de segunda ordem",
  // Linkage indices
  "BL (R$M)":"Backward Linkage hipotético: perda de produção total se o setor fosse eliminado (demanda por insumos)",
  "FL (R$M)":"Forward Linkage hipotético: perda de produção total se o setor fosse eliminado (oferta para outros)",
  // Value added components
  "VA/PIB"  :"Valor Adicionado: remuneração dos fatores (salários + EOB + outros) gerada na produção (R$ bi)",
  "Salários":"Salários e rendimentos pagos aos trabalhadores do setor (R$ bi)",
  "EOB"     :"Excedente Operacional Bruto: lucros e rendas do capital antes da depreciação (R$ bi)",
  // Final demand components
  "Export"    :"Exportações: demanda externa pelo produto do setor (R$ bi)",
  "Gov"       :"Consumo do Governo: compras governamentais de bens e serviços finais (R$ bi)",
  "ISFLSF"    :"ISFLSF: consumo das Instituições Sem Fins Lucrativos a Serviço das Famílias (R$ bi)",
  "Families"  :"Consumo das Famílias: demanda das famílias por bens e serviços finais (R$ bi)",
  "GFCF"      :"FBCF — Formação Bruta de Capital Fixo: investimento em ativos fixos (R$ bi)",
  "DeltaStock":"Variação de Estoques: mudança no nível de inventários (R$ bi)",
  // Production / occupation
  "VBP (R$ bi)" :"Valor Bruto da Produção: valor total dos bens e serviços gerados pelo setor (R$ bi)",
  "Ocupações (M)":"Total de ocupações (empregos formais + informais) — dado absoluto em milhões",
  "Ocupações (mil)":"Total de ocupações (empregos formais + informais) — em milhares"
};
// tooltip callback: show full sector name + indicator definition
const TIP_SECTOR = {callbacks:{
  title: ctx=>{const c=ctx[0]?.label; const s=D.Setores.find(x=>x.cod===c); return s?`${c} — ${s.nome}`:c;},
  label: ctx=>{
    const lbl=ctx.dataset.label||"";
    const val=typeof ctx.raw==="number"?ctx.raw.toFixed(2):String(ctx.raw??"-");
    const def=IND_DEF[lbl];
    return def?[`${lbl}: ${val}`,`ⓘ ${def}`]:`${lbl}: ${val}`;
  }
}};

// ════════════════════════════════════════════════════════════════════════════
// GROUPING SCHEMES
// ════════════════════════════════════════════════════════════════════════════
const _s0=D.Setores[0]||{};
const SCHEMES=[
  {id:"nt4",  col:"grupo_nt4",  label:"NT4",       ok:"grupo_nt4" in _s0},
  {id:"7g",   col:"grupo",      label:"7 Grupos",  ok:"grupo"     in _s0},
  {id:"ibge", col:"grupo_ibge", label:"IBGE",      ok:"grupo_ibge"in _s0},
  {id:"sec",  col:"cod",        label:"73 Setores",ok:true}
];
const STATE={schemeId:"7g", exercises:new Set(ALL_EX), tab:0, filterVer:1, builtVer:{}};

function sch(){return SCHEMES.find(s=>s.id===STATE.schemeId)||SCHEMES[1];}
function scCol(){return sch().col;}
function isSec(){return STATE.schemeId==="sec";}

// unique labels for current scheme in a dataset
function schLabels(data){
  const col=scCol();
  return [...new Set(data.map(r=>r[col]).filter(x=>x!=null&&x!==""))];
}
// aggregate a numeric field by scheme labels
function aggBy(data,field,labels){
  const col=scCol();
  return labels.map(lbl=>data.filter(r=>r[col]===lbl).reduce((s,r)=>s+(Number(r[field])||0),0));
}
// colour list for a label array
function lblColors(lbls){return lbls.map(l=>gc(l));}

// Enrich any sector-level data with group columns from D.Setores.
// Baseline / Demanda_Final may not carry grupo_nt4 / grupo_ibge — look them up.
const _SMAP=(()=>{const m={};D.Setores.forEach(s=>{m[s.cod]=s;});return m;})();
function enrich(data){
  return data.map(r=>{
    const s=_SMAP[r.cod]||{};
    // spread Setores fields first so row's own columns (e.g. grupo) take precedence
    return Object.assign({grupo:s.grupo,grupo_nt4:s.grupo_nt4,grupo_ibge:s.grupo_ibge},r);
  });
}

// Custom Chart.js legend for single-dataset per-bar-color charts.
// position:"top" keeps the legend above the bars.
// fontColor is set both globally (labels.color) AND per-item (Chart.js 4 uses both).
function makeColorLegend(lbls,colors,position="top"){
  return {display:true,position,labels:{
    generateLabels:()=>lbls.map((l,i)=>({
      text:l.replace(/_/g," "),
      fillStyle:colors[i],strokeStyle:colors[i],lineWidth:0,hidden:false,
      fontColor:"#e2e8f0"
    })),
    color:"#e2e8f0",font:{size:11},boxWidth:12,padding:10
  }};
}

// Smart group legend: all-energy groups are shown in orange with ⚡ prefix;
// avoids duplicating "⚡ Energia" when the scheme already groups energy together.
function buildGroupLegend(rows,grpC,setES,pos="top"){
  const grps=[...new Set(rows.map(r=>r[grpC]).filter(Boolean))];
  const lbls=[],cols=[];
  let mixedE=false;
  grps.forEach(g=>{
    const inG=rows.filter(r=>r[grpC]===g);
    if(inG.length>0&&inG.every(r=>setES.has(r.cod))){
      lbls.push("⚡ "+g.replace(/_/g," ")); cols.push("#F39C12");
    } else {
      lbls.push(g); cols.push(gc(g));
      if(inG.some(r=>setES.has(r.cod))) mixedE=true;
    }
  });
  if(mixedE){lbls.push("⚡ Energia"); cols.push("#F39C12");}
  return makeColorLegend(lbls,cols,pos);
}

// ════════════════════════════════════════════════════════════════════════════
// CHART REGISTRY
// ════════════════════════════════════════════════════════════════════════════
const CHARTS={};
function destChart(id){if(CHARTS[id]){CHARTS[id].destroy();delete CHARTS[id];}}
const CD={responsive:true,maintainAspectRatio:false,
  plugins:{legend:{labels:{color:"#8892a4",font:{size:11}}}},
  scales:{x:{ticks:{color:"#8892a4",font:{size:10}},grid:{color:"#1f2233"}},
          y:{ticks:{color:"#8892a4",font:{size:10}},grid:{color:"#1f2233"}}}};
function mkBar(id,labels,datasets,opts={}){
  destChart(id);const el=document.getElementById(id);if(!el)return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"bar",data:{labels,datasets},options:Object.assign({},CD,opts)});
  return CHARTS[id];}
function mkHBar(id,labels,datasets,opts={}){
  destChart(id);const el=document.getElementById(id);if(!el)return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"bar",data:{labels,datasets},options:Object.assign({},CD,{indexAxis:"y"},opts)});
  return CHARTS[id];}
function mkXY(id,datasets,opts={}){
  destChart(id);const el=document.getElementById(id);if(!el)return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"scatter",data:{datasets},options:Object.assign({},CD,opts)});
  return CHARTS[id];}
function mkDoughnut(id,labels,data,colors){
  destChart(id);const el=document.getElementById(id);if(!el)return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"doughnut",
    data:{labels,datasets:[{data,backgroundColor:colors,borderWidth:1,borderColor:"#0f1117"}]},
    options:{responsive:true,maintainAspectRatio:false,
      plugins:{legend:{position:"right",labels:{color:"#8892a4",font:{size:11}}}}}});
  return CHARTS[id];}
function clrTbody(id){const t=document.querySelector("#"+id+" tbody");if(t)t.innerHTML="";}
function clrTabTbls(n){document.querySelectorAll(`#tab${n} table.dt tbody`).forEach(t=>t.innerHTML="");}

// Static chart-title definitions (text-fragment → definition).
// Applied at bootstrap by scanning all .card-title elements.
const STATIC_DEFS={
  "Comparativo de Choques":"ΔVA por exercício: compara os efeitos macroeconômicos de cada cenário simulado de demanda.",
  "Top 12 MP":"12 setores com maior Multiplicador de Produção — geram mais produção agregada por R$1 de demanda final.",
  "Resumo dos Exerc":"Tabela-resumo dos 5 exercícios: impacto em produção, VA, emprego e energia por cenário.",
  "Top 15 Setores por VBP":"Os 15 maiores setores em Valor Bruto da Produção (R$ bi).",
  "Indicadores de Base":"Tabela completa com VBP, VA/PIB, salários, EOB e ocupações por setor.",
  "Multiplicadores de Produ":"MP ordenado: impacto total na produção de toda a economia por R$1 de demanda final.",
  "MP vs MPT vs MPTT":"Decomposição do multiplicador de produção em Tipo I, Truncado e Total — setores energéticos.",
  "Multiplicadores de Emprego":"ME, MEI e MET: empregos gerados por R$1M de demanda final nos setores energéticos.",
  "Efeito Direto vs Indireto":"Decomposição do MP em efeitos direto, indireto e induzido para os top-15 setores.",
  "Multiplicadores de Renda":"MR, MRI e MRT: renda das famílias gerada por R$1M de demanda final — setores energéticos.",
  "Tabela de Multiplicadores":"Tabela completa de MP, ME e MR para todos os setores activos.",
  "Rasmussen-Hirschman":"Diagrama BL × FLG: setores-chave têm BL>1 e FLG>1, sendo centrais nas cadeias produtivas.",
  "Top 20 BL":"20 maiores Backward Linkages — poder de arrastar outros setores via demanda por insumos.",
  "Top 20 FLG":"20 maiores Forward Linkages (Ghosh) — poder de oferta para outros setores.",
  "Distribui":"Proporção de setores por quadrante no diagrama Rasmussen-Hirschman.",
  "Coeficientes de Varia":"Vi (coluna) e Vj (linha): dispersão dos coeficientes de ligação — dependência estrutural.",
  "Fontes Energ":"Participação de cada fonte energética no consumo intermediário total (ktep).",
  "Top 15 Setores por Consumo":"Maiores consumidores de energia intermediária, por fonte (ktep).",
  "Intensidade Energ":"Alpha (ktep/R$M): consumo de energia por unidade de produto — eficiência energética setorial.",
  "Energia por Fonte":"Consumo energético intermediário por fonte e agrupamento (ktep).",
  "ΔEnergia por Fonte":"Variação no consumo energético por fonte de energia em resposta a cada choque (ktep).",
  "ΔEmprego por Categoria":"Variação nas ocupações por categoria laboral (formal/informal, gênero, escolaridade).",
  "Top 15 Setores ΔVA":"Setores com maior variação de Valor Adicionado no primeiro exercício activo.",
  "Ex3 vs Ex4":"Comparação do impacto na produção dos setores energéticos: contração fóssil vs expansão renovável.",
  "Detalhamento Setorial":"Tabela com impacto setorial detalhado (ΔX, ΔVA, ΔEmp) para o exercício selecionado.",
  "Extração Hipotética — Top 20 BL":"BL hipotético: perda de produção estimada se o setor fosse retirado da economia (demanda).",
  "Extração Hipotética — Top 20 FL":"FL hipotético: perda de produção estimada se o setor fosse retirado como fornecedor (oferta).",
  "PBLN":"PBLN × PFLN: Índices Puros Normalizados — PBLN mede poder de demanda; PFLN poder de oferta.",
  "Índices Puros":"Tabela completa de Índices Puros de Ligação: PBL, PFL, PTL e versões normalizadas por setor."
};

// Dynamic chart-title definitions (shown as native browser tooltip on hover)
const CARD_DEFS={
  "ttl-vbp-group":"VBP — Valor Bruto da Produção: valor total dos bens e serviços gerados por grupo (R$ bi).",
  "ttl-va-decomp":"VA/PIB — Valor Adicionado: renda gerada na produção, decomposta em Salários, EOB e outros (R$ bi).",
  "ttl-emp-group":"Ocupações: total de empregos formais e informais por grupo/setor (valores absolutos em milhões).",
  "ttl-df-group":"Demanda Final: componentes da absorção — Exportações, Famílias, Governo, ISFLSF, FBCF e Var. de Estoques (R$ bi).",
  "ttl-shock-va":"ΔVA — variação do Valor Adicionado induzida pelo choque de demanda final simulado (R$ bi).",
  "ttl-shock-emp":"ΔEmprego — variação no número de ocupações induzida pelo choque de demanda (mil pessoas)."
};
function setTtl(id,txt){
  const e=document.getElementById(id);if(!e)return;
  e.textContent=txt;
  // restore definition tooltip (cleared by textContent assignment)
  if(CARD_DEFS[id])e.title=CARD_DEFS[id];
}

// ════════════════════════════════════════════════════════════════════════════
// IN-CARD GROUP FILTER  — the key UX feature
// Call after mkBar/mkHBar for any chart where groups are on the x-axis.
// Renders coloured chips inside the .gf-row div; clicking toggles that bar.
// ════════════════════════════════════════════════════════════════════════════
function attachGroupFilter(chartId, labels, colors){
  const ch=CHARTS[chartId]; if(!ch) return;
  const row=document.getElementById("gf-"+chartId); if(!row) return;
  row.innerHTML="";
  // store originals on the chart object (safe to re-call on rebuild)
  ch._origLabels=[...ch.data.labels];
  ch.data.datasets.forEach(ds=>{ds._orig=[...ds.data];});
  const active=new Set(labels);

  labels.forEach((lbl,i)=>{
    const c=colors?colors[i]:gc(lbl);
    const btn=document.createElement("button");
    btn.className="gfc on";
    btn.style.color=c; btn.style.borderColor=c; btn.style.background=alpha(c,0.15);
    btn.textContent=lbl.replace(/_/g," ");
    btn.title=lbl;
    btn.onclick=()=>{
      if(active.has(lbl)){if(active.size<=1)return; active.delete(lbl);}
      else active.add(lbl);
      const on=active.has(lbl);
      btn.className="gfc"+(on?" on":"");
      btn.style.background=on?alpha(c,0.15):"transparent";
      btn.style.opacity=on?"1":"0.2";
      // update chart in-place (no destroy/rebuild needed)
      const idx=ch._origLabels.map((l,j)=>active.has(l)?j:-1).filter(j=>j>=0);
      ch.data.labels=idx.map(j=>ch._origLabels[j]);
      ch.data.datasets.forEach(ds=>{ds.data=idx.map(j=>ds._orig[j]);});
      ch.update("active");
    };
    row.appendChild(btn);
  });
}

// ════════════════════════════════════════════════════════════════════════════
// SCHEME SWITCHER
// ════════════════════════════════════════════════════════════════════════════
function buildSchemeSwitcher(){
  const ctrl=document.getElementById("schemeCtrl"); ctrl.innerHTML="";
  SCHEMES.forEach(s=>{
    const b=document.createElement("button");
    b.id="sch-"+s.id; b.className="sch-btn"+(s.id===STATE.schemeId?" active":"");
    b.textContent=s.label;
    if(!s.ok){b.disabled=true; b.title="Coluna não disponível nos dados";}
    else b.onclick=()=>onSchemeChange(s.id);
    ctrl.appendChild(b);
  });
}
function onSchemeChange(id){
  STATE.schemeId=id;
  SCHEMES.forEach(s=>{const b=document.getElementById("sch-"+s.id);if(b)b.classList.toggle("active",s.id===id);});
  onFilterChange();
}

// ════════════════════════════════════════════════════════════════════════════
// EXERCISE TOGGLES
// ════════════════════════════════════════════════════════════════════════════
function buildExToggles(){
  const c=document.getElementById("exToggles");if(!c)return; c.innerHTML="";
  ALL_EX.forEach(k=>{
    const col=EX_COLOR[k],on=STATE.exercises.has(k);
    const b=document.createElement("button");
    b.id="xt-"+k; b.className="ex-toggle"+(on?" active":"");
    b.style.color=col; b.style.borderColor=col; if(on)b.style.background=alpha(col,0.15);
    b.textContent=EX_LABEL[k]; b.onclick=()=>toggleEx(k);
    c.appendChild(b);
  });
}
function toggleEx(k){
  if(STATE.exercises.has(k)){if(STATE.exercises.size<=1)return;STATE.exercises.delete(k);}
  else STATE.exercises.add(k);
  const on=STATE.exercises.has(k); const col=EX_COLOR[k];
  const b=document.getElementById("xt-"+k); if(!b)return;
  b.className="ex-toggle"+(on?" active":"");
  b.style.background=on?alpha(col,0.15):"transparent"; b.style.opacity=on?"1":"0.22";
  rebuildShockCharts(); renderShockTable();
}
function resetExercises(){ALL_EX.forEach(k=>STATE.exercises.add(k)); buildExToggles(); rebuildShockCharts(); renderShockTable();}
function activeEx(){return ALL_EX.filter(k=>STATE.exercises.has(k));}

// ════════════════════════════════════════════════════════════════════════════
// TAB NAV & LAZY REBUILD
// ════════════════════════════════════════════════════════════════════════════
const INITS=[initOverview,initBaseline,initMultipliers,initLinkages,initEnergy,initExtraction,initShocks];
function showTab(n){
  document.querySelectorAll(".tab-panel").forEach((p,i)=>p.classList.toggle("active",i===n));
  document.querySelectorAll("#mainTabs button").forEach((b,i)=>b.classList.toggle("active",i===n));
  STATE.tab=n;
  if(!(n in STATE.builtVer)||STATE.builtVer[n]!==STATE.filterVer){
    clrTabTbls(n); INITS[n](); STATE.builtVer[n]=STATE.filterVer;
  }
}
function onFilterChange(){
  STATE.filterVer++;
  clrTabTbls(STATE.tab); INITS[STATE.tab](); STATE.builtVer[STATE.tab]=STATE.filterVer;
}

// ════════════════════════════════════════════════════════════════════════════
// TABLE UTILITIES
// ════════════════════════════════════════════════════════════════════════════
function filterTable(id,q){
  const rows=document.querySelectorAll("#"+id+" tbody tr"),lq=q.toLowerCase();
  rows.forEach(r=>r.style.display=r.textContent.toLowerCase().includes(lq)?"":"none");
}
let sDir={};
function sortTable(id,col){
  const tb=document.getElementById(id);
  const rows=Array.from(tb.querySelectorAll("tbody tr"));
  const asc=(sDir[id+col]=!sDir[id+col]);
  rows.sort((a,b)=>{const va=a.cells[col].textContent.trim(),vb=b.cells[col].textContent.trim();
    const na=parseFloat(va),nb=parseFloat(vb);
    if(!isNaN(na)&&!isNaN(nb))return asc?na-nb:nb-na; return asc?va.localeCompare(vb):vb.localeCompare(va);});
  rows.forEach(r=>tb.querySelector("tbody").appendChild(r));
}
function badge(g){const c=gc(g);return `<span class="badge-g" style="background:${alpha(c,0.22)};color:${c}">${g||"—"}</span>`;}

// ════════════════════════════════════════════════════════════════════════════
// OVERVIEW (Tab 0)
// ════════════════════════════════════════════════════════════════════════════
function initOverview(){
  const bl=enrich(D.Baseline); const sr=D.Choques_Resumo;
  const tot=(f)=>bl.reduce((s,r)=>s+(r[f]||0),0);
  document.getElementById("kpi-vbp").textContent=(tot("vbp")/1e6).toFixed(2)+" T";
  document.getElementById("kpi-va").textContent =(tot("va_pib")/1e6).toFixed(2)+" T";
  document.getElementById("kpi-emp").textContent=(tot("ocupacoes")/1e6).toFixed(1)+" M";

  const s=sch(); const sec=isSec();
  setTtl("ttl-vbp-group","VBP por "+(sec?"Setor (top 30)":s.label)+" (R$ bi)");

  if(sec){
    const top=[...bl].sort((a,b)=>b.vbp-a.vbp).slice(0,30);
    mkHBar("ch-vbp-group",top.map(r=>r.cod),
      [{label:"VBP (R$ bi)",data:top.map(r=>r.vbp/1e3),backgroundColor:top.map(r=>gc(r.grupo)),borderRadius:3}],
      {plugins:{...CD.plugins,legend:{display:false},tooltip:TIP_SECTOR}});
  } else {
    const lbls=schLabels(bl);
    mkBar("ch-vbp-group",lbls,
      [{label:"VBP (R$ bi)",data:aggBy(bl,"vbp",lbls).map(v=>v/1e3),backgroundColor:lblColors(lbls),borderRadius:4}],
      {plugins:{...CD.plugins,legend:{display:false}}});
    attachGroupFilter("ch-vbp-group",lbls,lblColors(lbls));
  }

  mkBar("ch-shock-va",sr.map(r=>r.exercicio.slice(0,28)),
    [{label:"ΔVA (R$ bi)",data:sr.map(r=>r.dVA_bi),
      backgroundColor:sr.map(r=>r.dVA_bi>=0?"#1D9E75":"#E24B4A"),borderRadius:4}],
    {plugins:{...CD.plugins,legend:{display:false}}});

  const mp=[...D.Mult_Producao].sort((a,b)=>b.MP-a.MP).slice(0,12);
  mkHBar("ch-mp-top",mp.map(r=>r.cod),
    [{label:"MP",data:mp.map(r=>r.MP),backgroundColor:mp.map(r=>gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:TIP_SECTOR},
     scales:{x:{...CD.scales.x,min:1},y:CD.scales.y}});

  clrTbody("tbl-shock-summary");
  const tb=document.querySelector("#tbl-shock-summary tbody");
  sr.forEach(r=>{const tr=document.createElement("tr");tr.innerHTML=
    `<td>${r.exercicio}</td><td>${(r.dx_bi||0).toFixed(1)}</td><td>${(r.dVA_bi||0).toFixed(1)}</td><td>${(r.demp_mil||0).toFixed(1)}</td><td>${(r.dE_ktep||0).toFixed(0)}</td>`;
    tb.appendChild(tr);});
}

// ════════════════════════════════════════════════════════════════════════════
// BASELINE (Tab 1)
// ════════════════════════════════════════════════════════════════════════════
function initBaseline(){
  const bl=enrich(D.Baseline); const dfAll=enrich(D.Demanda_Final);
  const s=sch(); const sec=isSec(); const sfx=sec?" (top 20)":" ("+s.label+")";
  setTtl("ttl-va-decomp","Valor Adicionado por Grupo"+sfx);
  setTtl("ttl-emp-group","Pessoal Ocupado por Grupo"+sfx+" (milhões)");
  setTtl("ttl-df-group", "Demanda Final por Componente"+sfx);

  if(sec){
    const topVA=[...bl].sort((a,b)=>b.va_pib-a.va_pib).slice(0,20);
    mkBar("ch-va-decomp",topVA.map(r=>r.cod),[
      {label:"VA/PIB",  data:topVA.map(r=>r.va_pib/1e3),  backgroundColor:"#378ADD",borderRadius:3},
      {label:"Salários",data:topVA.map(r=>r.salarios/1e3),backgroundColor:"#1D9E75",borderRadius:3},
      {label:"EOB",     data:topVA.map(r=>r.eob/1e3),     backgroundColor:"#F39C12",borderRadius:3}
    ],{plugins:{...CD.plugins,tooltip:TIP_SECTOR}});
    const topEmp=[...bl].sort((a,b)=>b.ocupacoes-a.ocupacoes).slice(0,20);
    mkBar("ch-emp-group",topEmp.map(r=>r.cod),
      [{label:"Ocupações (M)",data:topEmp.map(r=>r.ocupacoes/1e6),
        backgroundColor:topEmp.map(r=>gc(r.grupo)),borderRadius:4}],
      {plugins:{...CD.plugins,legend:{display:false},tooltip:TIP_SECTOR}});
    const df=dfAll; const dfC=["Export","Gov","ISFLSF","Families","GFCF","DeltaStock"];
    const dfCols=["#378ADD","#534AB7","#888780","#1D9E75","#F39C12","#E24B4A"];
    const col=scCol();
    const withT=df.map(r=>({...r,tot:dfC.reduce((s,c)=>s+(r[c]||0),0)}));
    const topDF=[...withT].sort((a,b)=>b.tot-a.tot).slice(0,20);
    mkBar("ch-df-group",topDF.map(r=>r.cod),
      dfC.map((c,i)=>({label:c,backgroundColor:dfCols[i],borderRadius:2,stack:"s",data:topDF.map(r=>r[c]||0)})),
      {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}},
       plugins:{...CD.plugins,tooltip:TIP_SECTOR}});
  } else {
    const lbls=schLabels(bl); const col=scCol();
    const grpColors=lblColors(lbls);

    // VA decomp: 3-dataset grouped bar — legend already shows VA/PIB, Salários, EOB
    mkBar("ch-va-decomp",lbls,[
      {label:"VA/PIB",  data:aggBy(bl,"va_pib",lbls).map(v=>v/1e3),  backgroundColor:"#378ADD",borderRadius:3},
      {label:"Salários",data:aggBy(bl,"salarios",lbls).map(v=>v/1e3),backgroundColor:"#1D9E75",borderRadius:3},
      {label:"EOB",     data:aggBy(bl,"eob",lbls).map(v=>v/1e3),     backgroundColor:"#F39C12",borderRadius:3}
    ]);

    // Employment: single dataset with per-group colours → custom generateLabels legend
    const empVals=aggBy(bl,"ocupacoes",lbls).map(v=>v/1e6);
    mkBar("ch-emp-group",lbls,
      [{label:"Ocupações (M)",data:empVals,backgroundColor:grpColors,borderRadius:4}],
      {plugins:{...CD.plugins,legend:makeColorLegend(lbls,grpColors)}});

    // Demanda Final: stacked by component — legend already shows Export / Gov / etc.
    const dfC=["Export","Gov","ISFLSF","Families","GFCF","DeltaStock"];
    const dfCols=["#378ADD","#534AB7","#888780","#1D9E75","#F39C12","#E24B4A"];
    mkBar("ch-df-group",lbls,
      dfC.map((c,i)=>({label:c,backgroundColor:dfCols[i],borderRadius:2,stack:"s",
        data:lbls.map(lbl=>dfAll.filter(r=>r[col]===lbl).reduce((s,r)=>s+(r[c]||0),0)/1e3)})),
      {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}});
  }

  const top15=[...bl].sort((a,b)=>b.vbp-a.vbp).slice(0,15);
  mkHBar("ch-vbp-top",top15.map(r=>r.cod),
    [{label:"VBP (R$ bi)",data:top15.map(r=>r.vbp/1e3),backgroundColor:top15.map(r=>gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:TIP_SECTOR}});

  const tb=document.querySelector("#tbl-baseline tbody");
  bl.forEach(r=>{const tr=document.createElement("tr");tr.innerHTML=
    `<td>${r.cod}</td><td title="${r.nome}">${r.nome.slice(0,38)}</td><td>${badge(r.grupo)}</td>
     <td>${(r.vbp||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
     <td>${(r.va_pib||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
     <td>${(r.remuner||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
     <td>${(r.salarios||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
     <td>${(r.eob||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>
     <td>${(r.ocupacoes||0).toLocaleString("pt-BR",{maximumFractionDigits:0})}</td>`;
    tb.appendChild(tr);});
}

// ════════════════════════════════════════════════════════════════════════════
// MULTIPLIERS (Tab 2)
// ════════════════════════════════════════════════════════════════════════════
function initMultipliers(){
  // Enrich so grupo_nt4 / grupo_ibge are available for colour coding
  const mp=[...enrich(D.Mult_Producao)].sort((a,b)=>b.MP-a.MP);
  const me=D.Mult_Emprego, mr=D.Mult_Renda;
  const setE=D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);

  // Colour by current scheme (fall back to "grupo" in 73-sector mode)
  const grpCol=isSec()?"grupo":scCol();
  const setES=new Set(setE);
  mkHBar("ch-mp-all",mp.map(r=>r.cod),
    [{label:"MP",data:mp.map(r=>r.MP),
      backgroundColor:mp.map(r=>setES.has(r.cod)?"#F39C12":gc(r[grpCol])),borderRadius:2}],
    {plugins:{...CD.plugins,
      legend:buildGroupLegend(mp,grpCol,setES,"top"),
      tooltip:TIP_SECTOR},
     scales:{x:{...CD.scales.x,min:1},y:{...CD.scales.y,ticks:{font:{size:9}}}}});

  const mpE=D.Mult_Producao.filter(r=>setE.includes(r.cod));
  mkBar("ch-mp-energy",mpE.map(r=>r.cod),[
    {label:"MP",data:mpE.map(r=>r.MP),backgroundColor:"#378ADD",borderRadius:3},
    {label:"MPT",data:mpE.map(r=>r.MPT),backgroundColor:"#1D9E75",borderRadius:3},
    {label:"MPTT",data:mpE.map(r=>r.MPTT),backgroundColor:"#F39C12",borderRadius:3}
  ],{plugins:{...CD.plugins,tooltip:TIP_SECTOR}});

  const meE=me.filter(r=>setE.includes(r.cod));
  mkBar("ch-me-energy",meE.map(r=>r.cod),[
    {label:"ME",data:meE.map(r=>r.ME),backgroundColor:"#378ADD",borderRadius:3},
    {label:"MEI",data:meE.map(r=>r.MEI),backgroundColor:"#1D9E75",borderRadius:3},
    {label:"MET",data:meE.map(r=>r.MET),backgroundColor:"#F39C12",borderRadius:3},
    {label:"MEII",data:meE.map(r=>r.MEII),backgroundColor:"#E24B4A",borderRadius:3}
  ],{plugins:{...CD.plugins,tooltip:TIP_SECTOR}});

  const top15=mp.slice(0,15);
  mkBar("ch-mp-decomp",top15.map(r=>r.cod),[
    {label:"Direto",data:top15.map(r=>r.direct),backgroundColor:"#378ADD",borderRadius:2,stack:"s"},
    {label:"Indireto",data:top15.map(r=>r.indirect),backgroundColor:"#534AB7",borderRadius:2,stack:"s"},
    {label:"Induzido",data:top15.map(r=>r.induced),backgroundColor:"#1D9E75",borderRadius:2,stack:"s"}
  ],{scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}},
     plugins:{...CD.plugins,tooltip:TIP_SECTOR}});

  const mrE=mr.filter(r=>setE.includes(r.cod));
  mkBar("ch-mr-energy",mrE.map(r=>r.cod),[
    {label:"MR",data:mrE.map(r=>r.MR),backgroundColor:"#378ADD",borderRadius:3},
    {label:"MRI",data:mrE.map(r=>r.MRI),backgroundColor:"#1D9E75",borderRadius:3},
    {label:"MRT",data:mrE.map(r=>r.MRT),backgroundColor:"#F39C12",borderRadius:3},
    {label:"MRII",data:mrE.map(r=>r.MRII),backgroundColor:"#E24B4A",borderRadius:3}
  ],{plugins:{...CD.plugins,tooltip:TIP_SECTOR}});

  const meByC=Object.fromEntries(me.map(r=>[r.cod,r]));
  const mrByC=Object.fromEntries(mr.map(r=>[r.cod,r]));
  const tb=document.querySelector("#tbl-mult tbody");
  mp.forEach(r=>{const m=meByC[r.cod]||{},n=mrByC[r.cod]||{};
    const tr=document.createElement("tr");tr.innerHTML=
      `<td>${r.cod}</td><td title="${r.nome}">${r.nome.slice(0,32)}</td>
       <td>${fmtN(r.MP)}</td><td>${fmtN(r.MPT)}</td><td>${fmtN(r.MPTT)}</td>
       <td>${fmtN(r.direct)}</td><td>${fmtN(r.indirect)}</td><td>${fmtN(r.induced)}</td>
       <td>${fmtN(m.ME)}</td><td>${fmtN(m.MEI)}</td><td>${fmtN(n.MR)}</td><td>${fmtN(n.MRI)}</td>
       <td>${badge(r.grupo)}</td>`;
    tb.appendChild(tr);});
}

// ════════════════════════════════════════════════════════════════════════════
// LINKAGES (Tab 3)
// ════════════════════════════════════════════════════════════════════════════
function initLinkages(){
  const lig=D.Ind_Ligacao;
  const QC={"Setor-Chave":"#F39C12","Demanda acima da media":"#1D9E75",
             "Oferta acima da media":"#378ADD","Independente":"#888780"};

  mkXY("ch-rasmussen",Object.entries(QC).map(([q,c])=>{
    const pts=lig.filter(r=>r.quadrante===q);
    return{label:q,data:pts.map(r=>({x:r.FLG,y:r.BL,cod:r.cod,nome:r.nome,isE:r.eh_energia})),
      backgroundColor:pts.map(r=>r.eh_energia?alpha(c,0.95):alpha(c,0.45)),
      pointRadius:pts.map(r=>r.eh_energia?8:4),pointStyle:pts.map(r=>r.eh_energia?"triangle":"circle")};}),
    {plugins:{legend:{labels:{color:"#8892a4",font:{size:11}}},
      tooltip:{callbacks:{label:ctx=>`${ctx.raw.cod} — ${ctx.raw.nome||""}: BL=${ctx.raw.y.toFixed(3)} FLG=${ctx.raw.x.toFixed(3)}${ctx.raw.isE?" ⚡":""}`}}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"FLG",color:"#8892a4"}},
             y:{...CD.scales.y,title:{display:true,text:"BL",color:"#8892a4"}}}});

  const blTop=[...lig].sort((a,b)=>b.BL-a.BL).slice(0,20);
  mkHBar("ch-bl-top",blTop.map(r=>r.cod),
    [{label:"BL",data:blTop.map(r=>r.BL),
      backgroundColor:blTop.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:TIP_SECTOR},
     scales:{x:{...CD.scales.x,min:0.8},y:CD.scales.y}});

  const flgTop=[...lig].sort((a,b)=>b.FLG-a.FLG).slice(0,20);
  mkHBar("ch-flg-top",flgTop.map(r=>r.cod),
    [{label:"FLG",data:flgTop.map(r=>r.FLG),
      backgroundColor:flgTop.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:TIP_SECTOR},
     scales:{x:{...CD.scales.x,min:0.5},y:CD.scales.y}});

  const qC={};lig.forEach(r=>{qC[r.quadrante]=(qC[r.quadrante]||0)+1;});
  mkDoughnut("ch-quadrant-pie",Object.keys(qC),Object.values(qC),Object.keys(qC).map(q=>QC[q]||"#888"));

  mkXY("ch-cv-scatter",[{label:"Setores",data:lig.map(r=>({x:r.Vi,y:r.Vj,cod:r.cod,nome:r.nome,isE:r.eh_energia})),
    backgroundColor:lig.map(r=>r.eh_energia?"#F39C12":alpha(gc(r.grupo),0.5)),
    pointRadius:lig.map(r=>r.eh_energia?7:3)}],
    {plugins:{legend:{display:false},tooltip:{callbacks:{label:ctx=>`${ctx.raw.cod} — ${ctx.raw.nome||""}: Vj=${ctx.raw.y.toFixed(2)} Vi=${ctx.raw.x.toFixed(2)}`}}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"Vi",color:"#8892a4"}},
             y:{...CD.scales.y,title:{display:true,text:"Vj",color:"#8892a4"}}}});
}

// ════════════════════════════════════════════════════════════════════════════
// ENERGY (Tab 4)
// ════════════════════════════════════════════════════════════════════════════
function initEnergy(){
  // enrich adds grupo_nt4 / grupo_ibge so NT4 and IBGE schemes work here too
  const ef=enrich(D.Energia_Fluxos_ktep);
  const fontes=["Derivados","Biodiesel","Etanol","EE_Central","EE_Distrib","Gas_Natural"];
  const s=sch(); const sec=isSec();
  setTtl("ttl-e-group","Energia por Fonte e "+(sec?"Setor (top 20)":s.label)+" (ktep)");

  if(sec){
    const withT=ef.map(r=>({...r,tot:fontes.reduce((s,f)=>s+(r[f]||0),0)}));
    const top20=[...withT].sort((a,b)=>b.tot-a.tot).slice(0,20);
    mkBar("ch-e-group",top20.map(r=>r.cod),
      fontes.map(f=>({label:f,backgroundColor:FONTE_C[f]||"#888",borderRadius:2,stack:"s",data:top20.map(r=>r[f]||0)})),
      {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}},
       plugins:{...CD.plugins,tooltip:TIP_SECTOR}});
  } else {
    const lbls=schLabels(ef); const col=scCol();
    mkBar("ch-e-group",lbls,
      fontes.map(f=>({label:f,backgroundColor:FONTE_C[f]||"#888",borderRadius:2,stack:"s",
        data:lbls.map(lbl=>ef.filter(r=>r[col]===lbl).reduce((s,r)=>s+(r[f]||0),0)/1e3)})),
      {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}});
    attachGroupFilter("ch-e-group",lbls,lblColors(lbls));
  }

  const totByF=fontes.map(f=>ef.reduce((s,r)=>s+(r[f]||0),0));
  mkDoughnut("ch-e-pie",fontes,totByF,fontes.map(f=>FONTE_C[f]||"#888"));

  const withT2=ef.map(r=>({...r,tot:fontes.reduce((s,f)=>s+(r[f]||0),0)}));
  const top15=[...withT2].sort((a,b)=>b.tot-a.tot).slice(0,15);
  mkHBar("ch-e-top-sectors",top15.map(r=>r.cod),
    [{label:"Total (ktep)",data:top15.map(r=>r.tot),backgroundColor:top15.map(r=>gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:TIP_SECTOR}});

  const al=D.Energia_Alpha; const setE=D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);
  const alE=[...al.filter(r=>setE.includes(r.cod))]
    .map(r=>({...r,tot:fontes.reduce((s,f)=>s+(r[f]||0),0)}))
    .sort((a,b)=>b.tot-a.tot);
  mkHBar("ch-alpha-energy",alE.map(r=>r.cod),
    fontes.map(f=>({label:f,data:alE.map(r=>r[f]||0),backgroundColor:FONTE_C[f]||"#888",borderRadius:2,stack:"s"})),
    {scales:{x:{...CD.scales.x,stacked:true,title:{display:true,text:"ktep/R$M",color:"#8892a4"}},
             y:{...CD.scales.y,stacked:true}},
     plugins:{...CD.plugins,tooltip:TIP_SECTOR}});
}

// ════════════════════════════════════════════════════════════════════════════
// SHOCKS (Tab 6)
// ════════════════════════════════════════════════════════════════════════════
function initShocks(){buildExToggles(); rebuildShockCharts(); renderShockTable();}

function rebuildShockCharts(){
  const exK=activeEx(); const cg=D.Choques_Grupos;
  const ce=D.Choques_Energia; const cl=D.Choques_Labor;
  const s=sch(); const sec=isSec(); const col=scCol();
  setTtl("ttl-shock-va","ΔVA por "+(sec?"Setor (top 20)":s.label)+" (R$ bi)");
  setTtl("ttl-shock-emp","ΔEmprego por "+(sec?"Setor (top 20)":s.label)+" (mil)");

  if(sec){
    const ref=D[exK[0]]||[]; const top20=[...ref].sort((a,b)=>b.delta_va-a.delta_va).slice(0,20);
    const cods=top20.map(r=>r.cod);
    mkBar("ch-shock-va-groups",cods,exK.map(k=>{
      const m=Object.fromEntries((D[k]||[]).map(r=>[r.cod,r]));
      return{label:EX_LABEL[k],data:cods.map(c=>(m[c]?.delta_va||0)/1e3),backgroundColor:EX_COLOR[k],borderRadius:3};
    }),{plugins:{...CD.plugins,tooltip:TIP_SECTOR}});
    mkBar("ch-shock-emp-groups",cods,exK.map(k=>{
      const m=Object.fromEntries((D[k]||[]).map(r=>[r.cod,r]));
      return{label:EX_LABEL[k],data:cods.map(c=>(m[c]?.delta_emp||0)/1e3),backgroundColor:EX_COLOR[k],borderRadius:3};
    }),{plugins:{...CD.plugins,tooltip:TIP_SECTOR}});
  } else {
    // Re-aggregate sector-level shock sheets by current scheme so NT4 / IBGE / 7G all work
    const grpOf=r=>(_SMAP[r.cod]||{})[col]||r[col];
    const allG=new Set();
    exK.forEach(k=>(D[k]||[]).forEach(r=>{const g=grpOf(r);if(g)allG.add(g);}));
    const lbls=[...allG].sort();
    mkBar("ch-shock-va-groups",lbls,exK.map(k=>({label:EX_LABEL[k],backgroundColor:EX_COLOR[k],borderRadius:3,
      data:lbls.map(g=>(D[k]||[]).reduce((s,r)=>s+(grpOf(r)===g?(r.delta_va||0):0),0)/1e3)})));
    attachGroupFilter("ch-shock-va-groups",lbls,lblColors(lbls));
    mkBar("ch-shock-emp-groups",lbls,exK.map(k=>({label:EX_LABEL[k],backgroundColor:EX_COLOR[k],borderRadius:3,
      data:lbls.map(g=>(D[k]||[]).reduce((s,r)=>s+(grpOf(r)===g?(r.delta_emp||0):0),0)/1e3)})));
    attachGroupFilter("ch-shock-emp-groups",lbls,lblColors(lbls));
  }

  // Note: Choques_Energia / Choques_Labor use long exercicio strings; map via EX_STR
  const fontes=[...new Set(ce.map(r=>r.fonte))];
  mkBar("ch-shock-energy",exK.map(k=>EX_LABEL[k]),
    fontes.map(f=>({label:f,backgroundColor:FONTE_C[f]||"#888",borderRadius:2,stack:"s",
      data:exK.map(k=>{const r=ce.find(x=>x.exercicio===EX_STR[k]&&x.fonte===f);return r?(r.delta_ktep||0):0;})})),
    {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true}}});

  const laborG=[...new Set(cl.map(r=>r.grupo_lab))];
  mkBar("ch-shock-labor",laborG,exK.map(k=>({label:EX_LABEL[k],backgroundColor:EX_COLOR[k],borderRadius:3,
    data:laborG.map(g=>{const r=cl.find(x=>x.exercicio===EX_STR[k]&&x.grupo_lab===g);return r?(r.delta_emp||0)/1e3:0;})})));

  const firstEx=exK[0]; const exD=firstEx?(D[firstEx]||[]):[];
  const top15VA=[...exD].sort((a,b)=>b.delta_va-a.delta_va).slice(0,15);
  mkHBar("ch-shock-ex1-sectors",top15VA.map(r=>r.cod),
    [{label:`ΔVA — ${firstEx?EX_LABEL[firstEx]:"—"}`,data:top15VA.map(r=>r.delta_va),
      backgroundColor:top15VA.map(r=>r.eh_energia?"#F39C12":gc(r.grupo)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:TIP_SECTOR}});

  const setE=D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);
  const ex3=(D.Choque_Ex3_Fossil||[]).filter(r=>setE.includes(r.cod));
  const ex4=(D.Choque_Ex4_Renov||[]).filter(r=>setE.includes(r.cod));
  mkBar("ch-shock-ex34-energy",setE,[
    {label:"Ex3 Fóssil -20%",data:setE.map(c=>{const r=ex3.find(x=>x.cod===c);return r?(r.delta_x||0):0;}),backgroundColor:"#E24B4A",borderRadius:3},
    {label:"Ex4 Renov +30%", data:setE.map(c=>{const r=ex4.find(x=>x.cod===c);return r?(r.delta_x||0):0;}),backgroundColor:"#1D9E75",borderRadius:3}
  ],{plugins:{...CD.plugins,tooltip:TIP_SECTOR}});
}

function renderShockTable(){
  const key=document.getElementById("sel-exercise").value;
  const rows=D[key]||[]; clrTbody("tbl-shock");
  const tb=document.querySelector("#tbl-shock tbody");
  rows.forEach(r=>{const tr=document.createElement("tr");tr.innerHTML=
    `<td>${r.cod}</td><td title="${r.nome}">${r.nome.slice(0,32)}</td>
     <td>${badge(r.grupo||r.grupo_nt4)}</td>
     <td>${r.eh_energia?'<span class="tag-renov">&#9889;</span>':""}</td>
     <td style="color:${(r.delta_x||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_x||0).toFixed(1)}</td>
     <td style="color:${(r.delta_va||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_va||0).toFixed(1)}</td>
     <td style="color:${(r.delta_emp||0)>=0?"#1D9E75":"#E24B4A"}">${(r.delta_emp||0).toFixed(0)}</td>
     <td>${(r.var_x_pct||0).toFixed(2)}%</td><td>${(r.var_va_pct||0).toFixed(2)}%</td>`;
    tb.appendChild(tr);});
}

// ════════════════════════════════════════════════════════════════════════════
// EXTRACTION (Tab 6)
// ════════════════════════════════════════════════════════════════════════════
function initExtraction(){
  // enrich so NT4 / IBGE group columns are available for colour coding
  const ext=enrich(D.Extr_Hipotetica||[]), ipl=D.Ind_Puros||[];
  const setE=D.Setores.filter(s=>s.eh_energia).map(s=>s.cod);
  const grpCol=isSec()?"grupo":scCol();
  const setES=new Set(setE);
  function barColor(r){return setES.has(r.cod)?"#F39C12":gc(r[grpCol]);}
  function extLegend(rows){return buildGroupLegend(rows,grpCol,setES,"top");}

  const blTop=[...ext].sort((a,b)=>b.BL_abs-a.BL_abs).slice(0,20);
  mkHBar("ch-extrac-bl",blTop.map(r=>r.cod),
    [{label:"BL (R$M)",data:blTop.map(r=>r.BL_abs),
      backgroundColor:blTop.map(barColor),borderRadius:3}],
    {plugins:{...CD.plugins,legend:extLegend(blTop),tooltip:TIP_SECTOR}});

  const flTop=[...ext].sort((a,b)=>b.FL_abs-a.FL_abs).slice(0,20);
  mkHBar("ch-extrac-fl",flTop.map(r=>r.cod),
    [{label:"FL (R$M)",data:flTop.map(r=>r.FL_abs),
      backgroundColor:flTop.map(barColor),borderRadius:3}],
    {plugins:{...CD.plugins,legend:extLegend(flTop),tooltip:TIP_SECTOR}});

  const wrap=document.getElementById("ch-ipln");
  if(ipl.length>0&&wrap){
    mkXY("ch-ipln",[{label:"Setores",
      data:ipl.map(r=>({x:r.PFLN,y:r.PBLN,cod:r.cod,nome:r.nome,isE:setE.includes(r.cod)})),
      backgroundColor:ipl.map(r=>setE.includes(r.cod)?"#F39C12":alpha(gc(r.grupo),0.55)),
      pointRadius:ipl.map(r=>setE.includes(r.cod)?8:4)}],
      {plugins:{legend:{display:false},tooltip:{callbacks:{label:ctx=>`${ctx.raw.cod} — ${ctx.raw.nome||""}: PBLN=${ctx.raw.y.toFixed(2)} PFLN=${ctx.raw.x.toFixed(2)}`}}},
       scales:{x:{...CD.scales.x,title:{display:true,text:"PFLN",color:"#8892a4"}},
               y:{...CD.scales.y,title:{display:true,text:"PBLN",color:"#8892a4"}}}});
    const tb=document.querySelector("#tbl-ipln tbody");
    [...ipl].sort((a,b)=>b.PBLN-a.PBLN).forEach(r=>{const tr=document.createElement("tr");tr.innerHTML=
      `<td>${r.cod}</td><td title="${r.nome}">${r.nome.slice(0,34)}</td>
       <td>${(r.PBL||0).toFixed(1)}</td><td>${(r.PFL||0).toFixed(1)}</td><td>${(r.PTL||0).toFixed(1)}</td>
       <td>${(r.PBLN||0).toFixed(3)}</td><td>${(r.PFLN||0).toFixed(3)}</td><td>${(r.PTLN||0).toFixed(3)}</td>
       <td>${badge(r.grupo)}</td>`;
      tb.appendChild(tr);});
  } else if(wrap){
    wrap.parentElement.innerHTML="<p style='color:#8892a4;text-align:center;padding:40px'>Índices puros não disponíveis (COMPUTE_SLOW=FALSE)</p>";
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BOOTSTRAP
// ════════════════════════════════════════════════════════════════════════════
buildSchemeSwitcher();
// Apply CARD_DEFS (id-based, dynamic titles)
Object.entries(CARD_DEFS).forEach(([id,def])=>{const e=document.getElementById(id);if(e)e.title=def;});
// Apply STATIC_DEFS (text-match, static titles) to all card-titles without a title yet
document.querySelectorAll(".card-title:not([title])").forEach(el=>{
  const txt=el.textContent.trim();
  const found=Object.entries(STATIC_DEFS).find(([k])=>txt.includes(k));
  if(found)el.title=found[1];
});
showTab(0);
</script>
</body></html>]")

writeLines(html, HTML_OUT, useBytes = FALSE)
cat("Dashboard written:", HTML_OUT, "\n")
cat("File size:", round(file.size(HTML_OUT)/1e3), "KB\n")
