function [SoC_new, P_batt_actual] = battery_model(A, SoC, P_batt_cmd, dt, battCapacity_Wh)

% This function updates the battery state of charge (SoC)
% for one simulation time step.
%
% Inputs:
% SoC             - Current battery state of charge
% P_batt_cmd      - Battery power (W)
%                   (+ve = discharging, -ve = charging)
% dt              - Time step (s)
% battCapacity_Wh - Battery capacity (Wh)

% Battery is supplying power
if P_batt_cmd >= 0

    % Energy taken from the battery
    dE_Wh = (P_batt_cmd * dt / 3600) / A.battEfficiency;

else

    % Energy stored in the battery while charging
    dE_Wh = (P_batt_cmd * dt / 3600) * A.chargerEfficiency;

end

% Update battery state of charge
SoC_new = SoC - dE_Wh / battCapacity_Wh;

% Keep SoC between 0 and 1
SoC_new = min(max(SoC_new, 0), 1);

% Actual battery power remains the same
P_batt_actual = P_batt_cmd;

end