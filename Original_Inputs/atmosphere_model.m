function [rho, T, P] = atmosphere_model(h)

% This function calculates air density, temperature and pressure
% using the standard atmosphere model.
%
% Input:
% h = altitude (m)
%
% Output:
% rho = air density (kg/m^3)
% T   = temperature (K)
% P   = pressure (Pa)

% Standard sea level values
T0 = 288.15;      % Temperature (K)
P0 = 101325;      % Pressure (Pa)
L  = 0.0065;      % Temperature lapse rate (K/m)
R  = 287.05;      % Gas constant for air (J/kg.K)
g0 = 9.80665;     % Gravity (m/s^2)

% Troposphere (0 - 11 km)
if h <= 11000

    T = T0 - L*h;

    P = P0 * (T/T0)^(g0/(R*L));

else

    % Lower stratosphere (11 - 20 km)

    T11 = T0 - L*11000;

    P11 = P0 * (T11/T0)^(g0/(R*L));

    T = T11;

    P = P11 * exp(-g0*(h-11000)/(R*T11));

end

% Calculate air density
rho = P / (R*T);

end