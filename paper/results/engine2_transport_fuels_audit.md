# Engine 2 aviation and maritime fuel-valuation audit

## Question

S49 (maritime) and S50 (aviation) use dedicated MMA physical fuel pathways. The current model reduces the S19 petroleum coefficient and adds the same monetary amount to S22 biofuels. That 1:1 replacement is a valuation assumption, not a consequence of constant prices.

## Fixed-2018-price diagnostic

- Maritime proxy: 2018 Biodiesel B100 / Fuel oil A1 = **1.721** in R$/GJ.
- Aviation proxy: 2018 Biodiesel B100 / QAV = **1.242** in R$/GJ.

Biodiesel B100 is used only as a transparent observed biofuel price proxy. It is not treated as the technological price of SAF, marine HVO, ammonia or e-fuels. The ANP-proxy case is therefore a sensitivity benchmark, not the preferred calibration.

## 2050 effect of replacing parity with the ANP biofuel proxy

- Unconstrained output difference relative to parity: **5.456 R$bn**.
- Unconstrained VA difference relative to parity: **1.837 R$bn**.
- Hard-constrained output difference relative to parity: **0.000 R$bn**.
- Hard-constrained VA difference relative to parity: **0.000 R$bn**.

These deltas isolate monetary valuation of the replacement fuel while keeping the MMA physical substitution path, investment shock, all other Engine 2 mappings, and Engine 3 physical constraints unchanged.

## Numerical stability

Across all tested years/variants, max spectral radius(A*) = **0.4571**; max kappa(I-A*) = **8.36**.

## Files

- `engine2_transport_fuels_price_inputs.csv`
- `engine2_transport_fuels_coefficients.csv`
- `engine2_transport_fuels_sector_outputs.csv`
- `engine2_transport_fuels_sensitivity_aggregate.csv`
- `engine2_transport_fuels_sensitivity_differences.csv`
