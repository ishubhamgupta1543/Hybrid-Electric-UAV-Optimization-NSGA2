%% MAIN - fixed reference design, for checking the simulator before NSGA-II
clear; clc;
A0 = assumptions();
% Values: DoH, battery kg, charge target SoC, charge kW, loiter assist fraction.
x = [0.38,75,0.65,8,0.45];
D = evaluate_design(A0,x);
if ~D.feasible
    fprintf('Reference design is NOT feasible: %s\n',D.reason);
    error('Change the example design or check the physics before optimizing.');
end

fprintf('\n========== BASELINE DESIGN ==========\n');
fprintf('Engine rating (assumed at 9 km): %.0f kW\n',D.A.P_rated/1000);
fprintf('Installed motor rating: %.1f kW shaft\n',D.A.motorMaxPower/1000);
fprintf('Installed-power DoH: %.3f\n',D.A.DoH);
fprintf('Battery: %.1f kg, %.1f kWh\n',D.A.battMass_kg, ...
    D.A.battMass_kg*D.A.battSpecificEnergy/1000);
fprintf('Effective OEW: %.2f kg (reference motor is already included)\n',D.A.OEW_effective);
fprintf('Fuel for fixed 2h-cruise mission: %.2f kg\n',D.referenceFuel_kg);
fprintf('Fuel for maximum-duration mission: %.2f kg\n',D.maxMission.totalFuel);
fprintf('Maximum cruise duration: %.1f min\n',D.cruiseDuration_s/60);
fprintf('Maximum total endurance: %.2f h\n',D.endurance_hr);
fprintf('Final SoC: %.1f%% (minimum required %.0f%%)\n', ...
    100*D.maxMission.finalSoC,100*D.A.finalSoC_min);
fprintf('Loiter electric assist target: %.0f%% of required shaft power\n', ...
    D.A.loiterAssistFraction*100);
fprintf('MTOW sum: %.2f kg / %.0f kg\n',D.massTotal_kg,D.A.MTOW);
fprintf('Feasible: %d\n',D.feasible);
fprintf('=====================================\n');

dashboard(D.maxMission,D.A,D.A.battMass_kg,D.cruiseDuration_s);
