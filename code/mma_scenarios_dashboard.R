# =============================================================================
# MMA SCENARIOS DASHBOARD  v2
# Focus: 100D vs Baseline · direct/indirect · grouping filter · energy highlight
#
# Input:  outputs/tables/mma_shock_results.xlsx
# Output: outputs/mma_scenarios_dashboard.html
# =============================================================================
library(readxl); library(jsonlite); library(dplyr)
setwd("C:/Users/Camila Ludovique/Documents/GitHub/brazil-climate-macro-model")

XLS      <- "outputs/tables/mma_shock_results.xlsx"
HTML_OUT <- "outputs/mma_scenarios_dashboard.html"
if (!file.exists(XLS)) stop("Run mma_shock_engines.R first.")
if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
cat("Reading:", XLS, "\n")

sheets_need <- c("Resumo","Resultados_Completos","Delta_F_Componentes",
                 "Energia_Impacto","Mix_Energetico","PIB_Pop",
                 "Aloc_Investimento","Mapeamento_Setores",
                 "Demanda_Componentes","Coef_Tecnicos",
                 "Ind_Ligacoes","Linkage_Comp",
                 "Mult_Producao","Mult_Emprego",
                 "Labor_Baseline","Tax_Choques","Tax_Base",
                 "Macro_Base","Producao_Fisica")
dat <- lapply(sheets_need, function(s) suppressMessages(read_excel(XLS, sheet = s)))
names(dat) <- sheets_need

js <- toJSON(dat, na = "null", digits = 4, auto_unbox = TRUE)
cat("JSON:", round(nchar(js)/1e3,1), "KB\n")

