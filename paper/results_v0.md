# Results V1 — mechanism-based narrative with NDC consistency constraint

> **Status:** scientific draft based on Model Audit 1. Numbers use the all-sector GDP-growth counterfactual rather than the current dashboard baseline. Employment results remain provisional pending coefficient choice and productivity sensitivity.

## 3.1 Aggregate production-network effects

The NDC-transition pathway produces a positive aggregate production-network differential relative to a counterfactual in which final demand grows with GDP while all sectors retain the 2018 production structure. By 2050, gross output reaches R$26.91 trillion under the 100D pathway, compared with R$26.28 trillion in the counterfactual, corresponding to an additional R$634 billion (2.41%). Value added reaches R$13.41 trillion, R$259 billion (1.97%) above the counterfactual.

The transition differential is strongly non-monotonic because the economic impulse from transition investment changes over time while the NDC physical-production constraints become progressively more binding relative to GDP-driven growth. The value-added differential rises from R$37 billion in 2025 to R$673 billion in 2030, before declining to R$547 billion in 2035, R$482 billion in 2040, and R$124 billion in 2045. It recovers to R$259 billion in 2050 as the modeled deployment wave accelerates again. The timing of the macroeconomic effect therefore reflects the interaction between the investment cycle, energy-input substitution, and the requirement that selected sectors remain consistent with the physical NDC pathway.

An important baseline diagnostic changes the interpretation of the headline result presented at IEW. The conference presentation reported a 2050 value-added differential of approximately R$607 billion (+4.7%). The current dashboard baseline suppresses GDP-driven growth in sectors that are physically constrained in the transition scenario. When those same sectors are instead allowed to grow with GDP in the no-transition counterfactual, the 2050 value-added differential falls to R$259 billion (+1.97%). The transition scenario itself is unchanged; the difference arises entirely from the counterfactual definition. We therefore use the all-sector GDP-growth counterfactual in the paper because it is consistent with the question of how the NDC pathway differs from an economy that grows without transition-specific structural change.

## 3.2 Two transmission channels and one consistency layer

The model should not be interpreted as containing three symmetric economic shocks. Instead, it combines **two transmission channels** with a **physical consistency layer**.

The first channel is transition investment. Investment expenditure is allocated across domestic construction, machinery, metals, engineering, transport equipment, electricity infrastructure, biofuel capacity, and related sectors. The second channel is intermediate-input rewiring. Changes in the energy mix modify selected technical coefficients of the input-output matrix, shifting intermediate demand between fossil fuels, bioenergy, and electricity.

The third component has a different role. Physical production trajectories from the MMA/BLUES pathway are used as **constraints on selected sectoral outputs**. For these sectors, the model does not allow GDP-driven scaling to determine output freely. Instead, it calculates the balancing final-demand adjustment required for the input-output system, under the scenario-specific technical-coefficient matrix, to remain consistent with the prescribed NDC physical trajectory. Thus, the physical layer is a calibration or consistency condition rather than an independent source of demand.

This distinction matters because energy-input rewiring and physical calibration interact. For example, electrification of transport or industry reduces intermediate demand for petroleum products through the modified technical coefficients. At the same time, oil and refining output are constrained to follow their externally specified physical trajectories. The balancing adjustment required to satisfy those physical constraints therefore depends on the rewired production structure. In constrained sectors, the physical layer should consequently be interpreted as the residual adjustment needed to reconcile endogenous production-network demand with the NDC production pathway.

## 3.3 What drives the transition differential?

For diagnostic purposes, the audit decomposes the model across all combinations of investment, energy-input rewiring, and the physical consistency layer using Shapley values. These values are useful because they allocate non-additive interactions consistently, but they should not be read as three independent causal effects. The physical contribution is better interpreted as the share of the scenario differential associated with enforcing the NDC production constraints, including its interaction with the other mechanisms.

The decomposition shows that **transition investment is the dominant positive macroeconomic transmission channel**. In 2030, investment contributes R$632 billion of the R$673 billion value-added differential. Investment remains the largest positive component throughout the horizon: R$557 billion in 2035, R$547 billion in 2040, R$265 billion in 2045, and R$487 billion in 2050.

By contrast, the **NDC physical consistency adjustment** evolves from a small positive contribution early in the transition to a substantial negative adjustment relative to unconstrained GDP-driven growth. Its Shapley-attributed value-added contribution is +R$41 billion in 2030, becomes negative by 2035, and reaches −R$243 billion in 2050. This does not mean that physical deployment itself destroys R$243 billion of value added. Rather, it indicates that keeping the physically constrained sectors aligned with their NDC production trajectories requires less output, and therefore less upstream production, than would occur if those sectors simply expanded with aggregate GDP.

