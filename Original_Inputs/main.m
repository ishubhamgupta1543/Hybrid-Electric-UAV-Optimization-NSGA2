%% MAIN SCRIPT
% This is the main file used to run the complete UAV mission simulation.
% First, the battery size is calculated.
% Then the maximum cruise time is found.
% Finally, the complete mission is simulated and the results are displayed.

clear;
clc;

% Load all aircraft and mission parameters
A = assumptions();

%% Step 1 - Find battery energy required before cruise

% Use a very large battery so that it never runs out during this test.
% Cruise duration is kept zero because only the non-cruise phases are needed.
probeBattCapacity_Wh = 1e6;
probe = mission_sim(A, probeBattCapacity_Wh, 0);

% Find where the battery is supplying power
dischargeMask = probe.Pbatt > 0;

if any(dischargeMask)

    % Time difference between every simulation step
    dt_series = diff([0 probe.time]);

    % Total battery energy used (Wh)
    dischargeEnergy_Wh = sum(probe.Pbatt(dischargeMask) .* dt_series(dischargeMask)) ...
                         / 3600 / A.battEfficiency;

else

    dischargeEnergy_Wh = 0;

end

% Fuel used during takeoff, climb, loiter and descent
nonCruiseFuel_kg = probe.totalFuel;

fprintf('Battery discharge during probe = %.1f Wh\n', dischargeEnergy_Wh);
fprintf('Non-cruise fuel = %.2f kg\n', nonCruiseFuel_kg);

%% Step 2 - Calculate required battery size

% Battery cannot be discharged below the reserve SoC.
% Therefore only this fraction of the battery can actually be used.
usableSoCFraction = A.SoC_initial - A.SoC_reserve;

% Calculate battery mass
battMass_kg = A.battSizingMargin * dischargeEnergy_Wh ...
             / (A.battSpecificEnergy * usableSoCFraction);
fprintf('Calculated battery mass = %.2f kg\n', battMass_kg);

% Battery capacity
battCapacity_Wh = battMass_kg * A.battSpecificEnergy;

%% Check if battery can provide enough power

peakBattPower_kW = max(probe.Pbatt) / 1000;

maxBattPowerCapability_kW = battMass_kg * A.battPowerDensity;

if peakBattPower_kW > maxBattPowerCapability_kW

    warning(['Battery cannot provide enough power. ' ...
             'Required = %.1f kW, Available = %.1f kW'], ...
             peakBattPower_kW, maxBattPowerCapability_kW);

end

%% Step 3 - Calculate maximum cruise duration

% Remaining aircraft mass can be used as fuel
availableForFuel_kg = A.MTOW - A.OEW - A.payload - battMass_kg;

% Fuel available only for cruise
cruiseFuelBudget_kg = availableForFuel_kg - nonCruiseFuel_kg;

if cruiseFuelBudget_kg <= 0

    error('No fuel is left for cruise.');

end

% Fuel consumption rate during cruise
cruiseFuelRate_kgps = engine_model(A, A.P_rated);

% Maximum cruise time
cruiseDuration_s = cruiseFuelBudget_kg / cruiseFuelRate_kgps;

%% Step 4 - Run complete mission

result = mission_sim(A, battCapacity_Wh, cruiseDuration_s);

%% Display final results

fprintf('\n========== FINAL DESIGN SUMMARY ==========\n');

fprintf('Engine: %s\n', A.engineName);

fprintf('Rated Power: %.0f kW\n', A.P_rated/1000);

fprintf('Cruise Altitude: %.0f m\n', A.cruiseAltitude);

fprintf('Battery Mass: %.1f kg\n', battMass_kg);

fprintf('Battery Capacity: %.1f Wh\n', battCapacity_Wh);

fprintf('Fuel Used: %.1f kg\n', result.totalFuel);

fprintf('\nMass Check\n');

fprintf('OEW      : %.1f kg\n', A.OEW);

fprintf('Payload  : %.1f kg\n', A.payload);

fprintf('Battery  : %.1f kg\n', battMass_kg);

fprintf('Fuel     : %.1f kg\n', result.totalFuel);

fprintf('Total    : %.1f kg\n', ...
        A.OEW + A.payload + battMass_kg + result.totalFuel);

fprintf('\nMission Time\n');

fprintf('Takeoff : %.1f min\n', A.takeoffDuration/60);

fprintf('Climb   : %.1f min\n', A.cruiseAltitude/A.climbRate/60);

fprintf('Cruise  : %.1f min\n', cruiseDuration_s/60);

fprintf('Loiter  : %.1f min\n', A.loiterDuration/60);

fprintf('Descent : %.1f min\n', A.descentDuration/60);

fprintf('\nTotal Endurance : %.2f hours\n', result.totalTime/3600);

fprintf('Final Battery SoC : %.1f%%\n', result.finalSoC*100);

fprintf('Mission Feasible : %d\n', result.feasible);

if ~isempty(result.failReason)
    fprintf('%s\n', result.failReason);
end

fprintf('============================================\n\n');

%% Show plots

dashboard(result, A, battMass_kg, cruiseDuration_s);