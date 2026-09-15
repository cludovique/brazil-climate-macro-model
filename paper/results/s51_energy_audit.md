# S51 energy-use audit

This diagnostic compares S51 (Armazenamento e correio) with S48 (Transporte terrestre) and S52 (Alojamento) using the 2018 IO technical coefficients and the EPE physical-energy satellite account.

## Monetary IO energy coefficients

- S48 total energy coefficient: **0.20009**; petroleum: **0.18138**; electricity: **0.00007**.
- S51 total energy coefficient: **0.02567**; petroleum: **0.01444**; electricity: **0.00934**.
- S51 monetary energy intensity is **12.8% of S48**.

## Physical EPE energy satellite

- S48 physical total-energy intensity: **0.1942652 ktep/R$M**, with petroleum/fossil share **75.0%** and electricity share **0.2%**.
- S51 physical total-energy intensity: **0.00149641 ktep/R$M**, with petroleum/fossil share **12.8%** and electricity share **87.2%**.
- S51 physical energy intensity is **0.8% of S48**.

## Interpretation rule

If S51 has substantial direct fossil/electric energy intensity relative to S48, applying the transport fuel-mix trajectory can be defended as a broad logistics-sector proxy. If its direct energy intensity is small, then applying the full S48 transport transition to S51 likely overstates direct fuel substitution: transport services purchased by S51 are already represented through intermediate purchases from S48 and therefore propagate through the Leontief network without rewriting S51's own energy coefficients.

See `s51_energy_audit.csv` for the full monetary and physical coefficient comparison.
