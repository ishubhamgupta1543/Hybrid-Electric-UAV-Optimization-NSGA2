function optimizer()
% NSGA-II multiobjective optimization using MATLAB gamultiobj.
% Requires Global Optimization Toolbox.
% RUN: optimizer
if exist('gamultiobj','file') ~= 2
    error('MATLAB Global Optimization Toolbox is required (gamultiobj).');
end
clc;
A0 = assumptions();
rng(42,'twister');

% Variables: [installed-power DoH, battery kg, charge SoC, charge kW, loiter assist fraction].
lb = [0.30, 60, 0.20, 2, 0.00];
ub = [0.55,120, 0.85,10, 0.85];
nvars = 5;

% A smaller search for a first trial, increase when ready for final study.
options = optimoptions('gamultiobj', ...
    'PopulationSize',40, ...
    'MaxGenerations',35, ...
    'ParetoFraction',0.6, ...
    'Display','iter', ...
    'PlotFcn',@gaplotpareto);

% Three objectives (all minimized):
% 1) Negative max endurance (hours)
% 2) Fuel used for the SAME fixed 2h-cruise mission (kg)
% 3) Battery mass (kg)
objFun = @(x) design_objectives(A0,x);
[xPareto,fPareto] = gamultiobj(objFun,nvars,[],[],[],[], ...
    lb,ub,[],options);

% Re-check the reported Pareto solutions with the full mission evaluator.
keep = false(size(xPareto,1),1);
for i = 1:size(xPareto,1)
    D = evaluate_design(A0,xPareto(i,:));
    keep(i) = D.feasible;
end
xPareto = xPareto(keep,:);
fPareto = fPareto(keep,:);
if isempty(xPareto)
    error('No feasible Pareto designs were found. Check constraints and bounds.');
end

% Normalize the objective columns and find a balanced, representative point.
% This is not a unique optimum: other Pareto points may be preferred.
fmin = min(fPareto,[],1);
fmax = max(fPareto,[],1);
scaled = (fPareto-fmin)./max(fmax-fmin,1e-9);
[~,chosen] = min(sum(scaled.^2,2));
selected = evaluate_design(A0,xPareto(chosen,:));

% Store all candidates for plots, reports and future reproducibility.
T = array2table([xPareto,-fPareto(:,1),fPareto(:,2),fPareto(:,3)], ...
    'VariableNames',{'DoH','Battery_kg','ChargeSoC','Charge_kW','LoiterAssist', ...
    'MaxEndurance_hr','ReferenceFuel_kg','ObjectiveBattery_kg'});
writetable(T,'NSGA2_Pareto_Results.csv');
save('NSGA2_Results.mat','A0','xPareto','fPareto','chosen','selected');

fprintf('\n=========== SELECTED PARETO DESIGN ===========\n');
fprintf('DoH: %.3f\n',selected.A.DoH);
fprintf('Motor rating: %.2f kW (shaft)\n',selected.A.motorMaxPower/1000);
fprintf('Battery mass: %.2f kg\n',selected.batteryMass_kg);
fprintf('Charge target: %.1f %%\n',100*selected.A.chargeStartSoC);
fprintf('Maximum charging: %.2f kW DC\n',selected.A.maxChargePower/1000);
fprintf('Loiter assist fraction: %.2f\n',selected.A.loiterAssistFraction);
fprintf('Final battery SoC: %.1f%%\n',100*selected.maxMission.finalSoC);
fprintf('Max endurance: %.2f h\n',selected.endurance_hr);
fprintf('Reference-mission fuel: %.2f kg\n',selected.referenceFuel_kg);
fprintf('Max-duration fuel: %.2f kg\n',selected.maxMission.totalFuel);
fprintf('MTOW: %.2f kg\n',selected.massTotal_kg);
fprintf('Feasible: %d\n',selected.feasible);
fprintf('==============================================\n');

% Two clear views of the Pareto trade-offs.
figure('Name','NSGA-II Pareto Designs','Color','w');
scatter(-fPareto(:,1),fPareto(:,2),45,fPareto(:,3),'filled');
hold on;
plot(selected.endurance_hr,selected.referenceFuel_kg,'kp', ...
    'MarkerSize',15,'MarkerFaceColor','y');
xlabel('Maximum endurance (h)');
ylabel('Fuel for fixed 2h-cruise mission (kg)');
title('NSGA-II Trade-off: Endurance vs Benchmark Fuel');
cb = colorbar; ylabel(cb,'Battery mass (kg)'); grid on;

figure('Name','Battery vs Endurance Trade-off','Color','w');
scatter(fPareto(:,3),-fPareto(:,1),45,fPareto(:,2),'filled');
hold on
plot(selected.batteryMass_kg,selected.endurance_hr,'kp', ...
    'MarkerSize',15,'MarkerFaceColor','y');
xlabel('Battery mass (kg)'); ylabel('Maximum endurance (h)');
title('NSGA-II Trade-off: Battery Mass vs Endurance');
cb = colorbar; ylabel(cb,'Fixed-mission fuel (kg)'); grid on;

dashboard(selected.maxMission,selected.A,selected.batteryMass_kg, ...
    selected.cruiseDuration_s);
end

function f = design_objectives(A0,x)
% Infeasible solutions get large objective values, never a fake endurance.
try
    D = evaluate_design(A0,x);
    if D.feasible
        f = [-D.endurance_hr,D.referenceFuel_kg,D.batteryMass_kg];
    else
        f = [1e4,1e4,1e4];
    end
catch
    f = [1e4,1e4,1e4];
end
end
