# Model Audit 1 — ERL paper

This report is generated from the current model code and input data on the paper branch.
It is a diagnostic document, not yet manuscript text.

## 1. Baseline audit

- Current-model 2050 gross-output transition differential: **R$ 1,680.1 bn**.
- Current-model 2050 value-added transition differential: **R$ 607.3 bn**.
- Using an all-sector GDP-growth counterfactual, the 2050 gross-output differential is **R$ 634.1 bn** and the value-added differential is **R$ 259.4 bn**.
- Difference attributable to the current baseline freezing Engine-3 sectors rather than allowing GDP-driven growth: **R$ 1,046 bn output** and **R$ 347.9 bn value added**.

**Interpretation:** the manuscript should use the all-sector GDP counterfactual as the primary baseline if the intent is 'GDP grows but the transition does not occur'. The current dashboard baseline should be retained only if its narrower definition is explicitly intended and defended.

## 2. Why does the transition differential emerge? — Shapley decomposition

Shapley values decompose the full result while allocating interactions among the three mechanisms, so the contributions add exactly to the modeled transition differential.

### 2050 value added

- Investment allocation: **R$ 487.4 bn** (187.8% of the total differential).
- Energy-input rewiring: **R$ 15.3 bn** (5.9%).
- Physical-production calibration: **R$ -243.2 bn** (-93.7%).

### 2050 gross output

- Investment allocation: **R$ 1,277.5 bn** (201.5% of the total differential).
- Energy-input rewiring: **R$ 9 bn** (1.4%).
- Physical-production calibration: **R$ -652.3 bn** (-102.9%).

## 3. Domestic supply-chain capture

- 2050 value-added premium with current MAI-based domestic-content factors: **R$ 259.4 bn**.
- 2050 value-added premium under a 100%-domestic investment upper bound: **R$ 302.7 bn**.
- Difference: **R$ 43.3 bn** of additional value added under zero investment import leakage.

This is an upper-bound diagnostic, not yet a policy scenario. Empirically grounded localization sensitivities should be selected before publication.

## 4. Employment coefficient sensitivity

- 2050 transition labor requirement using raw 2018 sectoral coefficients: **8,356,716** job-equivalents.
- Using the NT-calibrated employment coefficients: **3,342,686** job-equivalents.
- NT-calibrated/raw ratio: **40.0%**.

## 5. Files produced

- `baseline_audit.csv`
- `mechanism_shapley.csv`
- `mechanism_standalone_and_interactions.csv`
- `sector_mechanism_va.csv`
- `domestic_content_diagnostic.csv`
- `employment_coefficient_diagnostic.csv`

## 6. Next paper step

Use the mechanism decomposition to build Figure 2, then write the Results section around the mechanism story rather than around headline totals alone. The sector-level Shapley file can be used to explain which supply chains transmit each mechanism.
