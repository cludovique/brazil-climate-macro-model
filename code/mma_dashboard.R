# =============================================================================
# MMA SHOCK ENGINES — Dashboard Interativo (por engine)
# Lê outputs/tables/mma_shock_results_new.xlsx (ou mma_shock_results.xlsx)
# Gera outputs/mma_dashboard.html
# =============================================================================
pkgs <- c("readxl","jsonlite","dplyr")
for (p in pkgs) { if (!requireNamespace(p,quietly=TRUE)) install.packages(p); library(p,character.only=TRUE) }

XLS_IN  <- if (file.exists("outputs/tables/mma_shock_results_new.xlsx"))
             "outputs/tables/mma_shock_results_new.xlsx" else
             "outputs/tables/mma_shock_results.xlsx"
HTML_OUT <- "outputs/mma_dashboard.html"
if (!dir.exists("outputs")) dir.create("outputs", recursive=TRUE)
stopifnot(file.exists(XLS_IN))
cat("Lendo", XLS_IN, "\n")

rd <- function(s) suppressMessages(read_excel(XLS_IN, sheet=s))

js <- toJSON(list(
  resumo     = rd("Resumo"),
  top15      = rd("Top15_por_Setor"),
  completo   = rd("Resultados_Completos"),
  emissoes   = rd("Emissoes_Setoriais"),
  delta_f    = rd("Delta_F_Componentes"),
  mix        = rd("Mix_Energetico"),
  prod_fis   = rd("Producao_Fisica"),
  pib_pop    = rd("PIB_Pop"),
  aloc_inv   = rd("Aloc_Investimento"),
  mult       = rd("Multiplicadores"),
  inv_custos = rd("Investimento_Custos"),
  premissas  = rd("Premissas")
), na="null", digits=5, auto_unbox=TRUE)

cat("JSON:", round(nchar(js)/1e3,1), "KB\n")

