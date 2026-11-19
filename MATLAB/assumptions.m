function A = assumptions()
% All fixed values used by the UAV model.
% The 65 kW at 9 km and SFC are STUDY assumptions, not a verified TP100 map.

%% Aircraft and aerodynamics
A.MTOW = 1000;              % kg
A.payload = 200;            % kg
A.g = 9.81;                 % m/s^2
A.AR = 25;
A.e = 0.75;
A.CD0 = 0.030;
A.wingLoading = 62.5;      % kg/m^2
A.S = A.MTOW/A.wingLoading;
A.b = sqrt(A.AR*A.S);
A.K = 1/(pi*A.e*A.AR);
A.CLmax = 1.28;
A.etaP = 0.80;

%% Engine model: assumed 65 kW continuous at 9 km
A.engineName = 'PBS TP100 - assumed 65 kW at 9 km';
A.P_rated = 65e3;           % W, assumed available shaft power
A.engineDryMass = 61.6;    % kg, already covered by reference OEW
A.SFC_rated = 0.62/3.6e6;  % kg/J; assumed at the 65-kW study point
A.SFC_partload = @(x) A.SFC_rated.*(1+0.3.*(1-min(max(x,0.05),1)));

%% Battery and electrical system
A.battSpecificEnergy = 260;    % Wh/kg; fixed technology for optimization
A.battPowerDensity = 0.50;     % kW/kg, assume same limit for charge/discharge
A.battEfficiency = 0.92;       % discharge path efficiency
A.chargerEfficiency = 0.90;    % charging efficiency after DC bus
A.motorEfficiency = 0.92;      % DC-to-shaft conversion on electric assist
A.generatorEfficiency = 0.95;  % shaft-to-DC conversion on charge
A.generatorMaxPower = 12e3;   % W DC; ASSUMED auxiliary generator, needs validation
A.SoC_initial = 1.00;
A.SoC_reserve = 0.15;
A.finalSoC_min = 0.20;        % experimental terminal target (20%); hard floor remains 15%

%% Installed motor design and OEW bookkeeping
A.DoH = 0.38;                   % example design; optimizer will change it
A.DoH_reference = 0.38;         % motor included in reference OEW below
A.motorPowerDensity = 5.0;     % kW/kg, illustrative electrical-machine value
A.OEW_fraction = 0.55;
A.OEW = A.MTOW*A.OEW_fraction;  % 550 kg INCLUDES the reference motor and generator

%% Default charging controller
A.chargeStartSoC = 0.65;       % target SoC at which cruise charging stops
A.maxChargePower = 8e3;       % W on DC bus
A.loiterAssistFraction = 0.45; % share of loiter shaft power requested from motor
% Loiter electric assist stops at finalSoC_min (not at the 15% hard floor).

%% Mission: fixed, not GA variables
A.takeoffDuration = 60;       % s
A.takeoffSpeed = 55;          % m/s
A.climbRate = 2.5;            % m/s
A.climbSpeed = 55;            % m/s
A.cruiseAltitude = 9000;      % m
A.cruiseSpeed = 69.4;         % m/s, approx 250 km/h
A.loiterAltitude = 3000;      % m
A.loiterSpeed = 40.6;         % m/s
A.loiterDuration = 7200;      % s, fixed 2-hour station time
A.descentSpeed = 50;          % m/s
A.descentDuration = 1200;     % s, descent 3000 m -> ground
A.transitionDescentRate = 2.5; % m/s, descent from cruise to loiter altitude
A.descentPowerFrac = 0.15;   % minimum glide-assist shaft power fraction
A.missionCruise_min_s = 7200; % minimum cruise time for fuel comparison
A.dt = 10;                   % s

% Applied by configure_design before every simulation.
A.motorMaxPower = A.DoH/(1-A.DoH)*A.P_rated;
A.OEW_effective = A.OEW;
end
