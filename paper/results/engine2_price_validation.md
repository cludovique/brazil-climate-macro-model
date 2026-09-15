# Engine 2 constant-price validation

## Main result

The normalized Engine 2 formula already has a constant-base-price interpretation. For each energy group, the current transformation

`a_i,t(raw) = a_i,0 * (s_i,t / s_i,0)`

followed by normalization to the original total energy coefficient is algebraically identical to valuing the new physical shares with the relative prices implied by the base IO coefficients and base physical shares.

Maximum numerical difference between the current formula and the explicit implied-price formulation across tested 100D sectors/years: **0**.

Therefore the ANP/MME/EPE 2018 prices should **not** be multiplied into the current Engine 2 formula as an additional factor. That would count relative prices twice.

## External price benchmark

The external price bridge is instead used to ask whether the relative prices implicitly embedded by the IO/MMA base-year mapping are broadly compatible with observed 2018 energy-price evidence.

Across the tested normalized Engine-2 columns, the median implicit electricity/fossil relative-price ratio is **0.6**, compared with a median external benchmark of **2.62**.
The median implicit bio/fossil ratio is **0.09**, compared with an external benchmark of **1.66** using biodiesel as the bioenergy proxy.

These comparisons are diagnostics, not calibration targets. Differences can arise because the IO rows aggregate multiple products, MMA physical shares use 2020 while the IO table is 2018, and observed market-stage prices differ across carriers.

## Scope

This audit covers the blocks that use the normalized `rebalancear()` closure: steel, cement, chemicals, other industry, road transport and cities/buildings. Electricity generation, refining, shipping, aviation, biodiesel and biomethane use separate direct indicators in Engine 2 and require their own calibration checks.

## Files

- `engine2_constant_price_equivalence.csv`
- `engine2_external_price_validation.csv`
- source price bridge: `paper/data/engine2_price_bridge_2018.csv`
