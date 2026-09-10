# Paper Blueprint V0 — ERL

## Working title

**From NDC pathways to production networks: Macroeconomic spillovers of Brazil’s net-zero transition**

Alternative titles to keep in reserve:

- **Who gains from Brazil’s NDC transition? Production-network spillovers of net-zero investment**
- **Translating NDC pathways into production networks: Economy-wide effects of Brazil’s climate transition**
- **Green expansion, fossil contraction: Production-network effects of Brazil’s NDC transition**

## Target journal and article type

Target: **Environmental Research Letters (ERL)**.

The manuscript should be written as a concise Research Letter, with the main article focused on the scientific contribution and the detailed concordances, coefficients, sector mappings, robustness exercises, and expanded results moved to Supplementary Information.

## 1. Core scientific question

### Main research question

**How do NDC-consistent technology, investment, and production pathways propagate through Brazil’s production network, and under what conditions do transition-related gains offset the contraction of fossil-fuel activities?**

### Supporting questions

1. Through which channels does the NDC transition affect domestic production and value added: transition investment, changes in intermediate energy use, or changes in physical production trajectories?
2. Which sectors capture the largest gains and losses from the transition?
3. How sensitive are the macroeconomic gains to domestic supply-chain participation and import leakage?
4. What are the implied labor requirements and distributional patterns under the 2018 labor-market structure?

## 2. Central argument

Brazil is an analytically distinctive climate-transition case because its emissions profile is dominated by land use and agriculture while its power sector is already comparatively low-carbon. The implementation of its NDC therefore combines land-use mitigation with substantial restructuring of energy, transport, industry, buildings, and fuel supply chains.

The paper does not ask only whether emissions can be reduced. It asks how the implementation pathway itself propagates through the domestic economy.

The central argument is:

> **Under the modeled NDC pathway, the expansion of low-carbon investment and value chains more than offsets contraction in fossil-fuel activities in the aggregate, but the magnitude and distribution of the resulting production and value-added gains depend on how the transition is transmitted through domestic supply chains.**

The manuscript should avoid presenting the IO results as a forecast or as a causal estimate of climate policy. They are scenario-based production-network effects conditional on the modeled transition pathway, the counterfactual, and the fixed structural coefficients of the IO framework.

## 3. Scientific contribution

The contribution should be stated in three parts.

### Contribution 1 — Translating a bottom-up NDC pathway into an economy-wide production network

The model soft-links two different representations of the Brazilian economy:

- the MMA/BLUES NDC pathway, which provides sectoral physical trajectories, technology mixes, land-use changes, and investment information;
- the MIP-EPE 2018 input-output framework, which represents 73 economic sectors and contains value-added, employment, labor-composition, and energy satellite information.

The contribution is not simply applying an IO multiplier to an aggregate investment vector. The translation layer converts the physical transition pathway into year- and sector-specific economic shocks.

### Contribution 2 — Explicit decomposition into transmission mechanisms

The soft link distinguishes three mechanisms:

1. **Investment allocation (Engine 1)**: transition investment is transformed into sectoral final-demand shocks, with sector weights linked to technology deployment and adjusted for domestic content/import leakage.
2. **Intermediate-input substitution (Engine 2)**: sectoral energy mixes modify selected technical coefficients in the IO matrix, producing a scenario-specific matrix \(A_t^s\) and Leontief inverse \(L_t^s=(I-A_t^s)^{-1}\).
3. **Physical-production calibration (Engine 3)**: selected sectors follow physical trajectories from the NDC pathway rather than GDP-driven scaling; the target output path is translated into an equivalent final-demand shock.

This decomposition should become the methodological centerpiece of the paper.

### Contribution 3 — Identifying who captures the transition premium

The model traces the transition through construction, machinery, metals, electricity, bioenergy, transport, services, agriculture, and fossil activities. It therefore reveals whether the main beneficiaries are the sectors directly deploying clean technologies or the broader supplier network, and whether the contraction of fossil activities is offset elsewhere in the economy.

## 4. Model architecture

### 4.1 Base input-output system

Let \(Z\) be the 73×73 matrix of intermediate transactions, \(x\) gross output, and \(f\) final demand. The technical coefficient matrix is

