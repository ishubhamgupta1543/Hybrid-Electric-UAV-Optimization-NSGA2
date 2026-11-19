# Optimization design and result interpretation

## Problem definition

`MATLAB/optimizer.m` calls `gamultiobj` with `nvars=5`, `PopulationSize=40`, `MaxGenerations=35`, `ParetoFraction=0.6`, and random seed `rng(42,'twister')` for repeatability under the same software environment. The underlying solver is MATLAB's **controlled elitist multi-objective genetic algorithm**, commonly associated with NSGA-II. A Pareto front is a set of trade-offs, **not one global optimum**.

### Design variables

The vector passed to `configure_design.m` is

```matlab
% x = [DoH, battery_mass_kg, charge_target_SoC, charge_power_kW, loiter_assist]
lb = [0.30, 60, 0.20, 2, 0.00];
ub = [0.55,120, 0.85,10, 0.85];
```

The code translates charging power from kW to W and computes installed motor rating from DoH. It adjusts reference OEW only for the difference in assumed motor mass from the reference DoH.

### Three minimized objectives

```matlab
f = [-D.endurance_hr, D.referenceFuel_kg, D.batteryMass_kg];
```

- `-endurance_hr`: negative sign turns *maximize endurance* into minimization.
- `referenceFuel_kg`: the fuel consumed during a **fixed two-hour-cruise mission**, which has the same fixed loiter and other mission conditions for every design.
- `batteryMass_kg`: actual battery-pack mass, not electric-motor mass.

### Constraints and solver behavior

`evaluate_design.m` rejects candidates with invalid parameters, impossible propulsion power balance, reserve violations, stall coefficient violations, or fuel mass above the MTOW budget. An infeasible candidate receives a large objective penalty inside `design_objectives`. The valid Pareto results are **re-simulated and filtered** after the GA returns.

`evaluate_design.m` solves maximum cruise duration using bracketing and bisection. Fuel use depends on the battery charge state at the beginning of loiter, so this full-mission loop is necessary; a fixed cruise fuel rate is not sufficient to size all operating cases consistently.

### Selecting a representative solution

The optimization stores many non-dominated designs. `optimizer.m` normalizes each objective by its observed Pareto range and selects the point with the smallest sum of squared normalized objective values. This is a **demonstration trade-off selection**, not a proof that a chosen design is best under all engineering priorities.

### Outputs

- `NSGA2_Pareto_Results.csv`: candidate variables plus max endurance, reference fuel, battery mass.
- `NSGA2_Results.mat`: original assumptions, Pareto decision/objective matrices, selected index and selected design.
- Two Pareto figures: endurance vs fixed-mission fuel; battery mass vs endurance.
- Existing mission dashboard and power/energy diagnostics for the chosen representative solution.

### Reporting best practices

Report at least a table containing the reference design and a few Pareto designs (e.g. highest endurance, lowest fixed-mission fuel, lowest battery mass, and balanced choice). Include the same fixed mission when discussing fuel improvements; include variable cruise time separately when discussing maximum endurance. Quote actual MATLAB outputs, not assumed/sample values.

Record the exact seed, MATLAB release, Global Optimization Toolbox version, decision bounds, population, generations, failed/rejected design count, and any deviations from the reference assumptions.

### Scope caution

The genetic algorithm explores this model's selected five-variable design space. It does **not** optimize aircraft geometry, verified engine altitude performance, validated control trajectories, chemical battery selection, or detailed thermal/electrical component sizing. Optimize and validate those separately if needed.