# =============================================================================
html <- paste0(r"[<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MMA 100D — Engines 1 &amp; 2 &amp; 3</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-chart-sankey@0.13.0/dist/chartjs-chart-sankey.min.js"></script>
<style>
:root{
  --bg:#0f1117;--card:#1a1d27;--bdr:#2a2d3e;--txt:#e2e8f0;--mut:#8892a4;
  --acc:#378ADD;--100d:#E24B4A;--base:#888780;--trans:#F39C12;--renov:#1D9E75;
}
*{box-sizing:border-box}
body{background:var(--bg);color:var(--txt);font-family:"Inter","Segoe UI",sans-serif;font-size:13px;margin:0}
/* TOP BAR */
.topbar{background:#13151f;border-bottom:1px solid var(--bdr);padding:9px 24px;
  display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:110}
.topbar h1{font-size:14px;font-weight:700;color:#fff;margin:0}
.topbar span{font-size:11px;color:var(--mut)}
/* TABS */
nav.tabs{background:#13151f;border-bottom:1px solid var(--bdr);padding:0 24px;
  display:flex;gap:2px;overflow-x:auto;position:sticky;top:40px;z-index:109}
nav.tabs button{background:none;border:none;color:var(--mut);padding:8px 14px;
  font-size:12px;cursor:pointer;border-bottom:2px solid transparent;white-space:nowrap;transition:.15s}
nav.tabs button.active{color:#fff;border-bottom-color:var(--acc)}
nav.tabs button:hover:not(.active){color:var(--txt)}
/* CTRL BAR */
.ctrlbar{background:#13151f;border-bottom:1px solid var(--bdr);padding:6px 24px;
  display:flex;align-items:center;gap:10px;flex-wrap:wrap;position:sticky;top:80px;z-index:108}
.clbl{font-size:9px;font-weight:700;color:var(--mut);text-transform:uppercase;letter-spacing:.1em;white-space:nowrap}
.tog-grp{display:flex;gap:3px;flex-wrap:wrap}
.tog{border:1px solid currentColor;padding:2px 10px;border-radius:10px;font-size:11px;
  cursor:pointer;transition:.15s;background:transparent;white-space:nowrap;color:var(--mut);border-color:var(--bdr)}
.tog.on{opacity:1}
.tog:not(.on){opacity:.28;border-style:dashed}
.tog:hover{opacity:.8!important}
.vdiv{width:1px;height:18px;background:var(--bdr);margin:0 4px}
/* LAYOUT */
.tab-panel{display:none;padding:16px 24px}.tab-panel.active{display:block}
.g2{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px}
.g3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;margin-bottom:12px}
.g4{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:12px}
.full{grid-column:1/-1}
.card{background:var(--card);border:1px solid var(--bdr);border-radius:8px;padding:13px;margin-bottom:12px}
.ct{font-size:10px;font-weight:700;color:var(--mut);text-transform:uppercase;letter-spacing:.07em;margin-bottom:9px}
.kpi{text-align:center;padding:14px 8px}
.kpi .v{font-size:24px;font-weight:700;color:#fff;line-height:1}
.kpi .v2{font-size:14px;font-weight:600;margin-top:4px}
.kpi .l{font-size:11px;color:var(--mut);margin-top:4px}
.kpi .s{font-size:10px;color:var(--mut);margin-top:2px}
.cost-label{font-size:9px;font-weight:700;color:var(--mut);text-transform:uppercase;
  letter-spacing:.1em;padding:3px 7px;border-radius:3px;background:#1f2233;margin-bottom:2px;display:inline-block}
.cw{position:relative;height:250px}.cw.tall{height:340px}.cw.xtall{height:440px}
/* GROUP FILTER CHIPS */
.chips{display:flex;flex-wrap:wrap;gap:4px;margin-bottom:8px}
.chip{border:1px solid currentColor;padding:2px 8px;border-radius:8px;font-size:10px;
  font-weight:600;cursor:pointer;transition:.15s;background:transparent;white-space:nowrap}
.chip.on{opacity:1}
.chip:not(.on){opacity:.2;border-style:dashed}
.chip:hover{opacity:.75!important}
/* TABLE */
table.dt{width:100%;border-collapse:collapse;font-size:11px}
table.dt th{background:#1f2233;color:var(--mut);font-weight:500;padding:5px 8px;
  text-align:left;border-bottom:1px solid var(--bdr);cursor:pointer;white-space:nowrap}
table.dt th:hover{color:#fff}
table.dt td{padding:4px 8px;border-bottom:1px solid #1a1d2a}
table.dt tr:hover td{background:#1f2233}
.sb{background:#1f2233;border:1px solid var(--bdr);color:var(--txt);
  border-radius:5px;padding:4px 9px;font-size:11px;width:180px;outline:none}
.sb:focus{border-color:var(--acc)}
/* ── Responsive ── */
@media(max-width:900px){
  .g2,.g3,.g4{grid-template-columns:1fr}
  .g5c{grid-template-columns:1fr 1fr!important}
  .full{grid-column:1}
  .tab-panel{padding:10px 12px}
  .topbar{padding:8px 12px;flex-wrap:wrap;gap:6px}
  .topbar span{display:none}
  .ctrlbar{padding:5px 12px;top:52px}
  nav.tabs{top:36px;padding:0 12px}
  .kpi .v{font-size:20px}
}
@media(max-width:600px){
  .g2,.g3,.g4,.g5c{grid-template-columns:1fr!important}
  .cw{height:200px}
  .cw.tall{height:260px}
  .cw.xtall{height:320px}
  table.dt{font-size:10px}
  .topbar h1{font-size:12px}
}
</style></head>
<body>

<div class="topbar">
  <a href="index.html" style="color:var(--mut);font-size:11px;text-decoration:none;white-space:nowrap">← MIP-EPE</a>
  <h1>MMA 100D &mdash; Engines 1 &amp; 2 &amp; 3</h1>
  <span>100D vs Linha de Base &nbsp;&bull;&nbsp; Base: MIP-EPE 2018 &nbsp;&bull;&nbsp; 73 setores</span>
</div>

<nav class="tabs" id="mainTabs">
  <button class="active" onclick="showTab(0)">📋 Premissas</button>
  <button onclick="showTab(1)">🏭 Rede Produtiva</button>
  <button onclick="showTab(2)">📊 Resultados Macro</button>
</nav>

<!-- CTRL BAR: year filter only -->
<div class="ctrlbar">
  <span class="clbl">Ano:</span>
  <div class="tog-grp" id="ctrl-ano"></div>
</div>

<!-- ══ TAB 0: PREMISSAS ══════════════════════════════════════════════════════ -->
<div class="tab-panel active" id="tab0">

  <!-- ── Visão Geral: 3 Choques ─────────────────────────────────────────── -->
  <div style="margin-bottom:20px">
    <p style="font-size:12px;color:var(--mut);line-height:1.8;margin:0 0 14px">
      O modelo MMA 100D traduz as metas e projeções do Plano Clima MMA em
      <b style="color:var(--txt)">choques de demanda</b> sobre a Matriz Insumo-Produto MIP-EPE 2018 (73 setores).
      A diferença entre o cenário 100D e a <b style="color:var(--txt)">Linha de Base (crescimento via PIB apenas)</b>
      define o <b style="color:#1D9E75">prêmio da transição</b> — o impacto líquido da política climática sobre
      produção, emprego, renda e finanças públicas. Três choques estruturais são aplicados sequencialmente sobre a MIP.
    </p>
    <div class="g3" style="margin-bottom:6px">
      <div class="card" style="border-left:3px solid #378ADD">
        <div class="s" style="text-transform:uppercase;letter-spacing:.08em;font-size:9px;color:#378ADD;margin-bottom:6px">Choque 1 · Demanda Macroeconômica</div>
        <div style="font-weight:700;color:var(--txt);font-size:13px;margin-bottom:8px">Engines 1a &amp; 1b — PIB + Investimento Verde</div>
        <p style="font-size:10.5px;color:var(--mut);line-height:1.8;margin:0">
          <b style="color:var(--txt)">Engine 1a</b> escala o vetor de demanda final f₂₀₁₈ pela trajetória de PIB do MMA
          (fator 0.97 para conversão à base 2018). Todos os componentes da demanda final crescem proporcionalmente:
          consumo das famílias, governo, FBCF e exportações.<br><br>
          <b style="color:var(--txt)">Engine 1b</b> converte o plano de investimentos de transição do MMA
          em choques de FBCF setoriais — alocando capital verde (eólica, solar, redes, veículos elétricos,
          biocombustíveis) nos setores IO correspondentes.
        </p>
      </div>
      <div class="card" style="border-left:3px solid #E24B4A">
        <div class="s" style="text-transform:uppercase;letter-spacing:.08em;font-size:9px;color:#E24B4A;margin-bottom:6px">Choque 2 · Mix Energético</div>
        <div style="font-weight:700;color:var(--txt);font-size:13px;margin-bottom:8px">Engine 2 — Substituição de Coeficientes Técnicos</div>
        <p style="font-size:10.5px;color:var(--mut);line-height:1.8;margin:0">
          Repondera as linhas energéticas da matriz A (fóssil → renovável) conforme as metas de descarbonização
          setorial do MMA. Cada sub-setor — Ferro &amp; Aço, Cimento, Químico, Transporte, Cidades, Geração Elétrica —
          recebe fatores de escala próprios, calibrados a partir das tabelas de mix energético do plano.<br><br>
          O choque modifica <b style="color:var(--txt)">qual energia é consumida</b> por unidade produzida —
          reduzindo intensidade fóssil e expandindo biomassa e eletricidade renovável — sem alterar o nível
          de produção diretamente.
        </p>
      </div>
      <div class="card" style="border-left:3px solid #1D9E75">
        <div class="s" style="text-transform:uppercase;letter-spacing:.08em;font-size:9px;color:#1D9E75;margin-bottom:6px">Choque 3 · Volumes Físicos Setoriais</div>
        <div style="font-weight:700;color:var(--txt);font-size:13px;margin-bottom:8px">Engine 3 — Calibração por Trajetória Física</div>
        <p style="font-size:10.5px;color:var(--mut);line-height:1.8;margin:0">
          Para 9 setores-chave com dados físicos no MMA (energia, agro, indústria pesada), substitui o
          escalonamento do PIB por trajetórias físicas diretas (TWh, PJ, Mt, kbep). Computa Δx via razão
          volume/base₂₀₂₀, converte em choque de demanda equivalente Δf = (I − A*)·Δx, e zera o GDP-scaling
          correspondente para evitar dupla contagem.<br><br>
          Resultado agregado: <b style="color:var(--txt)">Δx_total = L* · ΔF_completo + Δx_engine3</b>
        </p>
      </div>
    </div>
  </div>

  <!-- 1 · PIB -->
  <div style="margin-bottom:4px"><span class="cost-label">📈 1 · Macroeconomia — PIB (Engine 1a)</span></div>
  <div class="g2" style="margin-bottom:16px">
    <div class="card">
      <div class="ct">Índice PIB — 2018–2050 (relativo a 2018, fator 0.97)</div>
      <div class="cw"><canvas id="ch-gdp-idx"></canvas></div>
    </div>
    <div class="card" style="display:flex;align-items:center">
      <div style="width:100%">
        <div class="ct">Engine 1a — Escalonamento pelo PIB MMA</div>
        <p style="font-size:11px;color:var(--mut);line-height:1.9;margin:0">
          O PIB projetado pelo MMA é expresso em índice relativo a 2020. Aplicamos um fator
          <b style="color:var(--txt)">0.97</b> para converter à base 2018 (ano-base da MIP-EPE), alinhando
          as trajetórias ao nível de preços constantes da matriz.<br><br>
          O choque de demanda é calculado como:
          <b style="color:#F39C12">Δf_PIB = f_2018 · (PIB_rel − 1)</b><br>
          onde f_2018 é o vetor de demanda final observado em 2018 (consumo das famílias, governo incl. ISFLSF,
          FBCF e exportações). Cada componente cresce proporcionalmente à mesma taxa do PIB — capturando a
          estrutura produtiva de 2018 como ponto de partida.<br><br>
          <b style="color:var(--txt)">Linha de Base:</b> o resultado do Engine 1a com a trajetória de PIB sem
          investimentos adicionais define o contrafactual — a referência para calcular o prêmio da transição.
        </p>
      </div>
    </div>
  </div>

  <!-- 2 · INVESTIMENTO -->
  <div style="margin-bottom:4px"><span class="cost-label">💰 2 · Investimento de Transição — Engine 1b</span></div>
  <!-- KPIs first -->
  <div class="g3" style="margin-bottom:8px">
    <div class="card kpi">
      <div class="v" style="font-size:20px;color:#378ADD">R$ 11.638 bi</div>
      <div class="l">VP Investimento 2020–2030</div><div class="s">10 anos · capex intenso · R$ bi 2023</div>
    </div>
    <div class="card kpi">
      <div class="v" style="font-size:20px;color:#378ADD">R$ 3.805 bi</div>
      <div class="l">VP Investimento 2031–2035</div><div class="s">5 anos · transição · R$ bi 2023</div>
    </div>
    <div class="card kpi">
      <div class="v" style="font-size:20px;color:#378ADD">R$ 4.584 bi</div>
      <div class="l">VP Investimento 2036–2050</div><div class="s">15 anos · manutenção · R$ bi 2023</div>
    </div>
  </div>
  <!-- VP + CAE side by side -->
  <div class="g2" style="margin-bottom:8px">
    <div class="card">
      <div class="ct">VP Investimento por Período — 100D (R$ bi total)</div>
      <div class="cw"><canvas id="ch-inv-pv"></canvas></div>
    </div>
    <div class="card">
      <div class="ct">CAE — Custo Anualizado Equivalente por Período — 100D (R$ bi/ano)</div>
      <div class="cw"><canvas id="ch-inv-cae"></canvas></div>
    </div>
  </div>
  <!-- FBCF by sector + allocation methodology -->
  <div class="g2" style="margin-bottom:16px">
    <div class="card">
      <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;margin-bottom:8px">
        <div class="ct" style="margin:0">FBCF — Alocação por Setor IO (R$ bi, 100D · ano selecionado no filtro)</div>
        <div style="display:flex;gap:12px;flex-wrap:wrap">
          <span style="display:flex;align-items:center;gap:5px;font-size:10px;color:var(--mut)">
            <span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#E24B4A"></span>Energéticos</span>
          <span style="display:flex;align-items:center;gap:5px;font-size:10px;color:var(--mut)">
            <span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#378ADD"></span>Indústria</span>
          <span style="display:flex;align-items:center;gap:5px;font-size:10px;color:var(--mut)">
            <span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#B4B2A9"></span>Serviços</span>
          <span style="display:flex;align-items:center;gap:5px;font-size:10px;color:var(--mut)">
            <span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:#3B6D11"></span>Agropecuária</span>
        </div>
      </div>
      <div class="cw xtall"><canvas id="ch-aloc"></canvas></div>
    </div>
    <div class="card" style="display:flex;align-items:flex-start">
      <div style="width:100%;padding-top:2px">
        <div class="ct">Engine 1b — Mapeamento Tecnologia → Setor IO</div>
        <p style="font-size:10.5px;color:var(--mut);line-height:1.8;margin:0 0 8px">
          Pesos derivados dos dados físicos do MMA (ΔGW instalado × capex unitário por tecnologia).
          Premissa simplificadora: <b style="color:var(--txt)">100% de produção doméstica</b> — todo o
          investimento de transição estimula setores da economia brasileira sem ajuste de vazamento importado.
        </p>

        <!-- Allocation groups table — reflects actual derive_aloc_inv() mapping -->
        <table style="width:100%;font-size:10.5px;border-collapse:collapse;margin-bottom:8px">
          <thead><tr>
            <th style="color:var(--mut);font-weight:500;padding:3px 6px;border-bottom:1px solid var(--bdr);text-align:left">Tecnologia / tema</th>
            <th style="color:var(--mut);font-weight:500;padding:3px 6px;border-bottom:1px solid var(--bdr);text-align:left">Setor IO</th>
            <th style="color:var(--mut);font-weight:500;padding:3px 6px;border-bottom:1px solid var(--bdr);text-align:right">~Peso¹</th>
            <th style="color:var(--mut);font-weight:500;padding:3px 6px;border-bottom:1px solid var(--bdr);text-align:left">O que captura</th>
          </tr></thead>
          <tbody>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#11B2C6;font-weight:600">Construção civil</td>
              <td style="padding:3px 6px;color:var(--mut)">S45</td>
              <td style="padding:3px 6px;color:#11B2C6;font-weight:700;text-align:right">~40%</td>
              <td style="padding:3px 6px;color:var(--mut)">Terraplenagem, fundações e montagem para eólica, solar, hidro, nuclear, bioCCS, biofuels, copro e edificações</td>
            </tr>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#1D9E75;font-weight:600">Biocombustíveis complexo</td>
              <td style="padding:3px 6px;color:var(--mut)">S22</td>
              <td style="padding:3px 6px;color:#1D9E75;font-weight:700;text-align:right">~19%</td>
              <td style="padding:3px 6px;color:var(--mut)">Plantas de biomassa-eletricidade+CCS, biometano, diesel verde (HVO), bioQAV e etanol+CCS</td>
            </tr>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#9B59B6;font-weight:600">Turbinas eólicas</td>
              <td style="padding:3px 6px;color:var(--mut)">S34 <span style="color:#555;font-size:9px">CNAE 2821</span></td>
              <td style="padding:3px 6px;color:#9B59B6;font-weight:700;text-align:right">~9%²</td>
              <td style="padding:3px 6px;color:var(--mut)">Máq. e equip. mecânicos — naceles, caixas de câmbio, eixos (CNAE 2821-6: turbinas, bombas, compressores)</td>
            </tr>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#F39C12;font-weight:600">Equipamentos elétricos</td>
              <td style="padding:3px 6px;color:var(--mut)">S33</td>
              <td style="padding:3px 6px;color:#F39C12;font-weight:700;text-align:right">~9%</td>
              <td style="padding:3px 6px;color:var(--mut)">Inversores, transformadores, HVAC, motores — presente em eólica, solar, baterias, copro, EVs e edificações</td>
            </tr>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#378ADD;font-weight:600">Transmissão &amp; distribuição</td>
              <td style="padding:3px 6px;color:var(--mut)">S42</td>
              <td style="padding:3px 6px;color:#378ADD;font-weight:700;text-align:right">~7%</td>
              <td style="padding:3px 6px;color:var(--mut)">Expansão de linhas de transmissão e subestações para escoar geração eólica, solar e hidro</td>
            </tr>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#95A5A6;font-weight:600">Metalurgia</td>
              <td style="padding:3px 6px;color:var(--mut)">S30</td>
              <td style="padding:3px 6px;color:#95A5A6;font-weight:700;text-align:right">~4%</td>
              <td style="padding:3px 6px;color:var(--mut)">Turbinas hidráulicas, vasos de pressão bioCCS e reatores biofuels (metais não-ferrosos e fundição)</td>
            </tr>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#E67E22;font-weight:600">Refino &amp; coprocessamento</td>
              <td style="padding:3px 6px;color:var(--mut)">S19 · S27</td>
              <td style="padding:3px 6px;color:#E67E22;font-weight:700;text-align:right">~2.5%</td>
              <td style="padding:3px 6px;color:var(--mut)">Adaptação de refinarias para HVO/SAF (S19) e insumos petroquímicos do processo (S27)</td>
            </tr>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#E24B4A;font-weight:600">Transporte elétrico</td>
              <td style="padding:3px 6px;color:var(--mut)">S35 · S36</td>
              <td style="padding:3px 6px;color:#E24B4A;font-weight:700;text-align:right">~2%</td>
              <td style="padding:3px 6px;color:var(--mut)">Veículos elétricos leves e pesados (S35) e peças/baterias automotivas (S36)</td>
            </tr>
            <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
              <td style="padding:3px 6px;color:#7F8C8D;font-weight:600">Painéis &amp; armazenamento</td>
              <td style="padding:3px 6px;color:var(--mut)">S32</td>
              <td style="padding:3px 6px;color:#7F8C8D;font-weight:700;text-align:right">~1%²</td>
              <td style="padding:3px 6px;color:var(--mut)">Painéis solares + baterias utility-scale + automação predial (eletrônicos e ópticos)</td>
            </tr>
            <tr>
              <td style="padding:3px 6px;color:#8E44AD;font-weight:600">Nuclear O&amp;M</td>
              <td style="padding:3px 6px;color:var(--mut)">S39</td>
              <td style="padding:3px 6px;color:#8E44AD;font-weight:700;text-align:right">~1%</td>
              <td style="padding:3px 6px;color:var(--mut)">Manutenção, reparação e instalação de máquinas — expansão da capacidade nuclear existente</td>
            </tr>
          </tbody>
        </table>

        <p style="font-size:10px;color:var(--mut);line-height:1.7;margin:0">
          <b style="color:var(--txt)">Mecanismo:</b>
          CAE (R$ bi/ano) × ALOC_INV[s, ano] → Δf[s] (choque FBCF setorial) → L* · Δf → Δx (produção induzida).<br>
          <b style="color:var(--txt)">Normalização:</b> pesos somam 1.0 — o total do investimento é integralmente alocado sem dupla contagem.<br>
          <b style="color:var(--txt)">S20 excluído:</b> biodiesel/HVO já cresce via Engine 3 (volume físico MMA calibrado) — incluir FBCF em S20 criaria dupla contagem.<br>
          <b style="color:var(--txt)">S40/S41 excluídos:</b> geração elétrica cresce via Engine 3; FBCF em S40/S41 seria também dupla contagem.<br>
          ¹ Pesos aproximados, 100D · 2050. Variam por ano conforme o capex incremental de cada tecnologia muda.
        </p>
      </div>
    </div>
  </div>

  <!-- 3 · MIX ENERGÉTICO — ENGINE 2 -->
  <div style="margin-bottom:4px"><span class="cost-label">⚡ 3 · Mix Energético — Engine 2 (substituição de coeficientes técnicos na matriz A)</span></div>

  <!-- 3a: Três grupos principais lado a lado -->
  <div style="margin-bottom:4px;font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.07em">3a · Grupos principais — % por tipo de combustível (100D) · dados extraídos das planilhas MMA</div>
  <div class="g3" style="margin-bottom:8px">
    <div class="card">
      <div class="ct">Indústria</div>
      <p style="font-size:10px;color:var(--mut);line-height:1.6;margin:0 0 6px">
        Agregado de Ferro &amp; Aço, Cimento, Químico e Outros. Biomassa avança de <b style="color:var(--txt)">23%</b>
        para <b style="color:#1D9E75">56%</b> até 2050, substituindo principalmente fóssil (44% → 11%).
        Eletricidade permanece estável (~33%).
      </p>
      <div class="cw tall"><canvas id="ch-mix-ind"></canvas></div>
    </div>
    <div class="card">
      <div class="ct">Transporte</div>
      <p style="font-size:10px;color:var(--mut);line-height:1.6;margin:0 0 6px">
        A transição mais intensa. Fóssil cai de <b style="color:#E24B4A">69%</b> para <b style="color:var(--txt)">17%</b>;
        biomassa (etanol, biodiesel, SAF) cresce de 30% → <b style="color:#1D9E75">67%</b>;
        elétrico sai de 0.4% → <b style="color:#F39C12">17%</b> (VEs + trens).
      </p>
      <div class="cw tall"><canvas id="ch-mix-tra"></canvas></div>
    </div>
    <div class="card">
      <div class="ct">Cidades / Edifícios</div>
      <p style="font-size:10px;color:var(--mut);line-height:1.6;margin:0 0 6px">
        Predominantemente elétrico desde 2020 (63%). No cenário 100D, eletricidade expande para
        <b style="color:#F39C12">84%</b> até 2050; gás/fóssil recua de 37% para <b style="color:var(--txt)">5%</b>.
        Biomassa permanece marginal (&lt;11%).
      </p>
      <div class="cw tall"><canvas id="ch-mix-cid"></canvas></div>
    </div>
  </div>

  <!-- 3a: como os dados são usados -->
  <div style="margin-bottom:10px">
    <div class="card">
      <div class="ct">Como os gráficos 3a alimentam o Engine 2 — do mix energético à modificação de A*</div>
      <div class="g2" style="margin-top:8px;gap:16px">
        <div>
          <p style="font-size:10.5px;color:var(--mut);line-height:1.8;margin:0 0 8px">
            Cada ponto dos gráficos 3a é uma <b style="color:var(--txt)">participação percentual por tipo de combustível</b>
            (elétrico, biomassa, fóssil) extraída diretamente das tabelas de mix setorial do plano MMA.
            Para cada sub-setor e ano, o Engine 2 computa um <b style="color:var(--txt)">fator de escala</b>
            comparando o mix 100D com o mix base 2020:<br><br>
            <code style="background:rgba(255,255,255,.06);padding:2px 6px;border-radius:3px;font-size:10px">
              sc_combustível = % 100D / % base 2020
            </code><br><br>
            Esses fatores são aplicados às linhas energéticas da coluna <i>j</i> de A:
            A[S40/S41, j] × sc_elec · A[S20/S22, j] × sc_bio · A[S19/S43, j] × sc_foss.<br><br>
            O resultado é a <b style="color:var(--txt)">matriz modificada A*</b>, que reflete a nova composição de
            insumos energéticos por setor e substitui A no cálculo da inversa de Leontief L* = (I − A*)⁻¹.
          </p>
          <p style="font-size:10px;color:var(--mut);line-height:1.7;margin:0">
            <b style="color:var(--txt)">Granularidade:</b> Indústria tem 4 sub-setores próprios (Ferro &amp; Aço, Cimento,
            Químico, Outros) — cada um com fatores de escala distintos, capturando trajetórias de
            descarbonização diferenciadas. Transporte e Cidades são tratados como grupo único.
          </p>
        </div>
        <div>
          <div style="font-size:10px;color:var(--txt);font-weight:600;margin-bottom:6px">Exemplo concreto — Transporte · 2050</div>
          <table style="width:100%;font-size:10.5px;border-collapse:collapse;margin-bottom:8px">
            <thead><tr>
              <th style="color:var(--mut);font-weight:500;padding:3px 8px;border-bottom:1px solid var(--bdr);text-align:left">Combustível</th>
              <th style="color:var(--mut);font-weight:500;padding:3px 8px;border-bottom:1px solid var(--bdr);text-align:right">Base 2020</th>
              <th style="color:var(--mut);font-weight:500;padding:3px 8px;border-bottom:1px solid var(--bdr);text-align:right">100D 2050</th>
              <th style="color:var(--mut);font-weight:500;padding:3px 8px;border-bottom:1px solid var(--bdr);text-align:right">Fator sc</th>
              <th style="color:var(--mut);font-weight:500;padding:3px 8px;border-bottom:1px solid var(--bdr);text-align:left">Efeito em A*</th>
            </tr></thead>
            <tbody>
              <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
                <td style="padding:3px 8px;color:#F39C12;font-weight:600">Elétrico</td>
                <td style="padding:3px 8px;color:var(--txt);text-align:right">0.4%</td>
                <td style="padding:3px 8px;color:#F39C12;font-weight:700;text-align:right">16.7%</td>
                <td style="padding:3px 8px;color:#F39C12;font-weight:700;text-align:right">46×</td>
                <td style="padding:3px 8px;color:var(--mut)">A[S40/S41, S50] × 46 → mais eletricidade comprada</td>
              </tr>
              <tr style="border-bottom:1px solid rgba(255,255,255,.04)">
                <td style="padding:3px 8px;color:#1D9E75;font-weight:600">Biomassa</td>
                <td style="padding:3px 8px;color:var(--txt);text-align:right">30.3%</td>
                <td style="padding:3px 8px;color:#1D9E75;font-weight:700;text-align:right">66.6%</td>
                <td style="padding:3px 8px;color:#1D9E75;font-weight:700;text-align:right">2.2×</td>
                <td style="padding:3px 8px;color:var(--mut)">A[S20/S22, S50] × 2.2 → mais biocombustível</td>
              </tr>
              <tr>
                <td style="padding:3px 8px;color:#E24B4A;font-weight:600">Fóssil</td>
                <td style="padding:3px 8px;color:var(--txt);text-align:right">69.3%</td>
                <td style="padding:3px 8px;color:#E24B4A;font-weight:700;text-align:right">16.8%</td>
                <td style="padding:3px 8px;color:#E24B4A;font-weight:700;text-align:right">0.24×</td>
                <td style="padding:3px 8px;color:var(--mut)">A[S19/S43, S50] × 0.24 → menos diesel/gasolina</td>
              </tr>
            </tbody>
          </table>
          <p style="font-size:10px;color:var(--mut);line-height:1.7;margin:0">
            <b style="color:var(--txt)">Normalização (normalize=TRUE):</b> com sc_elec = 46×, aplicar os fatores diretamente
            inflaria a intensidade energética total. Por isso os três coeficientes novos são normalizados para preservar
            a intensidade total original — apenas a composição muda, não o volume total de energia por unidade produzida.<br><br>
            <b style="color:#1D9E75">Exceção — Geração Elétrica (normalize=FALSE):</b> a queda de fóssil de 14.6% → 0.7%
            é uma redução genuína de intensidade (mais renováveis = menos insumo por MWh), portanto os coeficientes
            são escalados diretamente sem normalização.
          </p>
        </div>
      </div>
    </div>
  </div>


  <!-- 3c: Tabela de coeficientes técnicos -->
  <div style="margin-bottom:4px;font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.07em">3b · Coeficientes técnicos energéticos A* — tabela cruzada por setor × ano · agrupamento GRP7</div>
  <div class="card" style="margin-bottom:8px">
    <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:10px">
      <span class="clbl">Grupo:</span>
      <select id="coef-grp-sel" class="sb" style="width:240px" onchange="buildCoefTable()">
        <option value="Energia_Fossil">🔴 Energia Fóssil</option>
        <option value="Energia_Renov">🟢 Energia Renovável</option>
        <option value="Ind_Transform">🔵 Ind. Transformação</option>
        <option value="Infraestrutura">🟣 Infraestrutura</option>
        <option value="Agropecuaria">🟤 Agropecuária</option>
        <option value="Ind_Extrativa">⚫ Ind. Extrativa</option>
        <option value="Servicos">⚪ Serviços</option>
      </select>
      <span style="font-size:10px;color:var(--mut);margin-left:8px">Valores = coeficiente A*[linha_energia, setor IO] · variação vs base 2020 em cor</span>
    </div>
    <div style="overflow-x:auto">
      <table class="dt" id="tbl-coef" style="min-width:700px">
        <thead id="tbl-coef-head"></thead>
        <tbody id="tbl-coef-body"></tbody>
      </table>
    </div>
  </div>

  <!-- 3c: Gráfico de variação dos coeficientes por sub-setor -->
  <div class="g2" style="margin-bottom:8px">
    <div class="card">
      <div class="ct">Coeficientes A* por energia — evolução ao longo do tempo (grupo selecionado)</div>
      <div class="chips" id="chips-coef-sub"></div>
      <div class="cw tall"><canvas id="ch-coef-evol"></canvas></div>
    </div>
    <div class="card" style="display:flex;align-items:center">
      <div style="width:100%">
        <div class="ct">Engine 2 — Resumo metodológico</div>
        <p style="font-size:11px;color:var(--mut);line-height:1.9;margin:0">
          <b style="color:var(--txt)">O que muda na MIP:</b> as linhas energéticas de A (S19/S43 fóssil,
          S20/S22 biomassa, S40/S41 elétrico) são reponderadas coluna a coluna, de acordo com os fatores de escala
          derivados dos gráficos 3a. A inversa de Leontief é então recalculada com a nova A*,
          refletindo o novo padrão de insumos energéticos de toda a economia.<br><br>
          <b style="color:var(--txt)">Separação de efeitos:</b> a diferença entre L (A original) e L* (A modificada)
          isola o efeito puro da descarbonização do mix — independente do crescimento do PIB ou do
          investimento adicional. Isso permite atribuir parcela do prêmio da transição especificamente
          à mudança estrutural na composição energética.<br><br>
          <b style="color:var(--txt)">Coprocessamento S19:</b> a substituição de petróleo cru por biomassa no refino
          é capturada pela queda dos coeficientes A[S05,S19] e A[S19,S19] — redução de ~78% até 2050.<br><br>
          <b style="color:var(--txt)">Biometano S43:</b> lógica análoga ao coprocessamento — à medida que
          biometano (produzido de biomassa/resíduos, sem insumos fósseis) cresce de 0% para ~54% do output
          de S43, os coeficientes fósseis A[S19,S43] e A[S43,S43] caem proporcionalmente via
          <code>indicador_s43 = 900 / (900 + pj_biometano_t)</code>.<br><br>
          <b style="color:#1D9E75">Geração elétrica:</b> tratada com <code>normalize=FALSE</code> — a redução
          de fóssil de 14.6% → 0.7% é eficiência genuína (mais renováveis por MWh gerado), não redistribuição.
        </p>
      </div>
    </div>
  </div>

  <!-- ══ 4 · VOLUMES FÍSICOS — ENGINE 3 ══════════════════════════════════════ -->
  <div style="margin:18px 0 4px"><span class="cost-label">🏭 4 · Volumes Físicos de Produção — Engine 3</span></div>
  <div style="font-size:10px;color:var(--mut);margin-bottom:12px;line-height:1.8">
    Para <b style="color:var(--txt)">9 setores-chave</b> com dados físicos nas planilhas MMA — energia (S05, S19, S20, S22, S40, S43),
    agropecuária (S01) e indústria pesada (S28, S29) — o modelo substitui o escalonamento pelo PIB por trajetórias físicas diretas.
    O Engine 3 computa <b style="color:#F39C12">Δx</b> via razão volume físico / base 2020,
    converte para choque de demanda equivalente via <b style="color:#F39C12">Δf = (I − A*)·Δx</b>, e zera o componente
    de GDP-scaling nos setores com calibração direta (S05, S19, S40, S42) para evitar dupla contagem.
    Resultado: <b style="color:var(--txt)">Δx_total = L* · ΔF_completo + Δx_engine3</b>.
  </div>

  <!-- 4a: Energia & Biocombustíveis -->
  <div style="margin-bottom:4px;font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.07em">4a · Energia &amp; Biocombustíveis — S05 · S19 · S40 · S20 · S22 · S43 — índice de produção física (base 2020 = 100)</div>
  <div class="g2" style="margin-bottom:10px">
    <div class="card">
      <div class="ct">Índice de volume físico — 100D (sólido) vs Baseline PIB (tracejado) · base 2020 = 100</div>
      <div class="cw" style="height:380px"><canvas id="ch-eng3-energy"></canvas></div>
    </div>
    <div class="card" style="display:flex;align-items:flex-start">
      <div style="width:100%;padding-top:4px">
        <div class="ct">Variável física calibrada &amp; fonte MMA (Planilha 4)</div>
        <table style="width:100%;font-size:11px;border-collapse:collapse;margin-top:4px">
          <thead><tr>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Setor</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Variável física</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Unidade</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Dinâmica 100D</th>
          </tr></thead>
          <tbody>
            <tr><td style="padding:4px 6px;color:#E24B4A;font-weight:700">S05</td><td style="padding:4px 6px;color:#fff">Extração Petróleo &amp; Gás</td><td style="padding:4px 6px;color:var(--mut)">kbep</td><td style="padding:4px 6px;color:var(--mut)">Pico ~2030; declínio −58% até 2050</td></tr>
            <tr><td style="padding:4px 6px;color:#F39C12;font-weight:700">S19</td><td style="padding:4px 6px;color:#fff">Refino (derivados dom.+exp.)</td><td style="padding:4px 6px;color:var(--mut)">ktep</td><td style="padding:4px 6px;color:var(--mut)">Queda via coprocessamento: biomassa substitui petróleo cru no refino</td></tr>
            <tr><td style="padding:4px 6px;color:#1D9E75;font-weight:700">S20</td><td style="padding:4px 6px;color:#fff">Biodiesel / Diesel Verde (HVO)</td><td style="padding:4px 6px;color:var(--mut)">PJ</td><td style="padding:4px 6px;color:var(--mut)">Base 230 PJ + expansão por cenário</td></tr>
            <tr><td style="padding:4px 6px;color:#3CB371;font-weight:700">S22</td><td style="padding:4px 6px;color:#fff">Biocombust. avançados (Etanol+CCS + Gasolina Verde + BioQAV + Bunker Verde)</td><td style="padding:4px 6px;color:var(--mut)">PJ</td><td style="padding:4px 6px;color:var(--mut)">Base 1 020 PJ + todos os incrementos MMA</td></tr>
            <tr><td style="padding:4px 6px;color:#F1C40F;font-weight:700">S40</td><td style="padding:4px 6px;color:#fff">Geração Elétrica</td><td style="padding:4px 6px;color:var(--mut)">TWh</td><td style="padding:4px 6px;color:var(--mut)">Base 679 TWh → forte crescimento</td></tr>
            <tr><td style="padding:4px 6px;color:#17A589;font-weight:700">S43</td><td style="padding:4px 6px;color:#fff">Gás &amp; Biometano</td><td style="padding:4px 6px;color:var(--mut)">PJ</td><td style="padding:4px 6px;color:var(--mut)">Base 900 PJ + expansão por cenário</td></tr>
          </tbody>
        </table>
        <p style="font-size:10px;color:var(--mut);margin:10px 0 0;line-height:1.8">
          <b style="color:var(--txt)">GDP override:</b> S05, S19, S40 e S42 têm <code>delta_f_gdp = 0</code>.<br>
          <b style="color:var(--txt)">Índice S22 (combinado):</b> base 1 020 PJ (etanol 2020) + soma de todos os incrementos
          MMA (Etanol+CCS, Gasolina Verde, BioQAV, Bunker Verde). Índice > 100 = expansão líquida de S22.<br>
          <b style="color:var(--txt)">S19:</b> mesmo com queda de petróleo cru, derivados permanecem pois biomassa substitui cru no refino.
        </p>
      </div>
    </div>
  </div>

  <!-- 4a-adv: Biocombustíveis Avançados — produção absoluta PJ -->
  <div style="margin-bottom:4px;font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.07em">4a · Biocombustíveis Avançados — Gasolina Verde · BioQAV · Bunker Verde — produção absoluta (PJ)</div>
  <div class="g2" style="margin-bottom:10px">
    <div class="card">
      <div class="ct">Produção 100D (PJ) · base 2020 = 0 para todos · crescimento concentrado pós-2035</div>
      <div class="cw" style="height:300px"><canvas id="ch-eng3-bioadv"></canvas></div>
    </div>
    <div class="card" style="display:flex;align-items:flex-start">
      <div style="width:100%;padding-top:4px">
        <div class="ct">Produtos avançados — S22 (MMA Planilha 4)</div>
        <table style="width:100%;font-size:11px;border-collapse:collapse;margin-top:4px">
          <thead><tr>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Produto</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Rota</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">100D 2050</th>
          </tr></thead>
          <tbody>
            <tr><td style="padding:4px 6px;color:#A8D08D;font-weight:700">Gasolina Verde</td><td style="padding:4px 6px;color:var(--mut)">ATJ / Oligomerização / BTL</td><td style="padding:4px 6px;color:#A8D08D;font-weight:600">455 PJ</td></tr>
            <tr><td style="padding:4px 6px;color:#66B2FF;font-weight:700">BioQAV (SAF)</td><td style="padding:4px 6px;color:var(--mut)">HEFA / ATJ / H2-to-liquids</td><td style="padding:4px 6px;color:#66B2FF;font-weight:600">599 PJ</td></tr>
            <tr><td style="padding:4px 6px;color:#FFB347;font-weight:700">Bunker Verde</td><td style="padding:4px 6px;color:var(--mut)">HVO / BTL / H2-liquids</td><td style="padding:4px 6px;color:#FFB347;font-weight:600">106 PJ</td></tr>
          </tbody>
        </table>
        <p style="font-size:10px;color:var(--mut);margin:10px 0 0;line-height:1.7">
          <b style="color:var(--txt)">Setor IO:</b> todos mapeiam para S22 (Fabricação de biocombustíveis) no modelo de 73 setores.<br>
          <b style="color:var(--txt)">Engine 3:</b> incluídos na calibração combinada de S22 —
          <code>S22 total = 1 020 + Etanol+CCS + Gasolina Verde + BioQAV + Bunker Verde</code>.<br>
          <b style="color:var(--txt)">Nota:</b> base 2020 = 0 para todos — representados em PJ absolutos, não como índice.
        </p>
      </div>
    </div>
  </div>

  <!-- 4b: Agropecuária -->
  <div style="margin-bottom:4px;font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.07em">4b · Agropecuária — S01 — Soja · Milho · Cana · Oleaginosas Energ. — índice de produção física (base 2020 = 100)</div>
  <div class="g2" style="margin-bottom:12px">
    <div class="card">
      <div class="ct">Índice volume físico por cultura — 100D (sólido) vs Baseline PIB (tracejado) · base 2020 = 100</div>
      <div class="cw tall"><canvas id="ch-eng3-agro"></canvas></div>
    </div>
    <div class="card" style="display:flex;align-items:flex-start">
      <div style="width:100%;padding-top:4px">
        <div class="ct">Capacidade calibrada — Agropecuária (S01)</div>
        <table style="width:100%;font-size:11px;border-collapse:collapse;margin-top:4px">
          <thead><tr>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Cultura</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Peso S01</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Fonte energética</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Papel no cenário 100D</th>
          </tr></thead>
          <tbody>
            <tr>
              <td style="padding:4px 6px;color:#6B8E23;font-weight:700">Soja</td>
              <td style="padding:4px 6px;color:#F39C12;font-weight:600">28%</td>
              <td style="padding:4px 6px;color:var(--mut)">Diesel — mecanização</td>
              <td style="padding:4px 6px;color:var(--mut)">Exportação + biodiesel; cresce com expansão de fronteira</td>
            </tr>
            <tr>
              <td style="padding:4px 6px;color:#8FBC8F;font-weight:700">Milho</td>
              <td style="padding:4px 6px;color:#F39C12;font-weight:600">10%</td>
              <td style="padding:4px 6px;color:var(--mut)">Diesel — mecanização</td>
              <td style="padding:4px 6px;color:var(--mut)">Etanol de milho; expansão ligada à demanda biocombustíveis</td>
            </tr>
            <tr>
              <td style="padding:4px 6px;color:#3B6D11;font-weight:700">Cana</td>
              <td style="padding:4px 6px;color:#F39C12;font-weight:600">8%</td>
              <td style="padding:4px 6px;color:var(--mut)">Bagaço (cogeração)</td>
              <td style="padding:4px 6px;color:var(--mut)">Feedstock etanol+CCS; expansão de área exigida pela meta 100D</td>
            </tr>
            <tr>
              <td style="padding:4px 6px;color:#DAA520;font-weight:700">Oleaginosas Energ.</td>
              <td style="padding:4px 6px;color:#F39C12;font-weight:600">1%</td>
              <td style="padding:4px 6px;color:var(--mut)">Diesel — mecanização</td>
              <td style="padding:4px 6px;color:var(--mut)">Palma/girassol/canola para HVO/FAME; peso via razão de volume PAM 2018</td>
            </tr>
          </tbody>
        </table>
        <p style="font-size:10px;color:var(--mut);margin:10px 0 0;line-height:1.8">
          <b style="color:var(--txt)">Cobertura:</b> os quatro cultivos representam ~47% do VBP de S01; os 53% restantes seguem o PIB via Engine 1a.<br>
          <b style="color:var(--txt)">Desvio vs PIB:</b> quando 100D fica abaixo do Baseline PIB, a intensificação agrícola (maiores rendimentos) cresce mais lentamente que a economia — parte da terra é realocada para energéticos.
        </p>
      </div>
    </div>
  </div>

  <!-- 4b-area: Área agrícola Alimentos vs Energéticos -->
  <div style="margin-bottom:4px;font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.07em">4b · Agropecuária — Área do setor agrícola — índice de área por uso (base 2020 = 100) · 1000 ha</div>
  <div class="g2" style="margin-bottom:12px">
    <div class="card">
      <div class="ct">Índice área agrícola — Alimentos vs Energéticos — 100D vs Baseline PIB · base 2020 = 100</div>
      <div class="cw tall"><canvas id="ch-eng3-agro-area"></canvas></div>
    </div>
    <div class="card" style="display:flex;align-items:flex-start">
      <div style="width:100%;padding-top:4px">
        <div class="ct">Contexto: realocação de terra Alimentos → Energéticos</div>
        <p style="font-size:11px;color:var(--txt);line-height:1.7;margin:8px 0">
          No cenário 100D, a área total agrícola cresce (~15% até 2050), mas a composição muda: a fração de <b style="color:#E8A020">Energéticos</b> (cana, oleaginosas energéticas, gramíneas) expande mais rápido do que <b style="color:#5D9E4A">Alimentos</b>.
        </p>
        <p style="font-size:11px;color:var(--txt);line-height:1.7;margin:8px 0">
          Isso explica por que os <b>volumes de produção de alimentos</b> (gráfico acima) ficam <b>abaixo do Baseline PIB</b>: o crescimento de rendimento compensa parcialmente a perda de área, mas não integralmente.
        </p>
        <p style="font-size:10px;color:var(--mut);margin:10px 0 0;line-height:1.6">
          <b style="color:var(--txt)">Fonte:</b> MMA-SMC v3 AR5 (2024), Planilha 2 (Agropecuária), R115–R116.<br>
          <b style="color:var(--txt)">Uso:</b> dado de contexto — não calibra coeficientes técnicos da MIP.
        </p>
      </div>
    </div>
  </div>

  <!-- 4c: Indústria Pesada -->
  <div style="margin-bottom:4px;font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.07em">4c · Indústria Pesada — S28 Cimento · S29 Siderurgia — índice de produção física (base 2020 = 100)</div>
  <div class="g2" style="margin-bottom:10px">
    <div class="card">
      <div class="ct">Índice volume físico — 100D (sólido) vs Baseline PIB (tracejado) · base 2020 = 100</div>
      <div class="cw tall"><canvas id="ch-eng3-industry"></canvas></div>
    </div>
    <div class="card" style="display:flex;align-items:flex-start">
      <div style="width:100%;padding-top:4px">
        <div class="ct">Capacidade calibrada — Indústria Pesada</div>
        <table style="width:100%;font-size:11px;border-collapse:collapse;margin-top:4px">
          <thead><tr>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Setor</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Produto</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Base 2020</th>
            <th style="color:var(--mut);font-weight:500;padding:4px 6px;border-bottom:1px solid var(--bdr);text-align:left">Driver MMA</th>
          </tr></thead>
          <tbody>
            <tr>
              <td style="padding:4px 6px;color:#95A5A6;font-weight:700">S28</td>
              <td style="padding:4px 6px;color:#fff">Cimento / Minerais não-metálicos</td>
              <td style="padding:4px 6px;color:#F39C12;font-weight:600">42.7 Mt clinker</td>
              <td style="padding:4px 6px;color:var(--mut)">Construção civil — infraestrutura de transição (eólica, solar, linhas de transmissão) e habitação</td>
            </tr>
            <tr>
              <td style="padding:4px 6px;color:#5D8AA8;font-weight:700">S29</td>
              <td style="padding:4px 6px;color:#fff">Siderurgia / Ferro-gusa &amp; Aço bruto</td>
              <td style="padding:4px 6px;color:#F39C12;font-weight:600">31.4 Mt aço</td>
              <td style="padding:4px 6px;color:var(--mut)">Estruturas metálicas — geradores eólicos, subestações, veículos elétricos, construção pesada</td>
            </tr>
          </tbody>
        </table>
        <p style="font-size:10px;color:var(--mut);margin:10px 0 0;line-height:1.8">
          <b style="color:var(--txt)">Mecanismo:</b> S28 e S29 não têm override de GDP scaling — o Engine 3 acrescenta um delta incremental de volume físico <em>sobre</em> a trajetória do PIB (Engine 1a). Quando a linha 100D supera o Baseline PIB, a infraestrutura de transição exige mais capacidade industrial do que o crescimento tendencial forneceria.<br>
          <b style="color:var(--txt)">Descarbonização interna:</b> o Engine 2 também reduz a intensidade fóssil dos insumos energéticos de S28 e S29 (carvão → elétrico/biomassa), alterando as linhas energéticas da matriz A*.
        </p>
      </div>
    </div>
  </div>

</div>

<!-- ══ TAB 1: PRODUÇÃO ═══════════════════════════════════════════════════════ -->
<div class="tab-panel" id="tab1">
  <!-- ── Legenda e KPIs ───────────────────────────────────────────────────── -->
  <div class="card" style="display:flex;gap:16px;flex-wrap:wrap;padding:9px 14px;margin-bottom:12px;border-left:3px solid var(--acc)">
    <div style="display:flex;gap:12px;flex-wrap:wrap;font-size:10px;color:var(--mut)">
      <span><span style="display:inline-block;width:8px;height:8px;border-radius:2px;background:#E24B4A;margin-right:4px"></span>Energéticos</span>
      <span><span style="display:inline-block;width:8px;height:8px;border-radius:2px;background:#378ADD;margin-right:4px"></span>Indústria</span>
      <span><span style="display:inline-block;width:8px;height:8px;border-radius:2px;background:#B4B2A9;margin-right:4px"></span>Serviços</span>
      <span><span style="display:inline-block;width:8px;height:8px;border-radius:2px;background:#3B6D11;margin-right:4px"></span>Agropecuária</span>
    </div>
    <span style="font-size:10px;color:var(--mut);border-left:1px solid var(--bdr);padding-left:12px">
      <b style="color:var(--txt)">Δx 100D</b> = produção total (PIB + Inv + mix) &nbsp;|&nbsp;
      <b style="color:var(--txt)">Δx Trans.</b> = 100D − Base (efeito líquido da política) &nbsp;|&nbsp;
      Premissas → aba 📋
    </span>
  </div>
  <div class="g3">
    <div class="card kpi"><div class="v" id="m-base">—</div><div class="l">Produção Total — Linha de Base</div><div class="s">R$ tri · nível absoluto · R$2018</div></div>
    <div class="card kpi"><div class="v" id="m-100d">—</div><div class="l">Produção Total — 100D</div><div class="s">R$ tri · nível absoluto · R$2018</div></div>
    <div class="card kpi">
      <div class="v" id="m-trans">—</div>
      <div class="v2" id="m-trans-pct" style="color:var(--mut)">—</div>
      <div class="l">Prêmio da Transição (100D − Base)</div>
      <div class="s">R$ tri · efeito líquido da política · R$2018</div>
    </div>
  </div>

  <!-- ── A · Trajetória da Produção ─────────────────────────────────────────── -->
  <div style="margin:14px 0 4px"><span class="cost-label">📈 A · Trajetória da Produção — 100D vs Linha de Base</span></div>
  <div style="font-size:10px;color:var(--mut);margin-bottom:8px">
    Nível absoluto de produção total (R$ tri, R$2018). Ponto de partida = produção bruta da economia em 2018.
    Linha base = apenas crescimento do PIB com matriz 2018 congelada. Diferença = impacto líquido da política de transição.
  </div>
  <div class="g2" style="margin-bottom:12px">
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <div class="ct" style="margin:0">Produção Total — 100D vs Linha de Base</div>
        <div style="display:flex;gap:3px">
          <button id="traj-abs" class="tog on" style="color:#F39C12;border-color:#F39C12;background:rgba(243,156,18,.15);font-size:10px;padding:1px 8px" onclick="togTrajView(true)">R$ tri</button>
          <button id="traj-pct" class="tog" style="color:#F39C12;border-color:#F39C12;font-size:10px;padding:1px 8px" onclick="togTrajView(false)">%</button>
        </div>
      </div>
      <div class="cw"><canvas id="ch-traj-compare"></canvas></div>
    </div>
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <div class="ct" style="margin:0">Efeito Líquido da Transição (100D − Base) por ano</div>
        <div style="display:flex;gap:3px">
          <button id="net-abs" class="tog on" style="color:#F39C12;border-color:#F39C12;background:rgba(243,156,18,.15);font-size:10px;padding:1px 8px" onclick="togNetView(true)">R$ tri</button>
          <button id="net-pct" class="tog" style="color:#F39C12;border-color:#F39C12;font-size:10px;padding:1px 8px" onclick="togNetView(false)">%</button>
        </div>
      </div>
      <div class="cw"><canvas id="ch-traj-net"></canvas></div>
    </div>
  </div>

  <!-- ── B · Ranking Setorial ───────────────────────────────────────────────── -->
  <div style="margin:14px 0 4px"><span class="cost-label">🏆 B · Ranking Setorial — Quem mais cresce e quem mais muda</span></div>
  <div style="font-size:10px;color:var(--mut);margin-bottom:8px">
    Esquerda: maiores produções absolutas no cenário 100D (inclui crescimento do PIB).
    Direita: setores com maior <em>mudança relativa à linha base</em> — ganhos e perdas puros da política de transição.
    Cores por grupo NT4. Passe o mouse para ver o nome do setor.
  </div>
  <div class="g2" style="margin-bottom:4px">
    <div class="card">
      <div class="ct">Top 20 |Δx 100D| por Setor — produção total (R$ M)</div>
      <div class="chips" id="chips-top20" style="margin-bottom:4px"></div>
      <div class="cw xtall"><canvas id="ch-top20-100d"></canvas></div>
    </div>
    <div class="card">
      <div class="ct">Top 20 Efeito Transição — Δx 100D − Base (R$ M)</div>
      <div class="chips" id="chips-trans" style="margin-bottom:4px"></div>
      <div class="cw xtall"><canvas id="ch-top20-trans"></canvas></div>
    </div>
  </div>

  <!-- ── D · Setores Energéticos ──────────────────────────────────────────── -->
  <div style="margin:14px 0 4px"><span class="cost-label">⚡ C · Setores Energéticos — 100D vs. Base</span></div>
  <div class="g2" style="margin-bottom:12px">
    <div class="card">
      <div class="ct">Δx (100D − Base) por Setor Energético — trajetória (R$ bi, R$2018)</div>
      <div class="cw tall"><canvas id="ch-energy-traj"></canvas></div>
    </div>
    <div class="card">
      <div class="ct">Δx (100D − Base) — Setores Energéticos, ano selecionado (R$ M)</div>
      <div class="cw tall"><canvas id="ch-energy-bar"></canvas></div>
    </div>
  </div>
  <div class="card" style="margin-bottom:8px">
    <p style="font-size:12px;color:#8892a4;margin:0">
      <strong style="color:#d4ac4a">Como ler:</strong>
      Barras <span style="color:#1D9E75;font-weight:600">verdes</span> = o setor produz
      <em>mais</em> no cenário 100D do que na Base (sem efeito de transição) — renováveis ganham.
      Barras <span style="color:#E24B4A;font-weight:600">vermelhas</span> = o setor produz
      <em>menos</em> — combustíveis fósseis perdem demanda intermediária.
      O efeito decorre da combinação do <strong>investimento de transição</strong> (Engine 1b)
      e da <strong>menor demanda intermediária por fósseis</strong> à medida que a matriz
      energética da indústria e transporte muda (Engine 2).
    </p>
  </div>
  <div class="card" style="margin-bottom:12px">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
      <div class="ct" style="margin:0">Setores Energéticos — Produção e Encadeamentos</div>
    </div>
    <div style="overflow-x:auto">
      <table class="dt" id="tbl-energy"><thead><tr>
        <th onclick="sortTbl('tbl-energy',0)">Cód</th>
        <th onclick="sortTbl('tbl-energy',1)">Setor</th>
        <th onclick="sortTbl('tbl-energy',2)" title="100D minus Base total production (R$ M)">100D−Base ▲▼</th>
        <th onclick="sortTbl('tbl-energy',3)">Δx 100D</th>
        <th onclick="sortTbl('tbl-energy',4)">Δx Base</th>
        <th onclick="sortTbl('tbl-energy',5)">Direto Δf</th>
        <th onclick="sortTbl('tbl-energy',6)">Induzido</th>
        <th onclick="sortTbl('tbl-energy',7)">Mult. L</th>
        <th onclick="sortTbl('tbl-energy',8)">Mult. L*</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>

  <!-- ── E · Efeito Ripple da Transição — todos os setores ────────────────── -->
  <div style="margin:14px 0 4px"><span class="cost-label">🔄 D · Efeito Ripple da Transição — Todos os 73 Setores (100D − Base)</span></div>
  <div style="font-size:10px;color:var(--mut);margin-bottom:8px">
    Variação de produção atribuída exclusivamente à política de transição (100D − linha de base): positivo = setor ganha com a transição; negativo = setor perde. Inclui tanto setores diretamente afetados (energéticos) quanto setores que mudam via efeito cadeia. Cores por grupo NT4.
  </div>
  <div style="display:flex;align-items:center;gap:6px;margin-bottom:6px">
    <span style="font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.08em">Exibir:</span>
    <button id="spill-abs" class="tog on" style="color:#F39C12;border-color:#F39C12" onclick="setSpillMode('abs')">R$ M</button>
    <button id="spill-pct" class="tog" style="color:#378ADD;border-color:#378ADD" onclick="setSpillMode('pct')">% x Base</button>
  </div>
  <div class="card" style="margin-bottom:8px">
    <div class="cw" style="height:680px"><canvas id="ch-spillover"></canvas></div>
  </div>

  <!-- ── C · Tabela Setorial Completa ──────────────────────────────────────── -->
  <div style="margin:14px 0 4px"><span class="cost-label">📋 E · Tabela Setorial Completa</span></div>
  <div class="card" style="margin-bottom:12px">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;flex-wrap:wrap;gap:6px">
      <div class="ct" style="margin:0" id="tbl-lbl">Produção Setorial</div>
      <input class="sb" placeholder="Buscar setor..." oninput="filterTbl('tbl-sec',this.value)">
    </div>
    <div style="overflow-x:auto;max-height:320px;overflow-y:auto">
      <table class="dt" id="tbl-sec"><thead><tr>
        <th onclick="sortTbl('tbl-sec',0)">Cód</th>
        <th onclick="sortTbl('tbl-sec',1)">Setor</th>
        <th onclick="sortTbl('tbl-sec',2)">Grupo NT4</th>
        <th onclick="sortTbl('tbl-sec',3)">Δx 100D</th>
        <th onclick="sortTbl('tbl-sec',4)">Δx Base</th>
        <th onclick="sortTbl('tbl-sec',5)">Δx Trans.</th>
        <th onclick="sortTbl('tbl-sec',6)">Δx %</th>
        <th onclick="sortTbl('tbl-sec',7)">x Base (2018)</th>
      </tr></thead><tbody></tbody></table>
    </div>
  </div>

</div>

<!-- ══ TAB 2: RESULTADOS MACRO ═══════════════════════════════════════════════ -->
<div class="tab-panel" id="tab2">

<!-- ╔═══════════════════════════════════════════════════════════╗ -->
<!-- ║  1 · PIB                                                  ║ -->
<!-- ╚═══════════════════════════════════════════════════════════╝ -->
<div style="display:flex;align-items:center;gap:10px;margin:4px 0 10px">
  <span style="font-size:13px;font-weight:700;color:#fff">1 · PIB</span>
  <span style="font-size:10px;color:var(--mut)">Produto Interno Bruto — Valor Adicionado · R$ 2018 · base 2018 = R$6.011 tri</span>
</div>
<div class="g3" style="margin-bottom:12px">
  <div class="card kpi" style="border-left:3px solid var(--base)">
    <div class="v" id="pib-base-tri">—</div>
    <div class="l">PIB — Linha de Base</div>
    <div class="s">R$ tri · nível absoluto · R$2018</div>
  </div>
  <div class="card kpi" style="border-left:3px solid #1D9E75">
    <div class="v" id="pib-lvl-tri" style="color:#1D9E75">—</div>
    <div class="l">PIB — 100D</div>
    <div class="s">R$ tri · nível absoluto · R$2018</div>
  </div>
  <div class="card kpi" style="border-left:3px solid #F39C12">
    <div class="v" id="pib-trans" style="color:#F39C12">—</div>
    <div class="v2" id="pib-trans-pct" style="color:#F8C471">—</div>
    <div class="l">Prêmio da Transição (100D − Base)</div>
    <div class="s">R$ tri · efeito líquido da política · R$2018</div>
  </div>
</div>
<div class="g2" style="margin-bottom:4px">
  <div class="card">
    <div class="ct">PIB total — 100D vs Baseline</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:4px"><b style="color:#1D9E75">100D</b> = total. <b style="color:#888780">Baseline</b> = só crescimento do PIB. <b>Valores em R$ 2018 constantes</b> — o PIB nominal 2024 (~R$11 tri) deflacionado para 2018 equivale a ~R$7.5 tri.</div>
    <div style="display:flex;align-items:center;gap:6px;margin-bottom:6px">
      <span style="font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.08em">Exibir:</span>
      <button id="pib-tot-abs" class="tog on" style="color:#1D9E75;border-color:#1D9E75;background:rgba(29,158,117,.15)" onclick="togPibTotView(true)">R$ tri</button>
      <button id="pib-tot-pct" class="tog" style="color:#378ADD;border-color:var(--bdr)" onclick="togPibTotView(false)">% vs 2018</button>
    </div>
    <div id="pib-tot-abs-wrap" class="cw"><canvas id="ch-pib-traj"></canvas></div>
    <div id="pib-tot-pct-wrap" class="cw" style="display:none"><canvas id="ch-pib-traj-p"></canvas></div>
  </div>
  <div class="card">
    <div class="ct">PIB per capita — 100D vs Baseline</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:4px">Per capita cresce menos que o total pelo crescimento populacional (~+15% até 2050). <b>R$ 2018 constantes</b> — per capita nominal 2024 (~R$53 mil) ≈ R$35 mil em R$2018.</div>
    <div style="display:flex;align-items:center;gap:6px;margin-bottom:6px">
      <span style="font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.08em">Exibir:</span>
      <button id="pib-pc-abs" class="tog on" style="color:#9333EA;border-color:#9333EA;background:rgba(147,51,234,.15)" onclick="togPibPcView(true)">R$ mil/hab</button>
      <button id="pib-pc-pct" class="tog" style="color:#378ADD;border-color:var(--bdr)" onclick="togPibPcView(false)">% vs 2018</button>
    </div>
    <div id="pib-pc-abs-wrap" class="cw"><canvas id="ch-pib-pct"></canvas></div>
    <div id="pib-pc-pct-wrap" class="cw" style="display:none"><canvas id="ch-pib-pct-p"></canvas></div>
  </div>
</div>
<div class="card" style="margin-bottom:4px">
  <div class="ct">Contribuição da transição ao crescimento do PIB (%)</div>
  <div style="font-size:10px;color:var(--mut);margin-bottom:6px">% do crescimento total de PIB atribuível ao investimento verde + substituição energética (Engines 1b/2/3). O restante provém do crescimento autônomo do PIB (Engine 1a).</div>
  <div class="cw"><canvas id="ch-pib-dirindir"></canvas></div>
</div>
<div class="g2" style="margin-bottom:16px">
  <div class="card">
    <div class="ct">Prêmio por grupo setorial — 100D · ano selecionado</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:6px">Qual grupo setorial captura mais do prêmio? Δx_transição × coef VA. Ganhadores e perdedores da descarbonização.</div>
    <div style="display:flex;align-items:center;gap:6px;margin-bottom:6px">
      <span style="font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.08em">Exibir:</span>
      <button id="grp-view-abs" class="tog on" style="color:#F39C12;border-color:#F39C12;background:rgba(243,156,18,.15)" onclick="togGrpView(true)">R$ bi</button>
      <button id="grp-view-pct" class="tog" style="color:#378ADD;border-color:var(--bdr)" onclick="togGrpView(false)">% do prêmio</button>
    </div>
    <div id="grp-abs-wrap" class="cw"><canvas id="ch-pib-trans-grp"></canvas></div>
    <div id="grp-pct-wrap" class="cw" style="display:none"><canvas id="ch-pib-trans-grp-pct"></canvas></div>
  </div>
  <div class="card">
    <div class="ct">Variação % do PIB setorial vs 2018 — top 20 setores · prêmio da transição · ano</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:6px">% = Δx_transição / x_2018 × 100 por setor. Setores com maior variação relativa são os mais transformados pela transição.</div>
    <div class="cw xtall"><canvas id="ch-pib-sec-pct"></canvas></div>
  </div>
</div>

<!-- ╔═══════════════════════════════════════════════════════════╗ -->
<!-- ║  2 · EMPREGO                                              ║ -->
<!-- ╚═══════════════════════════════════════════════════════════╝ -->
<div style="display:flex;align-items:center;gap:10px;margin:16px 0 10px">
  <span style="font-size:13px;font-weight:700;color:#fff">2 · Emprego</span>
  <span style="font-size:10px;color:var(--mut)">Postos de trabalho diretos e indiretos · 100D vs Baseline PIB · base 2018 = 104.340 Mil postos</span>
</div>
<div class="g5c" style="display:grid;grid-template-columns:repeat(5,1fr);gap:12px;margin-bottom:12px">
  <div class="card kpi" style="border-left:3px solid var(--base)">
    <div class="v" id="e-emp-base" style="color:#fff">—</div>
    <div class="l">Emprego — Linha de Base</div>
    <div class="s">Milhões de postos · nível absoluto · R$2018</div>
  </div>
  <div class="card kpi" style="border-left:3px solid #1D9E75">
    <div class="v" id="e-emp-lvl" style="color:#1D9E75">—</div>
    <div class="l">Emprego — 100D</div>
    <div class="s">Milhões de postos · nível absoluto · R$2018</div>
  </div>
  <div class="card kpi" style="border-left:3px solid #F39C12">
    <div class="v" id="e-emp-trans" style="color:#F39C12">—</div>
    <div class="v2" id="e-emp-trans-pct" style="color:#F8C471">—</div>
    <div class="l">Prêmio da Transição (100D − Base)</div>
    <div class="s">Milhões · % vs base</div>
  </div>
  <div class="card kpi" style="border-left:3px solid #1D9E75">
    <div class="v" id="e-emp-trans-dir" style="color:#1D9E75">—</div>
    <div class="v2" id="e-emp-trans-dir-pct" style="color:#a3d9a5">—</div>
    <div class="l">Prêmio Direto</div>
    <div class="s">Milhões · % do prêmio total</div>
  </div>
  <div class="card kpi" style="border-left:3px solid #378ADD">
    <div class="v" id="e-emp-trans-ind" style="color:#378ADD">—</div>
    <div class="v2" id="e-emp-trans-ind-pct" style="color:#90bdef">—</div>
    <div class="l">Prêmio Indireto</div>
    <div class="s">Milhões · % do prêmio total</div>
  </div>
</div>

<!-- Row 1: Total trajectory (absolute from 104k) + Premium direct/indirect -->
<div class="g2" style="margin-bottom:4px">
  <div class="card">
    <div class="ct">Emprego total — 100D vs Baseline PIB · desde 2018</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:4px"><b style="color:#1D9E75">100D</b> = total. <b style="color:#888780">Baseline</b> = só crescimento do PIB. Ponto de partida 2018 = 104,3 Milhões de postos.</div>
    <div style="display:flex;align-items:center;gap:6px;margin-bottom:6px">
      <span style="font-size:10px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:.08em">Exibir:</span>
      <button id="emp-traj-abs" class="tog on" style="color:#1D9E75;border-color:#1D9E75;background:rgba(29,158,117,.15)" onclick="togEmpTrajView(true)">Milhões</button>
      <button id="emp-traj-pct" class="tog" style="color:#378ADD;border-color:var(--bdr)" onclick="togEmpTrajView(false)">% vs 2018</button>
    </div>
    <div id="emp-traj-abs-wrap" class="cw"><canvas id="ch-emp-traj"></canvas></div>
    <div id="emp-traj-pct-wrap" class="cw" style="display:none"><canvas id="ch-emp-traj-p"></canvas></div>
  </div>
  <div class="card">
    <div class="ct">Prêmio de emprego — Direto vs Indireto (Milhões) · trajetória</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:6px">Decomposição do prêmio da transição (100D − Baseline): <b style="color:#1D9E75">Direto</b> = empregos nos setores com choque. <b style="color:#3aad89">Indireto</b> = empregos propagados pela cadeia insumo-produto.</div>
    <div class="cw"><canvas id="ch-emp-formal"></canvas></div>
  </div>
</div>

<!-- Row 2: Top-20 transition premium + Group trajectory -->
<div class="g2" style="margin-bottom:4px">
  <div class="card">
    <div class="ct">Prêmio setorial — top 20 setores · emprego da transição (postos) · ano</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:4px">Empregos atribuíveis <b>exclusivamente à transição</b> (100D − Baseline PIB) por setor. Direto + indireto via cadeia.</div>
    <div class="chips" id="chips-emp"></div>
    <div class="cw xtall"><canvas id="ch-emp-top20"></canvas></div>
  </div>
  <div class="card">
    <div class="ct">Prêmio de emprego por grupo setorial — trajetória · Milhões</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:6px">Postos gerados <b>exclusivamente pela transição</b> (100D − Baseline PIB) por grupo. Mostra quem ganha e quem perde com a mudança energética.</div>
    <div class="cw tall"><canvas id="ch-emp-grp-traj"></canvas></div>
  </div>
</div>

<!-- Row 3: Energy sector zoom -->
<div class="card" style="margin-bottom:4px">
  <div class="ct">Setores energéticos — nível total de emprego · Base 2018 vs 100D · Mil postos</div>
  <div style="font-size:10px;color:var(--mut);margin-bottom:6px">
    Duas barras por setor.
    <b style="color:#6b7280">Base 2018</b> (cinza) = estoque total de empregos fixado no MIP-EPE 2018 — referência imutável.
    <b style="color:#1D9E75">Crescimento 100D</b> = variação total gerada pela transição no ano selecionado, decomposta em
    <b style="color:#1D9E75">Direto</b> (postos nos setores que recebem o choque) +
    <b style="color:#7aada0">Indireto</b> (postos induzidos via cadeia insumo-produto).
  </div>
  <div class="cw"><canvas id="ch-eng-lvl"></canvas></div>
</div>
<div class="g2" style="margin-bottom:4px">
  <div class="card">
    <div class="ct">Setores energéticos — prêmio de emprego · trajetória · Mil postos</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:6px">Prêmio da transição por setor energético. <b style="color:#E24B4A">Fóssil</b> = S05 · S19 · S21 · S43. <b style="color:#1D9E75">Renovável</b> = S20 · S22 · S40 · S41 · S42.</div>
    <div class="cw tall"><canvas id="ch-eng-traj"></canvas></div>
  </div>
  <div class="card">
    <div class="ct">Setores energéticos — prêmio de emprego · ano selecionado · Mil postos</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:6px">Postos gerados ou destruídos pela transição em cada setor energético. Ordenado por magnitude.</div>
    <div class="cw tall"><canvas id="ch-eng-bar"></canvas></div>
  </div>
</div>

<!-- Row 4: Matrix full width -->
<div style="margin-bottom:16px">
  <div class="card">
    <div class="ct">Prêmio da transição — grupo setorial × categoria demográfica · ano</div>
    <div style="font-size:10px;color:var(--mut);margin-bottom:6px">
      Valor = prêmio da transição (Mil postos, + = ganho vs Baseline PIB). Intensidade da cor proporcional ao volume. Ano selecionado.
    </div>
    <div id="emp-matrix" style="overflow-x:auto"></div>
  </div>
</div>

<!-- ╔═══════════════════════════════════════════════════════════╗ -->
<!-- ║  3 · RENDA                                                ║ -->
<!-- ╚═══════════════════════════════════════════════════════════╝ -->
<div style="display:flex;align-items:center;gap:10px;margin:16px 0 10px">
  <span style="font-size:13px;font-weight:700;color:#fff">3 · Renda</span>
  <span style="font-size:10px;color:var(--mut)">Remunerações do trabalho · 100D vs Baseline PIB · base 2018 = R$3.056 bi</span>
</div>
<div class="g3" style="margin-bottom:12px">
  <div class="card kpi">
    <div class="v" id="e-rem">—</div>
    <div class="l">Renda 100D · ano</div>
    <div class="s">R$ bi acumulados s/ 2018</div>
  </div>
  <div class="card kpi">
    <div class="v" id="e-rem-pct">—</div>
    <div class="l">Crescimento s/ 2018</div>
    <div class="s">% variação vs base R$3.056 bi</div>
  </div>
  <div class="card kpi">
    <div class="v" id="e-rem-trans">—</div>
    <div class="v2" id="e-rem-trans-pct" style="color:#9333EA">—</div>
    <div class="l">Prêmio Transição</div>
    <div class="s">100D − Baseline PIB · R$ bi e %</div>
  </div>
</div>

<!-- ╔═══════════════════════════════════════════════════════════╗ -->
<!-- ║  4 · GOVERNO                                              ║ -->
<!-- ╚═══════════════════════════════════════════════════════════╝ -->
<div style="display:flex;align-items:center;gap:10px;margin:16px 0 10px">
  <span style="font-size:13px;font-weight:700;color:#fff">4 · Governo</span>
  <span style="font-size:10px;color:var(--mut)">Receita tributária sobre a produção · 100D vs Baseline PIB</span>
</div>
<div class="g3" style="margin-bottom:12px">
  <div class="card kpi">
    <div class="v" id="e-tax">—</div>
    <div class="l">Arrecadação 100D · ano</div>
    <div class="s">R$ bi acumulados s/ 2018</div>
  </div>
  <div class="card kpi">
    <div class="v" id="e-tax-pct">—</div>
    <div class="l">Crescimento s/ 2018</div>
    <div class="s">% variação vs base tributária</div>
  </div>
  <div class="card kpi">
    <div class="v" id="e-tax-trans">—</div>
    <div class="v2" id="e-tax-trans-pct" style="color:#378ADD">—</div>
    <div class="l">Prêmio Transição</div>
    <div class="s">100D − Baseline PIB · R$ bi e %</div>
  </div>
</div>

<!-- ╔═══════════════════════════════════════════════════════════╗ -->
<!-- ║  5 · COMÉRCIO EXTERIOR                                    ║ -->
<!-- ╚═══════════════════════════════════════════════════════════╝ -->
<div style="display:flex;align-items:center;gap:10px;margin:16px 0 10px">
  <span style="font-size:13px;font-weight:700;color:#fff">5 · Comércio Exterior</span>
  <span style="font-size:10px;color:var(--mut)">Exportações estimadas por setor · substituição de importações · saldo energético</span>
</div>
<div class="g4" style="margin-bottom:12px">
  <div class="card kpi">
    <div class="v" id="exp-total">—</div>
    <div class="l">ΔExportações 100D · ano</div>
    <div class="s">R$ bi estimado · coef exportação</div>
  </div>
  <div class="card kpi">
    <div class="v" id="exp-win">—</div>
    <div class="l">Setores Ganhadores</div>
    <div class="s">R$ bi · grupos em expansão</div>
  </div>
  <div class="card kpi">
    <div class="v" id="exp-los">—</div>
    <div class="l">Setores Perdedores</div>
    <div class="s">R$ bi · grupos em retração</div>
  </div>
  <div class="card kpi">
    <div class="v" id="exp-trans">—</div>
    <div class="l">Prêmio Transição</div>
    <div class="s">100D − 0D · R$ bi exportações</div>
  </div>
</div>

<!-- ╔═══════════════════════════════════════════════════════════╗ -->
<!-- ║  Tabela Setorial Completa                                 ║ -->
<!-- ╚═══════════════════════════════════════════════════════════╝ -->
<div style="display:flex;align-items:center;gap:10px;margin:16px 0 10px">
  <span style="font-size:13px;font-weight:700;color:#fff">· Tabela Setorial</span>
  <span style="font-size:10px;color:var(--mut)">PIB · Emprego · Renda · Impostos · por setor · ano selecionado</span>
</div>
<div class="card">
  <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;flex-wrap:wrap;gap:6px">
    <div class="ct" style="margin:0" id="tbl-eco-lbl">Fatores Econômicos Setoriais</div>
    <input class="sb" placeholder="Buscar setor..." oninput="filterTbl('tbl-eco',this.value)">
  </div>
  <div style="overflow-x:auto;max-height:340px;overflow-y:auto">
    <table class="dt" id="tbl-eco"><thead><tr>
      <th onclick="sortTbl('tbl-eco',0)">Cód</th>
      <th onclick="sortTbl('tbl-eco',1)">Setor</th>
      <th onclick="sortTbl('tbl-eco',2)">Grupo</th>
      <th onclick="sortTbl('tbl-eco',3)">ΔPIB Total</th>
      <th onclick="sortTbl('tbl-eco',4)">ΔPIB Dir.</th>
      <th onclick="sortTbl('tbl-eco',5)">ΔPIB Ind.</th>
      <th onclick="sortTbl('tbl-eco',6)">ΔEmp Total</th>
      <th onclick="sortTbl('tbl-eco',7)">ΔEmp Dir.</th>
      <th onclick="sortTbl('tbl-eco',8)">ΔEmp Ind.</th>
      <th onclick="sortTbl('tbl-eco',9)">ΔRenda</th>
      <th onclick="sortTbl('tbl-eco',10)">ΔImposto</th>
      <th onclick="sortTbl('tbl-eco',11)">ΔExport.</th>
    </tr></thead><tbody></tbody></table>
  </div>
</div>
</div>


<script>
// ════════════════════════════════════════════════════════════════════════════
// DATA
// ════════════════════════════════════════════════════════════════════════════
const D = ]", js, r"[;

// ════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ════════════════════════════════════════════════════════════════════════════
const ANOS  = [2025,2030,2035,2040,2045,2050];
const ANOS_S= ANOS.map(String);
const TRAJ_LBL=["2018",...ANOS_S];  // all trajectory charts anchor at 2018=0
const C100  = "#E24B4A";
const CBASE = "#888780";
const CTRANS= "#F39C12";
const CINV  = "#1D9E75";
const FONTE_C={Derivados:"#E24B4A",Gas_Natural:"#8E44AD",Etanol:"#3B6D11",
               Biodiesel:"#1D9E75",EE_Central:"#F39C12",EE_Distrib:"#F8C471"};
const ENERGY_CODS=new Set(["S05","S19","S20","S21","S22","S40","S41","S42","S43"]);

// ── Build group map from Mapeamento_Setores ───────────────────────────────
const MAP = D.Mapeamento_Setores||[];
const GRP_OF={};   // cod → group name
const GRP_ALL=[];  // ordered unique groups
MAP.forEach(r=>{
  if(r.cod&&r.grupo){GRP_OF[r.cod]=r.grupo; if(!GRP_ALL.includes(r.grupo))GRP_ALL.push(r.grupo);}
});
// group colours (cycle through palette)
const GP = ["#3B6D11","#888780","#E24B4A","#1D9E75","#378ADD","#534AB7","#B4B2A9",
            "#F39C12","#0891B2","#9333EA","#BA7517","#92400E"];
const GRP_COL={};
GRP_ALL.forEach((g,i)=>GRP_COL[g]=GP[i%GP.length]);

// ── Sector name lookup (cod → full name) for tooltips ─────────────────────────
const SECNAME={};
(D.Resultados_Completos||[]).forEach(r=>{if(r.cod&&r.nome&&!SECNAME[r.cod])SECNAME[r.cod]=r.nome;});

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════
const S={ano:2035, grp:null, tab:0};

// ════════════════════════════════════════════════════════════════════════════
// CONTROLS
// ════════════════════════════════════════════════════════════════════════════
function buildControls(){
  // Year toggles
  const ca=document.getElementById("ctrl-ano");
  ANOS.forEach(a=>{
    const b=document.createElement("button");
    b.className="tog"+(a===S.ano?" on":"");
    b.textContent=a;
    b.style.color=a===S.ano?"#F39C12":"var(--mut)";
    b.style.borderColor=a===S.ano?"#F39C12":"var(--bdr)";
    if(a===S.ano)b.style.background="rgba(243,156,18,.18)";
    b.onclick=()=>{S.ano=a;refreshAno();rebuild();};
    ca.appendChild(b);
  });
  // Group toggles (only if ctrl-grp element exists in HTML)
  const cg=document.getElementById("ctrl-grp");
  if(cg){
    const all=document.createElement("button");
    all.id="grp-all"; all.className="tog on";
    all.textContent="Todos"; all.style.color="#fff"; all.style.borderColor="#fff";
    all.style.background="rgba(255,255,255,.12)";
    all.onclick=()=>{S.grp=null;refreshGrp();rebuild();};
    cg.appendChild(all);
    GRP_ALL.forEach(g=>{
      const b=document.createElement("button");
      b.id="grp-"+g; b.className="tog";
      b.textContent=g; b.style.color=GRP_COL[g]; b.style.borderColor=GRP_COL[g];
      b.onclick=()=>{S.grp=g;refreshGrp();rebuild();};
      cg.appendChild(b);
    });
  }
}
function refreshAno(){
  document.querySelectorAll("#ctrl-ano .tog").forEach(b=>{
    const on=+b.textContent.trim()===S.ano;
    b.classList.toggle("on",on);
    b.style.color=on?"#F39C12":"var(--mut)";
    b.style.borderColor=on?"#F39C12":"var(--bdr)";
    b.style.background=on?"rgba(243,156,18,.18)":"transparent";
  });
}
function refreshGrp(){
  const gAll=document.getElementById("grp-all");
  if(gAll){
    gAll.classList.toggle("on",S.grp===null);
    gAll.style.background=S.grp===null?"rgba(255,255,255,.12)":"transparent";
  }
  GRP_ALL.forEach(g=>{
    const b=document.getElementById("grp-"+g); if(!b)return;
    const on=S.grp===g;
    b.classList.toggle("on",on);
    b.style.background=on?hexAlpha(GRP_COL[g],.22):"transparent";
  });
}

// ════════════════════════════════════════════════════════════════════════════
// CHART HELPERS
// ════════════════════════════════════════════════════════════════════════════
const CD={responsive:true,maintainAspectRatio:false,animation:{duration:250},
  plugins:{legend:{labels:{color:"#8892a4",font:{size:10},boxWidth:11}},
           tooltip:{backgroundColor:"#1f2233",titleColor:"#e2e8f0",bodyColor:"#8892a4",
                    borderColor:"#2a2d3e",borderWidth:1}},
  scales:{x:{ticks:{color:"#8892a4",font:{size:10}},grid:{color:"#1f2233"}},
          y:{ticks:{color:"#8892a4",font:{size:10}},grid:{color:"#1f2233"}}}};
const CHARTS={};
function dest(id){if(CHARTS[id]){CHARTS[id].destroy();delete CHARTS[id];}}
function merge(...os){const r={};for(const o of os)for(const k in o){
  if(o[k]&&typeof o[k]==="object"&&!Array.isArray(o[k]))r[k]=merge(r[k]||{},o[k]);
  else r[k]=o[k];}return r;}
function mkBar(id,lbl,ds,opts={}){dest(id);const el=document.getElementById(id);if(!el)return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"bar",data:{labels:lbl,datasets:ds},options:merge(CD,opts)});}
function mkHBar(id,lbl,ds,opts={}){dest(id);const el=document.getElementById(id);if(!el)return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"bar",data:{labels:lbl,datasets:ds},options:merge(CD,{indexAxis:"y"},opts)});}
function mkLine(id,lbl,ds,opts={}){dest(id);const el=document.getElementById(id);if(!el)return;
  CHARTS[id]=new Chart(el.getContext("2d"),{type:"line",data:{labels:lbl,datasets:ds},options:merge(CD,opts)});}
function hexAlpha(h,a){const r=parseInt(h.slice(1,3),16),g=parseInt(h.slice(3,5),16),b=parseInt(h.slice(5,7),16);return `rgba(${r},${g},${b},${a})`;}
function clrTbody(id){const t=document.querySelector("#"+id+" tbody");if(t)t.innerHTML="";}
function filterTbl(id,q){document.querySelectorAll("#"+id+" tbody tr").forEach(r=>
  r.style.display=r.textContent.toLowerCase().includes(q.toLowerCase())?"":"none");}
const _sd={};
function sortTbl(id,c){const tb=document.getElementById(id);
  const rows=Array.from(tb.querySelectorAll("tbody tr"));const asc=(_sd[id+c]=!_sd[id+c]);
  rows.sort((a,b)=>{const va=a.cells[c].textContent.trim(),vb=b.cells[c].textContent.trim();
    const na=parseFloat(va),nb=parseFloat(vb);
    return(!isNaN(na)&&!isNaN(nb))?(asc?na-nb:nb-na):(asc?va.localeCompare(vb):vb.localeCompare(va));});
  rows.forEach(r=>tb.querySelector("tbody").appendChild(r));}
function setText(id,v){const e=document.getElementById(id);if(e)e.textContent=v;}

// Group-filter chips attached to a chart
function mkChips(containerId, labels, colors, onToggle){
  const c=document.getElementById(containerId); if(!c)return;
  c.innerHTML="";
  labels.forEach((l,i)=>{
    const b=document.createElement("button");
    b.className="chip on"; b.textContent=l;
    b.style.color=colors[i]||"#888"; b.style.borderColor=colors[i]||"#888";
    b.onclick=()=>{
      b.classList.toggle("on");
      const vis=Array.from(c.querySelectorAll(".chip")).map(x=>x.classList.contains("on"));
      onToggle(vis);
    };
    c.appendChild(b);
  });
}

// Generic canvas-pair toggle helper
function togCanvasPair(wrapAbs,wrapPct,btnAbs,btnPct,isAbs,colAbs,colPct){
  const wA=document.getElementById(wrapAbs),wP=document.getElementById(wrapPct);
  const bA=document.getElementById(btnAbs), bP=document.getElementById(btnPct);
  if(wA)wA.style.display=isAbs?"":"none";
  if(wP)wP.style.display=isAbs?"none":"";
  if(bA){bA.classList.toggle("on",isAbs);bA.style.color=isAbs?colAbs:"var(--mut)";bA.style.borderColor=isAbs?colAbs:"var(--bdr)";bA.style.background=isAbs?hexAlpha(colAbs,.15):"transparent";}
  if(bP){bP.classList.toggle("on",!isAbs);bP.style.color=!isAbs?colPct:"var(--mut)";bP.style.borderColor=!isAbs?colPct:"var(--bdr)";bP.style.background=!isAbs?hexAlpha(colPct,.15):"transparent";}
}
function togPibView(isAbs){togCanvasPair("pib-abs-wrap","pib-pct-wrap","pib-view-abs","pib-view-pct",isAbs,"#1D9E75","#378ADD");}
function togGrpView(isAbs){togCanvasPair("grp-abs-wrap","grp-pct-wrap","grp-view-abs","grp-view-pct",isAbs,"#F39C12","#378ADD");}
function togPibTotView(isAbs){togCanvasPair("pib-tot-abs-wrap","pib-tot-pct-wrap","pib-tot-abs","pib-tot-pct",isAbs,"#1D9E75","#378ADD");}
function togPibPcView(isAbs){togCanvasPair("pib-pc-abs-wrap","pib-pc-pct-wrap","pib-pc-abs","pib-pc-pct",isAbs,"#9333EA","#378ADD");}
function togEmpTrajView(isAbs){togCanvasPair("emp-traj-abs-wrap","emp-traj-pct-wrap","emp-traj-abs","emp-traj-pct",isAbs,"#1D9E75","#378ADD");}

// ════════════════════════════════════════════════════════════════════════════
// SECTOR FILTER HELPERS
// ════════════════════════════════════════════════════════════════════════════
const energyHighlight=()=>document.getElementById("chk-energy")?.checked||false;

function filterRows(rows){
  // Filter by selected group (or all)
  let r=rows;
  if(S.grp) r=r.filter(x=>(GRP_OF[x.cod]||"")=== S.grp);
  return r;
}
function rowColor(r){return nt4Color(r.cod);}

// ════════════════════════════════════════════════════════════════════════════
// TAB NAV
// ════════════════════════════════════════════════════════════════════════════
const INITS=[initPremissas,initProducao,initFatores];
const _built=new Set();
function showTab(n){
  document.querySelectorAll(".tab-panel").forEach(p=>p.classList.remove("active"));
  document.getElementById("tab"+n).classList.add("active");
  document.querySelectorAll("#mainTabs button").forEach((b,i)=>b.classList.toggle("active",i===n));
  S.tab=n; if(!_built.has(n)){INITS[n]();_built.add(n);}
}
function rebuild(){_built.clear();INITS[S.tab]();}

// ── FBCF allocation chart ─────────────────────────────────────────────────
function renderAlocChart(aloc){
  const rs=D.Resumo||[];
  const invAno=(+(rs.find(r=>r.cenario==="100D"&&+r.ano===S.ano)||{}).inv_shock_bi)||0;
  const hasAno=aloc.some(r=>r.ano!=null);
  const alocS=[...aloc]
    .filter(r=>r.cenario==="100D"&&(!hasAno||+r.ano===S.ano))
    .sort((a,b)=>(+(b.aloc_pct)||0)-(+(a.aloc_pct)||0));
  mkHBar("ch-aloc",alocS.map(r=>r.cod),
    [{label:"R$ bi (100D)",
      data:alocS.map(r=>+((+(r.aloc_pct)||0)*invAno/100).toFixed(2)),
      backgroundColor:alocS.map(r=>hexAlpha(nt4Color(r.cod),.78)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},
              tooltip:{...CD.plugins.tooltip,callbacks:{
                title:items=>{const i=items[0]?.dataIndex??-1;
                  const r=alocS[i];
                  return r?(r.cod+(r.nome?" — "+r.nome:"")):"";},
                label:ctx=>`R$ ${ctx.parsed.x.toFixed(2)} bi  (${(+(alocS[ctx.dataIndex]?.aloc_pct)||0).toFixed(1)}%)`
              }}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"R$ bi (R$2018)",color:"#8892a4"}},y:CD.scales.y}});
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 0 — PREMISSAS
// ════════════════════════════════════════════════════════════════════════════
const SUBSEC_COLORS=["#E24B4A","#F39C12","#7C3AED","#3A8AC4"];
const ETYPE_COLORS={Fóssil:"#E24B4A",Biomassa:"#1D9E75",Elétrico:"#F39C12"};

function initPremissas(){
  const rs=D.Resumo||[], pp=D.PIB_Pop||[], mx=D.Mix_Energetico||[],
        aloc=D.Aloc_Investimento||[], dc=D.Demanda_Componentes||[];

  // ── 1. GDP index anchored at 2018=1 ───────────────────────────────────────
  mkLine("ch-gdp-idx", ["2018",...ANOS_S],
    [{label:"PIB × 0.97 (base 2018=1)",
      data:[1,...ANOS.map(a=>{const r=pp.find(x=>+x.ano===a);return r?(+(r.gdp_rel_2018)||0):null;})],
      borderColor:"#F39C12",backgroundColor:hexAlpha("#F39C12",.1),tension:.35,fill:false,pointRadius:4,borderWidth:2}],
    {plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"relativo a 2018",color:"#8892a4"}}}});

  // ── 2a. VP and CAE — both derived from the same discounted VP values ─────────
  // VP values come from the MMA model (match KPI cards above)
  const PER=[
    {label:"2020–2030", vp:11.638, n:10},
    {label:"2031–2035", vp:3.805,  n:5},
    {label:"2036–2050", vp:4.584,  n:15}
  ];
  const perLbls = PER.map(p=>p.label);
  const perVP   = PER.map(p=>p.vp);
  const perCAE  = PER.map(p=>+(p.vp/p.n).toFixed(3));
  const perBgPV =[hexAlpha(C100,.85),hexAlpha(C100,.65),hexAlpha(C100,.45)];
  const perBgCAE=[hexAlpha("#F39C12",.85),hexAlpha("#F39C12",.65),hexAlpha("#F39C12",.45)];

  mkBar("ch-inv-pv", perLbls,
    [{label:"VP (R$ bi)",data:perVP,
      backgroundColor:perBgPV,borderColor:C100,borderWidth:1,borderRadius:5}],
    {plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:CD.scales.x,
             y:{...CD.scales.y,beginAtZero:true,
                title:{display:true,text:"R$ bi (R$ 2023)",color:"#8892a4"}}}});

  mkBar("ch-inv-cae", perLbls,
    [{label:"CAE (R$ bi/ano)",data:perCAE,
      backgroundColor:perBgCAE,borderColor:"#F39C12",borderWidth:1,borderRadius:5}],
    {plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:CD.scales.x,
             y:{...CD.scales.y,beginAtZero:true,
                title:{display:true,text:"R$ bi/ano (R$ 2023)",color:"#8892a4"}}}});

  // ── 2c. FBCF sector allocation bar — absolute R$bi ───────────────────────
  renderAlocChart(aloc);


  // ── 3a. Main energy groups — stacked 100% bar, 100D ───────────────────────
  ["Indústria","Transporte","Cidades"].forEach((tipo,ti)=>{
    const id=["ch-mix-ind","ch-mix-tra","ch-mix-cid"][ti];
    const mxT=mx.filter(r=>r.cenario==="100D"&&r.tipo===tipo);
    const base=mxT[0]||{};
    const LBL=["2020",...ANOS_S];
    const be=(+(base.base_elec)||0)*100, bb=(+(base.base_bio)||0)*100, bf=(+(base.base_fossil)||0)*100;
    mkBar(id, LBL,[
      {label:"% Elétrica",
       data:[be,...ANOS.map(a=>{const r=mxT.find(x=>+x.ano===a);return r?(+(r.pct_elec)||0)*100:null;})],
       backgroundColor:hexAlpha("#F39C12",.85),borderRadius:2,stack:"s"},
      {label:"% Biomassa",
       data:[bb,...ANOS.map(a=>{const r=mxT.find(x=>+x.ano===a);return r?(+(r.pct_bio)||0)*100:null;})],
       backgroundColor:hexAlpha("#1D9E75",.85),borderRadius:2,stack:"s"},
      {label:"% Fóssil",
       data:[bf,...ANOS.map(a=>{const r=mxT.find(x=>+x.ano===a);return r?(+(r.pct_fossil)||0)*100:null;})],
       backgroundColor:hexAlpha("#E24B4A",.85),borderRadius:2,stack:"s"}
    ],{scales:{x:{...CD.scales.x,stacked:true},
               y:{...CD.scales.y,min:0,max:100,stacked:true,
                  title:{display:true,text:"%",color:"#8892a4"}}}});
  });

  // ── 3b. Coefficient table and evolution chart (initial render) ───────────
  buildCoefTable();
}

