# Engine 2 sector-mapping audit

## S51/S52 correction

The paper model now applies the aggregate road-transport fuel-mix pathway to **S48 (Transporte terrestre)** and **S51 (Armazenamento e correio)**. **S52 (Alojamento)** is excluded from the transport block and remains in the cities/buildings block.

- Maximum overlap among the broad normalized Engine-2 blocks: **0 sector(s)**.

## 100D 2050 verification

- S48 total modeled energy coefficient: 0.20009 in the base matrix and 0.20009 after Engine 2.
- S51 total modeled energy coefficient: 0.02567 in the base matrix and 0.02567 after Engine 2.
- S52 total modeled energy coefficient: 0.05957 in the base matrix and 0.05957 after the cities/buildings calibration.

Because the normalized rebalance closure preserves each column's total modeled energy coefficient, the diagnostic should mainly show a redistribution among electricity, bioenergy and fossil suppliers for S48, S51 and S52.

## Interpretation for the next audit

The coding error S52↔S51 is resolved for the paper workflow. The remaining question is substantive rather than syntactic: whether **S51 (storage and postal services)** should inherit the same aggregate road-transport physical fuel shares as S48. Since S51 combines warehousing and postal activities, this should be treated as a proxy assumption and tested against its baseline energy structure before publication.

The largest broader Engine-2 aggregation assumption is `other_industry`: many heterogeneous manufacturing sectors inherit one common MMA 'other industry' energy-mix trajectory. This is not necessarily wrong given the available scenario data, but it should be documented and, if material, tested as a sensitivity.

## Files

- `engine2_sector_mapping.csv`
- `engine2_block_overlaps.csv`
- `engine2_S48_S51_S52_check.csv`
