function fuelFlow = engine_model(A,P_turb)
% Turbine shaft power W -> fuel mass flow kg/s.
% The part-load SFC law is an approximation, not a manufacturer engine map.
if P_turb <= 0
    fuelFlow = 0;
    return;
end
load = P_turb/A.P_rated;
SFC = A.SFC_partload(load);
fuelFlow = SFC*P_turb;
end