// ── Sector groupings (NT4 + 7-group — from mma project code) ─────────────────
const FOSSIL_S    = ["S05","S19","S21","S43"];
const RENEWABLE_S = ["S20","S22","S40","S41","S42"];
const ENERGY_S    = [...FOSSIL_S,...RENEWABLE_S];
const sId = cod => parseInt((cod||"0").replace(/\D/g,""),10);

// 7-group classification (mirror of grupos_7 in R)
function grp7(cod){
  if(["S01","S02","S03"].includes(cod))                    return "Agropecuaria";
  if(["S04","S06","S07"].includes(cod))                    return "Ind_Extrativa";
  if(FOSSIL_S.includes(cod))                               return "Energia_Fossil";
  if(RENEWABLE_S.includes(cod))                            return "Energia_Renov";
  if(["S44","S45","S48","S49","S50","S51"].includes(cod))  return "Infraestrutura";
  const id=sId(cod);
  if((id>=8&&id<=18)||(id>=23&&id<=39))                    return "Ind_Transform";
  // Servicos: id 46,47 + 52-73
  return "Servicos";
}
// NT4 classification (4 groups used in Rede Produtiva tab)
function grpNT4(cod){
  if(["S01","S02","S03"].includes(cod)) return "Agropecuaria";
  if(ENERGY_S.includes(cod))            return "Energeticos";
  const id=sId(cod);
  // Industria: extraction S04-S07 (non-energy), manufacturing S08-S39,
  // construction/infra S44-S45, utilities S48-S51
  if((id>=4&&id<=45)||id===48||id===49||id===50||id===51) return "Industria";
  return "Servicos"; // commerce S46, transport S47, services S52-S73
}
const GRP7_COLS={
  Agropecuaria:"#3B6D11",  Ind_Extrativa:"#888780",
  Energia_Fossil:"#E24B4A",Energia_Renov:"#1D9E75",
  Ind_Transform:"#378ADD", Infraestrutura:"#534AB7",
  Servicos:"#B4B2A9"
};
const GRP7_LABELS={
  Agropecuaria:"Agropecuária",Ind_Extrativa:"Ind. Extrativa",
  Energia_Fossil:"Energia Fóssil",Energia_Renov:"Energia Renovável",
  Ind_Transform:"Ind. Transformação",Infraestrutura:"Infraestrutura",
  Servicos:"Serviços"
};
// NT4 — 4-group classification used for production tab colours
const NT4_COLS={Agropecuaria:"#3B6D11",Energeticos:"#E24B4A",Industria:"#378ADD",Servicos:"#B4B2A9"};
const NT4_LABELS={Agropecuaria:"Agropecuária",Energeticos:"Energéticos",Industria:"Indústria",Servicos:"Serviços"};
function nt4Color(cod){return NT4_COLS[grpNT4(cod)]||"#888";}

