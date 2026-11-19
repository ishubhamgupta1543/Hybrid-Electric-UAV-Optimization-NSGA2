function [rho,T,P] = atmosphere_model(h)
% ISA atmosphere up to 20 km (valid for this project's altitudes).
T0 = 288.15;
P0 = 101325;
L = 0.0065;
R = 287.05;
g = 9.80665;
if h <= 11000
    T = T0-L*h;
    P = P0*(T/T0)^(g/(R*L));
else
    T11 = T0-L*11000;
    P11 = P0*(T11/T0)^(g/(R*L));
    T = T11;
    P = P11*exp(-g*(h-11000)/(R*T11));
end
rho = P/(R*T);
end
