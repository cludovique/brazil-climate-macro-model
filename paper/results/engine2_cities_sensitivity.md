# Engine 2 cities/buildings sensitivity

The current Engine 2 applies one common MMA cities/buildings energy-mix trajectory to S52, S53, S59 and S66-S70. This audit tests the importance of that broad proxy mapping without changing any other model component.

## Baseline direct energy coefficients

The 2018 city-proxy sectors span total direct modeled energy coefficients from **0.001** to **0.060** per unit of gross output.

## 2050 sensitivity relative to current specification

- Excluding S59 (real estate) from direct cities rewiring: unconstrained VA **-0.008 R$bn**; hard-constrained VA **-0.021 R$bn**.
- Extreme hospitality-only stress test (only S52/S53 rewired): unconstrained VA **-0.361 R$bn**; hard-constrained VA **-0.344 R$bn**.

The hospitality-only case is deliberately conservative and should be interpreted as a bound on the cities/buildings mapping assumption, not as a preferred scenario.

## Files

- `engine2_cities_baseline_structure.csv`
- `engine2_cities_sensitivity_aggregate.csv`
- `engine2_cities_sensitivity_differences.csv`
- `engine2_cities_sensitivity_sectors.csv`
