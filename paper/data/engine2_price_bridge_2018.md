# Engine 2 — 2018 constant-price energy bridge

## Purpose

This file documents the 2018 energy-price evidence used to validate the constant-price interpretation of **Engine 2**. Physical energy shares come from MMA/BLUES; the input-output matrix is the 2018 MIP-EPE/FIPE table.

The model has no scenario-specific series for future sectoral energy intensity. Therefore, for the sectors treated with the normalized share-rebalancing method, total monetary energy-input intensity is held at its base IO value while the composition of the energy bundle changes with MMA/BLUES.

## Important algebraic result: do not multiply the model by these prices again

The current normalized Engine 2 transformation is

`a_i,t(raw) = a_i,0 * (s_i,t / s_i,0)`

followed by normalization so that

`sum_i a_i,t = sum_i a_i,0 = a_E,0`.

If the base IO coefficient can be written as `a_i,0 = p_i,0 q_i,0 / X_0`, and the MMA base physical share is `s_i,0 = q_i,0 / sum_k q_k,0`, then

`a_i,0 / s_i,0 = p_i,0 * (sum_k q_k,0 / X_0)`.

The common term cancels during normalization. Hence the existing transformation is algebraically equivalent to

`a_i,t ∝ p_i,0 * s_i,t`,

or, written as constant-price monetary weights,

`w_i,t = (p_i,0 * s_i,t) / sum_k (p_k,0 * s_k,t)`

and

`a_i,t = a_E,0 * w_i,t`.

**Implication:** inserting ANP/EPE/MME prices as an additional multiplier into the current ratio-and-normalization formula would double-count relative prices. The external 2018 prices below are therefore used to **validate the implicit base-year relative-price structure** and to support sensitivity checks, not as an extra multiplier in the core specification.

This equivalence holds only to the extent that the MMA 2020 physical-share grouping is compatible with the corresponding grouped energy inputs in the 2018 IO column. This mapping is therefore an empirical validation issue rather than a reason to apply prices twice.

## 2018 price evidence

| Carrier | 2018 price | Market stage / proxy | Approx. R$2018/GJ | Status | Preferred use |
|---|---:|---|---:|---|---|
| Electricity | R$451.66/MWh | Industrial tariff, Brazil average | 125.46 | Verified | Industry / electricity benchmark |
| Natural gas | R$1.89/m3 | Industrial consumer, <=50,000 m3/day | 51.30 | Published proxy | Industry/buildings fossil-gas benchmark |
| Diesel | R$2.444/L | Producer/importer | 68.83 | Verified | Road transport fossil benchmark |
| Gasoline A | R$2.713/L | Producer/importer | 84.15 | Verified | Road transport fossil benchmark |
| QAV | R$2.207/L | Producer/importer | 64.14 | Verified | Aviation fossil benchmark |
| GLP | R$2.195/kg | Producer/importer | 46.41 | Verified | Buildings/cities fossil benchmark |
| Fuel oil A1 | R$1.879/kg | Producer/importer | 46.28 | Verified | Industry/maritime fossil benchmark |
| Biodiesel B100 | R$2.589/L | 2018 ANP auctions, volume-weighted L59-L64 | 79.67 | Derived, documented | Biofuel benchmark / sensitivity |
| Ethanol hydrated | R$2.497/L | Late-2018 distribution proxy | 116.96 | Provisional | Road-transport biofuel sensitivity |
| Ethanol hydrated | R$2.889/L | 2018 annual consumer average | 135.32 | Verified, not preferred | Validation only |

The machine-readable version is stored in `paper/data/engine2_price_bridge_2018.csv`.

## Sources and verification notes

### Electricity

EPE/ANEEL, *Anuario Estatistico de Energia Eletrica 2019*. The 2018 industrial tariff is R$451.66/MWh. This is the preferred electricity benchmark for industry.

### Petroleum products

