# Engine 2 — 2018 constant-price energy bridge

## Purpose

This file documents the provisional price bridge used to translate **physical fuel shares from MMA/BLUES** into **constant-2018-price monetary weights** for Engine 2. It is intended for later use in the manuscript and/or Supplementary Information.

The key modeling assumption is that future **total energy-input intensity is held constant** because no scenario-specific energy-intensity series is available, while the composition of energy inputs changes according to the MMA/BLUES physical shares.

For sector `j`, let the observed 2018 monetary energy coefficient be

`a_E,j = sum_i a_i,j,2018`

for energy carriers `i`. Given physical shares `s_i,t` from MMA/BLUES and fixed 2018 prices `p_i,2018`, convert physical shares into monetary weights as

`w_i,t = (p_i,2018 * s_i,t) / sum_k (p_k,2018 * s_k,t)`.

Then the updated technical coefficients are

`a*_i,j,t = a_E,j * w_i,t`.

Therefore:

- prices remain fixed at 2018 values;
- total energy-input intensity remains fixed because it is not observed in the scenario data;
- only the supplier composition of the energy bundle changes;
- the change in fuel shares is driven by MMA/BLUES.

## Provisional calibration table

| Carrier | 2018 price | Market stage / proxy | Energy content | Approx. R$2018/GJ | Status |
|---|---:|---|---:|---:|---|
| Electricity | R$451.66/MWh | Industrial tariff, Brazil average | 3.6 GJ/MWh | 125.46 | Verified |
| Natural gas | R$1.89/m3 | Industrial consumer proxy | 0.03684 GJ/m3 | 51.30 | Provisional |
| Diesel | R$2.444/L | Producer/importer | 0.03551 GJ/L | 68.83 | Provisional |
| Gasoline A | R$2.713/L | Producer/importer | 0.03224 GJ/L | 84.15 | Provisional |
| QAV | R$2.207/L | Producer/importer | 0.03441 GJ/L | 64.14 | Provisional |
| GLP | R$2.195/kg | Producer/importer | 0.0473 GJ/kg | 46.41 | Provisional |
| Fuel oil A1 | R$1.879/kg | Producer/importer | 0.0406 GJ/kg | 46.28 | Provisional |
| Biodiesel B100 | ~R$2.59/L | ANP biodiesel auctions, approximate 2018 weighted value | 0.0325 GJ/L | ~79.69 | Provisional |
| Ethanol hydrated | R$2.497/L | Distribution, December 2018 proxy | 0.02135 GJ/L | 116.96 | Provisional |

The machine-readable version is stored in `paper/data/engine2_price_bridge_2018.csv`.

## Source map

### Electricity

EPE, *Anuario Estatistico de Energia Eletrica 2019/2020*, Table 2.15. The 2018 industrial tariff is R$451.66/MWh, reported from ANEEL/SAD and excluding taxes.

Official source:
https://www.epe.gov.br/sites-pt/publicacoes-dados-abertos/publicacoes/PublicacoesArquivos/publicacao-160/topico-168/Anu%C3%A1rio_2019_WEB_alterado.pdf

### Petroleum products

ANP, *Anuario Estatistico Brasileiro do Petroleo, Gas Natural e Biocombustiveis 2019*. Tables 2.38–2.42 contain weighted producer/importer prices for gasoline A, diesel, GLP, QAV and fuel oil, including 2018.

Official source landing page:
https://www.gov.br/anp/pt-br/centrais-de-conteudo/publicacoes/anuario-estatistico/anuario-estatistico-2019

These values should be re-read from ANP's downloadable tables before the manuscript is frozen; the current table is explicitly marked provisional for this reason.

### Natural gas

MME, *Boletim Mensal de Acompanhamento da Industria de Gas Natural*, 2018 series. The current bridge uses R$1.89/m3 as an industrial-consumer proxy for the consumption band up to 50,000 m3/day.

Official archive:
https://www.gov.br/mme/pt-br/assuntos/secretarias/petroleo-gas-natural-e-biocombustiveis/publicacoes-1/boletim-mensal-de-acompanhamento-da-industria-de-gas-natural/2018

### Biodiesel

ANP, biodiesel auctions with deliveries in 2018 (L58–L63). The current R$2.59/L value is a provisional approximate weighted value and should be recalculated directly from the official auction files for publication.

Official source:
https://www.gov.br/anp/pt-br/assuntos/distribuicao-e-revenda/leiloes-biodiesel/leiloes-com-entregas-em-2018

### Ethanol

The current R$2.497/L entry is a distribution-price proxy from late 2018. It should be replaced by a full-year 2018 distribution average before use in the final specification.

## Recommended sector-specific application

Rather than collapsing all fuels into one universal fossil and one universal bio price, Engine 2 should use price proxies consistent with each sector's physical transition:

- road transport: diesel/gasoline versus ethanol/biodiesel and electricity;
- aviation: QAV versus SAF/biofuel proxy;
- maritime: fuel oil/diesel versus green-bunker/biofuel proxy;
- buildings/cities: electricity versus natural gas/GLP;
- industry: electricity versus natural gas/fuel oil and bioenergy;
- electricity generation: direct fuel-input indicators may remain preferable to this share-reweighting method because the technology mix already changes the actual use of combustible inputs.

## Publication status

**Do not treat all values in this table as final calibration parameters yet.** The table is preserved now so the source trail is not lost. Before publication, verify the ANP annual national values directly from the downloadable 2019 statistical-yearbook tables, calculate the full-year ethanol distribution average, and recompute the biodiesel weighted average from official auction results.