\[
A = Z\,\mathrm{diag}(x)^{-1}.
\]

The standard open Leontief system is

\[
x=(I-A)^{-1}f = Lf.
\]

The transition analysis uses the open production model. Although the repository also contains a Type-II closed model with endogenous household consumption, that closed model is not used in the MMA scenario simulations. Therefore the main text should describe the reported network effects as **direct and indirect supply-chain effects**, not induced effects.

### 4.2 Scenario-specific technical coefficients

For a transition scenario \(s\) and year \(t\), Engine 2 constructs a modified technical coefficient matrix:

\[
A_t^s = A + \Delta A_t^s,
\]

and

\[
L_t^s=(I-A_t^s)^{-1}.
\]

Energy-related coefficients are reweighted using MMA sectoral shares for fossil fuels, biomass/biofuels, and electricity. Where appropriate, the procedure preserves aggregate energy-input intensity while changing the supplier composition.

### 4.3 Final-demand and investment shocks

The model separates a GDP-driven component from transition investment:

\[
\Delta f_{1,t}^s = \Delta f_{GDP,t} + \Delta f_{INV,t}^s.
\]

Transition investment is allocated across IO sectors as

\[
\Delta f_{INV,j,t}^s = INV_{t}^s\, w_{j,t}^s\, d_j,
\]

where \(INV_t^s\) is the annual investment quantum, \(w_{j,t}^s\) is the sector allocation weight, and \(d_j\) is the domestic-content share.

The annual investment series is reconstructed from overlapping MMA annualized-cost windows and, for later years, distributed according to the pace of physical deployment.

### 4.4 Physical calibration

For sectors with explicit physical trajectories, the target production change is

\[
\Delta x_{3,j,t}^s = x_{j,2018}\left(\frac{q_{j,t}^s}{q_{j,2020}}-1\right),
\]

where \(q\) is the corresponding physical quantity from the MMA pathway.

This target is converted into an equivalent final-demand vector using

\[
\Delta f_{3,t}^s=(I-A_t^s)\Delta x_{3,t}^s.
\]

The current code applies physical calibration to selected energy and heavy-industry sectors and suppresses GDP scaling for those sectors to avoid double counting.

### 4.5 Total production effect

The scenario production change is

\[
\Delta x_t^s=L_t^s\left(\Delta f_{1,t}^s+\Delta f_{3,t}^s\right).
\]

Value added, wages, and labor requirements are then obtained using 2018 satellite coefficients:

\[
\Delta VA_t^s=\hat{v}\,\Delta x_t^s,
\]

\[
\Delta EMP_t^s=\hat{e}\,\Delta x_t^s,
\]

where \(\hat{v}\) and \(\hat{e}\) contain sector-specific value-added and labor coefficients.

The labor result should be described as **employment supported / labor requirements under constant 2018 labor intensity**, unless a different productivity treatment is introduced.

## 5. Scenario design

### Baseline counterfactual

The current baseline is a no-transition, fixed-structure counterfactual in which final demand grows with GDP while the 2018 IO structure remains unchanged. There is no transition investment, no Engine 2 rewiring, and no NDC physical calibration.

The main transition quantity is therefore best described as a **scenario differential**:

\[
TP_t = X_{NDC,t} - X_{baseline,t},
\]

where \(X\) can be gross output, value added, wages, or labor requirements.

Avoid language such as “causal effect of climate policy.”

### Transition scenarios

The repository contains 0D, 25D, and 100D MMA trajectories. The current presentation focuses on the 100D pathway. The paper should use 100D as the main NDC-transition case while using at least one alternative transition pathway as a robustness/sensitivity comparison if conceptually consistent with the MMA scenario definitions.

## 6. Main findings currently supported by the model/presentation

These numbers are provisional until the audit and robustness runs are complete.

- The 100D transition pathway produces a positive aggregate production differential relative to the fixed-structure baseline by 2050.
- The presentation reports a gross-output transition premium of approximately **R$1.7 trillion (+6.7%)** in 2050.
- The presentation reports approximately **R$607 billion (+4.7%)** in additional value added in 2050.
- Gains are concentrated in construction/infrastructure, machinery and equipment, electricity, biofuels, transmission, manufacturing, and supplier networks.
- Fossil extraction and related activities contract relative to the baseline.
- The employment module indicates a large positive labor-requirement differential, but the headline employment result must be re-audited before publication because it relies on fixed 2018 labor intensities and the repository contains both raw and NT-calibrated labor coefficients.
- The 2030s appear to be the period of largest transition investment and therefore the largest production-network impulse.