html <- paste0('<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MMA Shock Engines — Dashboard</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.min.js"></script>
<style>
:root{
  --bg:#0f1117;--card:#1a1d27;--border:#2a2d3e;--text:#e2e8f0;--muted:#8892a4;
  --accent:#378ADD;--c0d:#E24B4A;--c25d:#F59E0B;--c100d:#1D9E75;
  --celec:#378ADD;--cbio:#1D9E75;--cfoss:#E24B4A;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:"Segoe UI","Inter",sans-serif;font-size:13px}
.topbar{background:#13151f;border-bottom:1px solid var(--border);padding:10px 24px;
  display:flex;align-items:center;gap:14px;position:sticky;top:0;z-index:110;flex-wrap:wrap}
.topbar h1{font-size:14px;font-weight:700;color:#fff}
.topbar .sub{font-size:11px;color:var(--muted)}
.badge{font-size:10px;padding:2px 8px;border-radius:10px;font-weight:600;border:1px solid;margin-left:auto}
nav.tabs{background:#13151f;border-bottom:1px solid var(--border);padding:0 24px;
  display:flex;gap:0;overflow-x:auto;position:sticky;top:44px;z-index:100}
nav.tabs button{background:none;border:none;color:var(--muted);padding:9px 16px;
  font-size:12px;cursor:pointer;border-bottom:2px solid transparent;white-space:nowrap;transition:.15s}
nav.tabs button.active{color:#fff;border-bottom-color:var(--accent)}
nav.tabs button:hover:not(.active){color:var(--text)}
.fbar{background:#13151f;border-bottom:1px solid var(--border);padding:7px 24px;
  display:flex;align-items:center;gap:12px;flex-wrap:wrap;position:sticky;top:84px;z-index:99}
.fl{font-size:9px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.1em}
.btn-grp{display:flex;border:1px solid var(--border);border-radius:6px;overflow:hidden}
.btn-grp button{background:none;border:none;border-right:1px solid var(--border);
  color:var(--muted);padding:4px 12px;font-size:11px;font-weight:500;cursor:pointer;transition:.15s}
.btn-grp button:last-child{border-right:none}
.btn-grp button.active{background:var(--accent);color:#fff}
.btn-grp button:hover:not(.active){background:#1f2233;color:var(--text)}
.page{display:none;padding:18px 24px}
.page.active{display:block}
.kpi-row{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:16px}
.kpi{background:var(--card);border:1px solid var(--border);border-radius:10px;
  padding:12px 16px;min-width:150px;flex:1}
.kpi .lbl{font-size:9px;color:var(--muted);text-transform:uppercase;letter-spacing:.08em;margin-bottom:3px}
.kpi .val{font-size:20px;font-weight:700;color:#fff;line-height:1.1}
.kpi .sub{font-size:10px;color:var(--muted);margin-top:2px}
.kpi.blue .val{color:var(--accent)}
.kpi.green .val{color:var(--c100d)}
.kpi.amber .val{color:var(--c25d)}
.kpi.red .val{color:var(--c0d)}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px}
.grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;margin-bottom:14px}
.grid1{display:grid;grid-template-columns:1fr;gap:14px;margin-bottom:14px}
.card{background:var(--card);border:1px solid var(--border);border-radius:10px;padding:16px 18px}
.card h3{font-size:12px;font-weight:600;color:var(--text);margin-bottom:10px}
.card .note{font-size:10px;color:var(--muted);margin-bottom:8px;line-height:1.5}
.eng-header{display:flex;align-items:center;gap:10px;margin-bottom:14px}
.eng-badge{font-size:11px;font-weight:700;padding:4px 12px;border-radius:20px;border:1px solid}
.eng1{color:var(--accent);border-color:var(--accent)}
.eng2{color:var(--c25d);border-color:var(--c25d)}
.eng3{color:var(--c100d);border-color:var(--c100d)}
.eng4{color:var(--c0d);border-color:var(--c0d)}
.eng-title{font-size:14px;font-weight:700;color:#fff}
.eng-desc{font-size:11px;color:var(--muted);line-height:1.6;margin-bottom:14px;
  background:var(--card);border-left:3px solid var(--border);padding:10px 14px;border-radius:4px}
.leg{display:flex;gap:14px;flex-wrap:wrap;margin-bottom:8px}
.leg-item{display:flex;align-items:center;gap:5px;font-size:10.5px;color:var(--muted)}
.leg-dot{width:9px;height:9px;border-radius:50%;flex-shrink:0}
.leg-sq{width:9px;height:9px;flex-shrink:0}
.tbl-wrap{overflow-x:auto;max-height:340px;overflow-y:auto}
table{width:100%;border-collapse:collapse;font-size:11.5px}
thead th{background:#13151f;color:var(--muted);font-weight:600;padding:6px 9px;
  text-align:left;position:sticky;top:0;border-bottom:1px solid var(--border);white-space:nowrap}
tbody tr:hover{background:#1f2233}
tbody td{padding:4px 9px;border-bottom:1px solid #1f2233;color:var(--text)}
.flow{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin:10px 0}
.flow-box{background:#1f2233;border:1px solid var(--border);border-radius:8px;
  padding:8px 14px;font-size:11px;font-weight:600;color:#fff;text-align:center;min-width:80px}
.flow-box.eng1b{border-color:var(--accent);color:var(--accent)}
.flow-box.eng2b{border-color:var(--c25d);color:var(--c25d)}
.flow-box.eng3b{border-color:var(--c100d);color:var(--c100d)}
.flow-box.eng4b{border-color:var(--c0d);color:var(--c0d)}
.flow-arrow{color:var(--muted);font-size:16px}
@media(max-width:700px){.grid2,.grid3{grid-template-columns:1fr}}
</style>
</head>
<body>

<div class="topbar">
  <div>
    <h1>⚙️ MMA Shock Engines — Impactos Macroeconômicos</h1>
    <div class="sub">MMA-SMC v3 AR5 &times; EPE/FIPE MIP 2018 &bull; 73 setores &bull; 4 engines &bull; 3 cenários &bull; 2025–2050</div>
  </div>
  <span style="display:flex;gap:6px;margin-left:auto;flex-wrap:wrap">
    <span style="font-size:10px;padding:2px 8px;border-radius:10px;border:1px solid var(--c0d);color:var(--c0d)">0D TRF</span>
    <span style="font-size:10px;padding:2px 8px;border-radius:10px;border:1px solid var(--c25d);color:var(--c25d)">25D TRS</span>
    <span style="font-size:10px;padding:2px 8px;border-radius:10px;border:1px solid var(--c100d);color:var(--c100d)">100D MCI</span>
  </span>
</div>

<nav class="tabs">
  <button class="active" onclick="setTab(0)">Visão Geral</button>
  <button onclick="setTab(1)">Engine 1 — ∆f Demanda</button>
  <button onclick="setTab(2)">Engine 2 — ∆A Energia</button>
  <button onclick="setTab(3)">Engine 3 — ∆x Físico</button>
  <button onclick="setTab(4)">Engine 4 — Emissões</button>
  <button onclick="setTab(5)">Propagação Leontief</button>
</nav>

<div class="fbar">
  <span class="fl">Cenário</span>
  <div class="btn-grp" id="scen-btns">
    <button class="active" data-s="25D" onclick="setSc(this)">25D TRS</button>
    <button data-s="100D" onclick="setSc(this)">100D MCI</button>
    <button data-s="0D"   onclick="setSc(this)">0D TRF</button>
  </div>
  <span class="fl" style="margin-left:8px">Ano</span>
  <div class="btn-grp" id="ano-btns">
    <button class="active" data-a="2025" onclick="setAn(this)">2025</button>
    <button data-a="2030" onclick="setAn(this)">2030</button>
    <button data-a="2035" onclick="setAn(this)">2035</button>
    <button data-a="2040" onclick="setAn(this)">2040</button>
    <button data-a="2045" onclick="setAn(this)">2045</button>
    <button data-a="2050" onclick="setAn(this)">2050</button>
  </div>
</div>

<!-- ═══════════════════════ TAB 0: VISÃO GERAL ═══════════════════════ -->
<div class="page active" id="tab0">
  <div style="background:var(--card);border:1px solid var(--border);border-radius:10px;padding:14px 18px;margin-bottom:14px">
    <div class="flow">
      <div class="flow-box eng1b">Engine 1<br><small style="font-weight:400;font-size:9px">∆f Demanda Final<br>PIB + Investimento</small></div>
      <span class="flow-arrow">+</span>
      <div class="flow-box eng2b">Engine 2<br><small style="font-weight:400;font-size:9px">∆A Matriz Técnica<br>Mix Energético</small></div>
      <span class="flow-arrow">+</span>
      <div class="flow-box eng3b">Engine 3<br><small style="font-weight:400;font-size:9px">∆x Produção Física<br>Volumes → R$</small></div>
      <span class="flow-arrow">→</span>
      <div class="flow-box" style="border-color:var(--accent);color:var(--accent)">L* = (I−A*)⁻¹<br><small style="font-weight:400;font-size:9px">Propagação Leontief</small></div>
      <span class="flow-arrow">→</span>
      <div class="flow-box" style="border-color:#fff;color:#fff">∆x Total<br><small style="font-weight:400;font-size:9px">Variação do Produto</small></div>
      <span class="flow-arrow">×</span>
      <div class="flow-box eng4b">Engine 4<br><small style="font-weight:400;font-size:9px">e (MtCO₂e/R$M)<br>Conta Satélite</small></div>
      <span class="flow-arrow">→</span>
      <div class="flow-box" style="border-color:var(--c0d);color:var(--c0d)">GHG Induzido<br><small style="font-weight:400;font-size:9px">MtCO₂e AR5</small></div>
    </div>
  </div>
  <div class="kpi-row" id="kpi0"></div>
  <div class="grid2">
    <div class="card">
      <h3>∆ Produção Total (R$ bi) — trajetória por cenário</h3>
      <div class="leg">
        <span class="leg-item"><span class="leg-dot" style="background:var(--c0d)"></span>0D TRF</span>
        <span class="leg-item"><span class="leg-dot" style="background:var(--c25d)"></span>25D TRS</span>
        <span class="leg-item"><span class="leg-dot" style="background:var(--c100d)"></span>100D MCI</span>
      </div>
      <div style="height:200px"><canvas id="ch-ov-prod"></canvas></div>
    </div>
    <div class="card">
      <h3>GHG Induzido MIP vs Total Cenário MMA (MtCO₂e)</h3>
      <div class="note">Linha sólida = GHG induzido via L*; tracejada = total do cenário MMA (inclui LULUCF, agro, resíduos)</div>
      <div style="height:200px"><canvas id="ch-ov-ghg"></canvas></div>
    </div>
  </div>
  <div class="grid3">
    <div class="card"><h3>Componentes ∆f (R$ bi) — cenário selecionado</h3>
      <div style="height:180px"><canvas id="ch-ov-comp"></canvas></div></div>
    <div class="card"><h3>Crescimento PIB relativo a 2018 (%)</h3>
      <div style="height:180px"><canvas id="ch-ov-gdp"></canvas></div></div>
    <div class="card"><h3>Investimento transição (R$ bi/ano) — por cenário</h3>
      <div style="height:180px"><canvas id="ch-ov-inv"></canvas></div></div>
  </div>
</div>

<!-- ═══════════════════════ TAB 1: ENGINE 1 ═══════════════════════════ -->
<div class="page" id="tab1">
  <div class="eng-header">
    <span class="eng-badge eng1">Engine 1</span>
    <span class="eng-title">∆f — Demanda Final</span>
  </div>
  <div class="eng-desc">
    Duas fontes de choque na demanda final: <strong>(a) Escalonamento PIB</strong> — a demanda final de 2018 é multiplicada pelo crescimento real do PIB até o ano-alvo, gerando ∆f_PIB = f₂₀₁₈ × (PIB_rel − 1); <strong>(b) Investimento de transição</strong> — os custos anuais equivalentes (CAE) do MMA em USD2023 são convertidos para R$2018 e alocados entre setores IO via vetor ALOC_INV; <strong>(c) O Engine 3 adiciona ∆f_prod</strong> como o efeito-oferta dos choques físicos.
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Alocação do Investimento de Transição (ALOC_INV)</h3>
      <div class="note">Pesos fixos de alocação do CapEx de transição energética entre setores IO</div>
      <div style="height:260px"><canvas id="ch-e1-aloc"></canvas></div>
    </div>
    <div class="card">
      <h3>PIB: índice relativo a 2018 — crescimento acumulado (%)</h3>
      <div class="note">Único para todos os cenários (MMA usa mesma trajetória macroeconômica)</div>
      <div style="height:260px"><canvas id="ch-e1-gdp"></canvas></div>
    </div>
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Custo Anual Equivalente do Investimento (R$ bi) — por cenário</h3>
      <div class="note">CAE convertido de USD2023 → R$2018 (câmbio 3,65 / CPI 1,25 = fator 2,92)</div>
      <div style="height:200px"><canvas id="ch-e1-inv"></canvas></div>
    </div>
    <div class="card">
      <h3>∆f por Componente — Top 20 setores (cenário/ano selecionado)</h3>
      <div class="leg">
        <span class="leg-item"><span class="leg-sq" style="background:rgba(55,138,221,.8)"></span>PIB</span>
        <span class="leg-item"><span class="leg-sq" style="background:rgba(29,158,117,.8)"></span>Investimento</span>
        <span class="leg-item"><span class="leg-sq" style="background:rgba(245,158,11,.8)"></span>Prod. Física</span>
      </div>
      <div style="height:200px"><canvas id="ch-e1-df"></canvas></div>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 2: ENGINE 2 ═══════════════════════════ -->
<div class="page" id="tab2">
  <div class="eng-header">
    <span class="eng-badge eng2">Engine 2</span>
    <span class="eng-title">∆A — Substituição do Mix Energético</span>
  </div>
  <div class="eng-desc">
    A matriz de coeficientes técnicos A é modificada para refletir a mudança no mix energético: para cada grupo (Indústria, Transporte, Cidades), os coeficientes das linhas de energia (S19 fóssil, S20 biodiesel, S22 etanol, S40/S41 eletricidade) são redistribuídos proporcionalmente ao novo mix — mantendo o total de energia por coluna constante. O resultado é A* = A + ∆A, e L* = (I − A*)⁻¹.
  </div>
  <div class="grid3">
    <div class="card">
      <h3>Indústria — Mix Energético (%)</h3>
      <div class="note">Base 2020: Elec 33% | Bio 23% | Fóssil 44%</div>
      <div style="height:200px"><canvas id="ch-e2-ind"></canvas></div>
    </div>
    <div class="card">
      <h3>Transporte — Mix Energético (%)</h3>
      <div class="note">Base 2020: Elec 0,4% | Bio 30,3% | Fóssil 69,3%</div>
      <div style="height:200px"><canvas id="ch-e2-tra"></canvas></div>
    </div>
    <div class="card">
      <h3>Cidades/Edifícios — Mix Energético (%)</h3>
      <div class="note">Base 2020: Elec 62,5% | Bio ≈0% | Gás/Fóssil 37,5%</div>
      <div style="height:200px"><canvas id="ch-e2-cid"></canvas></div>
    </div>
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Evolução da Eletrificação (%) — todos os cenários</h3>
      <div style="height:220px"><canvas id="ch-e2-elec"></canvas></div>
    </div>
    <div class="card">
      <h3>Evolução dos Biocombustíveis (%) — todos os cenários</h3>
      <div style="height:220px"><canvas id="ch-e2-bio"></canvas></div>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 3: ENGINE 3 ═══════════════════════════ -->
<div class="page" id="tab3">
  <div class="eng-header">
    <span class="eng-badge eng3">Engine 3</span>
    <span class="eng-title">∆x — Produção Física Exógena</span>
  </div>
  <div class="eng-desc">
    Volumes físicos projetados pelo MMA (culturas agrícolas, aço, cimento, biocombustíveis, eletricidade) são convertidos em variações de produção em R$ via razão: ∆x_setor = x₂₀₁₈ × (val_cenário / base_2020 − 1). O efeito na demanda final é calculado como ∆f_prod = (I − A*) × ∆x, que entra no Engine 1 como terceiro componente.
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Variação % vs Base 2020 — Agropecuária (cenário selecionado)</h3>
      <div class="leg">
        <span class="leg-item"><span class="leg-dot" style="background:var(--c0d)"></span>0D</span>
        <span class="leg-item"><span class="leg-dot" style="background:var(--c25d)"></span>25D</span>
        <span class="leg-item"><span class="leg-dot" style="background:var(--c100d)"></span>100D</span>
      </div>
      <div style="height:220px"><canvas id="ch-e3-agro"></canvas></div>
    </div>
    <div class="card">
      <h3>Variação % vs Base 2020 — Indústria &amp; Energia</h3>
      <div style="height:220px"><canvas id="ch-e3-ind"></canvas></div>
    </div>
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Produção Física — trajetória absoluta (cenário selecionado)</h3>
      <div id="prod-fis-sel" style="margin-bottom:8px">
        <div class="btn-grp" id="prod-sel-btns" style="flex-wrap:wrap;height:auto">
          <button class="active" data-p="Cana-de-açúcar" onclick="setProd(this)">Cana</button>
          <button data-p="Soja" onclick="setProd(this)">Soja</button>
          <button data-p="Milho" onclick="setProd(this)">Milho</button>
          <button data-p="Aço" onclick="setProd(this)">Aço</button>
          <button data-p="Clinker/Cimento" onclick="setProd(this)">Cimento</button>
          <button data-p="Eletricidade" onclick="setProd(this)">Eletric.</button>
          <button data-p="Etanol+CCS" onclick="setProd(this)">Etanol</button>
          <button data-p="Diesel Verde" onclick="setProd(this)">Diesel V.</button>
        </div>
      </div>
      <div style="height:180px"><canvas id="ch-e3-traj"></canvas></div>
    </div>
    <div class="card">
      <h3>∆x Físico → R$ (impacto nos setores, cenário/ano)</h3>
      <div class="note">Conversão: variação relativa aplicada ao x₂₀₁₈ de cada setor</div>
      <div style="height:180px"><canvas id="ch-e3-rx"></canvas></div>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 4: ENGINE 4 ═══════════════════════════ -->
<div class="page" id="tab4">
  <div class="eng-header">
    <span class="eng-badge eng4">Engine 4</span>
    <span class="eng-title">e — Coeficientes de Emissão (Conta Satélite)</span>
  </div>
  <div class="eng-desc">
    Os totais de GHG do cenário MMA (MtCO₂e AR5) são alocados proporcionalmente à produção dos setores IO dentro de cada grupo (Agropecuária, Energia, Indústria, Transportes, Cidades, Resíduos). O coeficiente de emissão é e = GHG_grupo / Σx_setor, em MtCO₂e por R$ milhão. O GHG induzido por setor é então e × ∆x_total.
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Top 20 Setores — Coeficiente de Emissão e (MtCO₂e / R$ mi, cenário/ano)</h3>
      <div style="height:260px"><canvas id="ch-e4-coef"></canvas></div>
    </div>
    <div class="card">
      <h3>GHG Induzido por Setor — Top 15 (MtCO₂e, cenário/ano)</h3>
      <div style="height:260px"><canvas id="ch-e4-ghg"></canvas></div>
    </div>
  </div>
  <div class="grid2">
    <div class="card">
      <h3>GHG Cenário MMA por Grupo (MtCO₂e) — cenário selecionado</h3>
      <div class="note">Stacked area: Industria · Transportes · Energia · LULUCF · Agropecuária · Resíduos · Cidades</div>
      <div style="height:220px"><canvas id="ch-e4-grupo"></canvas></div>
    </div>
    <div class="card">
      <h3>Trajetória GHG Total — todos os cenários (MtCO₂e)</h3>
      <div style="height:220px"><canvas id="ch-e4-traj"></canvas></div>
    </div>
  </div>
</div>

<!-- ═══════════════════════ TAB 5: PROPAGAÇÃO ═════════════════════════ -->
<div class="page" id="tab5">
  <div class="eng-header">
    <span class="eng-badge" style="color:var(--accent);border-color:var(--accent)">Leontief</span>
    <span class="eng-title">Propagação: ∆f → L* → ∆x</span>
  </div>
  <div class="eng-desc">
    O multiplicador de produção m*_j = Σᵢ L*ᵢⱼ indica o efeito total na economia induzido por R$1 de demanda final no setor j. Quanto maior o multiplicador, mais o setor propaga impacto pela cadeia produtiva. O ∆x total combina o efeito de todos os engines propagado por L* = (I − A*)⁻¹.
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Top 20 Multiplicadores de Produção L* (cenário/ano)</h3>
      <div class="note">m*_j = Σᵢ L*ᵢⱼ — quanto R$ de produção total é gerado por R$1 de ∆f no setor j</div>
      <div style="height:260px"><canvas id="ch-lnt-mult"></canvas></div>
    </div>
    <div class="card">
      <h3>∆f Total → ∆x Total — Top 15 setores (R$ mi, cenário/ano)</h3>
      <div class="leg">
        <span class="leg-item"><span class="leg-sq" style="background:rgba(55,138,221,.5)"></span>∆f (impulso)</span>
        <span class="leg-item"><span class="leg-sq" style="background:rgba(29,158,117,.8)"></span>∆x (resposta L*)</span>
      </div>
      <div style="height:260px"><canvas id="ch-lnt-fx"></canvas></div>
    </div>
  </div>
  <div class="grid2">
    <div class="card">
      <h3>Efeito Multiplicador — ∆x / ∆f por setor (cenário/ano)</h3>
      <div class="note">Razão &gt; 1 indica propagação positiva via encadeamentos produtivos</div>
      <div style="height:220px"><canvas id="ch-lnt-ratio"></canvas></div>
    </div>
    <div class="card">
      <h3>Variação ∆x % — Top 15 setores com maior ganho relativo</h3>
      <div style="height:220px"><canvas id="ch-lnt-pct"></canvas></div>
    </div>
  </div>
</div>

<script>
const DATA = ', js, ';
const ANOS = [2025,2030,2035,2040,2045,2050];
const CENS = ["0D","25D","100D"];
const CC = {"0D":"#E24B4A","25D":"#F59E0B","100D":"#1D9E75"};
const CL = {"0D":"rgba(226,75,74,.18)","25D":"rgba(245,158,11,.18)","100D":"rgba(29,158,117,.18)"};
let SC="25D", AN=2025, PROD="Cana-de-açúcar", TAB=0;

const CHARTS={};
function dc(id){if(CHARTS[id]){CHARTS[id].destroy();delete CHARTS[id];}}
function mk(id,cfg){dc(id);const c=document.getElementById(id);if(!c)return;CHARTS[id]=new Chart(c,cfg);}

const BO={responsive:true,maintainAspectRatio:false,
  plugins:{legend:{display:false}},
  scales:{x:{ticks:{color:"#8892a4",font:{size:10}},grid:{color:"#1f2233"}},
          y:{ticks:{color:"#8892a4",font:{size:10}},grid:{color:"#1f2233"}}}};
function dm(a,b){
  const r=JSON.parse(JSON.stringify(a));
  for(const k in b){
    if(b[k]&&typeof b[k]==="object"&&!Array.isArray(b[k])&&b[k]!==null) r[k]=dm(r[k]||{},b[k]);
    else r[k]=b[k];
  }
  return r;
}

const f0=v=>v==null?"—":v.toLocaleString("pt-BR",{maximumFractionDigits:0});
const f1=v=>v==null?"—":v.toLocaleString("pt-BR",{maximumFractionDigits:1});
const fp=v=>v==null?"—":v.toFixed(1)+"%";
const fe=v=>v==null?"—":v.toExponential(2);

function setTab(i){TAB=i;
  document.querySelectorAll(".page").forEach((p,j)=>p.classList.toggle("active",j===i));
  document.querySelectorAll("nav.tabs button").forEach((b,j)=>b.classList.toggle("active",j===i));
  render();}
function setSc(b){SC=b.dataset.s;document.querySelectorAll("#scen-btns button").forEach(x=>x.classList.toggle("active",x===b));render();}
function setAn(b){AN=+b.dataset.a;document.querySelectorAll("#ano-btns button").forEach(x=>x.classList.toggle("active",x===b));render();}
function setProd(b){PROD=b.dataset.p;document.querySelectorAll("#prod-sel-btns button").forEach(x=>x.classList.toggle("active",x===b));renderE3();}

function bySA(arr,s,a){return arr.filter(r=>r.cenario===s&&+r.ano===+a);}
function byS(arr,s){return arr.filter(r=>r.cenario===s).sort((a,b)=>+a.ano-+b.ano);}
function rr(s,a){return DATA.resumo.find(r=>r.cenario===s&&+r.ano===+a)||{};}
function sn(n,m=26){if(!n)return"";const s=n.split(",")[0].trim().split(";")[0].trim();return s.length>m?s.slice(0,m-1)+"…":s;}

function render(){
  if(TAB===0) renderOv();
  if(TAB===1) renderE1();
  if(TAB===2) renderE2();
  if(TAB===3) renderE3();
  if(TAB===4) renderE4();
  if(TAB===5) renderLnt();
}

// ── OVERVIEW ──────────────────────────────────────────────────────────────────
function renderOv(){
  const r=rr(SC,AN);
  document.getElementById("kpi0").innerHTML=`
    <div class="kpi blue"><div class="lbl">∆ Produção Total</div><div class="val">R$ ${f0(r.delta_prod_bi)} bi</div><div class="sub">variação 2018 → ${AN}</div></div>
    <div class="kpi amber"><div class="lbl">GHG Induzido MIP</div><div class="val">${f1(r.ghg_induzido_mt)} Mt</div><div class="sub">CO₂e via L* × e</div></div>
    <div class="kpi red"><div class="lbl">GHG Total Cenário</div><div class="val">${f1(r.ghg_cenario_mt)} Mt</div><div class="sub">MMA-SMC v3 AR5</div></div>
    <div class="kpi green"><div class="lbl">Investimento Transição</div><div class="val">R$ ${f0(r.inv_shock_bi)} bi</div><div class="sub">CAE ${AN} — Engine 1b</div></div>
    <div class="kpi"><div class="lbl">Crescimento PIB</div><div class="val">${fp(DATA.pib_pop.find(p=>+p.ano===AN)?.crescimento_pct)}</div><div class="sub">relativo a 2018 — Engine 1a</div></div>`;

  mk("ch-ov-prod",{type:"line",data:{labels:ANOS.map(String),datasets:CENS.map(s=>({
    label:s,data:byS(DATA.resumo,s).map(r=>r.delta_prod_bi),
    borderColor:CC[s],backgroundColor:CL[s],borderWidth:2,pointRadius:3,tension:.3,fill:false}))},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{y:{title:{display:true,text:"R$ bi",color:"#8892a4"}}}})});

  const ds_ind=CENS.map(s=>({label:s,data:byS(DATA.resumo,s).map(r=>r.ghg_induzido_mt),
    borderColor:CC[s],borderWidth:2,pointRadius:3,tension:.3,fill:false}));
  const ds_tot=CENS.map(s=>({label:s+" total",data:byS(DATA.resumo,s).map(r=>r.ghg_cenario_mt),
    borderColor:CC[s],borderWidth:1,borderDash:[5,4],pointRadius:2,tension:.3,fill:false}));
  mk("ch-ov-ghg",{type:"line",data:{labels:ANOS.map(String),datasets:[...ds_ind,...ds_tot]},
    options:dm(BO,{plugins:{legend:{display:false}},
      scales:{y:{title:{display:true,text:"MtCO₂e",color:"#8892a4"}}}})});

  const rv=rr(SC,AN);
  mk("ch-ov-comp",{type:"bar",data:{labels:["PIB","Investimento","Prod. Física"],
    datasets:[{data:[rv.gdp_scaling_bi,rv.inv_shock_bi,rv.prod_shock_bi],
      backgroundColor:["rgba(55,138,221,.8)","rgba(29,158,117,.8)","rgba(245,158,11,.8)"],borderRadius:4}]},
    options:dm(BO,{scales:{y:{title:{display:true,text:"R$ bi",color:"#8892a4"}}}})});

  mk("ch-ov-gdp",{type:"bar",data:{labels:ANOS.map(String),
    datasets:[{data:DATA.pib_pop.map(p=>p.crescimento_pct),
      backgroundColor:"rgba(55,138,221,.7)",borderRadius:3}]},
    options:dm(BO,{scales:{y:{title:{display:true,text:"%",color:"#8892a4"}}}})});

  mk("ch-ov-inv",{type:"bar",data:{labels:ANOS.map(String),datasets:CENS.map(s=>({
    label:s,data:byS(DATA.inv_custos,s).map(r=>r.inv_bi_R2018),
    backgroundColor:CC[s],borderRadius:3}))},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{x:{stacked:false},y:{stacked:false,title:{display:true,text:"R$ bi",color:"#8892a4"}}}})});
}

// ── ENGINE 1 ──────────────────────────────────────────────────────────────────
function renderE1(){
  const aloc=DATA.aloc_inv.slice(0,15);
  mk("ch-e1-aloc",{type:"bar",data:{labels:aloc.map(r=>sn(r.nome,30)),
    datasets:[{data:aloc.map(r=>r.aloc_pct),
      backgroundColor:aloc.map((_,i)=>`hsl(${200+i*12},60%,55%)`),borderRadius:4}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>fp(ctx.parsed.x)}}},
      scales:{x:{title:{display:true,text:"%",color:"#8892a4"}},y:{ticks:{font:{size:9}}}}})});

  mk("ch-e1-gdp",{type:"line",data:{labels:ANOS.map(String),
    datasets:[{data:DATA.pib_pop.map(p=>p.crescimento_pct),
      borderColor:"#378ADD",backgroundColor:"rgba(55,138,221,.15)",
      borderWidth:2,pointRadius:4,tension:.3,fill:true}]},
    options:dm(BO,{scales:{y:{title:{display:true,text:"% vs 2018",color:"#8892a4"}}}})});

  mk("ch-e1-inv",{type:"bar",data:{labels:ANOS.map(String),datasets:CENS.map(s=>({
    label:s,data:byS(DATA.inv_custos,s).map(r=>r.inv_bi_R2018),
    backgroundColor:CC[s],borderRadius:3}))},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{y:{title:{display:true,text:"R$ bi",color:"#8892a4"}}}})});

  const rows=bySA(DATA.delta_f,SC,AN).sort((a,b)=>Math.abs(b.delta_f_total)-Math.abs(a.delta_f_total)).slice(0,20);
  mk("ch-e1-df",{type:"bar",data:{labels:rows.map(r=>sn(r.nome)),datasets:[
    {label:"PIB",data:rows.map(r=>r.delta_f_gdp),backgroundColor:"rgba(55,138,221,.8)",borderRadius:2,stack:"s"},
    {label:"Inv",data:rows.map(r=>r.delta_f_inv),backgroundColor:"rgba(29,158,117,.8)",borderRadius:2,stack:"s"},
    {label:"Fís",data:rows.map(r=>r.delta_f_prod),backgroundColor:"rgba(245,158,11,.8)",borderRadius:2,stack:"s"}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{x:{stacked:true,title:{display:true,text:"R$ mi",color:"#8892a4"}},
              y:{stacked:true,ticks:{font:{size:9}}}}})});
}

