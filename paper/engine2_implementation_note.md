# Engine 2 implementation note — constant-price calibration

## Decision

Do **not** multiply the normalized Engine 2 coefficients by the external ANP/MME/EPE 2018 prices.

For the normalized blocks, the implemented rule is

`a_i,t(raw) = a_i,0 * (s_i,t / s_i,0)`

followed by normalization so that the sector's total monetary energy-input coefficient is unchanged.

At fixed base prices, `a_i,0 = p_i,0 q_i,0 / X_0` and `s_i,0 = q_i,0 / sum(q_0)`. Therefore

`a_i,0 * (s_i,t / s_i,0) ∝ p_i,0 * s_i,t`.

The normalization removes the common proportional term. Thus the current ratio-to-base formulation already implements the constant-base-price transformation **conditional on anchoring the model to the observed IO coefficients**. Applying the external prices again would double-count relative prices.

External 2018 prices are retained in `paper/data/engine2_price_bridge_2018.csv` for validation, transparency and sensitivity analysis.

## Empirical validation

The reproducible audit `paper/engine2_price_validation.R` confirms the algebraic equivalence numerically (maximum difference = 0 in the tested 100D normalized blocks).

The external-price comparison should not be interpreted as a target to which the IO coefficients must be forced. The IO energy rows are aggregated products, the IO base is 2018, MMA physical base shares are 2020, and the available external prices refer to different market stages. Forcing uncalibrated external R$/GJ weights directly into A would break the exact base-year IO anchoring.

## Mapping issue discovered during the audit

The current source code comments describe `S51` as **Armazenamento e correio** and `S52` as **Alojamento**, but the road-transport rebalance call uses `c("S48","S52")`. Since the cities/buildings block subsequently rewrites S52, the final S52 coefficients primarily follow the cities calibration, but **S51 is omitted from the road-transport rewiring**.

This mapping should be corrected to `c("S48","S51")` before the Engine 2 specification is frozen for the paper. The price-validation diagnostic should likewise use S48 and S51 for the road-transport block.

## Publication framing

Because future sectoral energy-intensity trajectories are unavailable, the paper should state that Engine 2 changes the composition of a fixed monetary energy-input bundle. MMA/BLUES determines the evolution of physical fuel shares; the IO table anchors base-year monetary coefficients; fixed base-year relative prices are implicit in the ratio-to-base transformation. External ANP/MME/EPE 2018 price evidence documents and checks this constant-price interpretation rather than introducing a price shock.