ANP, *Anuario Estatistico Brasileiro do Petroleo, Gas Natural e Biocombustiveis 2019*, Tables 2.38-2.42. The tables report Brazil-wide volume-weighted producer/importer prices for 2018. ANP states that these producer/importer prices include Cide and PIS/Cofins where applicable and exclude ICMS.

Verified national 2018 values used here are gasoline A R$2.713/L, diesel R$2.444/L, GLP R$2.195/kg, QAV R$2.207/L, and fuel oil A1 R$1.879/kg.

Official landing page:
https://www.gov.br/anp/pt-br/centrais-de-conteudo/publicacoes/anuario-estatistico/anuario-estatistico-2019

### Natural gas

MME, *Boletim Mensal de Acompanhamento da Industria de Gas Natural*. The bridge uses R$1.89/m3 as the published national industrial-consumer proxy for the band up to 50,000 m3/day. This is not a producer-price series and should be described as an industrial tariff proxy.

Official archive:
https://www.gov.br/mme/pt-br/assuntos/secretarias/petroleo-gas-natural-e-biocombustiveis/publicacoes-1/boletim-mensal-de-acompanhamento-da-industria-de-gas-natural/2018

### Biodiesel

For a calendar-2018 transaction-price diagnostic, the price was recomputed from ANP auctions L59-L64 using awarded volumes as weights. The resulting value is R$2,589.214/m3 = R$2.589214/L.

ANP's published tables list for L61 a maximum reference price of R$2,657.59/m3 but an average price of R$5,630.59/m3. The latter is internally impossible and is treated as a publication/transcription error; the calculation uses R$2,630.59/m3 for L61. The correction is explicit and the biodiesel value is therefore classified as **derived/documented**, not as a directly verified published annual average.

Official 2018 auction page:
https://www.gov.br/anp/pt-br/assuntos/distribuicao-e-revenda/leiloes-biodiesel/leiloes-com-entregas-em-2018

### Ethanol

ANP's 2019 statistical yearbook reports a verified 2018 Brazil consumer average of R$2.889/L. Because retail price is not the preferred valuation for an IO intermediate input, it is retained only as a validation check.

The preferred concept is the distribution price. The current R$2.497/L value is a late-2018 national distribution-price observation from ANP's historical survey. A full-year 2018 distribution average should replace it if the downloadable monthly series is extracted later. This limitation does **not** require changing the core normalized Engine 2, because the external price bridge is a validation device rather than an extra model multiplier.

Official historical price-series page:
https://www.gov.br/anp/pt-br/assuntos/precos-e-defesa-da-concorrencia/precos/precos-revenda-e-de-distribuicao-combustiveis/serie-historica-do-levantamento-de-precos

## Sector-specific interpretation

The external benchmarks should be compared with the implicit relative-price structure appropriate to each Engine 2 mapping rather than collapsed into a single universal fossil price:

- road transport: diesel/gasoline versus ethanol/biodiesel and electricity;
- aviation: QAV versus a biofuel/SAF proxy;
- maritime: fuel oil/diesel versus a green-bunker/biofuel proxy;
- buildings/cities: electricity versus natural gas/GLP;
- industry: electricity versus natural gas/fuel oil and bioenergy;
- electricity generation: keep the direct fuel-input indicators because this block models the actual disappearance/expansion of combustible inputs rather than a fixed energy bundle.

## Publication interpretation

A concise methods statement is:

> Because scenario-specific sectoral energy-intensity trajectories are unavailable, Engine 2 holds each affected sector's aggregate monetary energy-input coefficient constant at its base IO value and reallocates that coefficient across energy suppliers according to MMA/BLUES physical fuel shares. The ratio-to-base formulation is algebraically equivalent to valuing the changing physical mix at fixed base-year relative prices. External 2018 ANP, MME and EPE price data are used to validate those implicit relative prices rather than being applied as an additional price shock.

This formulation preserves constant-price accounting and avoids introducing an unsupported future energy-efficiency trajectory or a future energy-price scenario.