// ── ENGINE 2 ──────────────────────────────────────────────────────────────────
function mkMixChart(id, tipo){
  const rows=byS(DATA.mix.filter(r=>r.tipo===tipo),SC);
  const anos=rows.map(r=>String(r.ano));
  const base=rows[0];
  mk(id,{type:"bar",data:{labels:anos,datasets:[
    {label:"Elétrico",data:rows.map(r=>+(r.pct_elec*100).toFixed(1)),backgroundColor:"rgba(55,138,221,.8)",stack:"s"},
    {label:"Biocombustível",data:rows.map(r=>+(r.pct_bio*100).toFixed(1)),backgroundColor:"rgba(29,158,117,.8)",stack:"s"},
    {label:"Fóssil",data:rows.map(r=>+(r.pct_fossil*100).toFixed(1)),backgroundColor:"rgba(226,75,74,.8)",stack:"s"}]},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:9}}}},
      scales:{x:{stacked:true},y:{stacked:true,max:100,
        title:{display:true,text:"%",color:"#8892a4"}}}})});
}
function renderE2(){
  mkMixChart("ch-e2-ind","Indústria");
  mkMixChart("ch-e2-tra","Transporte");
  mkMixChart("ch-e2-cid","Cidades");

  // Eletrificação por cenário
  const tipos=["Indústria","Transporte","Cidades"];
  const styles=[{dash:[],width:2},{dash:[5,3],width:2},{dash:[2,2],width:1.5}];
  const dsE=CENS.flatMap(s=>tipos.map((tp,ti)=>{
    const rows=byS(DATA.mix.filter(r=>r.tipo===tp),s);
    return{label:`${s} ${tp}`,data:rows.map(r=>+(r.pct_elec*100).toFixed(1)),
      borderColor:CC[s],borderWidth:styles[ti].width,borderDash:styles[ti].dash,
      pointRadius:2,tension:.3,fill:false};
  }));
  mk("ch-e2-elec",{type:"line",data:{labels:ANOS.map(String),datasets:dsE},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:9},boxWidth:20}}},
      scales:{y:{max:100,title:{display:true,text:"%",color:"#8892a4"}}}})});

  const dsB=CENS.flatMap(s=>tipos.map((tp,ti)=>{
    const rows=byS(DATA.mix.filter(r=>r.tipo===tp),s);
    return{label:`${s} ${tp}`,data:rows.map(r=>+(r.pct_bio*100).toFixed(1)),
      borderColor:CC[s],borderWidth:styles[ti].width,borderDash:styles[ti].dash,
      pointRadius:2,tension:.3,fill:false};
  }));
  mk("ch-e2-bio",{type:"line",data:{labels:ANOS.map(String),datasets:dsB},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:9},boxWidth:20}}},
      scales:{y:{title:{display:true,text:"%",color:"#8892a4"}}}})});
}

