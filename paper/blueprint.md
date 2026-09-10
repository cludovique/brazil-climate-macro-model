# Paper Blueprint V1 — ERL

## Working title

**From NDC pathways to production networks: Macroeconomic spillovers of Brazil’s net-zero transition**

## Target journal

Environmental Research Letters (ERL). Main text should remain concise; detailed mappings, coefficients, calibration assumptions, sensitivity analyses, and expanded tables should move to Supplementary Information.

## 1. Main research question

**How do NDC-consistent investment and technology pathways propagate through Brazil’s production network, and how does enforcing consistency with sectoral physical production pathways alter the resulting macroeconomic and distributional effects?**

Supporting questions:

1. How much of the transition differential is associated with the domestic investment wave?
2. How does energy-input substitution redistribute activity between fossil, renewable, agricultural, manufacturing, infrastructure, and service supply chains?
3. How much adjustment is required to keep selected sectoral outputs consistent with the NDC physical pathway?
4. How sensitive is the domestic value-added gain to import leakage and domestic supply-chain participation?
5. What labor requirements are implied under alternative employment-coefficient assumptions?

## 2. Conceptual architecture

The model should no longer be described as three symmetric transmission mechanisms.

Instead, it combines **two economic transmission channels** with **one physical consistency layer**:

### Channel 1 — Transition investment

Transition expenditure enters as a sectorally allocated final-demand shock:

\[
\Delta f_{INV,j,t}^{s}=INV_t^s w_{j,t}^{s}d_j.
\]

This channel asks: where does transition expenditure occur, how much is supplied domestically, and how does it propagate through the production network?

### Channel 2 — Intermediate energy substitution

Scenario-specific energy shares modify selected technical coefficients:

\[
A_t^s=A+\Delta A_t^s,
\qquad
L_t^s=(I-A_t^s)^{-1}.
\]

This channel asks: how does the transition change the composition of intermediate demand between fossil fuels, bioenergy, electricity, and their upstream suppliers?

### Physical consistency layer — NDC production constraints

Selected sectoral outputs are constrained to remain consistent with the MMA/BLUES physical production pathway:

\[
\Delta x_{j,t}^{NDC}=x_{j,2018}\left(\frac{q_{j,t}^s}{q_{j,2020}}-1\right).
\]

The corresponding balancing term is

\[
\Delta f_{C,t}^{s}=(I-A_t^s)\Delta x_{C,t}^{NDC}.
\]

This term is **not an autonomous final-demand shock**. It is the residual adjustment required for the scenario-specific IO system to reproduce the externally specified physical production level.

For constrained sectors, the conceptual condition is:

\[
x_{j,t}\stackrel{!}{=}x_{j,t}^{NDC}.
\]

## 3. Why the consistency layer matters

Energy rewiring and physical constraints necessarily interact.

If transport or industry becomes less oil-intensive, the altered technical coefficients reduce endogenous intermediate demand for petroleum products. If the NDC pathway simultaneously prescribes a particular oil-production trajectory, the consistency layer reconciles the endogenous production-network demand with that external production level.

For fossil sectors, this means that the balancing term can represent residual changes in final domestic demand, exports, inventories, or other final-demand components not explicitly modeled. The paper should therefore avoid interpreting the consistency adjustment as an independent economic shock or as the causal effect of physical decline.

This interaction is not a model flaw; it is the reason the soft link is needed. The IO system provides endogenous production-network propagation, while the IAM provides external information on physical trajectories that the IO system cannot determine by itself.

## 4. Baseline

The preferred primary counterfactual is an **all-sector GDP-growth, fixed-structure baseline**:

- final demand grows with the exogenous GDP path;
- the 2018 technical-coefficient matrix remains unchanged;
- no transition investment is added;
- no energy-input rewiring occurs;
- no physical NDC constraints are imposed.

For any outcome \(X\):

\[
TP_t=X_{NDC,t}-X_{baseline,t}.
\]

The current dashboard baseline should be treated as a sensitivity because it suppresses GDP scaling in the sectors later constrained by the physical layer.

## 5. Result interpretation

The paper should distinguish three different questions rather than present three causal components.

### A. Economic impulse

What additional domestic activity is associated with the transition investment wave?

### B. Structural redistribution

How does changing the technical coefficient matrix reallocate intermediate demand across fossil and low-carbon supply chains?

### C. NDC consistency adjustment

How much does the unconstrained production-network solution need to change to remain consistent with externally specified physical production trajectories?

A Shapley decomposition can still be used as a **diagnostic accounting decomposition** because it allocates interactions across model components consistently. However, its physical component must be labelled as the contribution associated with enforcing the NDC consistency constraint, not as an autonomous “physical-production effect.”

## 6. Current quantitative picture

Using the all-sector GDP-growth counterfactual, the current 100D model gives in 2050:

- Gross output: R$26.91 trillion versus R$26.28 trillion baseline; differential **+R$634 billion (+2.41%)**.
- Value added: R$13.41 trillion versus R$13.15 trillion baseline; differential **+R$259 billion (+1.97%)**.

The diagnostic Shapley attribution of 2050 value added is:

- Transition investment: **+R$487.4 billion**.
- Energy-input rewiring: **+R$15.3 billion**.
- NDC physical consistency adjustment: **−R$243.2 billion**.