// ── Coefficient cross-table (rebuilds on filter change) ──────────────────────
function buildCoefTable(){
  const sel=(document.getElementById("coef-grp-sel")||{}).value||"Energia_Fossil";
  const cd=D.Coef_Tecnicos||[];
  const ETYPES=["Fóssil","Biomassa","Elétrico"];
  // Columns: base2020 (cenario="base2020", ano=2020) + 100D projection years
  const PROJ_ANOS=[2025,2030,2035,2040,2045,2050];
  const DISP_ANOS=["Base","2025","2030","2035","2040","2045","2050"];

  const head=document.getElementById("tbl-coef-head");
  const body=document.getElementById("tbl-coef-body");
  if(!head||!body) return;
  head.innerHTML="";
  body.innerHTML="";

  // Get unique sectors for this GRP7 group, sorted by numeric id
  const allSecs=[...new Map(
    cd.map(r=>[r.cod,{cod:r.cod,nome:r.nome}])
  ).values()].sort((a,b)=>sId(a.cod)-sId(b.cod));
  const secRows=allSecs.filter(s=>grp7(s.cod)===sel);

  if(secRows.length===0){
    body.innerHTML=`<tr><td colspan="22" style="color:var(--mut);text-align:center;padding:16px">Nenhum setor encontrado para "${GRP7_LABELS[sel]||sel}"</td></tr>`;
    return;
  }

  // Build header: Setor | Fóssil×7 | Biomassa×7 | Elétrico×7
  let r1=`<tr><th rowspan="2" style="min-width:60px;position:sticky;left:0;background:#1f2233;color:#e2e8f0">Cód</th>
               <th rowspan="2" style="min-width:160px;position:sticky;left:60px;background:#1f2233;color:#e2e8f0">Setor</th>`;
  ETYPES.forEach(et=>{
    r1+=`<th colspan="${DISP_ANOS.length}" style="text-align:center;background:${hexAlpha(ETYPE_COLORS[et],.18)};color:${ETYPE_COLORS[et]}">${et}</th>`;
  });
  r1+=`</tr>`;
  let r2=`<tr>`;
  ETYPES.forEach(()=>{
    DISP_ANOS.forEach((d,di)=>{
      const isBase=di===0;
      r2+=`<th style="font-size:9px;min-width:44px;text-align:right;${isBase?"color:#8892a4":""}">${d}</th>`;
    });
  });
  r2+=`</tr>`;
  head.innerHTML=r1+r2;

  // Lookup: base = cenario=="base2020" & ano==2020 ; projection = cenario=="100D" & ano==year
  const getCoef=(cod,et,isBase,ano)=>{
    const r=cd.find(x=>x.cod===cod&&x.energy_type===et&&
                       (isBase?(x.cenario==="base2020"&&+x.ano===2020)
                               :(x.cenario==="100D"&&+x.ano===ano)));
    return r?(+(r.coef)||0):null;
  };

  let rows="";
  secRows.forEach(sec=>{
    const {cod,nome}=sec;
    const baseFoss=getCoef(cod,"Fóssil",true,2020)||0;
    const baseBio =getCoef(cod,"Biomassa",true,2020)||0;
    const baseElec=getCoef(cod,"Elétrico",true,2020)||0;
    const baseOf={Fóssil:baseFoss,Biomassa:baseBio,Elétrico:baseElec};
    const grp7c=GRP7_COLS[grp7(cod)]||"#888";
    rows+=`<tr>
      <td style="font-size:10px;font-weight:700;color:${grp7c};white-space:nowrap;position:sticky;left:0;background:var(--card)">${cod}</td>
      <td style="font-weight:600;color:#fff;white-space:nowrap;max-width:160px;overflow:hidden;text-overflow:ellipsis;
                 position:sticky;left:60px;background:var(--card)" title="${nome||""}">${String(nome||"").slice(0,24)}</td>`;
    ETYPES.forEach(et=>{
      const bc=baseOf[et]||0;
      // Base column
      const bv=getCoef(cod,et,true,2020);
      const bfmt=bv===null?"—":(bv<0.0001?bv.toExponential(2):bv.toFixed(5));
      rows+=`<td style="text-align:right;color:var(--mut);font-size:10px">${bfmt}</td>`;
      // Projection columns
      PROJ_ANOS.forEach(a=>{
        const v=getCoef(cod,et,false,a);
        if(v===null){rows+=`<td style="color:var(--mut);text-align:right">—</td>`;return;}
        const pct=bc>1e-8?((v-bc)/bc*100):0;
        const col=et==="Fóssil"?(v<bc-1e-8?"#1D9E75":(v>bc+1e-8?"#E24B4A":"var(--mut)")):
                  et==="Elétrico"?(v>bc+1e-8?"#1D9E75":(v<bc-1e-8?"#E24B4A":"var(--mut)")):
                  (v>bc+1e-8?"#1D9E75":"var(--mut)");
        const fmt=v<0.0001?v.toExponential(2):v.toFixed(5);
        const pctStr=Math.abs(pct)>0.5?
          `<br><span style="font-size:8px;color:${col}">${pct>=0?"+":""}${pct.toFixed(0)}%</span>`:"";
        rows+=`<td style="text-align:right;font-size:10px;color:${col==="var(--mut)"?"var(--txt)":col}">${fmt}${pctStr}</td>`;
      });
    });
    rows+=`</tr>`;
  });
  body.innerHTML=rows;

  // ── 3c. Coefficient evolution chart for this group ────────────────────────
  const CHART_ANOS_LBL=["Base",...ANOS_S];
  const PROJ_ANOS_N=[2020,...PROJ_ANOS];
  const allDs=[];
  // Pick a diverse palette for the sectors in this group
  const SEC_COLS=["#E24B4A","#F39C12","#1D9E75","#378ADD","#9333EA","#0891B2","#BA7517","#B4B2A9","#7C3AED","#92400E","#3B6D11","#534AB7"];

  secRows.forEach((sec,si)=>{
    const {cod,nome}=sec;
    ETYPES.forEach(et=>{
      const bc=getCoef(cod,et,true,2020)||0;
      const vals=[bc,...PROJ_ANOS.map(a=>getCoef(cod,et,false,a)||0)];
      if(vals.every(v=>Math.abs((v||0)-bc)<1e-7)) return;
      const col=ETYPE_COLORS[et]||"#888";
      const dash=si%3===0?[]:si%3===1?[4,3]:[2,2];
      allDs.push({
        label:`${cod} · ${et}`,
        data:vals,
        borderColor:col,backgroundColor:hexAlpha(col,.06),
        borderDash:dash,tension:.35,fill:false,pointRadius:3,borderWidth:1.5
      });
    });
  });

  dest("ch-coef-evol");
  const el=document.getElementById("ch-coef-evol");
  if(el&&allDs.length>0){
    CHARTS["ch-coef-evol"]=new Chart(el.getContext("2d"),{
      type:"line",data:{labels:CHART_ANOS_LBL,datasets:allDs},
      options:merge(CD,{
        plugins:{
          ...CD.plugins,
          legend:{labels:{
            color:"#8892a4",font:{size:9},boxWidth:9,padding:8,
            generateLabels:chart=>chart.data.datasets.map((ds,i)=>{
              const parts=ds.label.split(" · ");
              const cod=parts[0], et=parts[1]||"";
              const name=(SECNAME[cod]||cod).slice(0,24);
              return {
                text:`${name}`,
                fillStyle:ds.borderColor,strokeStyle:ds.borderColor,
                fontColor:"#8892a4",hidden:ds.hidden||false,
                datasetIndex:i,lineDash:ds.borderDash||[]
              };
            })
          }},
          tooltip:{...CD.plugins.tooltip,callbacks:{
            title:ctx=>{
              const parts=(ctx[0]?.dataset?.label||"").split(" · ");
              const cod=parts[0], et=parts[1]||"";
              return `${SECNAME[cod]||cod}`;
            },
            label:ctx=>{
              const parts=(ctx.dataset?.label||"").split(" · ");
              const et=parts[1]||"";
              return ` ${et}: ${ctx.parsed.y.toFixed(5)}`;
            }
          }}
        },
        scales:{x:CD.scales.x,y:{...CD.scales.y,
          title:{display:true,text:"coeficiente A*",color:"#8892a4"}}}
      })
    });
  }

  // Chips: one per energy type (simpler than per-sector when 73 sectors)
  mkChips("chips-coef-sub",ETYPES,ETYPES.map(e=>ETYPE_COLORS[e]),vis=>{
    const ch=CHARTS["ch-coef-evol"]; if(!ch)return;
    ch.data.datasets.forEach(ds=>{
      const et=ds.label.split(" · ").pop();
      const idx=ETYPES.indexOf(et);
      ds.hidden=idx>=0?!vis[idx]:false;
    });
    ch.update();
  });

  // ── 4. Engine 3 — Physical Volume Calibration Charts ────────────────────
  const pf=D.Producao_Fisica||[];
  // Helper: physical index = (valor / base_2020) × 100; base year anchor = 100
  const getIdx=(produto,cen,yr)=>{
    const r=pf.find(x=>x.produto===produto&&x.cenario===cen&&+x.ano===yr);
    if(!r||r.base_2020<=0)return null;
    return +(r.valor/r.base_2020*100)||null;
  };
  // Helper: absolute value (for PJ increment products with base=0)
  const getVal=(produto,cen,yr)=>{
    const r=pf.find(x=>x.produto===produto&&x.cenario===cen&&+x.ano===yr);
    return r?+(r.valor)||null:null;
  };

  // ── 4a: Energy + Biofuels production index (all base 2020 = 100) ─────────
  // Energy sectors: index = valor/base_2020 × 100  (base stored in Producao_Fisica)
  // Biofuels: Producao_Fisica stores only the PJ INCREMENT (base=0), so we
  //   reconstruct the full index using known 2020 bases from the engine:
  //   S22 Etanol 1020 PJ · S20 Biodiesel 230 PJ · S43 Gás/Biometano 900 PJ
  //   Advanced biofuels (Gasolina Verde, BioQAV, Bunker Verde) have base=0
  //   and are added to the combined S22 total.
  const BIO_BASE={"Etanol+CCS":1020,"Diesel Verde":230,"Biometano/Gás":900};
  const getIdxBio=(produto,cen,yr)=>{
    const r=pf.find(x=>x.produto===produto&&x.cenario===cen&&+x.ano===yr);
    if(!r)return null;
    const b=BIO_BASE[produto]||0;
    return b>0?((b+(+(r.valor)||0))/b*100):null;
  };
  // Combined S22 index: 1020 PJ base + sum of all four S22 biofuel increments
  const S22_ADV=["Etanol+CCS","Gasolina Verde","BioQAV","Bunker Verde"];
  const getIdxS22=(cen,yr)=>{
    const base=1020;
    const total=S22_ADV.reduce((s,p)=>{
      const r=pf.find(x=>x.produto===p&&x.cenario===cen&&+x.ano===yr);
      return s+(r?+(r.valor)||0:0);
    },0);
    return (base+total)/base*100;
  };
  // Absolute PJ value for advanced biofuels (base=0, no index possible)
  const getValPJ=(produto,cen,yr)=>{
    const r=pf.find(x=>x.produto===produto&&x.cenario===cen&&+x.ano===yr);
    return r?+(r.valor)||0:0;
  };

  // GDP baseline index: gdp_rel_2018 × 100 (what pure Engine 1a would predict)
  // For ENGINE3_SECTORS (S05/S19/S40/S42) delta_f_gdp=0, so GDP baseline ≈ flat at 100.
  // Showing it anyway keeps the reference consistent across all three sub-sections.
  const pp=D.PIB_Pop||[];
  const gdpIdx=(yr)=>{
    const r=pp.find(x=>+x.ano===yr);
    return r?(+(r.gdp_rel_2018)||1)*100:null;
  };

  const E3_EN=[
    {prod:"Petróleo bruto (S05)",   color:"#E24B4A", label:"S05 Petróleo"},
    {prod:"Derivados totais (S19)", color:"#F39C12", label:"S19 Derivados"},
    {prod:"Eletricidade",           color:"#F1C40F", label:"S40 Eletric."}
  ];
  // E3_BIO: S22 uses combined index (Etanol+CCS + advanced biofuels)
  // S20 and S43 keep their individual index approach
  const E3_BIO_SIMPLE=[
    {prod:"Diesel Verde",  fn:(cen,yr)=>getIdxBio("Diesel Verde",cen,yr),  color:"#1D9E75", label:"S20 Diesel Verde"},
    {prod:"Biometano/Gás", fn:(cen,yr)=>getIdxBio("Biometano/Gás",cen,yr),color:"#17A589", label:"S43 Biometano"}
  ];
  const e3aDs=[
    ...E3_EN.map(s=>({
      label:s.label+" 100D",
      data:[100,...ANOS.map(a=>getIdx(s.prod,"100D",a))],
      borderColor:s.color,backgroundColor:hexAlpha(s.color,.06),
      tension:.35,fill:false,pointRadius:4,borderWidth:2.5
    })),
    // S22 combined: Etanol+CCS + Gasolina Verde + BioQAV + Bunker Verde
    {label:"S22 Biocombust. Total 100D",
     data:[100,...ANOS.map(a=>getIdxS22("100D",a))],
     borderColor:"#3CB371",backgroundColor:hexAlpha("#3CB371",.06),
     tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    ...E3_BIO_SIMPLE.map(s=>({
      label:s.label+" 100D",
      data:[100,...ANOS.map(a=>s.fn("100D",a))],
      borderColor:s.color,backgroundColor:hexAlpha(s.color,.06),
      tension:.35,fill:false,pointRadius:4,borderWidth:2.5
    })),
    {label:"Baseline PIB (Engine 1a)",
     data:[100,...ANOS.map(a=>gdpIdx(a))],
     borderColor:"#888780",backgroundColor:"transparent",
     tension:.35,fill:false,pointRadius:2,borderWidth:1.5,borderDash:[6,4]}
  ];
  mkLine("ch-eng3-energy",["2020",...ANOS_S],e3aDs,
    {plugins:{...CD.plugins,legend:{labels:{color:"#8892a4",font:{size:9},boxWidth:9,padding:8}}},
     scales:{x:CD.scales.x,y:{...CD.scales.y,
       title:{display:true,text:"Índice (base 2020 = 100)",color:"#8892a4"},
       grid:{color:ctx=>ctx.tick.value===100?"rgba(255,255,255,0.22)":"#1f2233"}}}});
  // ── 4a-adv: Advanced biofuels — absolute PJ (base 2020 = 0, no index) ──────
  const ADV_BIO=[
    {prod:"Gasolina Verde", color:"#A8D08D", label:"Gasolina Verde"},
    {prod:"BioQAV",         color:"#66B2FF", label:"BioQAV (SAF)"},
    {prod:"Bunker Verde",   color:"#FFB347", label:"Bunker Verde"}
  ];
  const advOpts={
    plugins:{...CD.plugins,legend:{labels:{color:"#8892a4",font:{size:10},boxWidth:10,padding:10}}},
    scales:{x:CD.scales.x,y:{...CD.scales.y,
      title:{display:true,text:"PJ",color:"#8892a4"},min:0}}
  };
  mkLine("ch-eng3-bioadv",["2020",...ANOS_S],
    ADV_BIO.map(s=>({
      label:s.label+" 100D",
      data:[0,...ANOS.map(a=>getValPJ(s.prod,"100D",a))],
      borderColor:s.color,backgroundColor:hexAlpha(s.color,.1),
      tension:.35,fill:true,pointRadius:4,borderWidth:2.5
    })),
    advOpts);

  // Baseline dashed dataset — shared across 4b and 4c (one reference line)
  const gdpBaseDs={
    label:"Baseline PIB (Engine 1a)",
    data:[100,...ANOS.map(a=>gdpIdx(a))],
    borderColor:"#888780",backgroundColor:"transparent",
    tension:.35,fill:false,pointRadius:2,borderWidth:1.5,borderDash:[6,4]
  };

  const indOpts={
    plugins:{...CD.plugins,legend:{labels:{color:"#8892a4",font:{size:9},boxWidth:9,padding:8}}},
    scales:{x:CD.scales.x,y:{...CD.scales.y,
      title:{display:true,text:"Índice (base 2020 = 100)",color:"#8892a4"},
      grid:{color:ctx=>ctx.tick.value===100?"rgba(255,255,255,0.22)":"#1f2233"}}}
  };

  // ── 4b: Industry index — S28 Cimento / S29 Aço — 100D vs GDP baseline ───
  const E3_IND=[
    {prod:"Aço",             color:"#5D8AA8", label:"S29 Aço bruto (Mt)"},
    {prod:"Clinker/Cimento", color:"#95A5A6", label:"S28 Clinker (Mt)"}
  ];
  mkLine("ch-eng3-industry",["2020",...ANOS_S],[
    ...E3_IND.map(s=>({
      label:s.label+" 100D",
      data:[100,...ANOS.map(a=>getIdx(s.prod,"100D",a))],
      borderColor:s.color,backgroundColor:hexAlpha(s.color,.08),
      tension:.35,fill:false,pointRadius:4,borderWidth:2.5
    })),
    gdpBaseDs
  ], indOpts);

  // ── 4b: Agro index — Soja / Milho / Cana / Oleaginosas Energ. — 100D vs GDP baseline ──
  const E3_AGRO=[
    {prod:"Soja (→S01)",                    color:"#6B8E23", label:"Soja (1000t)"},
    {prod:"Milho (→S01)",                   color:"#8FBC8F", label:"Milho (1000t)"},
    {prod:"Cana-de-açúcar (→S01)",          color:"#3B6D11", label:"Cana (1000t)"},
    {prod:"Oleaginosas Energéticas (→S01)", color:"#DAA520", label:"Oleaginosas Energ. (1000t)"}
  ];
  mkLine("ch-eng3-agro",["2020",...ANOS_S],[
    ...E3_AGRO.map(s=>({
      label:s.label+" 100D",
      data:[100,...ANOS.map(a=>getIdx(s.prod,"100D",a))],
      borderColor:s.color,backgroundColor:hexAlpha(s.color,.08),
      tension:.35,fill:false,pointRadius:4,borderWidth:2.5
    })),
    gdpBaseDs
  ], indOpts);

  // ── 4b-area: Agricultural area split — Alimentos vs Energéticos ──────────
  const getArea=(produto,cen,yr)=>{
    const r=(D.Producao_Fisica||[]).find(x=>x.produto===produto&&x.cenario===cen&&+x.ano===yr);
    if(!r||!r.base_2020||+r.base_2020<=0) return null;
    return +(+r.valor / +r.base_2020 * 100)||null;
  };
  mkLine("ch-eng3-agro-area",["2020",...ANOS_S],[
    {label:"Área Alimentos 100D",
     data:[100,...ANOS.map(a=>getArea("Área Alimentos","100D",a))],
     borderColor:"#5D9E4A",backgroundColor:hexAlpha("#5D9E4A",.08),
     tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Área Energéticos 100D",
     data:[100,...ANOS.map(a=>getArea("Área Energéticos","100D",a))],
     borderColor:"#E8A020",backgroundColor:hexAlpha("#E8A020",.08),
     tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline PIB (Engine 1a)",data:[100,...ANOS.map(a=>gdpIdx(a))],
     borderColor:"#888780",backgroundColor:"transparent",
     tension:.35,fill:false,pointRadius:2,borderWidth:1.5,borderDash:[6,4]}
  ], indOpts);
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 1 — PRODUÇÃO
// ════════════════════════════════════════════════════════════════════════════
function initProducao(){
  const rs=D.Resumo||[], rc=D.Resultados_Completos||[], df=D.Delta_F_Componentes||[];
  const all100=rc.filter(r=>r.cenario==="100D"&&+r.ano===S.ano);
  const rows=filterRows(all100);
  const row100=rs.find(r=>r.cenario==="100D"&&+r.ano===S.ano)||{};

  // Base 2018 total output (sum of all sectors from Macro_Base)
  const PROD_BASE=(D.Macro_Base||[]).reduce((s,r)=>s+(+(r.output_bi)||0),0)||0;

  // KPIs — absolute production level (2018 base + delta), in tri (÷1000)
  const base=(+(row100.delta_prod_baseline_bi)||0);
  const tot100=(+(row100.delta_prod_bi)||0);
  const net =(+(row100.delta_prod_transition_bi)||0);
  const fmtTri=v=>(v>=0?"":(v<0?"-":""))+(Math.abs(v)/1000).toFixed(1)+" tri";
  setText("m-base", fmtTri(PROD_BASE + base));   // absolute level — matches chart
  setText("m-100d", fmtTri(PROD_BASE + tot100));  // absolute level — matches chart
  const netEl=document.getElementById("m-trans");
  const pctEl=document.getElementById("m-trans-pct");
  if(netEl){netEl.textContent=(net>=0?"+":"")+fmtTri(net); netEl.style.color=net>=0?"#1D9E75":"#E24B4A";}
  if(pctEl){const absBase=PROD_BASE+base; const pct=absBase>0?(net/absBase*100):0;
    pctEl.textContent=(pct>=0?"+":"")+pct.toFixed(1)+"% vs base"; pctEl.style.color=pct>=0?"#1D9E75":"#E24B4A";}

  // Trajectories — absolute production level starting from real 2018
  const TRAJ_LBL=["2018",...ANOS_S];
  const trajAbsData={
    d100:[PROD_BASE/1000,...ANOS.map(a=>{const r=rs.find(x=>x.cenario==="100D"&&+x.ano===a);return r?(PROD_BASE+(+(r.delta_prod_bi)||0))/1000:null;})],
    dBase:[PROD_BASE/1000,...ANOS.map(a=>{const r=rs.find(x=>x.cenario==="100D"&&+x.ano===a);return r?(PROD_BASE+(+(r.delta_prod_baseline_bi)||0))/1000:null;})]
  };
  const trajPctData={
    d100:[0,...ANOS.map(a=>{const r=rs.find(x=>x.cenario==="100D"&&+x.ano===a);return r&&PROD_BASE?(+(r.delta_prod_bi)||0)/PROD_BASE*100:null;})],
    dBase:[0,...ANOS.map(a=>{const r=rs.find(x=>x.cenario==="100D"&&+x.ano===a);return r&&PROD_BASE?(+(r.delta_prod_baseline_bi)||0)/PROD_BASE*100:null;})]
  };
  let trajIsAbs=true;
  const buildTrajChart=()=>{
    const d=trajIsAbs?trajAbsData:trajPctData;
    const ytxt=trajIsAbs?"R$ tri (R$2018)":"% vs 2018";
    const fmt=trajIsAbs?(v=>`R$ ${v.toFixed(2)} tri`):(v=>`${v>=0?"+":""}${v.toFixed(1)}%`);
    dest("ch-traj-compare");
    mkLine("ch-traj-compare", TRAJ_LBL,[
      {label:"100D (PIB + Inv + Mix)",data:d.d100,
       borderColor:C100,backgroundColor:hexAlpha(C100,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2},
      {label:"Linha de Base (só PIB)",data:d.dBase,
       borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2,borderDash:[5,4]}
    ],{scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:ytxt,color:"#8892a4"}}},
       plugins:{...CD.plugins,tooltip:{...CD.plugins.tooltip,callbacks:{label:ctx=>`${ctx.dataset.label}: ${fmt(ctx.parsed.y)}`}}}});
  };
  window.togTrajView=isAbs=>{
    trajIsAbs=isAbs;
    document.getElementById("traj-abs").classList.toggle("on",isAbs);
    document.getElementById("traj-pct").classList.toggle("on",!isAbs);
    buildTrajChart();
  };
  buildTrajChart();

  let netIsAbs=true;
  const buildNetChart=()=>{
    const ytxt=netIsAbs?"R$ tri (R$2018)":"% da produção base 2018";
    const fmt=netIsAbs?(v=>`R$ ${v.toFixed(2)} tri`):(v=>`${v>=0?"+":""}${v.toFixed(2)}%`);
    const vals=ANOS.map(a=>{const r=rs.find(x=>x.cenario==="100D"&&+x.ano===a);
      if(!r)return null;
      const v=+(r.delta_prod_transition_bi)||0;
      return netIsAbs?v/1000:(PROD_BASE>0?v/PROD_BASE*100:0);});
    dest("ch-traj-net");
    mkBar("ch-traj-net", ANOS_S,
      [{label:"Efeito Transição (100D − Base)",
        data:vals,
        backgroundColor:ANOS.map(a=>{const r=rs.find(x=>x.cenario==="100D"&&+x.ano===a);
          const v=(+(r?.delta_prod_transition_bi)||0);return v>=0?hexAlpha(CTRANS,.8):hexAlpha("#E24B4A",.8);}),
        borderRadius:4}],
      {plugins:{...CD.plugins,legend:{display:false},
        tooltip:{...CD.plugins.tooltip,callbacks:{label:ctx=>fmt(ctx.parsed.y)}}},
       scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:ytxt,color:"#8892a4"}}}});
  };
  window.togNetView=isAbs=>{
    netIsAbs=isAbs;
    document.getElementById("net-abs").classList.toggle("on",isAbs);
    document.getElementById("net-pct").classList.toggle("on",!isAbs);
    buildNetChart();
  };
  buildNetChart();

  // ── Top 20 charts ───────────────────────────────────────────────────────────
  // Common tooltip showing sector name + NT4 group
  const secTip={callbacks:{
    title:ctx=>SECNAME[ctx[0].label]||ctx[0].label,
    label:ctx=>`${ctx.parsed.x.toFixed(0)} R$ M · ${NT4_LABELS[grpNT4(ctx.label)]||grpNT4(ctx.label)}`
  }};

  // Top 20 by absolute 100D production, colored by NT4
  const top20=[...rows].sort((a,b)=>Math.abs(+b.delta_x_total||0)-Math.abs(+a.delta_x_total||0)).slice(0,20).reverse();
  mkHBar("ch-top20-100d", top20.map(r=>r.cod),
    [{label:"Δx 100D",data:top20.map(r=>+(r.delta_x_total)||0),
      backgroundColor:top20.map(r=>hexAlpha(nt4Color(r.cod),0.82)),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:{...CD.plugins.tooltip,...secTip}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"R$ M",color:"#8892a4"}},y:CD.scales.y}});
  // NT4 legend
  const t20lg=document.getElementById("chips-top20"); if(t20lg){
    t20lg.innerHTML="";
    Object.keys(NT4_COLS).forEach(g=>{
      const b=document.createElement("span");
      b.style.cssText=`display:inline-flex;align-items:center;gap:3px;margin:0 6px 2px 0;font-size:9px;color:${NT4_COLS[g]}`;
      b.innerHTML=`<span style="width:8px;height:8px;border-radius:2px;background:${NT4_COLS[g]};display:inline-block"></span>${NT4_LABELS[g]||g}`;
      t20lg.appendChild(b);
    });
  }

  // Top 20 transition effect, NT4 colors (positive/negative shading)
  const top20t=[...rows].sort((a,b)=>Math.abs(+b.delta_x_transition||0)-Math.abs(+a.delta_x_transition||0)).slice(0,20).reverse();
  mkHBar("ch-top20-trans", top20t.map(r=>r.cod),
    [{label:"Δx Trans.",data:top20t.map(r=>+(r.delta_x_transition)||0),
      backgroundColor:top20t.map(r=>{
        const v=+(r.delta_x_transition)||0;
        return v>=0?hexAlpha(nt4Color(r.cod),0.82):hexAlpha("#E24B4A",0.75);
      }),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:{...CD.plugins.tooltip,...secTip}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"R$ M",color:"#8892a4"}},y:CD.scales.y}});
  // NT4 legend for transition chart
  const ttlg=document.getElementById("chips-trans"); if(ttlg){
    ttlg.innerHTML="";
    Object.keys(NT4_COLS).forEach(g=>{
      const b=document.createElement("span");
      b.style.cssText=`display:inline-flex;align-items:center;gap:3px;margin:0 6px 2px 0;font-size:9px;color:${NT4_COLS[g]}`;
      b.innerHTML=`<span style="width:8px;height:8px;border-radius:2px;background:${NT4_COLS[g]};display:inline-block"></span>${NT4_LABELS[g]||g}`;
      ttlg.appendChild(b);
    });
  }

  // Production table
  setText("tbl-lbl",`Produção Setorial — 100D | ${S.ano}`);
  clrTbody("tbl-sec");
  const tb=document.querySelector("#tbl-sec tbody");
  [...rows].sort((a,b)=>Math.abs(+b.delta_x_total||0)-Math.abs(+a.delta_x_total||0)).forEach(r=>{
    const dx=+(r.delta_x_total)||0, dt=+(r.delta_x_transition)||0, db=+(r.delta_x_baseline)||0;
    const nt4=grpNT4(r.cod), gc=NT4_COLS[nt4]||"#6b7280";
    const codStyle=ENERGY_CODS.has(r.cod)?"font-weight:700;color:#F39C12":"color:var(--txt)";
    const tr=document.createElement("tr");
    tr.title=r.nome||"";
    tr.innerHTML=
      `<td style="${codStyle}">${r.cod}</td>
       <td title="${r.nome||""}" style="color:#fff">${String(r.nome||"").slice(0,30)}</td>
       <td><span style="background:${hexAlpha(gc,.18)};color:${gc};padding:1px 6px;border-radius:4px;font-size:10px;white-space:nowrap">${NT4_LABELS[nt4]||nt4}</span></td>
       <td style="color:${dx>=0?"#1D9E75":"#E24B4A"};font-weight:600">${dx.toFixed(0)}</td>
       <td style="color:var(--mut)">${db.toFixed(0)}</td>
       <td style="color:${dt>=0?"#F39C12":"#E24B4A"}">${dt.toFixed(0)}</td>
       <td style="color:var(--mut)">${(+(r.delta_x_pct)||0).toFixed(2)}%</td>
       <td style="color:var(--mut)">${(+(r.x_base)||0).toFixed(0)}</td>`;
    tb.appendChild(tr);
  });

  // dfMap: cod → delta_f_total (used in energy table below)
  const dfMap={};
  df.filter(r=>r.cenario==="100D"&&+r.ano===S.ano).forEach(r=>{dfMap[r.cod]=+(r.delta_f_total)||0;});

  // ── Energy sector: 100D vs Base comparison (delta_x_baseline from 100D rows) ─
  const ECODS=Array.from(ENERGY_CODS);
  const EPAL=["#E24B4A","#F39C12","#1D9E75","#378ADD","#9333EA","#0891B2","#F8C471","#BA7517","#8E44AD"];
  const ENAMES={};
  (D.Resultados_Completos||[]).forEach(r=>{if(ECODS.includes(r.cod)&&!ENAMES[r.cod])ENAMES[r.cod]=r.nome||r.cod;});
  // Helper: get delta_x_total for a given scenario/year/cod
  const getDx=(cen,yr,cod)=>{
    const r=(D.Resultados_Completos||[]).find(x=>x.cenario===cen&&+x.ano===yr&&x.cod===cod);
    return r?+(r.delta_x_total)||0:0;
  };

  // Helper: get delta_x_baseline for a given year/cod from 100D rows
  const getBase=(yr,cod)=>{
    const r=(D.Resultados_Completos||[]).find(x=>x.cenario==="100D"&&+x.ano===yr&&x.cod===cod);
    return r?+(r.delta_x_baseline)||0:0;
  };

  // Trajectory: 100D minus Base → fossil negative (transition reduces fossil demand), renewables positive
  mkLine("ch-energy-traj", ["2018",...ANOS_S],
    ECODS.map((cod,i)=>({
      label:(ENAMES[cod]||cod).slice(0,22),
      data:[0,...ANOS.map(a=>(getDx("100D",a,cod)-getBase(a,cod))/1e3)],
      borderColor:EPAL[i%EPAL.length],backgroundColor:hexAlpha(EPAL[i%EPAL.length],.08),
      tension:.35,fill:false,pointRadius:3,borderWidth:2
    })),
    {scales:{x:CD.scales.x,y:{...CD.scales.y,
      title:{display:true,text:"R$ bi (100D − Base)",color:"#8892a4"}}}});

  // Bar: 100D−Base per energy sector for selected year, sorted by value
  const eRows=all100.filter(r=>ECODS.includes(r.cod));
  const eRowsSorted=[...eRows].sort((a,b)=>
    ((+(b.delta_x_total)||0)-(+(b.delta_x_baseline)||0))-((+(a.delta_x_total)||0)-(+(a.delta_x_baseline)||0)));
  mkHBar("ch-energy-bar", eRowsSorted.map(r=>(ENAMES[r.cod]||r.cod).slice(0,24)),
    [{label:"Δx 100D−Base",
      data:eRowsSorted.map(r=>(+(r.delta_x_total)||0)-(+(r.delta_x_baseline)||0)),
      backgroundColor:eRowsSorted.map(r=>{
        const v=(+(r.delta_x_total)||0)-(+(r.delta_x_baseline)||0);
        return v>=0?hexAlpha("#1D9E75",.85):hexAlpha("#E24B4A",.85);
      }),
      borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"R$ M",color:"#8892a4"}},y:CD.scales.y}});

  // ── Energy sector table (sorted by 100D−Base: winners first) ────────────────
  clrTbody("tbl-energy");
  const tbe2=document.querySelector("#tbl-energy tbody");
  if(tbe2){
    eRowsSorted.forEach(r=>{
      const dx100=+(r.delta_x_total)||0, dx0=+(r.delta_x_baseline)||0;
      const cross=dx100-dx0;
      const dfd=dfMap[r.cod]||0, ind=dx100-dfd;
      const mb=+(r.mult_prod_base)||0, ms_=+(r.mult_prod_star)||0;
      const col=EPAL[ECODS.indexOf(r.cod)%EPAL.length];
      const crossColor=cross>=0?"#1D9E75":"#E24B4A";
      const tr=document.createElement("tr");
      tr.title=r.nome||"";
      tr.innerHTML=
        `<td style="font-weight:700;color:${col}">${r.cod}</td>
         <td title="${r.nome||""}" style="color:#fff">${String(r.nome||"").slice(0,34)}</td>
         <td style="color:${crossColor};font-weight:700">${cross>=0?"+":""}${cross.toFixed(0)}</td>
         <td style="color:var(--mut)">${dx100.toFixed(0)}</td>
         <td style="color:var(--mut)">${dx0.toFixed(0)}</td>
         <td style="color:#378ADD">${dfd.toFixed(0)}</td>
         <td style="color:${CTRANS}">${ind.toFixed(0)}</td>
         <td style="color:var(--mut)">${mb.toFixed(3)}</td>
         <td style="color:${CTRANS}">${ms_.toFixed(3)}</td>`;
      tbe2.appendChild(tr);
    });
  }

  // ── Section E: Spillover — all 73 sectors ordered by transition effect ──────
  buildSpillover(rc);
}

