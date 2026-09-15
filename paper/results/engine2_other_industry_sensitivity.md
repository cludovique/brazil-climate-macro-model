# Engine 2 other-industry sensitivity

This test protects likely material-feedstock coefficients from the generic MMA `other industry` fuel-switching trajectory, while leaving the rest of Engine 2 unchanged.

Protected coefficients: S19->S23 and S20/S22->S25/S26. This is a conservative diagnostic, not yet a final structural split between energy and feedstocks.

## 2050 effect

- Unconstrained VA difference (energy-only minus current): **R$ 4.644 bn**.
- Hard-constrained VA difference: **R$ 0 bn**.
- Unconstrained gross-output difference: **R$ 19.549 bn**.
- Hard-constrained gross-output difference: **R$ 0 bn**.

If these differences are small relative to the overall transition differential, the current residual-industry aggregation is robust to the feedstock interpretation. If they are material, the paper should retain the energy-only specification or introduce an explicit feedstock bridge.

## Files

- `engine2_other_industry_sensitivity_aggregate.csv`
- `engine2_other_industry_sensitivity_sectors.csv`
- `engine2_other_industry_protected_coefficients.csv`
