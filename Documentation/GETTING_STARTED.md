# Setup and running the MATLAB model

## 1. Open the project

Download the repository as ZIP or clone it. In MATLAB's **Current Folder** browser, navigate to `HAL_Hybrid_UAV_NSGA2/MATLAB` (where `assumptions.m`, `main.m`, and `optimizer.m` are located). Do not use the `Original_Inputs` folder for the new model.

From another MATLAB folder, you can use:

```matlab
cd('path/to/HAL_Hybrid_UAV_NSGA2/MATLAB')
```

Replace `path/to/...` with the real path on your computer. Avoid adding multiple folders containing old/new versions of functions to the MATLAB path simultaneously.

## 2. Confirm toolboxes

```matlab
ver                         % lists MATLAB and installed toolboxes
which gamultiobj            % should show a path when toolbox is present
which assumptions           % should point to this repository's MATLAB folder
```

`main`, `test_project`, and `compare_pms` do not call the optimization toolbox. The `optimizer` command requires `gamultiobj` from Global Optimization Toolbox.

## 3. Run the checks and simulation

```matlab
test_project
main
compare_pms
```

First command runs assertions. The second evaluates the fixed example configuration `[0.38,75,0.65,8,0.45]`. The third compares loiter with and without electric assistance at the same design settings.

`main` will display a dashboard, power-management diagnostics and stored battery-energy/C-rate plots. Confirm flight phases, power sign conventions, battery 15% reserve, 20% terminal requirement and 1000-kg mass constraint.

## 4. Run NSGA-II

```matlab
optimizer
```

The multi-objective GA evaluates repeated full-mission simulations. It may be substantially slower than `main` because each design uses a reference mission plus a cruise-duration search. The optimizer produces Pareto plots and writes `NSGA2_Pareto_Results.csv` / `NSGA2_Results.mat` in the Current Folder.

For a quick *exploratory* run, reduce `'PopulationSize'` and `'MaxGenerations'` in `optimizer.m`; restore the study settings for final results and document any changes.

## 5. Where to edit parameters

| Goal | File | Variable |
|---|---|---|
| Change the **assumed** 65 kW engine point | `assumptions.m` | `A.P_rated` |
| Change mission altitude/speed/climb/loiter | `assumptions.m` | `A.cruiseAltitude`, `A.cruiseSpeed`, `A.climbRate`, etc. |
| Change experimental final SoC | `assumptions.m` | `A.finalSoC_min` |
| Change fixed reference design | `main.m` | `x = [...]` |
| Change optimizer decision bounds | `optimizer.m` | `lb`, `ub` |
| Change EMS policy | `power_split.m` | Charge/assist logic |
| Change mass accounting or benchmark | `evaluate_design.m` | Fuel-budget/benchmark logic |

If you change the engine power, the documented SFC reference and assumed altitude capability **do not automatically become validated**. Avoid changing `A.SFC_rated` without independent evidence.

## 6. Troubleshooting

**“Unrecognized function 'mission_profile'”** — set MATLAB Current Folder to the repository's `MATLAB` directory. Use `which mission_profile -all` to check if older copies shadow this version.

**“Undefined function 'gamultiobj'”** — check Global Optimization Toolbox installation and licensing. Base simulation/test commands can still run without it.

**`main` reports infeasible** — review the reason printed by `evaluate_design.m`, confirm the reference design vector and `assumptions.m` parameters, then run `test_project`.

**PMS charges but final SoC remains higher than 20%** — this is not necessarily a defect. A minimum is not an equality target, and motor/pack power or timing can limit further discharge. Analyze the actual energy and fuel trade-off.

**Reference fuel differs from full-endurance fuel** — the fixed comparison mission is a two-hour cruise, while the longest feasible mission has variable cruise time. These should differ and must not be compared as equivalent missions.

**MATLAB displays old results** — check `which main -all`, `which power_split -all`; close old figures and rerun. Do not run archived `Original_Inputs` code accidentally.

## 7. Reproducible results before publication

Save Command Window outputs from `test_project`, `main`, `compare_pms`, and `optimizer`, record the git commit ID and MATLAB/toolbox versions, and include final generated plots under your own repository's results folder if you choose to publish them.