## 7. Claims we should make — and claims we should avoid

### Defensible claims

- NDC implementation can create positive economy-wide production and value-added spillovers even while fossil activities contract.
- The transmission channels matter: investment, technical-coefficient changes, and physical production shifts affect different parts of the economy.
- Domestic participation in capital-goods and infrastructure supply chains influences the size of the domestic macroeconomic dividend.
- Aggregate gains coexist with sectoral losses, so industrial and labor-market policy affect how benefits and costs are distributed.
- IO results identify structural exposure and supply-chain propagation under stated assumptions; they do not forecast equilibrium GDP or employment.

### Avoid or qualify

- “Decarbonization causes GDP to rise by 4.7%.”
- “11 million new jobs will be created.”
- “The model captures induced effects” in the current scenario implementation.
- “Climate policy has a causal net benefit of R$X.”
- “The transition is costless.”

Preferred wording:

> “Under the modeled NDC pathway, value added is 4.7% higher in 2050 than in the fixed-structure counterfactual.”

and

> “The employment satellite implies X million additional job-equivalents under constant 2018 sectoral labor intensities.”

## 8. Main figures

### Figure 1 — From NDC pathways to production networks

A single framework diagram showing:

MMA/BLUES transition pathway → translation layer → three transmission mechanisms → scenario-specific IO system → gross output, value added, wages, labor requirements.

Include the three key equations for Engines 1–3.

### Figure 2 — What drives the transition premium?

**New analysis required.** Decompose the aggregate 100D–baseline differential over time into:

- investment allocation;
- technical-coefficient rewiring;
- physical-output calibration;
- interactions among mechanisms, if non-additivity is material.

Suggested output: stacked bars or waterfall by year, with gross output and/or value added.

This figure is essential because it makes the paper about mechanisms rather than only headline multipliers.

### Figure 3 — Winners and losers across the production network

Show sectoral value-added differentials in 2050, with the major positive and negative sectors. Prefer an absolute-value panel plus a normalized structural-change panel if space allows.

### Figure 4 — Labor and distribution

Use only after the employment audit. Possible structure:

- labor-requirement differential by broad sector group;
- distribution of implied jobs by skill, gender, or informality under the 2018 workforce composition.

The caption must state clearly that the demographic allocation reflects the 2018 sectoral workforce structure.

## 9. Supplementary Information plan

SI should contain:

1. Full 73-sector concordance.
2. Mapping between MMA sectors/technologies and IO sectors.
3. Detailed investment-allocation coefficients and CAPEX assumptions.
4. Domestic-content factors and sources.
5. Reconstruction of annual investment from MMA overlapping windows.
6. Technical-coefficient substitution equations by sector/subsector.
7. Physical calibration sectors, units, and base values.
8. Alternative scenario results (25D/0D where appropriate).
9. Full sectoral output/value-added/labor tables.
10. Robustness and sensitivity analysis.
11. Validation against the original MIP-EPE technical note/replication exercises.
12. Reproducibility and code/data availability statement.

## 10. Priority robustness tests

### R1 — Domestic-content sensitivity

Re-run transition investment with alternative domestic-content assumptions, for example:

- observed/base values;
- lower domestic participation;
- higher/localized supply-chain participation.

Main question: how much does domestic capture alter the 2050 value-added premium?

### R2 — Investment-allocation sensitivity

Perturb technology-to-sector allocation weights or compare alternative mappings for major capital-goods categories. Report the effect on aggregate and sectoral results.

### R3 — Mechanism decomposition

Run counterfactual combinations:

- baseline only;
- baseline + Engine 1 investment;
- baseline + Engine 2 only;
- baseline + Engine 3 only;
- Engines 1+2;
- Engines 1+3;
- Engines 2+3;
- full model.

Because Engine 2 changes the Leontief inverse, the combined effect may not equal the simple sum of standalone effects. If so, report the interaction term explicitly.

### R4 — Employment coefficient sensitivity

