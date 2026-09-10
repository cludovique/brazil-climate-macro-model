# From NDC pathways to production networks: Macroeconomic spillovers of Brazil’s net-zero transition

## Abstract

*To be drafted after the model audit and robustness exercises.*

## 1. Introduction

Nationally Determined Contributions (NDCs) are typically expressed as emissions targets and sectoral mitigation pathways, but their implementation requires concrete changes in investment, technology deployment, intermediate inputs, and production. These changes propagate through domestic supply chains and can therefore produce economy-wide effects that are not visible in emissions accounting alone. Understanding those effects is particularly relevant for emerging economies, where the balance between imported technologies and domestic production can strongly influence who captures the economic gains from decarbonization.

Brazil provides an analytically distinctive case. Its emissions profile differs from that of most major emitters because land-use change and agriculture account for a dominant share of national greenhouse-gas emissions, while electricity generation is already comparatively low-carbon. Achieving the country’s climate targets therefore involves not only further power-sector decarbonization, but also changes in land use, bioenergy, transport, industry, buildings, fuels, and associated infrastructure. The resulting transition is thus better understood as a restructuring of production networks than as a simple substitution between fossil and renewable energy.

Existing integrated assessment and energy-system models provide detailed information on technology and physical deployment pathways, but they generally do not directly represent the full set of domestic inter-industry linkages through which those pathways affect output, value added, and labor demand. Conversely, input-output models are well suited to tracing production-network effects, but transition studies often introduce stylized final-demand shocks rather than deriving those shocks from a detailed NDC implementation pathway. Bridging these two representations requires a translation layer that maps physical and technological changes into economically consistent sectoral shocks.

This paper develops such a framework for Brazil by soft-linking the mitigation pathways used to inform the country’s climate planning with the 73-sector energy-disaggregated input-output matrix developed by EPE/FIPE for 2018. The linkage operates through three transmission mechanisms. First, transition investment is reconstructed over time and allocated across domestic capital-goods, construction, infrastructure, and related sectors. Second, sectoral changes in energy use modify selected technical coefficients of the input-output matrix, allowing intermediate demand to shift between fossil fuels, bioenergy, and electricity. Third, physical production trajectories for selected energy and heavy-industry sectors are imposed directly and translated into equivalent demand shocks. Together, these mechanisms generate scenario-specific production networks through which the NDC pathway propagates across the economy.

We ask: **How do NDC-consistent technology, investment, and production pathways propagate through Brazil’s production network, and under what conditions do transition-related gains offset the contraction of fossil-fuel activities?** We evaluate the resulting changes in gross output, value added, sectoral activity, and labor requirements relative to a fixed-structure counterfactual in which final demand grows with GDP but no transition-specific investment, energy-input substitution, or physical calibration occurs.

Preliminary results indicate that the modeled transition produces positive aggregate production and value-added differentials by 2050, with gains concentrated in infrastructure, machinery and equipment, electricity, bioenergy, transmission, manufacturing, and upstream supplier networks, while fossil-related activities contract. The results also suggest that the magnitude of the domestic economic dividend depends on the degree to which transition expenditure is captured by Brazilian supply chains. Rather than treating NDC implementation solely as an emissions pathway, the analysis therefore highlights it as a reallocation of investment, intermediate inputs, and production across interconnected sectors.

## 2. Methods

### 2.1 Data and sectoral representation

The analysis combines two distinct representations of the Brazilian economy. The first is the set of sectoral mitigation pathways used in the Brazilian climate-planning process, derived from the MMA/BLUES framework. These pathways provide scenario-specific trajectories for energy demand, technology shares, physical production, land-use variables, and transition-related expenditures. The second is the MIP-EPE 2018 input-output framework, which represents 73 economic sectors and provides the inter-industry transaction matrix, final-demand components, gross output, value added, employment, remuneration, and energy-use satellite information.

Let \(Z\) denote the 73×73 intermediate-consumption matrix, \(x\) the vector of sectoral gross output, and \(f\) the vector of final demand. The matrix of technical coefficients is

\[
A = Z\,\mathrm{diag}(x)^{-1},
\]

and the standard open Leontief system is

\[
x = (I-A)^{-1} f = Lf,
\]

where \(L\) is the Leontief inverse.

The scenario implementation uses this open production model. Household consumption is therefore not endogenized in the transition simulations, and the reported network effects should be interpreted as direct and indirect supply-chain effects rather than induced effects.

### 2.2 Scenario design and counterfactual

The analysis compares the transition pathway with a fixed-structure counterfactual. In the counterfactual, final demand grows according to the exogenous GDP trajectory while the 2018 technical-coefficient matrix remains unchanged. No transition-specific investment, energy-input substitution, or physical-output calibration is introduced.

For an economic variable \(X\), the transition differential is defined as

\[
TP_t = X_{NDC,t} - X_{baseline,t}.
\]

This quantity is interpreted as the scenario difference associated with the modeled transition assumptions. It is not a causal estimate of climate policy.

### 2.3 Engine 1 — transition investment and final demand

The first transmission channel translates transition-related expenditure into sectoral final-demand shocks. The model distinguishes a GDP-driven component of final demand from an additional transition-investment component:

\[
\Delta f_{1,t}^{s}=\Delta f_{GDP,t}+\Delta f_{INV,t}^{s}.
\]

