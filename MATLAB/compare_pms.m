function compare_pms()
% Compare old turbine-only loiter with the revised electric-assisted loiter.
% Both designs have the same engine, DoH, battery, charge target and mission.
% Only the loiter assist fraction is different.
A0 = assumptions();

x_old = [0.38,75,0.65,8,0.00];
x_new = [0.38,75,0.65,8,0.45];

oldDesign = evaluate_design(A0,x_old);
newDesign = evaluate_design(A0,x_new);

if ~oldDesign.feasible || ~newDesign.feasible
    error('One PMS comparison design is infeasible. Check assumptions.');
end

T = table({'Turbine only';'Electric loiter assist'}, ...
    [oldDesign.endurance_hr;newDesign.endurance_hr], ...
    [oldDesign.referenceFuel_kg;newDesign.referenceFuel_kg], ...
    [oldDesign.maxMission.finalSoC;newDesign.maxMission.finalSoC]*100, ...
    'VariableNames',{'Strategy','MaximumEndurance_hr','FixedMissionFuel_kg','LandingSoC_percent'});

disp('PMS comparison (same hardware, different loiter assist)');
disp(T);

figure('Name','PMS Strategy Comparison','Color','w');
subplot(1,2,1)
bar([oldDesign.referenceFuel_kg,newDesign.referenceFuel_kg]);
set(gca,'XTickLabel',{'Turbine only','Electric assist'});
ylabel('Fuel for fixed mission (kg)'); title('Fuel comparison'); grid on
subplot(1,2,2)
bar([oldDesign.endurance_hr,newDesign.endurance_hr]);
set(gca,'XTickLabel',{'Turbine only','Electric assist'});
ylabel('Maximum endurance (h)'); title('Endurance comparison'); grid on
end