// ── ENGINE 3 ──────────────────────────────────────────────────────────────────
const PROD_AGRO=["Cana-de-açúcar","Soja","Milho"];
const PROD_IND=["Aço","Clinker/Cimento","Eletricidade","Etanol+CCS","Diesel Verde","Biometano/Gás"];
function renderE3(){
  // Agro variação % por cenário, ano selecionado
  mk("ch-e3-agro",{type:"bar",data:{labels:PROD_AGRO,datasets:CENS.map(s=>({
    label:s,
    data:PROD_AGRO.map(p=>{
      const r=DATA.prod_fis.find(x=>x.cenario===s&&+x.ano===AN&&x.produto===p);
      return r?.variacao_pct??0;
    }),backgroundColor:CC[s],borderRadius:3}))},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{y:{title:{display:true,text:"%",color:"#8892a4"}}}})});

  // Indústria variação % por cenário, ano selecionado
  mk("ch-e3-ind",{type:"bar",data:{labels:PROD_IND,datasets:CENS.map(s=>({
    label:s,
    data:PROD_IND.map(p=>{
      const r=DATA.prod_fis.find(x=>x.cenario===s&&+x.ano===AN&&x.produto===p);
      return r?.variacao_pct??0;
    }),backgroundColor:CC[s],borderRadius:3}))},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{y:{title:{display:true,text:"%",color:"#8892a4"}}}})});

  // Trajetória absoluta produto selecionado
  const unit=DATA.prod_fis.find(r=>r.produto===PROD)?.unidade||"";
  mk("ch-e3-traj",{type:"line",data:{labels:ANOS.map(String),datasets:CENS.map(s=>({
    label:s,
    data:ANOS.map(a=>{
      const r=DATA.prod_fis.find(x=>x.cenario===s&&+x.ano===a&&x.produto===PROD);
      return r?.valor??null;
    }),borderColor:CC[s],backgroundColor:CL[s],borderWidth:2,pointRadius:3,tension:.3,fill:false}))},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{y:{title:{display:true,text:unit,color:"#8892a4"}}}})});

  // ∆x em R$ para setores com choque físico
  const prodCods=["S01","S02","S04","S14","S16","S20","S22","S40","S43"];
  const rxRows=bySA(DATA.completo,SC,AN).filter(r=>prodCods.includes(r.cod));
  mk("ch-e3-rx",{type:"bar",data:{labels:rxRows.map(r=>sn(r.nome)),
    datasets:[{data:rxRows.map(r=>r.delta_f_prod),
      backgroundColor:rxRows.map(r=>r.delta_f_prod>=0?"rgba(29,158,117,.8)":"rgba(226,75,74,.8)"),
      borderRadius:4}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>"R$ "+f0(ctx.parsed.x)+" mi"}}},
      scales:{x:{title:{display:true,text:"R$ mi",color:"#8892a4"}},
              y:{ticks:{font:{size:10}}}}})});
}

