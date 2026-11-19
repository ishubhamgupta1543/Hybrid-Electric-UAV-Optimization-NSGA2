function A = assumptions()

% This file contains all the aircraft, battery and mission parameters.
% If any value needs to be changed, edit it here.

%% Mission Data

A.MTOW = 1000;          % Maximum take-off weight (kg)
A.payload = 200;        % Payload weight (kg)
A.g = 9.81;             % Gravity (m/s^2)

%% Aircraft Geometry

A.AR = 25;              % Aspect ratio
A.e = 0.75;             % Oswald efficiency factor
A.CD0 = 0.03;           % Zero lift drag coefficient

A.wingLoading = 62.5;           % Wing loading (kg/m^2)
A.S = A.MTOW / A.wingLoading;   % Wing area (m^2)
A.b = sqrt(A.AR * A.S);         % Wing span (m)
A.K = 1 / (pi * A.e * A.AR);    % Induced drag factor

A.CLmax = 1.28;         % Maximum lift coefficient
A.etaP = 0.80;          % Propeller efficiency

%% Engine Data

A.engineName = 'PBS TP100 (derated)';

A.P_SL_continuous = 160e3;      % Sea level power (W)
A.P_rated = 60e3;               % Rated power used in simulation (W)

A.engineDryMass = 61.6;         % Engine mass (kg)

A.SFC_rated = 0.62 / 3.6e6;     % Rated specific fuel consumption

% Fuel consumption changes slightly at part load
A.SFC_partload = @(x) A.SFC_rated .* ...
                     (1 + 0.3 .* (1 - min(max(x,0.05),1)));

%% Battery Data

A.battSpecificEnergy = 260;     % Wh/kg

A.battPowerDensity = 0.5;       % kW/kg

A.DoD = 0.80;                   % Depth of discharge

A.battEfficiency = 0.92;        % Battery efficiency

A.SoC_initial = 1.00;           % Initial battery charge

A.SoC_reserve = 0.15;           % Minimum battery charge allowed

% Small safety margin while sizing the battery
A.battSizingMargin = 1.05;

%% Motor and Charger

A.motorEfficiency = 0.92;

A.chargerEfficiency = 0.90;

%% Power Management Strategy

% Degree of Hybridization (initial value)
A.DoH = 0.30;

% Battery charging starts below this SoC
A.chargeStartSoC = 0.65;

% Maximum battery charging power (W)
A.maxChargePower = 8000;

% Total propulsion power
A.totalPower = A.P_rated/(1-A.DoH);

% Maximum motor power
A.motorMaxPower = A.totalPower*A.DoH;

%% Aircraft Mass

A.OEW_fraction = 0.55;

A.OEW = A.OEW_fraction * A.MTOW;

%% Mission Parameters

A.climbRate = 2.5;              % m/s

A.climbSpeed = 55;              % m/s

A.cruiseAltitude = 9000;        % m

A.cruiseSpeed = 69.4;           % m/s

A.loiterAltitude = 3000;        % m

A.loiterSpeed = 40.6;           % m/s

A.loiterDuration = 7200;        % s

A.descentAltitude = 4500;       % m

A.descentSpeed = 50;            % m/s

A.descentDuration = 1200;       % s

A.descentPowerFrac = 0.15;

A.takeoffDuration = 60;         % s

A.takeoffSpeed = 55;            % m/s

%% Battery Options

A.battTiers_WhKg = [90, 200, 260, 800];

end