The third component, **energy-input rewiring**, has a comparatively small net aggregate contribution but a large compositional effect. In 2050 its Shapley-attributed contribution is +R$15 billion in value added. Underneath that small net number, the mechanism shifts approximately R$48 billion of value added toward renewable-energy supply chains and R$29 billion toward agriculture while reducing value added in fossil-energy supply chains by approximately R$66 billion. Thus, changing intermediate energy requirements primarily redistributes activity across the production network.

The 2050 balance can therefore be summarized as follows: transition investment creates a large positive domestic production impulse; energy substitution changes who supplies the economy; and the physical consistency layer prevents selected sectors from drifting away from the NDC production pathway. The resulting net value-added differential is +R$259 billion relative to the all-sector GDP-growth counterfactual.

## 3.4 Where do the gains and losses occur?

The investment channel spreads well beyond the sectors that directly produce energy. In 2050, infrastructure captures approximately R$185 billion of the value-added contribution associated with transition investment, manufacturing R$125 billion, and services R$129 billion. Renewable-energy sectors account for only about R$15 billion of the investment contribution itself. The largest individual contribution is construction (R$164 billion), followed by wholesale and retail trade (R$43 billion), non-ferrous metals and metal casting (R$35 billion), machinery and mechanical equipment (R$34 billion), architecture, engineering, testing and R&D services (R$20 billion), and financial and insurance services (R$17 billion).

This result highlights a central production-network feature of the transition: although energy-system deployment initiates the investment shock, much of the resulting value added is captured by conventional infrastructure, manufacturing, trade, engineering, and business-service sectors. The size of the macroeconomic gain therefore depends on the domestic economy's ability to supply the capital goods, materials, construction, and professional services required by the transition.

Energy-input rewiring produces a different distribution. Agriculture (+R$28 billion), biofuels (+R$26 billion), and centralized electricity generation (+R$15 billion) gain as intermediate demand moves away from fossil energy, while oil and gas extraction (−R$38 billion), petroleum products (−R$16 billion), and natural gas (−R$11 billion through the rewiring channel) lose value added relative to the unchanged 2018 input structure. This large two-way reallocation explains why the aggregate net effect of rewiring is small even though its sectoral consequences are substantial.

The physical consistency layer generates the largest negative adjustment in oil and gas extraction, approximately −R$135 billion of value added in 2050 relative to unconstrained GDP-driven growth, followed by petroleum products at approximately −R$25 billion. These values should be interpreted as the economic consequence of forcing the corresponding output paths to remain consistent with the NDC scenario rather than allowing those sectors to expand with GDP. The adjustment propagates into trade, agriculture, finance, professional services, and other supplier sectors through backward linkages.

## 3.5 Domestic supply-chain capture

Import leakage materially affects the size of the domestic transition dividend. With the current MAI-based domestic-content coefficients, the 2050 value-added differential is R$259 billion. Under a diagnostic upper bound in which all transition investment is supplied domestically, the differential increases to R$303 billion. Eliminating investment-related import leakage would therefore add approximately R$43 billion of domestic value added, increasing the modeled transition premium by roughly 17% relative to the current domestic-content case.

The 100%-domestic case is not intended as a realistic policy scenario. It provides an upper-bound diagnostic showing the economic importance of supply-chain localization. The publication version should complement it with empirically grounded low- and high-domestic-content sensitivities for the main capital-goods categories.

## 3.6 Labor requirements — provisional

The employment satellite produces a positive labor-requirement differential, but its magnitude is highly sensitive to coefficient selection. Using the raw 2018 sectoral employment intensities currently applied in the MMA scenario engine, the 2050 transition differential is approximately 8.36 million job-equivalents relative to the all-sector GDP counterfactual. Using the employment coefficients calibrated to reproduce the MIP-EPE technical-note exercises reduces the same result to approximately 3.34 million, or 40% of the raw estimate.

These estimates should not yet be interpreted as job creation forecasts. Both use fixed base-year employment intensities and therefore abstract from future productivity growth, occupational change, labor-market adjustment, and wage responses. Until an employment-coefficient convention and productivity sensitivity are selected, labor results should remain outside the headline abstract and be reported as labor requirements under alternative assumptions.

## Result in one sentence

> **The positive aggregate transition differential is driven primarily by the domestic investment wave, while energy-input substitution redistributes activity across fossil and low-carbon supply chains and a physical consistency layer ensures that selected sectoral outputs remain aligned with the NDC pathway.**