Compare:

- raw 2018 labor intensity;
- NT-calibrated labor coefficient used in the replication exercise;
- if possible, a simple productivity-growth sensitivity.

The main text should not report a single employment number until this exercise is complete.

### R5 — Baseline sensitivity

Assess whether the sign and ranking of transition effects remain robust under a different structural baseline or an alternative scenario comparison (e.g., 100D vs 25D) where conceptually appropriate.

## 11. Manuscript structure

### 1. Introduction — target 650–750 words

Paragraph 1: NDC implementation challenge and why macroeconomic transmission matters.

Paragraph 2: Brazil’s distinctive emissions and energy-system context.

Paragraph 3: Literature gap — most NDC/IAM analyses describe technology/emissions pathways; macroeconomic IO studies often apply exogenous demand shocks without reproducing the detailed implementation pathway.

Paragraph 4: Research question and methodological contribution.

Paragraph 5: Main results and broader relevance.

### 2. Methods — target 1,100–1,250 words

2.1 Data and sectoral representation.

2.2 Scenario design and counterfactual.

2.3 Engine 1: investment allocation.

2.4 Engine 2: intermediate energy substitution.

2.5 Engine 3: physical-output calibration.

2.6 Value-added and labor satellite accounts.

2.7 Interpretation and limitations.

### 3. Results — target 1,150–1,250 words

3.1 Aggregate production-network effects.

3.2 Mechanism decomposition.

3.3 Sectoral winners and losers.

3.4 Labor requirements and distribution.

### 4. Discussion — target 650–750 words

4.1 Why low-carbon expansion can offset fossil contraction in Brazil.

4.2 Domestic-content and industrial-policy implications.

4.3 Timing of the investment wave.

4.4 Generalizability to other emerging economies.

4.5 Limitations and interpretation.

### 5. Conclusion — target 150–200 words

One concise takeaway: NDCs are not only emissions trajectories; their implementation restructures production networks, and the domestic distribution of the gains depends on how investment and supply chains are organized.

## 12. Immediate audit questions before drafting Results

1. Confirm whether the latest presentation numbers correspond exactly to the current `main` output files.
2. Verify the 2050 100D value-added and gross-output transition premiums from the current `mma_shock_results.xlsx`/RDS.
3. Verify which components are included in the presentation’s “baseline” and “transition premium.”
4. Remove “induced” terminology from the current paper unless the scenario engine is explicitly re-run using the closed Type-II model.
5. Resolve the employment coefficient choice (`labor_coef_raw` versus the NT-calibrated coefficient) and document the rationale.
6. Rebuild the direct/indirect decomposition so Engine 3’s equivalent final-demand transformation is not misinterpreted as economically direct employment or value added.
7. Document all assumptions currently hard-coded in the investment and Engine 2 mappings.
8. Check whether any placeholder or approximate physical base values should be replaced by documented official values before submission.
9. Decide whether the 100D scenario is best described as an NDC-consistent pathway, a net-zero pathway, or a specific MMA mitigation scenario. Use the source nomenclature consistently.
10. Freeze one version/tag of the model for the manuscript once all audit corrections are complete.

## 13. Draft abstract logic — not final prose

**Context:** NDCs define emissions goals but do not directly reveal how implementation propagates across domestic production networks.

**Method:** We soft-link Brazil’s NDC implementation pathways with a 73-sector energy-disaggregated IO model through three channels: transition investment, intermediate energy substitution, and physical-production calibration.

**Result:** Under the main NDC-transition pathway, expansion in low-carbon infrastructure, manufacturing, electricity, and bioenergy outweighs contraction in fossil-related activities at the aggregate level, producing positive gross-output and value-added differentials relative to a fixed-structure counterfactual.

**Distribution:** Gains are concentrated in transition supply chains and depend on domestic-content assumptions; labor effects are uneven across skill, gender, and formality categories under the 2018 workforce structure.

**Implication:** The macroeconomic consequences of NDC implementation depend not only on emissions targets but also on the production networks through which investment and technology deployment occur.

## 14. Current preferred paper sentence

> **NDC implementation is not only an emissions pathway; it is a reallocation of investment, intermediate inputs, and production across interconnected domestic supply chains.**

This should guide the paper’s framing.
