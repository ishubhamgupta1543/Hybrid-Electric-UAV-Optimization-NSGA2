function [SoC_new,energyChange_Wh] = battery_model(A,SoC,P_batt_DC,dt,battCapacity_Wh)
% Positive DC battery power = discharge; negative = charge.
% Discharge path and charging path are treated separately.
if P_batt_DC >= 0
    energyChange_Wh = (P_batt_DC*dt/3600)/A.battEfficiency;
else
    energyChange_Wh = (P_batt_DC*dt/3600)*A.chargerEfficiency;
end
SoC_new = SoC-energyChange_Wh/battCapacity_Wh;
SoC_new = min(max(SoC_new,0),1);
end