let SPILL_MODE="abs";
function setSpillMode(m){
  SPILL_MODE=m;
  document.getElementById("spill-abs").classList.toggle("on",m==="abs");
  document.getElementById("spill-pct").classList.toggle("on",m==="pct");
  buildSpillover();
}

function buildSpillover(rcFull){
  // Use current selected year; get ALL sectors (no group filter applied)
  const rc100=rcFull?(rcFull.filter(r=>r.cenario==="100D"&&+r.ano===S.ano))
                    :(D.Resultados_Completos||[]).filter(r=>r.cenario==="100D"&&+r.ano===S.ano);

  // Use delta_x_transition directly (= delta_x_total − delta_x_baseline)
  const all=[...rc100].map(r=>({
    cod:r.cod,
    nome:r.nome||r.cod,
    trans:+(r.delta_x_transition)||0,
    xbase:+(r.x_base)||0
  })).map(r=>({...r,
    transPct:r.xbase>0?(r.trans/r.xbase)*100:0
  })).sort((a,b)=>b.trans-a.trans);

  const isPct=SPILL_MODE==="pct";
  const vals=all.map(r=>isPct?r.transPct:r.trans);
  const axLabel=isPct?"% variação da produção base (100D − Base)":"R$ M (100D − Base)";
  const dsLabel=isPct?"Δx% Trans. (100D − Base)":"Δx Trans. (100D − Base)";

  dest("ch-spillover");
  const el=document.getElementById("ch-spillover"); if(!el)return;
  CHARTS["ch-spillover"]=new Chart(el.getContext("2d"),{
    type:"bar",
    data:{
      labels:all.map(r=>r.cod),
      datasets:[{
        label:dsLabel,
        data:vals,
        backgroundColor:all.map((r,i)=>{
          const c=nt4Color(r.cod);
          return vals[i]<0?hexAlpha("#E24B4A",0.72):hexAlpha(c,0.80);
        }),
        borderRadius:2
      }]
    },
    options:merge(CD,{
      indexAxis:"y",
      plugins:{
        legend:{display:false},
        tooltip:{...CD.plugins.tooltip,callbacks:{
          title:ctx=>all[ctx[0].dataIndex].nome,
          label:ctx=>{
            const r=all[ctx.dataIndex];
            const absStr=`${r.trans>=0?"+":""}${r.trans.toFixed(0)} R$ M`;
            const pctStr=`${r.transPct>=0?"+":""}${r.transPct.toFixed(2)}%`;
            return `${absStr}  (${pctStr}) · ${NT4_LABELS[grpNT4(r.cod)]||""}`;
          }
        }}
      },
      scales:{
        x:{...CD.scales.x,title:{display:true,text:axLabel,color:"#8892a4"},
           grid:{...CD.scales.x.grid,
             color:ctx=>ctx.tick.value===0?"rgba(255,255,255,0.18)":"#1f2233"}},
        y:{...CD.scales.y,ticks:{...CD.scales.y.ticks,font:{size:9}}}
      }
    })
  });
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 2 — RESULTADOS MACRO (5 sections)
// ════════════════════════════════════════════════════════════════════════════
// Base 2018 aggregates (from Macro_Base)
const VA_BASE   = 6011.1;   // R$bi — valor adicionado total 2018
const REM_BASE  = 3055.8;   // R$bi — remunerações 2018
const EMP_BASE  = 104340275;// postos — emprego total 2018
const EXP_BASE  = 1025.1;   // R$bi — exportações 2018

function initFatores(){
  const rc =D.Resultados_Completos||[];
  const rs =D.Resumo||[];
  const pp =D.PIB_Pop||[];
  const tc =D.Tax_Choques||[];
  const lb =D.Labor_Baseline||[];
  const mb =D.Macro_Base||[];

  // ── helpers ───────────────────────────────────────────────────────────────
  const rsGet=(cen,a,col)=>{const r=rs.find(x=>x.cenario===cen&&+x.ano===a);return r?(+(r[col])||0):0;};
  const tcGet=(cen,a,col)=>{const r=tc.find(x=>x.cenario===cen&&+x.ano===a);return r?(+(r[col])||0):0;};
  const popGet=a=>{const p=pp.find(x=>+x.ano===a);return p?(+(p.pop_milhoes)||220):220;};
  const fmtBi=v=>(Math.abs(v)<100?v.toFixed(1):(v/1).toFixed(0))+" bi";
  const fmtPct=v=>(v>=0?"+":"")+v.toFixed(1)+"%";
  const fmtK=v=>(v/1e6).toFixed(2)+" Milhões";
  // export coefficient per sector (Exp2018/Output2018)
  const expCoef={};
  mb.forEach(r=>{const o=+(r.output_bi)||0;if(o>0)expCoef[r.cod]=(+(r.export_bi)||0)/o;});
  // compute estimated delta-export for a given scenario+year
  const deltaExpSec=(cen,a)=>{
    const rows=rc.filter(r=>r.cenario===cen&&+r.ano===a);
    const byGrp={};
    rows.forEach(r=>{
      const dx=+(r.delta_x_total)||0;
      const de_bi=dx*expCoef[r.cod]/1e3||0;
      const g=grp7(r.cod);
      byGrp[g]=(byGrp[g]||0)+de_bi;
    });
    return byGrp;
  };
  const deltaExpTotal=(cen,a)=>Object.values(deltaExpSec(cen,a)).reduce((s,v)=>s+v,0);
  // social-category delta employment
  // share_cat_sector from Labor_Baseline: lb has {cod, grupo_labor, emprego_abs, share}
  // share = emprego_abs / total_emp_sector (already computed in R)
  const DEMOG_CATS=["Formal","Informal","Homem","Mulher","Branca","PPI","Baixo_Med","Superior"];
  const DEMOG_LABELS={Formal:"Formal",Informal:"Informal",Homem:"Homem",Mulher:"Mulher",
                      Branca:"Branca",PPI:"PPI",Baixo_Med:"Baixo/Méd",Superior:"Superior"};
  const DEMOG_COLS={Formal:"#1D9E75",Informal:"#E24B4A",Homem:"#378ADD",Mulher:"#9333EA",
                    Branca:"#F39C12",PPI:"#BA7517",Baixo_Med:"#534AB7",Superior:"#0891B2"};
  // build share lookup: {cod: {cat: share}}
  const shareMap={};
  lb.forEach(r=>{
    if(!shareMap[r.cod])shareMap[r.cod]={};
    shareMap[r.cod][r.grupo_labor]=+(r.share)||0;
  });
  const deltaEmpSocial=(cen,a)=>{
    const rows=rc.filter(r=>r.cenario===cen&&+r.ano===a);
    const bycat={};DEMOG_CATS.forEach(c=>{bycat[c]=0;});
    rows.forEach(r=>{
      const de=+(r.delta_emp_total)||0;
      DEMOG_CATS.forEach(c=>{
        bycat[c]+=de*(shareMap[r.cod]?shareMap[r.cod][c]||0:0);
      });
    });
    return bycat;
  };

  const rowsSel=filterRows(rc.filter(r=>r.cenario==="100D"&&+r.ano===S.ano));
  const G7K=["Agropecuaria","Ind_Extrativa","Energia_Fossil","Energia_Renov","Ind_Transform","Infraestrutura","Servicos"];
  const secTip={callbacks:{title:ctx=>SECNAME[ctx[0].label]||ctx[0].label}};

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — PIB
  // ══════════════════════════════════════════════════════════════════════════
  const va100    = rsGet("100D",S.ano,"delta_va_bi");
  const vaBase   = rsGet("100D",S.ano,"delta_va_baseline_bi");
  const vaTrans  = rsGet("100D",S.ano,"delta_va_transition_bi");
  const fmtTri2=v=>(v>=0?"":(v<0?"-":""))+(Math.abs(v)/1e3).toFixed(2)+" tri";
  const baseLevel  = VA_BASE + vaBase;   // absolute baseline level R$bi
  const totalLevel = VA_BASE + va100;    // absolute 100D level R$bi
  const transShare = baseLevel>0?(vaTrans/baseLevel*100):0; // % vs baseline level

  setText("pib-base-tri",  fmtTri2(baseLevel));
  setText("pib-lvl-tri",   fmtTri2(totalLevel));
  const ptEl=document.getElementById("pib-trans");
  const ptPctEl=document.getElementById("pib-trans-pct");
  if(ptEl){ptEl.textContent=(vaTrans>=0?"+":"")+fmtTri2(vaTrans); ptEl.style.color=vaTrans>=0?"#F39C12":"#E24B4A";}
  if(ptPctEl){ptPctEl.textContent=(transShare>=0?"+":"")+transShare.toFixed(1)+"% vs base"; ptPctEl.style.color=transShare>=0?"#F8C471":"#E24B4A";}

  // Per capita helpers — VA_BASE in R$bi, pop in millions → result in R$ mil/habitante
  const pop2018=(+(pp.find(x=>+x.ano===2018)||{}).pop_milhoes)||209;
  const pcBase=VA_BASE/pop2018;  // R$ mil/hab base 2018
  const pc100=(a)=>(VA_BASE+rsGet("100D",a,"delta_va_bi"))/popGet(a);
  const pcBsl=(a)=>(VA_BASE+rsGet("100D",a,"delta_va_baseline_bi"))/popGet(a);
  const CPC="#9333EA";  // per capita colour

  // Left chart: total PIB in R$ tri — single axis
  mkLine("ch-pib-traj", TRAJ_LBL,[
    {label:"100D (R$ tri)",
     data:[VA_BASE/1e3,...ANOS.map(a=>(VA_BASE+rsGet("100D",a,"delta_va_bi"))/1e3)],
     borderColor:CINV,backgroundColor:hexAlpha(CINV,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline PIB (R$ tri)",
     data:[VA_BASE/1e3,...ANOS.map(a=>(VA_BASE+rsGet("100D",a,"delta_va_baseline_bi"))/1e3)],
     borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.08),tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,
    y:{...CD.scales.y,beginAtZero:false,title:{display:true,text:"R$ tri (R$2018)",color:"#8892a4"}}}});

  // Right chart: PIB per capita in R$ mil/hab — single axis
  mkLine("ch-pib-pct", TRAJ_LBL,[
    {label:"100D per capita (R$ mil/hab)",
     data:[pcBase,...ANOS.map(a=>pc100(a))],
     borderColor:CPC,backgroundColor:hexAlpha(CPC,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline per capita (R$ mil/hab)",
     data:[pcBase,...ANOS.map(a=>pcBsl(a))],
     borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.08),tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,
    y:{...CD.scales.y,beginAtZero:false,title:{display:true,text:"R$ mil / habitante (R$2018)",color:"#8892a4"}}}});

  // PIB total % view
  mkLine("ch-pib-traj-p", TRAJ_LBL,[
    {label:"100D (%)",
     data:[0,...ANOS.map(a=>(rsGet("100D",a,"delta_va_bi")/VA_BASE*100))],
     borderColor:CINV,backgroundColor:hexAlpha(CINV,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline (%)",
     data:[0,...ANOS.map(a=>(rsGet("100D",a,"delta_va_baseline_bi")/VA_BASE*100))],
     borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.08),tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,
    y:{...CD.scales.y,title:{display:true,text:"% vs 2018",color:"#8892a4"}}}});

  // PIB per capita % view
  mkLine("ch-pib-pct-p", TRAJ_LBL,[
    {label:"100D per capita (%)",
     data:[0,...ANOS.map(a=>((pc100(a)-pcBase)/pcBase*100))],
     borderColor:CPC,backgroundColor:hexAlpha(CPC,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline per capita (%)",
     data:[0,...ANOS.map(a=>((pcBsl(a)-pcBase)/pcBase*100))],
     borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.08),tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,
    y:{...CD.scales.y,title:{display:true,text:"% vs 2018 (per capita)",color:"#8892a4"}}}});

  // Contribution %: how much of total PIB growth is from transition — anchored at 2018=0
  mkLine("ch-pib-dirindir", TRAJ_LBL,[
    {label:"Contribuição da transição (% do crescimento total)",
     data:[0,...ANOS.map(a=>{
       const tot=rsGet("100D",a,"delta_va_bi");
       const trans=rsGet("100D",a,"delta_va_transition_bi");
       return tot>0?(trans/tot*100):0;
     })],
     borderColor:"#F39C12",backgroundColor:hexAlpha("#F39C12",.18),
     tension:.35,fill:true,pointRadius:4,borderWidth:2.5}
  ],{plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:CD.scales.x,y:{...CD.scales.y,
       title:{display:true,text:"% do crescimento total atribuível à transição",color:"#8892a4"},
       min:0,
       grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});

  // Prêmio by sector group (100D transition component, selected year) — abs + % share toggle
  const transByGrp=G7K.map(g=>rc.filter(r=>r.cenario==="100D"&&+r.ano===S.ano&&grp7(r.cod)===g)
    .reduce((s,r)=>s+(+(r.delta_va_transition)||0),0)/1e3);
  const transTotal=transByGrp.reduce((s,v)=>s+v,0)||1;
  const transByGrpPct=transByGrp.map(v=>(v/transTotal*100));
  const grpBarOpts=(unit)=>({
    plugins:{...CD.plugins,legend:{display:false}},
    scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:unit,color:"#8892a4"},
      grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});
  mkBar("ch-pib-trans-grp",G7K.map(g=>GRP7_LABELS[g]||g),
    [{label:"Prêmio (R$ bi)",data:transByGrp,
      backgroundColor:G7K.map((g,i)=>transByGrp[i]>=0?hexAlpha(GRP7_COLS[g]||"#888",.85):hexAlpha("#E24B4A",.75)),
      borderRadius:4}],grpBarOpts("R$ bi"));
  mkBar("ch-pib-trans-grp-pct",G7K.map(g=>GRP7_LABELS[g]||g),
    [{label:"% do prêmio total",data:transByGrpPct.map(v=>+v.toFixed(1)),
      backgroundColor:G7K.map((g,i)=>transByGrp[i]>=0?hexAlpha(GRP7_COLS[g]||"#888",.85):hexAlpha("#E24B4A",.75)),
      borderRadius:4}],grpBarOpts("% do prêmio total"));

  // Top 20 sectors: % change vs 2018 from transition component
  const allTrans=[...rowsSel]
    .map(r=>({cod:r.cod, pct:(+(r.x_base)||0)>0?(+(r.delta_x_transition)||0)/(+(r.x_base)||1)*100:0}))
    .sort((a,b)=>Math.abs(b.pct)-Math.abs(a.pct)).slice(0,20).reverse();
  mkHBar("ch-pib-sec-pct", allTrans.map(r=>r.cod),
    [{label:"Δx transição / x_2018 (%)",
      data:allTrans.map(r=>+r.pct.toFixed(2)),
      backgroundColor:allTrans.map(r=>hexAlpha(r.pct>=0?CINV:"#E24B4A",.82)),
      borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false},tooltip:{...CD.plugins.tooltip,...secTip}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"% vs produção 2018",color:"#8892a4"},
       grid:{...CD.scales.x.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}},y:CD.scales.y}});

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — EMPREGO
  // ══════════════════════════════════════════════════════════════════════════
  const emp100   = rsGet("100D",S.ano,"delta_emp_total");
  const empBase  = rsGet("100D",S.ano,"delta_emp_baseline");
  const empTrans = rsGet("100D",S.ano,"delta_emp_transition");
  const empInd   = rsGet("100D",S.ano,"delta_emp_indirect");
  const empDir   = rsGet("100D",S.ano,"delta_emp_direct");
  const fmtMi=v=>(v>=0?"":(v<0?"-":""))+(Math.abs(v)/1e6).toFixed(2)+" Milhões";
  const emp100Level  = EMP_BASE + emp100;
  const empBaseLevel = EMP_BASE + empBase;
  // Direct/indirect split of the transition premium (proportional approximation)
  const empTransDir = emp100!==0?empTrans*(empDir/emp100):0;
  const empTransInd = emp100!==0?empTrans*(empInd/emp100):0;

  // Card 1 — baseline absolute level
  setText("e-emp-base", fmtMi(empBaseLevel));
  // Card 2 — 100D absolute level
  setText("e-emp-lvl", fmtMi(emp100Level));
  // Card 2 — transition premium
  const etEl=document.getElementById("e-emp-trans");
  if(etEl){etEl.textContent=(empTrans>=0?"+":"")+fmtMi(empTrans); etEl.style.color=empTrans>=0?"#F39C12":"#E24B4A";}
  setText("e-emp-trans-pct", empBaseLevel>0?(empTrans/empBaseLevel*100).toFixed(1)+"% vs base":"—");
  // Card 3 — direct premium + % of transition prize
  const edEl=document.getElementById("e-emp-trans-dir");
  if(edEl){edEl.textContent=(empTransDir>=0?"+":"")+fmtMi(empTransDir); edEl.style.color=empTransDir>=0?"#1D9E75":"#E24B4A";}
  setText("e-emp-trans-dir-pct", empTrans!==0?(empTransDir/empTrans*100).toFixed(1)+"% do prêmio":"—");
  // Card 4 — indirect premium + % of transition prize
  const eiEl=document.getElementById("e-emp-trans-ind");
  if(eiEl){eiEl.textContent=(empTransInd>=0?"+":"")+fmtMi(empTransInd); eiEl.style.color=empTransInd>=0?"#378ADD":"#E24B4A";}
  setText("e-emp-trans-ind-pct", empTrans!==0?(empTransInd/empTrans*100).toFixed(1)+"% do prêmio":"—");

  // Helper: employment delta by category using a specific column from Resultados_Completos
  const empCatTraj=(cat,col)=>[0,...ANOS.map(a=>{
    return rc.filter(r=>r.cenario==="100D"&&+r.ano===a)
      .reduce((s,r)=>s+(+(r[col])||0)*(shareMap[r.cod]?shareMap[r.cod][cat]||0:0),0)/1e3;
  })];

  // Trajectory: absolute level from EMP_BASE (Mi postos = millions)
  mkLine("ch-emp-traj", TRAJ_LBL,[
    {label:"100D (Mi postos)",
     data:[EMP_BASE/1e6,...ANOS.map(a=>(EMP_BASE+rsGet("100D",a,"delta_emp_total"))/1e6)],
     borderColor:CINV,backgroundColor:hexAlpha(CINV,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline PIB (Mi postos)",
     data:[EMP_BASE/1e6,...ANOS.map(a=>(EMP_BASE+rsGet("100D",a,"delta_emp_baseline"))/1e6)],
     borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.08),tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,y:{...CD.scales.y,beginAtZero:false,
     title:{display:true,text:"Milhões de postos",color:"#8892a4"}}}});

  // Trajectory: % view
  mkLine("ch-emp-traj-p", TRAJ_LBL,[
    {label:"100D (%)",
     data:[0,...ANOS.map(a=>rsGet("100D",a,"delta_emp_total")/EMP_BASE*100)],
     borderColor:CINV,backgroundColor:hexAlpha(CINV,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline PIB (%)",
     data:[0,...ANOS.map(a=>rsGet("100D",a,"delta_emp_baseline")/EMP_BASE*100)],
     borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.08),tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"% vs 2018",color:"#8892a4"}}}});

  // Premium decomposition: Direct vs Indirect (stacked bar, Mil postos, per projection year)
  // Approximation: transition premium split using same direct/indirect ratio as total
  const CDIR2="#1D9E75", CIND2="#378ADD";
  const premDirYr=ANOS.map(a=>{
    const tot=rsGet("100D",a,"delta_emp_total");
    const dir=rsGet("100D",a,"delta_emp_direct");
    const trans=rsGet("100D",a,"delta_emp_transition");
    return tot!==0?+(trans*(dir/tot)/1e6).toFixed(3):0;
  });
  const premIndYr=ANOS.map(a=>{
    const tot=rsGet("100D",a,"delta_emp_total");
    const ind=rsGet("100D",a,"delta_emp_indirect");
    const trans=rsGet("100D",a,"delta_emp_transition");
    return tot!==0?+(trans*(ind/tot)/1e6).toFixed(3):0;
  });
  mkBar("ch-emp-formal",ANOS_S,[
    {label:"Direto",data:premDirYr,
     backgroundColor:hexAlpha(CDIR2,.82),borderRadius:3,stack:"s"},
    {label:"Indireto (cadeia)",data:premIndYr,
     backgroundColor:hexAlpha(CIND2,.72),borderRadius:3,stack:"s"}
  ],{plugins:{...CD.plugins,legend:{labels:{color:"#8892a4",font:{size:10},boxWidth:10,padding:8}}},
     scales:{x:{...CD.scales.x,stacked:true},
       y:{...CD.scales.y,stacked:true,title:{display:true,text:"Milhões de postos (prêmio da transição)",color:"#8892a4"},
         grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});

  // Top 20 sectors by TRANSITION premium — sorted descending so largest is at top
  // Use per-sector dir/ind split of the transition premium (approx: trans × dir/tot ratio)
  const top20emp=[...rowsSel]
    .sort((a,b)=>Math.abs(+(b.delta_emp_transition)||0)-Math.abs(+(a.delta_emp_transition)||0))
    .slice(0,20);
  mkHBar("ch-emp-top20", top20emp.map(r=>r.cod),
    [{label:"Direto",
      data:top20emp.map(r=>{
        const tot=+(r.delta_emp_total)||0, dir=+(r.delta_emp_direct)||0, trans=+(r.delta_emp_transition)||0;
        return tot!==0?+((trans*(dir/tot))/1e3).toFixed(2):0;
      }),
      backgroundColor:hexAlpha(CDIR2,.82),borderRadius:2,stack:"s"},
     {label:"Indireto (cadeia)",
      data:top20emp.map(r=>{
        const tot=+(r.delta_emp_total)||0, ind=+(r.delta_emp_indirect)||0, trans=+(r.delta_emp_transition)||0;
        return tot!==0?+((trans*(ind/tot))/1e3).toFixed(2):0;
      }),
      backgroundColor:hexAlpha(CIND2,.65),borderRadius:2,stack:"s"}],
    {plugins:{...CD.plugins,
       tooltip:{...CD.plugins.tooltip,...secTip},
       legend:{labels:{color:"#8892a4",font:{size:10},boxWidth:10,padding:8}}},
     scales:{x:{...CD.scales.x,stacked:true,title:{display:true,text:"Mil postos — prêmio da transição",color:"#8892a4"},
       grid:{...CD.scales.x.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}},
       y:{...CD.scales.y,stacked:true}}});
  mkChips("chips-emp",["Direto","Indireto (cadeia)"],[hexAlpha(CDIR2,.82),hexAlpha(CIND2,.65)],vis=>{
    const ch=CHARTS["ch-emp-top20"]; if(!ch)return;
    ch.data.datasets.forEach((ds,i)=>{ds.hidden=!vis[i];}); ch.update();});

  // Group employment TRAJECTORY — transition premium only (shows who gains/loses from transition)
  mkLine("ch-emp-grp-traj", TRAJ_LBL,
    G7K.map(g=>({
      label:GRP7_LABELS[g]||g,
      data:[0,...ANOS.map(a=>rc.filter(r=>r.cenario==="100D"&&+r.ano===a&&grp7(r.cod)===g)
        .reduce((s,r)=>s+(+(r.delta_emp_transition)||0)/1e6,0))],
      borderColor:GRP7_COLS[g]||"#888",backgroundColor:hexAlpha(GRP7_COLS[g]||"#888",.08),
      tension:.35,fill:false,pointRadius:3,borderWidth:2
    })),
    {plugins:{...CD.plugins,legend:{labels:{color:"#8892a4",font:{size:9},boxWidth:9,padding:8}}},
     scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"Milhões de postos (prêmio da transição)",color:"#8892a4"},
       grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});

  // ── Energy sector zoom ──────────────────────────────────────────────────────
  // Individual colour per energy sector: fossil=red shades, renewable=green shades
  const ENG_COLS={
    S05:"#E24B4A", S19:"#C0392B", S21:"#F39C12", S43:"#E67E22",  // fossil
    S20:"#1D9E75", S22:"#27AE60", S40:"#00897B", S41:"#0097A7", S42:"#388E3C" // renewable
  };
  const engSecTip={callbacks:{
    title:ctx=>SECNAME[ctx[0].dataset.label]||ctx[0].dataset.label,
    label:ctx=>`${ctx.parsed.y.toFixed(2)} Mil postos`
  }};
  const engBarTip={callbacks:{
    title:ctx=>SECNAME[ctx[0].label]||ctx[0].label,
    label:ctx=>`${ctx.parsed.x.toFixed(1)} Mil postos`
  }};

  // Left: trajectory for each of the 9 energy sectors (Mil postos, delta_emp_transition)
  mkLine("ch-eng-traj", TRAJ_LBL,
    ENERGY_S.map(s=>({
      label:s,
      data:[0,...ANOS.map(a=>rc.filter(r=>r.cenario==="100D"&&+r.ano===a&&r.cod===s)
        .reduce((sm,r)=>sm+(+(r.delta_emp_transition)||0)/1e3,0))],
      borderColor:ENG_COLS[s]||"#888",
      backgroundColor:hexAlpha(ENG_COLS[s]||"#888",.08),
      tension:.35,fill:false,pointRadius:3,
      borderWidth:FOSSIL_S.includes(s)?1.8:2.5,
      borderDash:FOSSIL_S.includes(s)?[5,3]:[]
    })),
    {plugins:{...CD.plugins,
       tooltip:{...CD.plugins.tooltip,...engSecTip},
       legend:{labels:{
         color:"#8892a4",font:{size:9},boxWidth:9,padding:6,
         generateLabels:chart=>chart.data.datasets.map((ds,i)=>({
           text:(SECNAME[ds.label]||ds.label).slice(0,26),
           fillStyle:ds.borderColor,strokeStyle:ds.borderColor,
           fontColor:"#8892a4",
           hidden:ds.hidden||false,datasetIndex:i,
           lineDash:ds.borderDash||[]
         }))
       }}},
     scales:{x:CD.scales.x,y:{...CD.scales.y,
       title:{display:true,text:"Mil postos (prêmio da transição)",color:"#8892a4"},
       grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});

  // Right: bar chart — current year, sorted by transition premium magnitude
  const engBars=ENERGY_S
    .map(s=>{
      const r=rowsSel.find(x=>x.cod===s)||{};
      return {cod:s, val:+(r.delta_emp_transition||0)/1e3};
    })
    .sort((a,b)=>b.val-a.val);
  // Use sector names as labels directly (no index trick needed)
  const engBarLabels=engBars.map(r=>SECNAME[r.cod]||r.cod);
  mkHBar("ch-eng-bar", engBarLabels,
    [{label:"Prêmio da transição",
      data:engBars.map(r=>+r.val.toFixed(1)),
      backgroundColor:engBars.map(r=>hexAlpha(ENG_COLS[r.cod]||"#888",Math.abs(r.val)>0?.82:.4)),
      borderRadius:4}],
    {plugins:{...CD.plugins,legend:{display:false},
       tooltip:{...CD.plugins.tooltip,...engBarTip}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"Mil postos",color:"#8892a4"},
       grid:{...CD.scales.x.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}},
       y:{...CD.scales.y}}});

  // ── Level chart: Base 2018 (MIP stock, gray) | 100D delta (direct + indirect)
  // Base: use Macro_Base.emprego — direct MIP 2018 employment stock per sector
  const empMIP2018={};
  (D.Macro_Base||[]).forEach(r=>{empMIP2018[r.cod]=(+(r.emprego)||0);});
  const engLvl=ENERGY_S.map(s=>{
    const base=(empMIP2018[s]||0)/1e3;
    const r=rowsSel.find(x=>x.cod===s)||{};
    const dir =(+(r.delta_emp_direct  )||0)/1e3;
    const ind =(+(r.delta_emp_indirect)||0)/1e3;
    return {cod:s, base:+base.toFixed(1), dir:+dir.toFixed(1), ind:+ind.toFixed(1),
            total:+(base+dir+ind).toFixed(1)};
  }).sort((a,b)=>b.total-a.total);
  const engLvlLabels=engLvl.map(r=>SECNAME[r.cod]||r.cod);
  mkHBar("ch-eng-lvl", engLvlLabels,[
    {label:"Base 2018",
     data:engLvl.map(r=>r.base),
     backgroundColor:"#4a5168", borderRadius:3, stack:"base"},
    {label:"Direto (100D)",
     data:engLvl.map(r=>r.dir),
     backgroundColor:engLvl.map(r=>hexAlpha(ENG_COLS[r.cod]||"#888",.88)),
     borderRadius:0, stack:"100d"},
    {label:"Indireto (100D)",
     data:engLvl.map(r=>r.ind),
     backgroundColor:engLvl.map(r=>hexAlpha(ENG_COLS[r.cod]||"#888",.35)),
     borderRadius:3, stack:"100d"}],
    {plugins:{...CD.plugins,
       tooltip:{...CD.plugins.tooltip,callbacks:{
         title:ctx=>SECNAME[ctx[0].label]||ctx[0].label,
         label:ctx=>`${ctx.dataset.label}: ${ctx.parsed.x.toFixed(1)} Mil postos`,
         footer:ctx=>{
           const i=ctx[0].dataIndex;
           return `Total 100D: ${(engLvl[i].dir+engLvl[i].ind).toFixed(1)} Mil postos`;}}},
       legend:{labels:{color:"#8892a4",font:{size:10},boxWidth:10,padding:10,
         generateLabels:chart=>chart.data.datasets.map((ds,i)=>({
           text:ds.label,
           fillStyle:i===0?"#4a5168":(i===1?"#1D9E75":"rgba(29,158,117,.35)"),
           strokeStyle:"transparent",
           fontColor:"#8892a4", hidden:ds.hidden||false, datasetIndex:i}))}}},
     scales:{x:{...CD.scales.x,stacked:true,title:{display:true,text:"Mil postos",color:"#8892a4"}},
             y:{...CD.scales.y,stacked:true}}});

  // Matrix: sector group × demographic category — transition premium + % of 2018 base
  const matrixEl=document.getElementById("emp-matrix");
  if(matrixEl){
    // Demographic pairs — columns (4 complementary pairs)
    const MPAIRS=[["Formal","Informal"],["Homem","Mulher"],["Branca","PPI"],["Baixo_Med","Superior"]];
    const MCOLS=MPAIRS.flat();
    const MHDR={Formal:"Formal",Informal:"Informal",Homem:"Homem",Mulher:"Mulher",
                Branca:"Branca",PPI:"PPI",Baixo_Med:"Baixo/Méd",Superior:"Superior"};
    // Build 2018 base employment per group × demographic category directly from lb
    const grpBase={};
    G7K.forEach(g=>{grpBase[g]={};MCOLS.forEach(c=>{grpBase[g][c]=0;});});
    lb.forEach(r=>{
      const g=grp7(r.cod), cat=r.grupo_labor;
      if(grpBase[g]&&grpBase[g][cat]!==undefined) grpBase[g][cat]+=(+(r.emprego_abs)||0);
    });
    // Aggregate per group × category: transition premium
    const mtxT={};
    G7K.forEach(g=>{mtxT[g]={};MCOLS.forEach(c=>{mtxT[g][c]=0;});});
    rc.filter(r=>r.cenario==="100D"&&+r.ano===S.ano).forEach(r=>{
      const g=grp7(r.cod), sm=shareMap[r.cod]||{};
      const trans=+(r.delta_emp_transition)||0;
      MCOLS.forEach(c=>{ mtxT[g][c]+=trans*(sm[c]||0); });
    });
    // Row totals (transition premium per group, independent of demo split)
    const rowT={}; G7K.forEach(g=>{
      rowT[g]=rc.filter(r=>r.cenario==="100D"&&+r.ano===S.ano&&grp7(r.cod)===g)
        .reduce((s,r)=>s+(+(r.delta_emp_transition)||0),0);
    });
    const rowBase={}; G7K.forEach(g=>{
      // sum Formal+Informal from grpBase = total 2018 base for this group
      rowBase[g]=(grpBase[g]["Formal"]||0)+(grpBase[g]["Informal"]||0);
    });
    // Column totals and bases
    const colT={},colBase={}; MCOLS.forEach(c=>{
      colT[c]=G7K.reduce((s,g)=>s+mtxT[g][c],0);
      colBase[c]=G7K.reduce((s,g)=>s+(grpBase[g][c]||0),0);
    });
    // Scale: max |transition| for colour intensity
    const allVals=[...G7K.flatMap(g=>MCOLS.map(c=>Math.abs(mtxT[g][c]))),
                   ...G7K.map(g=>Math.abs(rowT[g]))];
    const maxV=Math.max(...allVals,1);
    // mkCell: t = transition premium (postos), base = 2018 base for % calculation
    const mkCell=(t,base)=>{
      const i=Math.min(Math.abs(t)/maxV,1);
      const pos=t>=0;
      const rgb=pos?"29,158,117":"226,75,74";
      const bg=`rgba(${rgb},${.08+i*.72})`;
      const fg=i>.48?"#fff":"#c8d0dc";
      const sub=i>.48?"rgba(255,255,255,.65)":"#6b7685";
      const sign=t>=0&&t!==0?"+":"";
      return `<td style="text-align:center;padding:6px 4px;background:${bg};border-radius:3px;min-width:60px;white-space:nowrap">`+
             `<div style="color:${fg};font-weight:700;font-size:11px">${sign}${(t/1e3).toFixed(1)} Mil</div>`+
             `</td>`;
    };
    // Pair separators: light right border after each pair
    const pairSep=(c)=>MPAIRS.some(p=>p[1]===c)?"border-right:1px solid rgba(255,255,255,.08);padding-right:5px":"";
    let hh=`<table style="border-collapse:separate;border-spacing:2px;width:100%;font-size:10px">`;
    // Pair group headers
    hh+=`<thead><tr><th></th>`;
    MPAIRS.forEach(pair=>{
      hh+=`<th colspan="2" style="text-align:center;color:#8892a4;font-size:8.5px;padding:2px 4px;letter-spacing:.06em;text-transform:uppercase;border-bottom:1px solid rgba(255,255,255,.1)">`+
          `${MHDR[pair[0]]} / ${MHDR[pair[1]]}</th>`;
    });
    hh+=`<th style="text-align:center;color:#8892a4;font-size:8.5px;padding:2px 4px">Total</th></tr>`;
    // Individual column headers
    hh+=`<tr><th style="text-align:left;color:#4a5568;font-size:8.5px;padding:2px 6px">Grupo</th>`;
    MCOLS.forEach(c=>{
      hh+=`<th style="text-align:center;color:#8892a4;font-size:8.5px;padding:2px 3px">${MHDR[c]}</th>`;
    });
    hh+=`<th style="text-align:center;color:#8892a4;font-size:8.5px;padding:2px 4px">Δ transição</th></tr></thead>`;
    // Data rows
    hh+=`<tbody>`;
    G7K.forEach(g=>{
      hh+=`<tr><td style="color:${GRP7_COLS[g]||"#888"};font-weight:700;font-size:9.5px;white-space:nowrap;padding:4px 6px">${GRP7_LABELS[g]||g}</td>`;
      MCOLS.forEach(c=>{ hh+=mkCell(mtxT[g][c],grpBase[g][c]||0); });
      hh+=mkCell(rowT[g],rowBase[g]); hh+=`</tr>`;
    });
    // Total row
    hh+=`<tr style="border-top:1px solid rgba(255,255,255,.1)">`;
    hh+=`<td style="color:#8892a4;font-weight:700;font-size:9px;padding:4px 6px">TOTAL</td>`;
    MCOLS.forEach(c=>{ hh+=mkCell(colT[c],colBase[c]); });
    hh+=mkCell(empTrans,EMP_BASE); hh+=`</tr>`;
    hh+=`</tbody></table>`;
    hh+=`<p style="font-size:8.5px;color:var(--mut);margin:5px 0 0 2px">Prêmio = postos atribuíveis à transição (100D − Baseline PIB). Shares demográficos: MIP-EPE 2018.</p>`;
    matrixEl.innerHTML=hh;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — RENDA
  // ══════════════════════════════════════════════════════════════════════════
  const rem100   = rsGet("100D",S.ano,"delta_rem_bi");
  const remBase  = rsGet("100D",S.ano,"delta_rem_baseline_bi");
  const remTrans = rsGet("100D",S.ano,"delta_rem_transition_bi");
  const remPct   = rem100/REM_BASE*100;
  const remTransPct = remBase>0?(remTrans/remBase*100):0;

  setText("e-rem",          fmtBi(rem100));
  setText("e-rem-pct",      fmtPct(remPct));
  setText("e-rem-trans",    fmtBi(remTrans));
  setText("e-rem-trans-pct",fmtPct(remTransPct));

  // Trajectory: 100D vs Baseline PIB — anchored at 2018=0
  mkLine("ch-rem-traj", TRAJ_LBL,[
    {label:"100D (total)",
     data:[0,...ANOS.map(a=>rsGet("100D",a,"delta_rem_bi"))],
     borderColor:"#9333EA",backgroundColor:hexAlpha("#9333EA",.1),tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline PIB",
     data:[0,...ANOS.map(a=>rsGet("100D",a,"delta_rem_baseline_bi"))],
     borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.08),tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"R$ bi (R$2018)",color:"#8892a4"}}}});

  // Renda: Prêmio trajectory — anchored at 2018=0
  mkLine("ch-rem-dirindir", TRAJ_LBL,[
    {label:"Prêmio Transição (R$ bi)",
     data:[0,...ANOS.map(a=>rsGet("100D",a,"delta_rem_transition_bi"))],
     borderColor:"#9333EA",backgroundColor:hexAlpha("#9333EA",.22),tension:.35,fill:true,pointRadius:4,borderWidth:2.5}
  ],{plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"R$ bi — prêmio salarial da transição",color:"#8892a4"},
       grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION 4 — GOVERNO
  // ══════════════════════════════════════════════════════════════════════════
  const tax100   = tcGet("100D",S.ano,"delta_tax_total_bi");
  const TAX_BASE = mb.reduce((s,r)=>s+(+(r.impostos_bi)||0),0)||328;
  const taxPct   = tax100/TAX_BASE*100;
  // Baseline tax = tax100 × (prod_baseline / prod_total) — proportional proxy
  const taxBaseFrac = a=>{const tot=rsGet("100D",a,"delta_prod_bi")||1; return rsGet("100D",a,"delta_prod_baseline_bi")/tot;};
  const taxBase100  = ANOS.map(a=>tcGet("100D",a,"delta_tax_total_bi")*taxBaseFrac(a));
  const taxTrans100 = ANOS.map(a=>tcGet("100D",a,"delta_tax_total_bi")*(1-taxBaseFrac(a)));
  const taxBaseSel  = tax100*taxBaseFrac(S.ano);
  const taxTransSel = tax100-taxBaseSel;
  const taxTransPct = taxBaseSel>0?(taxTransSel/taxBaseSel*100):0;

  setText("e-tax",          fmtBi(tax100));
  setText("e-tax-pct",      fmtPct(taxPct));
  setText("e-tax-trans",    fmtBi(taxTransSel));
  setText("e-tax-trans-pct",fmtPct(taxTransPct));

  // Trajectory: 100D vs Baseline PIB (proportional proxy) — anchored at 2018=0
  mkLine("ch-tax-traj", TRAJ_LBL,[
    {label:"100D (total)",
     data:[0,...ANOS.map(a=>tcGet("100D",a,"delta_tax_total_bi"))],
     borderColor:CINV,backgroundColor:hexAlpha(CINV,.1),tension:.35,fill:false,pointRadius:4,borderWidth:2.5},
    {label:"Baseline PIB (proxy)",
     data:[0,...taxBase100],
     borderColor:CBASE,backgroundColor:hexAlpha(CBASE,.08),tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"R$ bi (R$2018)",color:"#8892a4"}}}});

  // Stacked direct / indirect 100D
  mkBar("ch-tax-decomp", ANOS_S,
    [{label:"Direto",
      data:ANOS.map(a=>tcGet("100D",a,"delta_tax_direct_bi")),
      backgroundColor:hexAlpha("#378ADD",.8),borderRadius:3,stack:"s"},
     {label:"Indireto",
      data:ANOS.map(a=>tcGet("100D",a,"delta_tax_indirect_bi")),
      backgroundColor:hexAlpha("#F39C12",.8),borderRadius:3,stack:"s"}],
    {scales:{x:{...CD.scales.x,stacked:true},y:{...CD.scales.y,stacked:true,
      title:{display:true,text:"R$ bi (100D)",color:"#8892a4"}}}});

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION 5 — COMÉRCIO EXTERIOR
  // ══════════════════════════════════════════════════════════════════════════
  const FOSSIL_GRPS   =new Set(["Energia_Fossil"]);
  const WINNER_GRPS   =new Set(["Energia_Renov","Agropecuaria","Ind_Transform","Ind_Extrativa"]);
  const expGrp100 =deltaExpSec("100D",S.ano);
  const expGrp0   =deltaExpSec("0D",  S.ano);
  const expTot100 =Object.values(expGrp100).reduce((s,v)=>s+v,0);
  const expTot0   =Object.values(expGrp0).reduce((s,v)=>s+v,0);
  const expWin    =G7K.reduce((s,g)=>s+(expGrp100[g]>0?expGrp100[g]:0),0);
  const expLos    =G7K.reduce((s,g)=>s+(expGrp100[g]<0?expGrp100[g]:0),0);
  const expTrans  =expTot100-expTot0;

  setText("exp-total", expTot100.toFixed(1)+" bi");
  setText("exp-win",   expWin.toFixed(1)+" bi");
  setText("exp-los",   expLos.toFixed(1)+" bi");
  setText("exp-trans", (expTrans>=0?"+":"")+expTrans.toFixed(1)+" bi");

  // By group 100D vs 0D (grouped bar)
  const grpLabels=G7K.map(g=>GRP7_LABELS[g]||g);
  mkBar("ch-exp-grp", grpLabels,
    [{label:"100D", data:G7K.map(g=>+(expGrp100[g]||0).toFixed(2)),
      backgroundColor:G7K.map(g=>hexAlpha(GRP7_COLS[g]||"#888",.85)),borderRadius:3},
     {label:"0D",   data:G7K.map(g=>+(expGrp0[g]||0).toFixed(2)),
      backgroundColor:G7K.map(g=>hexAlpha(GRP7_COLS[g]||"#888",.35)),borderRadius:3}],
    {scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"R$ bi",color:"#8892a4"},
      grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});

  // Trajectory winners vs losers
  const RENOV_GRPS_EXP=["Energia_Renov","Agropecuaria","Ind_Transform"];
  const FOSSIL_GRP_EXP=["Energia_Fossil","Ind_Extrativa"];
  mkLine("ch-exp-traj", ANOS_S,[
    {label:"Renov+Agro+Ind 100D",
     data:ANOS.map(a=>{const eg=deltaExpSec("100D",a);return RENOV_GRPS_EXP.reduce((s,g)=>s+(eg[g]||0),0);}),
     borderColor:CINV,backgroundColor:hexAlpha(CINV,.12),tension:.35,fill:true,pointRadius:4,borderWidth:2.5},
    {label:"Fóssil+Extr. 100D",
     data:ANOS.map(a=>{const eg=deltaExpSec("100D",a);return FOSSIL_GRP_EXP.reduce((s,g)=>s+(eg[g]||0),0);}),
     borderColor:C100,backgroundColor:hexAlpha(C100,.12),tension:.35,fill:true,pointRadius:4,borderWidth:2.5},
    {label:"Total 100D",
     data:ANOS.map(a=>deltaExpTotal("100D",a)),
     borderColor:"#F39C12",backgroundColor:"transparent",tension:.35,fill:false,pointRadius:4,borderWidth:2,borderDash:[4,3]},
    {label:"Total 0D",
     data:ANOS.map(a=>deltaExpTotal("0D",a)),
     borderColor:CBASE,backgroundColor:"transparent",tension:.35,fill:false,pointRadius:4,borderWidth:1.5,borderDash:[6,4]}
  ],{scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"R$ bi",color:"#8892a4"},
    grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});

  // Energy sector export balance (renewable vs fossil)
  const RENOV_CODS=["S20","S22","S40","S41","S43"];
  const FOSSIL_CODS=["S05","S19"];
  mkLine("ch-exp-energia", ANOS_S,[
    {label:"Energia renovável (S20/S22/S40/S41/S43)",
     data:ANOS.map(a=>rc.filter(r=>r.cenario==="100D"&&+r.ano===a&&RENOV_CODS.includes(r.cod))
       .reduce((s,r)=>s+(+(r.delta_x_total)||0)*(expCoef[r.cod]||0)/1e3,0)),
     borderColor:CINV,backgroundColor:hexAlpha(CINV,.15),tension:.35,fill:true,pointRadius:4,borderWidth:2.5},
    {label:"Energia fóssil (S05/S19)",
     data:ANOS.map(a=>rc.filter(r=>r.cenario==="100D"&&+r.ano===a&&FOSSIL_CODS.includes(r.cod))
       .reduce((s,r)=>s+(+(r.delta_x_total)||0)*(expCoef[r.cod]||0)/1e3,0)),
     borderColor:C100,backgroundColor:hexAlpha(C100,.15),tension:.35,fill:true,pointRadius:4,borderWidth:2.5}
  ],{scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"R$ bi",color:"#8892a4"},
    grid:{...CD.scales.y.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}}}});

  // Top 10 export sectors 100D vs 0D
  const allSecs=rc.filter(r=>r.cenario==="100D"&&+r.ano===S.ano)
    .map(r=>({cod:r.cod,v100:(+(r.delta_x_total)||0)*(expCoef[r.cod]||0)/1e3}))
    .sort((a,b)=>Math.abs(b.v100)-Math.abs(a.v100)).slice(0,10).reverse();
  const expSec0=rc.filter(r=>r.cenario==="0D"&&+r.ano===S.ano).reduce((m,r)=>{m[r.cod]=(+(r.delta_x_total)||0)*(expCoef[r.cod]||0)/1e3;return m;},{});
  mkHBar("ch-exp-top10", allSecs.map(r=>r.cod),
    [{label:"100D",data:allSecs.map(r=>+r.v100.toFixed(3)),
      backgroundColor:allSecs.map(r=>hexAlpha(r.v100>=0?CINV:C100,.8)),borderRadius:3},
     {label:"0D",  data:allSecs.map(r=>+(expSec0[r.cod]||0).toFixed(3)),
      backgroundColor:allSecs.map(r=>hexAlpha(CBASE,.45)),borderRadius:3}],
    {plugins:{...CD.plugins,tooltip:{...CD.plugins.tooltip,...secTip}},
     scales:{x:{...CD.scales.x,title:{display:true,text:"R$ bi",color:"#8892a4"},
       grid:{...CD.scales.x.grid,color:ctx=>ctx.tick.value===0?"rgba(255,255,255,.22)":"#1f2233"}},y:CD.scales.y}});

  // ══════════════════════════════════════════════════════════════════════════
  // TABELA SETORIAL
  // ══════════════════════════════════════════════════════════════════════════
  setText("tbl-eco-lbl",`PIB · Emprego · Renda · Impostos — 100D | ${S.ano}`);
  clrTbody("tbl-eco");
  const tbe=document.querySelector("#tbl-eco tbody");
  const taxCoefMap={};
  (D.Tax_Base||[]).forEach(r=>{if(r.cod)taxCoefMap[r.cod]=+(r.tax_coef)||0;});
  const MUT="#8892a4", TXT="#e2e8f0";
  [...rowsSel].sort((a,b)=>Math.abs(+b.delta_va_total||0)-Math.abs(+a.delta_va_total||0)).forEach(r=>{
    const g7=grp7(r.cod), gc=GRP7_COLS[g7]||"#6b7280", gl=GRP7_LABELS[g7]||g7||"—";
    const isE=ENERGY_CODS.has(r.cod);
    const dv=+(r.delta_va_total)||0, dvd=+(r.delta_va_direct)||0, dvi=+(r.delta_va_indirect)||0;
    const de=+(r.delta_emp_total)||0, ded=+(r.delta_emp_direct)||0, dei=+(r.delta_emp_indirect)||0;
    const dr=+(r.delta_rem_total)||0;
    const dtax=(+(r.delta_x_total)||0)*(taxCoefMap[r.cod]||0);
    const dexp=(+(r.delta_x_total)||0)*(expCoef[r.cod]||0)/1e3;
    const sgn=(v,pos,neg)=>v>=0?pos:neg;
    const tr2=document.createElement("tr");
    tr2.title=r.nome||"";
    tr2.innerHTML=
      `<td style="color:${gc};font-weight:700">${r.cod}</td>
       <td style="color:${TXT}" title="${r.nome||""}">${String(r.nome||"").slice(0,30)}</td>
       <td><span style="background:${hexAlpha(gc,.18)};color:${gc};padding:2px 7px;border-radius:4px;font-size:10px;white-space:nowrap;font-weight:600">${gl}</span></td>
       <td style="color:${sgn(dv,"#1D9E75","#E24B4A")};font-weight:600">${dv.toFixed(0)}</td>
       <td style="color:${MUT}">${dvd.toFixed(0)}</td>
       <td style="color:${MUT}">${dvi.toFixed(0)}</td>
       <td style="color:${sgn(de,"#1D9E75","#E24B4A")};font-weight:600">${(de/1e3).toFixed(1)}k</td>
       <td style="color:${MUT}">${(ded/1e3).toFixed(1)}k</td>
       <td style="color:${MUT}">${(dei/1e3).toFixed(1)}k</td>
       <td style="color:${TXT}">${dr.toFixed(0)}</td>
       <td style="color:${TXT}">${dtax.toFixed(1)}</td>
       <td style="color:${sgn(dexp,"#0891B2","#E24B4A")}">${dexp.toFixed(2)}</td>`;
    tbe.appendChild(tr2);
  });
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 3 — IMPACTOS ENERGÉTICOS
// ════════════════════════════════════════════════════════════════════════════
function initEnergia(){
  const ei=D.Energia_Impacto||[];
  const FONTES=["Derivados","Gas_Natural","Etanol","Biodiesel","EE_Central","EE_Distrib"];
  const FOSSIL=new Set(["Derivados","Gas_Natural"]);

  mkBar("ch-ei-fonte", FONTES,
    [{label:`Δktep 100D | ${S.ano}`,
      data:FONTES.map(f=>{const r=ei.find(x=>x.cenario==="100D"&&+x.ano===S.ano&&x.fonte===f);return r?(+(r.delta_ktep)||0):0;}),
      backgroundColor:FONTES.map(f=>FONTE_C[f]||"#888"),borderRadius:3}],
    {plugins:{...CD.plugins,legend:{display:false}},
     scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"ktep",color:"#8892a4"}}}});

  mkLine("ch-ei-traj", ANOS_S,[
    {label:"Fóssil (Derivados+Gás)",
     data:ANOS.map(a=>ei.filter(r=>r.cenario==="100D"&&+r.ano===a&&FOSSIL.has(r.fonte)).reduce((s,r)=>s+(+(r.delta_ktep)||0),0)),
     borderColor:"#E24B4A",backgroundColor:hexAlpha("#E24B4A",.1),tension:.35,fill:false,pointRadius:4,borderWidth:2},
    {label:"Renovável",
     data:ANOS.map(a=>ei.filter(r=>r.cenario==="100D"&&+r.ano===a&&!FOSSIL.has(r.fonte)).reduce((s,r)=>s+(+(r.delta_ktep)||0),0)),
     borderColor:"#1D9E75",backgroundColor:hexAlpha("#1D9E75",.1),tension:.35,fill:false,pointRadius:4,borderWidth:2}
  ],{scales:{x:CD.scales.x,y:{...CD.scales.y,title:{display:true,text:"ktep",color:"#8892a4"}}}});
}

// ════════════════════════════════════════════════════════════════════════════
// INIT
// ════════════════════════════════════════════════════════════════════════════
buildControls();
showTab(0);
</script>
</body></html>]")

writeLines(html, HTML_OUT, useBytes = FALSE)
cat("Dashboard written:", HTML_OUT, "\n")
cat("File size:", round(file.size(HTML_OUT)/1e3), "KB\n")