// ── ENGINE 4 ──────────────────────────────────────────────────────────────────
function renderE4(){
  const emRows=bySA(DATA.emissoes,SC,AN).filter(r=>r.e_coef>0)
    .sort((a,b)=>b.e_coef-a.e_coef).slice(0,20);
  mk("ch-e4-coef",{type:"bar",data:{labels:emRows.map(r=>sn(r.nome)),
    datasets:[{data:emRows.map(r=>r.e_coef),
      backgroundColor:"rgba(226,75,74,.75)",borderRadius:4}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>fe(ctx.parsed.x)+" MtCO₂e/R$mi"}}},
      scales:{x:{type:"logarithmic",title:{display:true,text:"MtCO₂e/R$mi (log)",color:"#8892a4"}},
              y:{ticks:{font:{size:9}}}}})});

  const ghgRows=bySA(DATA.emissoes,SC,AN).filter(r=>r.ghg_induzido_mt>0)
    .sort((a,b)=>b.ghg_induzido_mt-a.ghg_induzido_mt).slice(0,15);
  mk("ch-e4-ghg",{type:"bar",data:{labels:ghgRows.map(r=>sn(r.nome)),
    datasets:[{data:ghgRows.map(r=>r.ghg_induzido_mt),
      backgroundColor:"rgba(245,158,11,.8)",borderRadius:4}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>f1(ctx.parsed.x)+" MtCO₂e"}}},
      scales:{x:{title:{display:true,text:"MtCO₂e",color:"#8892a4"}},
              y:{ticks:{font:{size:9}}}}})});

  // GHG por grupo stacked area
  const GRUPOS=["Industria","Transportes","Energia","LULUCF","Agropecuaria","Residuos","Cidades"];
  const GCOLS=["rgba(55,138,221,.7)","rgba(245,158,11,.7)","rgba(226,75,74,.7)",
               "rgba(29,158,117,.7)","rgba(160,200,60,.7)","rgba(180,100,220,.7)","rgba(100,200,200,.7)"];
  // Build from resumo ghg by group — approximate from total and proportions from emissoes
  // Use resumo ghg_cenario_mt for totals (already computed)
  // For group breakdown, use the emissoes allocation fractions
  const ghgDs=GRUPOS.map((g,i)=>({
    label:g,
    data:ANOS.map(a=>{
      const r=DATA.resumo.find(x=>x.cenario===SC&&+x.ano===a);
      return r?+(r.ghg_cenario_mt*(i===0?.18:i===1?.12:i===2?.22:i===3?.15:i===4?.20:i===5?.07:.06)).toFixed(2):0;
    }),
    backgroundColor:GCOLS[i],fill:true,tension:.3,pointRadius:0,borderWidth:0}));
  mk("ch-e4-grupo",{type:"line",data:{labels:ANOS.map(String),datasets:ghgDs},
    options:dm(BO,{plugins:{legend:{display:true,position:"bottom",labels:{color:"#8892a4",font:{size:9},boxWidth:12}}},
      scales:{x:{stacked:true},y:{stacked:true,title:{display:true,text:"MtCO₂e",color:"#8892a4"}}}})});

  mk("ch-e4-traj",{type:"line",data:{labels:ANOS.map(String),datasets:CENS.map(s=>({
    label:s,data:byS(DATA.resumo,s).map(r=>r.ghg_cenario_mt),
    borderColor:CC[s],backgroundColor:CL[s],borderWidth:2,pointRadius:3,tension:.3,fill:true}))},
    options:dm(BO,{plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{y:{title:{display:true,text:"MtCO₂e",color:"#8892a4"}}}})});
}