For each destination sector \(j\), transition investment is allocated as

\[
\Delta f_{INV,j,t}^{s}=INV_t^s w_{j,t}^{s}d_j,
\]

where \(INV_t^s\) is the annual transition-investment quantum, \(w_{j,t}^{s}\) is the allocation weight associated with the technology deployment observed in scenario \(s\), and \(d_j\) is the estimated domestic-content share.

The MMA investment data are reported as overlapping annualized-cost windows. The model reconstructs non-overlapping investment waves from those windows and distributes later-period expenditure according to the pace of physical technology deployment. Technology-specific deployment is then mapped into IO sectors using capital-cost assumptions and investment structures that represent construction, machinery, electrical equipment, metals, transmission, engineering services, vehicles, biofuel capacity, and related categories. Imported capital goods are excluded from the domestic demand shock through sector-specific domestic-content factors.

### 2.4 Engine 2 — intermediate energy substitution

The second channel modifies selected technical coefficients to represent changes in intermediate energy use. For scenario \(s\) and year \(t\), sector-specific MMA energy shares are converted into scaling factors for fossil energy, bioenergy, and electricity. These factors modify selected rows of the input-output matrix to construct a scenario-specific technical-coefficient matrix:

\[
A_t^s=A+\Delta A_t^s.
\]

The resulting Leontief inverse is

\[
L_t^s=(I-A_t^s)^{-1}.
\]

For sectors where the transition represents mainly a change in energy-supplier composition, the revised coefficients are normalized to preserve the aggregate energy-input intensity of the sector while changing its composition. Sector- and subsector-specific trajectories are used where available, including differentiated pathways for steel, cement, chemicals, other industry, transport, buildings, electricity generation, refining, biodiesel, and natural gas/biomethane.

### 2.5 Engine 3 — physical-production calibration

The third channel uses explicit physical trajectories to calibrate the output of selected sectors that cannot be adequately represented by uniform GDP scaling. For sector \(j\), the target production change is defined as

\[
\Delta x_{3,j,t}^{s}=x_{j,2018}\left(\frac{q_{j,t}^{s}}{q_{j,2020}}-1\right),
\]

where \(q_{j,t}^{s}\) is the corresponding physical quantity in the transition pathway.

The target output change is transformed into an equivalent final-demand shock:

\[
\Delta f_{3,t}^{s}=(I-A_t^s)\Delta x_{3,t}^{s}.
\]

GDP-driven scaling is switched off for the directly calibrated sectors to avoid double counting. The current implementation applies this procedure to selected fossil, electricity, biofuel, gas, transmission, steel, and cement-related sectors.

### 2.6 Total production, value added, and labor requirements

The total production change is obtained from

\[
\Delta x_t^{s}=L_t^s\left(\Delta f_{1,t}^{s}+\Delta f_{3,t}^{s}\right).
\]

Sector-specific value-added and labor coefficients from the 2018 satellite accounts are then applied to the resulting production vector. Let \(v_j\) denote value added per unit of output and \(e_j\) employment per unit of output. Then

\[
\Delta VA_t^s=\hat v\,\Delta x_t^s,
\]

and

\[
\Delta EMP_t^s=\hat e\,\Delta x_t^s.
\]

Because these coefficients are fixed at their 2018 values, the employment estimates represent labor requirements or job-equivalents under the observed base-year productivity structure. They should not be interpreted as forecasts of future employment.

### 2.7 Interpretation and limitations

The framework is a comparative-static production-network model conditioned on exogenous transition pathways. Technical coefficients are modified only where explicitly represented by the transition mechanisms; the remainder of the production structure is fixed. Prices, wages, interest rates, endogenous substitution, fiscal feedbacks, labor-market clearing, and general-equilibrium adjustments are not modeled. The results therefore identify the direction, composition, and order of magnitude of supply-chain effects under the stated assumptions rather than predicting the future Brazilian economy.

## 3. Results

*To be drafted after the model audit, mechanism decomposition, employment sensitivity, and final figure generation.*

### 3.1 Aggregate production-network effects

### 3.2 Decomposing the transition premium

### 3.3 Sectoral winners and losers

### 3.4 Labor requirements and distribution

## 4. Discussion

*To be drafted after Results are frozen.*

### 4.1 Why low-carbon expansion can offset fossil contraction

### 4.2 Domestic supply chains and industrial policy

### 4.3 Timing of the investment wave

### 4.4 Broader relevance for NDC implementation

### 4.5 Limitations

## 5. Conclusion

*To be drafted after the main results and discussion are complete.*

## Data and code availability

The model code, input data that can be publicly redistributed, documentation, and reproducible output files will be archived in the project repository and assigned a versioned release for the manuscript. Any source data subject to redistribution restrictions will be identified separately, together with instructions for obtaining them from the original provider.

## Acknowledgements

*To be completed.*

## Author contributions

*To be completed after the author list is finalized.*

## Competing interests

*To be completed.*

## Supplementary Information

A separate Supplementary Information document will contain the 73-sector concordance, technology-to-sector mappings, investment-allocation assumptions, domestic-content coefficients, detailed technical-coefficient transformations, physical calibration data, robustness tests, alternative scenario results, and full sectoral tables.
