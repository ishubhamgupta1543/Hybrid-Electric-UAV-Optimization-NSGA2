# Validation checklist — revised loiter-assist NSGA-II

## Before simulation

- [ ] Set MATLAB Current Folder to `HAL_Hybrid_UAV_NSGA2/MATLAB`.
- [ ] Run `test_project` and save Command Window output.
- [ ] Run `main` and check it finishes (this is the 5-variable reference design).
- [ ] Run `compare_pms` to compare reference fuel and endurance with vs. without loiter assist.
- [ ] Inspect the original six-panel dashboard and the extra two diagnostic figures.
- [ ] Check that the battery discharges during climb, recharges during cruise when commanded, and *may* discharge during loiter down toward the 20% experimental terminal requirement.
- [ ] Verify pack SoC never falls below the absolute 15% reserve.
- [ ] Verify the result ends >=20% SoC, and that the 20% limit is explicitly labelled a study assumption.
- [ ] Verify 1000-kg MTOW upper bound, battery specific power, motor rating and shaft power balance.
- [ ] Verify uninterrupted altitude transitions from cruise to loiter to touchdown.

## NSGA-II

- [ ] Confirm MATLAB Global Optimization Toolbox is installed (`which gamultiobj`).
- [ ] Run `optimizer`.
- [ ] Confirm Pareto CSV includes the fifth column `LoiterAssist`.
- [ ] Confirm reported solutions are feasible after re-simulation.
- [ ] Use fixed 2-hour-cruise reference fuel for across-design fuel comparisons.
- [ ] Use separate MTOW-limited maximum-duration mission for maximum endurance comparisons.
- [ ] Inspect the selected Pareto design's final SoC; **more than 20% is not by itself a failure**.
- [ ] Save MATLAB version, random seed, optimization settings and resulting plots.

## Engineering caveats for the report

- [ ] The **65 kW at 9 km** turbine shaft rating is a sensitivity scenario, not established PBS TP100 altitude performance.
- [ ] Validate part-load SFC with independent data or uncertainty bounds.
- [ ] Justify generator DC rating, efficiency and integration mass.
- [ ] Clarify that reference OEW includes engine, motor and generator but not propulsion battery or fuel; incremental motor mass is adjusted when DoH changes.
- [ ] Justify or sensitivity-test battery specific energy, battery power density, charger and motor efficiency.
- [ ] Explain fixed-weight aerodynamics and approximated descent/loiter controls.
- [ ] Explain the 15% hard reserve and 20% *user-selected experiment* landing requirement; these are not interchangeable.
- [ ] Do not claim 20% is an optimal final SoC before examining Pareto trade-offs.

## Validation carried out during packaging

The 5-variable model and its 6-phase energy accounting were independently mirrored in Python and the baseline example was checked for sign conventions, turbine/motor limits, battery-charge/loiter-discharge SoC direction and mass feasibility. MATLAB itself was not executed in the authoring environment; the commands above remain mandatory before treating results as verified.
