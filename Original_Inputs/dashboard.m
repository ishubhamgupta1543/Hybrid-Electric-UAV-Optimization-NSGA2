function dashboard(result, A, battMass_kg, cruiseDuration_s)

% This function displays all the important mission results
% using different plots and a summary.

% Convert time from seconds to minutes
t_min = result.time / 60;

% Create dashboard window
figure('Name','UAV Hybrid-Electric Propulsion Dashboard', ...
       'Color','w', ...
       'Position',[50 50 1100 800]);

%% 1. Mission altitude profile

subplot(3,2,1)

plot(t_min, result.alt,'b-','LineWidth',1.5)

xlabel('Time (min)')
ylabel('Altitude (m)')

title('Mission Profile - Altitude')

grid on

%% 2. Turbine and battery power

subplot(3,2,2)

plot(t_min,result.Pturb/1000,'r-','LineWidth',1.5)
hold on

plot(t_min,result.Pbatt/1000,'b-','LineWidth',1.5)

yline(A.P_rated/1000,'k--','Rated Power')

xlabel('Time (min)')
ylabel('Power (kW)')

legend('Turbine','Battery (+discharge/-charge)','Location','best')

title('Power Distribution')

grid on

%% 3. Battery State of Charge

subplot(3,2,3)

plot(t_min,result.SoC*100,'g-','LineWidth',1.5)
hold on

yline(A.SoC_reserve*100,'r--','Reserve Floor')

xlabel('Time (min)')
ylabel('SoC (%)')

title('Battery State of Charge')

ylim([0 105])

grid on

%% 4. Fuel consumption

subplot(3,2,4)

plot(t_min,result.fuel,'m-','LineWidth',1.5)

xlabel('Time (min)')
ylabel('Cumulative Fuel (kg)')

title('Fuel Consumption')

grid on

%% 5. Aircraft mass breakdown

subplot(3,2,5)

massVals = [A.OEW, A.payload, battMass_kg, result.totalFuel];

labels = { ...
    sprintf('OEW\n%.0f kg',A.OEW), ...
    sprintf('Payload\n%.0f kg',A.payload), ...
    sprintf('Battery\n%.1f kg',battMass_kg), ...
    sprintf('Fuel\n%.1f kg',result.totalFuel)};

pie(massVals,labels)

title(sprintf('MTOW Breakdown (Total: %.0f kg)',sum(massVals)))

%% 6. Mission summary

subplot(3,2,6)

axis off

summaryStr = { ...
    sprintf('ENDURANCE: %.2f hours',result.totalTime/3600), ...
    sprintf('Cruise duration: %.1f min',cruiseDuration_s/60), ...
    sprintf('Battery mass: %.1f kg (%.0f Wh/kg)',battMass_kg,A.battSpecificEnergy), ...
    sprintf('Fuel mass: %.1f kg',result.totalFuel), ...
    sprintf('Engine: %s',A.engineName), ...
    sprintf('Design power: %.0f kW @ %.0f m',A.P_rated/1000,A.cruiseAltitude), ...
    sprintf('Climb rate: %.1f m/s',A.climbRate), ...
    sprintf('AR = %.0f, S = %.1f m^2, b = %.1f m',A.AR,A.S,A.b), ...
    sprintf('Feasible: %d',result.feasible) ...
    };

text(0.05,0.95,summaryStr,...
    'VerticalAlignment','top',...
    'FontSize',10,...
    'FontName','FixedWidth')

title('Design Summary')

% Overall dashboard title
sgtitle('Hybrid-Electric UAV Propulsion - Mission Dashboard')

end