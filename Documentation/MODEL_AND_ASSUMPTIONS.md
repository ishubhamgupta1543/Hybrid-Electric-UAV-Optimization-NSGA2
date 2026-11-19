# Model methodology and assumptions

This page documents the model **as implemented** in `MATLAB/`, not the capabilities of a validated aircraft. All SI units unless otherwise noted.

## 1. Aerodynamic power demand

`atmosphere_model.m` estimates ISA density `rho` from altitude. The `power_required.m` function uses

\[
q = \tfrac12\rho V^2,\qquad D_0=qSC_{D0},\qquad D_i=\frac{KW^2}{qS},\qquad K=\frac{1}{\pi e AR},
\]

\[
D=D_0+D_i, \quad C_L=\frac{W}{qS}, \quad P_{req}=\frac{DV}{\eta_P}+\frac{W\dot h}{\eta_P}.
\]

`W = MTOW*g` throughout the simulated flight, even though fuel burns down. This is a simplification, **not** variable-mass flight dynamics. `mission_sim.m` checks if `CL` exceeds `A.CLmax`.

## 2. Mission sequence

`mission_profile.m` implements six continuous phases: Takeoff → Climb → Cruise → Transit Descent (9 to 3 km) → Loiter (2 hours at 3 km) → Final Descent (3 km to ground). `mission_sim.m` integrates in steps controlled by `A.dt` and calculates altitude at each step midpoint. Descending segments use the larger of the aerodynamic model output or a minimum throttle fraction of rated power.

## 3. Installed degree of hybridization

This project defines a **sizing metric**, not an instantaneous energy fraction:

\[
DoH_{installed}=\frac{P_{motor,rated}}{P_{engine,rated}+P_{motor,rated}}, \qquad
P_{motor,rated}=\frac{DoH}{1-DoH}P_{engine,rated}.
\]

The 550 kg reference OEW already includes a baseline motor and generator. `configure_design.m` adjusts only the *difference* in calculated motor mass if DoH changes, using an assumed motor power density (`A.motorPowerDensity`). This approximation does not independently size wiring, converter, cooling, shaft coupling, or generator hardware.

## 4. Shaft/DC energy flows

- Turbine (`P_turb`) and motor (`P_motor`) are **shaft power**.
- Battery (`P_batt_DC`) is **DC bus power**: positive discharge, negative charge.
- Motor conversion: `P_DC = P_motor_shaft / motorEfficiency`.
- Generator conversion: DC charging output = generator shaft input × `generatorEfficiency`.
- `power_split.m` checks that `P_turb + P_motor_shaft - P_generator_shaft = P_req` within numerical tolerance.

Battery energy update for a step of length `dt` (seconds):

\[
\Delta E_{Wh}=\begin{cases}
P_{batt,DC}\,dt/(3600\eta_{discharge}), &P_{batt,DC}\geq0,\\
P_{batt,DC}\,dt\,\eta_{charge}/3600,&P_{batt,DC}<0,
\end{cases}
\]

\[
SoC_{next}=\operatorname{clip}\bigl(SoC-\Delta E_{Wh}/E_{pack,Wh},0,1\bigr).
\]

Battery electric power limits scale with battery mass: `packMax_W = batteryMass_kg * batteryPowerDensity * 1000`. The same pack-specific power is assumed in both charging and discharge directions; real packs may have different limits. Motor efficiency is in addition to battery discharge efficiency.

## 5. Energy management strategy

`power_split.m` uses **demand and phase-aware supervisory logic**, not a globally optimal continuous-time controller:

- **High shaft demand:** engine up to assumed 65 kW, motor makes up the shortfall; otherwise infeasible.
- **Cruise:** engine covers propulsion and may supply an auxiliary generator until the charge-target SoC is reached; generator, pack, SoC and engine headroom cap charging.
- **Loiter:** electric motor may assist, bounded by loiter assist request, installed motor shaft rating, battery power and energy above the 20% terminal threshold.
- **Transit/final descent:** turbine covers the prescribed demand; no electric charging is commanded in these phases.

Forcing the battery to land *exactly* at 20% is not an objective. Burning fuel to recharge battery energy that is never used may be wasteful, but leaving extra energy can also be optimal under the chosen constraints and cost functions.

## 6. Fuel and mass bookkeeping

The engine approximates fuel flow as `m_dot_fuel = SFC(P_turb/P_rated) * P_turb`. `A.SFC_partload` is an illustrative relation rather than a manufacturer map.

Fuel budget is:

\[
m_{fuel,budget}=MTOW-OEW_{effective}-m_{payload}-m_{battery}.
\]

`evaluate_design.m` first evaluates a **common benchmark mission** with a two-hour cruise and two-hour loiter, then searches for the longest feasible cruise using numerical duration bracketing and bisection. Loiter assist and cruise charging change fuel use through SoC; therefore fuel for non-cruise phases cannot in general be treated as constant across candidate cruise durations.

## 7. Assumptions requiring sensitivity analysis or validation

| Model assumption | Current treatment | Needed validation |
|---|---|---|
| PBS TP100 usable output at 9 km | 65 kW assumed | Altitude lapse/continuous rating data |
| Part-load SFC | Constant reference plus analytic penalty | Engine test/empirical map |
| Propeller efficiency | Constant 0.80 | Airspeed, altitude, and propeller operating-point map |
| Battery energy / power density | 260 Wh/kg; 0.50 kW/kg | Pack-level specifications and thermal/charge limits |
| Motor, generator, battery efficiencies | Constant | Operating-point maps and installation losses |
| OEW fraction | 0.55 of MTOW | Hardware-level mass breakdown |
| Generator rating | 12 kW DC | Hardware rating, cooling, electrical protection |
| Terminal SoC constraint | 20% experimental | Required reserve / diversion analysis |
| Descent model | Minimum throttle plus aerodynamic approximation | Flight path, regenerative limits, airspeed feasibility |

These are documented approximations. A feasible numerical output is **not** proof that the engine and aircraft can perform the mission in practice.
