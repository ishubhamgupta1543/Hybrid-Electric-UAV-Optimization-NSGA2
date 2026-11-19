function dashboard(result,A,battMass_kg,cruiseDuration_s)
% Original six-panel dashboard retained; extra engineering plots follow.
t_min = result.time/60;
P_sum = result.Pturb+result.Pmotor;
operatingDoH = zeros(size(P_sum));
mask = P_sum>0;
operatingDoH(mask) = result.Pmotor(mask)./P_sum(mask);

figure('Name','UAV Hybrid Propulsion Dashboard','Color','w', ...
    'Position',[50 50 1150 800]);
subplot(3,2,1)
plot(t_min,result.alt,'b-','LineWidth',1.5)
xlabel('Time (min)'); ylabel('Altitude (m)');
title('Mission Altitude'); grid on

subplot(3,2,2)
plot(t_min,result.Pturb/1000,'r-','LineWidth',1.5); hold on
plot(t_min,result.Pbatt/1000,'b-','LineWidth',1.5)
yline(A.P_rated/1000,'k--','Engine Rating')
xlabel('Time (min)'); ylabel('Power (kW)')
legend('Turbine shaft','Battery DC (+/-)','Location','best')
title('Power Distribution'); grid on

subplot(3,2,3)
plot(t_min,result.SoC*100,'g-','LineWidth',1.5); hold on
yline(A.SoC_reserve*100,'r--','Reserve')
yline(A.finalSoC_min*100,'k:','Minimum landing SoC')
xlabel('Time (min)'); ylabel('SoC (%)')
title('Battery State of Charge'); ylim([0 105]); grid on

subplot(3,2,4)
plot(t_min,result.fuel,'m-','LineWidth',1.5)
xlabel('Time (min)'); ylabel('Fuel used (kg)')
title('Cumulative Fuel Consumption'); grid on

subplot(3,2,5)
massVals = [A.OEW_effective A.payload battMass_kg result.totalFuel];
labels = {sprintf('OEW %.1f kg',A.OEW_effective), ...
    sprintf('Payload %.0f kg',A.payload), ...
    sprintf('Battery %.1f kg',battMass_kg), ...
    sprintf('Fuel %.1f kg',result.totalFuel)};
pie(massVals,labels)
title(sprintf('MTOW Breakdown (%.1f kg)',sum(massVals)))

subplot(3,2,6); axis off
notes = { ...
    sprintf('ENDURANCE: %.2f hours',result.totalTime/3600), ...
    sprintf('Cruise: %.1f min',cruiseDuration_s/60), ...
    sprintf('Battery mass: %.1f kg',battMass_kg), ...
    sprintf('Fuel mass: %.1f kg',result.totalFuel), ...
    sprintf('Engine: %.0f kW (assumed)',A.P_rated/1000), ...
    sprintf('Design DoH: %.3f',A.DoH), ...
    sprintf('Max operating DoH: %.3f',max(operatingDoH)), ...
    sprintf('Motor rating: %.1f kW',A.motorMaxPower/1000), ...
    sprintf('Loiter assist setting: %.0f%%',100*A.loiterAssistFraction), ...
    sprintf('Final SoC: %.1f%%',result.finalSoC*100), ...
    sprintf('Mission feasible: %d',result.feasible)};
text(0.02,0.95,notes,'VerticalAlignment','top', ...
    'FontSize',10,'FontName','FixedWidth')
title('Design Summary')
sgtitle('Hybrid-Electric UAV Propulsion - Mission Dashboard')

% Additional figures: quantities reported in papers and sizing studies.
figure('Name','Electric and Turbine Operation','Color','w');
subplot(2,2,1)
plot(t_min,result.Pturb/A.P_rated*100,'LineWidth',1.5)
xlabel('Time (min)'); ylabel('Engine load (%)'); grid on
subplot(2,2,2)
plot(t_min,result.Pmotor/1000,'LineWidth',1.5)
xlabel('Time (min)'); ylabel('Motor shaft assist (kW)'); grid on
subplot(2,2,3)
plot(t_min,operatingDoH,'LineWidth',1.5)
xlabel('Time (min)'); ylabel('Operating DoH'); grid on
subplot(2,2,4)
plot(t_min,max(-result.Pbatt,0)/1000,'LineWidth',1.5)
xlabel('Time (min)'); ylabel('DC charging power (kW)'); grid on
sgtitle('Power Management Diagnostics')

figure('Name','Battery Energy and C-rate','Color','w');
capacity_kWh = battMass_kg*A.battSpecificEnergy/1000;
energyStored_kWh = result.SoC*capacity_kWh;
subplot(2,1,1)
plot(t_min,energyStored_kWh,'LineWidth',1.5)
xlabel('Time (min)'); ylabel('Stored battery energy (kWh)'); grid on
subplot(2,1,2)
C_rate = result.Pbatt/1000/capacity_kWh;
plot(t_min,C_rate,'LineWidth',1.5)
xlabel('Time (min)'); ylabel('Battery C-rate (+ discharge)'); grid on
end
