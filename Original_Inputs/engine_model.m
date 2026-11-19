function fuelFlow = engine_model(A, P_turb)

% This function calculates the fuel flow rate of the engine
% based on the power produced by the turbine.
%
% Input:
% P_turb = Turbine power (W)
%
% Output:
% fuelFlow = Fuel flow rate (kg/s)

% If the engine is not producing power,
% no fuel is consumed.
if P_turb <= 0

    fuelFlow = 0;
    return;

end

% Calculate power as a fraction of rated power
x = P_turb / A.P_rated;

% Get the specific fuel consumption
SFC = A.SFC_partload(x);

% Calculate fuel flow rate
fuelFlow = SFC * P_turb;

end