These values add to the net differential but should not be interpreted as independent causal effects.

The physical consistency adjustment becomes increasingly negative after 2035 because selected constrained sectors, especially fossil-related activities, grow more slowly than the all-sector GDP counterfactual or contract. Investment remains the dominant positive economic impulse.

## 7. Main paper message

Preferred framing:

> **Brazil’s NDC transition generates a positive production-network differential because the domestic investment wave activates infrastructure, manufacturing, engineering, trade, and service supply chains. Energy substitution primarily redistributes intermediate demand away from fossil suppliers and toward low-carbon chains, while a physical consistency layer constrains selected sectoral outputs to remain aligned with the NDC pathway.**

A second key result is that domestic capture matters: the diagnostic 100%-domestic investment case raises 2050 value added from roughly R$259 billion to R$303 billion, indicating an upper-bound gain of about R$43 billion relative to the current MAI-based import-leakage assumptions.

## 8. Claims to make carefully

Defensible:

- The transition pathway is associated with a positive production and value-added differential relative to the stated counterfactual.
- Transition investment is the dominant positive production-network impulse in the current model.
- Energy-input substitution causes large sectoral redistribution even when its net aggregate contribution is small.
- Enforcing the NDC physical pathway materially changes the unconstrained IO solution, especially for fossil activities.
- Domestic supply-chain participation changes how much of the investment impulse is retained in Brazil.

Avoid or qualify:

- “Decarbonization causes GDP to increase by X%.”
- “Physical decline destroys R$X billion.”
- “Engine 3 is a third independent economic shock.”
- “The model predicts X million jobs.”
- “The model captures induced household effects” in the current scenario implementation.

## 9. Figure plan

### Figure 1 — Model architecture

Show:

MMA/BLUES pathway → two parallel translation channels:

1. Investment → \(\Delta f_{INV}\)
2. Energy shares → \(A_t^*\)

These feed the IO production-network solution.

Then show a **constraint loop** from MMA/BLUES physical trajectories back to selected sector outputs:

\[
x_{j,t}\stackrel{!}{=}x_{j,t}^{NDC}
\]

with a balancing adjustment \(\Delta f_C\).

Engine 3 should be visually different from Channels 1 and 2: not a third parallel arrow, but a calibration/constraint layer.

### Figure 2 — How the net differential emerges

Preferred main panel:

- transition investment contribution;
- energy-rewiring contribution;
- NDC consistency adjustment;
- net value-added differential over time.

Label the decomposition explicitly as **diagnostic/Shapley attribution**, not independent causal effects.

A possible second panel should compare the unconstrained transition solution (investment + rewiring) with the NDC-constrained solution. This directly visualizes the role of the physical consistency layer.

### Figure 3 — Production-network winners and losers

Show 2050 sectoral value-added differences, separating where useful:

- gains associated with investment;
- redistribution associated with energy rewiring;
- largest consistency adjustments in constrained sectors and their suppliers.

### Figure 4 — Domestic capture / labor distribution

Priority option: domestic-content sensitivity, because it connects directly to the paper’s industrial-policy implication.

Labor distribution should remain secondary until the coefficient and productivity sensitivities are resolved.

## 10. Next model tests

1. **Unconstrained vs constrained solution.** Run investment + rewiring without the physical layer, then impose physical constraints. Quantify the balancing adjustment by sector and year.
2. **Constraint residual interpretation.** For oil/refining and other major constrained sectors, calculate how much of the balancing term is plausibly associated with exports/final demand versus changes already generated by intermediate-demand rewiring.
3. **Engine 2 × constraint interaction.** Explicitly quantify the difference between imposing physical constraints under the original \(A\) and under the rewired \(A_t^*\).
4. **Domestic-content sensitivity.** Replace the 100%-domestic upper bound with empirically grounded low/base/high localization cases.
5. **Baseline sensitivity.** Compare all-sector GDP baseline, current dashboard baseline, and an alternative MMA scenario where conceptually appropriate.
6. **Employment sensitivity.** Resolve raw versus NT-calibrated coefficients and add an exogenous productivity sensitivity before reporting headline labor numbers.

## 11. Manuscript structure

### Introduction

Frame the paper around translating NDC implementation into production-network consequences, not around a generic “green vs brown” claim.

### Methods

1. Data and sectoral representation.
2. Baseline/counterfactual.
3. Channel 1: investment.
4. Channel 2: energy-input substitution.
5. Physical consistency layer: sectoral NDC constraints and balancing adjustment.
6. Satellite accounts.
7. Diagnostic decomposition and sensitivities.

### Results

1. Aggregate transition differential.
2. Economic impulse versus NDC consistency adjustment.
3. Sectoral redistribution and production-network propagation.
4. Domestic supply-chain capture.
5. Labor requirements, if robust enough.

### Discussion

Focus on why NDC implementation cannot be represented by investment multipliers alone: economic propagation and physical consistency must be reconciled. Discuss implications for industrial policy, fossil-sector contraction, trade/export assumptions, and transferability to other emerging economies.

## 12. Key sentence

> **NDC implementation is not only an emissions pathway or an investment shock: it is a restructuring of production networks subject to physical constraints on how key sectors evolve.**