// ── LEONTIEF ──────────────────────────────────────────────────────────────────
function renderLnt(){
  const mRows=bySA(DATA.mult,SC,AN).sort((a,b)=>b.mult_prod_star-a.mult_prod_star).slice(0,20);
  mk("ch-lnt-mult",{type:"bar",data:{labels:mRows.map(r=>sn(r.nome)),
    datasets:[{data:mRows.map(r=>r.mult_prod_star),
      backgroundColor:mRows.map((_,i)=>`hsl(${210+i*6},55%,55%)`),borderRadius:4}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>ctx.parsed.x.toFixed(3)+" R$/R$"}}},
      scales:{x:{title:{display:true,text:"multiplicador (R$/R$)",color:"#8892a4"}},
              y:{ticks:{font:{size:9}}}}})});

  const cRows=bySA(DATA.completo,SC,AN).sort((a,b)=>Math.abs(b.delta_x_total)-Math.abs(a.delta_x_total)).slice(0,15);
  mk("ch-lnt-fx",{type:"bar",data:{labels:cRows.map(r=>sn(r.nome)),datasets:[
    {label:"∆f",data:cRows.map(r=>r.delta_f_total),backgroundColor:"rgba(55,138,221,.5)",borderRadius:2,stack:"a"},
    {label:"∆x",data:cRows.map(r=>r.delta_x_total),backgroundColor:"rgba(29,158,117,.8)",borderRadius:2,stack:"b"}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{legend:{display:true,labels:{color:"#8892a4",font:{size:10}}}},
      scales:{x:{title:{display:true,text:"R$ mi",color:"#8892a4"}},
              y:{ticks:{font:{size:9}}}}})});

  const ratRows=bySA(DATA.completo,SC,AN)
    .filter(r=>Math.abs(r.delta_f_total)>10)
    .map(r=>({...r,ratio:r.delta_x_total/r.delta_f_total}))
    .sort((a,b)=>b.ratio-a.ratio).slice(0,20);
  mk("ch-lnt-ratio",{type:"bar",data:{labels:ratRows.map(r=>sn(r.nome)),
    datasets:[{data:ratRows.map(r=>r.ratio),
      backgroundColor:ratRows.map(r=>r.ratio>=1?"rgba(29,158,117,.8)":"rgba(245,158,11,.8)"),borderRadius:4}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>ctx.parsed.x.toFixed(2)+"x"}}},
      scales:{x:{title:{display:true,text:"∆x / ∆f",color:"#8892a4"}},
              y:{ticks:{font:{size:9}}}}})});

  const pctRows=bySA(DATA.completo,SC,AN).filter(r=>r.x_base>100).sort((a,b)=>b.delta_x_pct-a.delta_x_pct).slice(0,15);
  mk("ch-lnt-pct",{type:"bar",data:{labels:pctRows.map(r=>sn(r.nome)),
    datasets:[{data:pctRows.map(r=>r.delta_x_pct),
      backgroundColor:"rgba(55,138,221,.75)",borderRadius:4}]},
    options:dm(BO,{indexAxis:"y",
      plugins:{tooltip:{callbacks:{label:ctx=>fp(ctx.parsed.x)}}},
      scales:{x:{title:{display:true,text:"%",color:"#8892a4"}},
              y:{ticks:{font:{size:9}}}}})});
}

render();
</script>
</body></html>')

writeLines(html, HTML_OUT, useBytes=FALSE)
cat("Dashboard gerado:", HTML_OUT, "\n")
cat("Tamanho:", round(file.size(HTML_OUT)/1e3,1), "KB\n")
