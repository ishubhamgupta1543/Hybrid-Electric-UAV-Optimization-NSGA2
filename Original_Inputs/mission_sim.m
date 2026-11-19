function result = mission_sim(A, battCapacity_Wh, cruiseDuration_s)

% This function simulates the complete UAV mission.
% It calculates battery SoC, fuel consumption and power
% during every mission phase.

% Get all mission phases
phases = mission_profile(A, cruiseDuration_s);

% Assume aircraft weight remains constant
W = A.MTOW * A.g;

% Time step for simulation
dt = 10;

% Initial conditions
SoC = A.SoC_initial;
t = 0;
totalFuel = 0;

% Arrays to store simulation results
time_tr = [];
SoC_tr = [];
fuel_tr = [];
Pturb_tr = [];
Pbatt_tr = [];
alt_tr = [];
phase_tr = {};

% Mission status
feasible = true;
failReason = '';

%% Run all mission phases

for i = 1:length(phases)

    ph = phases(i);

    % Skip if phase duration is zero
    if ph.duration <= 0
        continue;
    end

    % Number of simulation steps
    nSteps = max(1, round(ph.duration/dt));

    % Actual time step
    dtActual = ph.duration / nSteps;

    %% Simulation loop

    for k = 1:nSteps

        % Time at the middle of each step
        tLocal = (k-0.5) * dtActual;

        %% Calculate required power

        switch ph.mode

            case 'climb'

                h = ph.altStart + ph.climbRate * tLocal;

                [P_req,~,~,~] = power_required( ...
                    A, W, ph.speed, h, ph.climbRate);

            case 'descent'

                h = ph.altStart;

                % Low engine power during descent
                P_req = A.descentPowerFrac * A.P_rated;

            otherwise

                % Level flight

                h = ph.altStart;

                [P_req,~,~,~] = power_required( ...
                    A, W, ph.speed, h, 0);

        end

        %% Power supplied by turbine and battery

        [P_turb,P_batt]=power_split(A,...
                            ph.name,...
                            P_req,...
                            SoC);

        %% Fuel consumption

        fuelFlow = engine_model(A, P_turb);

        totalFuel = totalFuel + fuelFlow * dtActual;

        %% Update battery charge

        [SoC,~] = battery_model( ...
            A, SoC, P_batt, dtActual, battCapacity_Wh);

        %% Update time

        t = t + dtActual;

        %% Store results

        time_tr(end+1) = t;
        SoC_tr(end+1) = SoC;
        fuel_tr(end+1) = totalFuel;
        Pturb_tr(end+1) = P_turb;
        Pbatt_tr(end+1) = P_batt;
        alt_tr(end+1) = h;
        phase_tr{end+1} = ph.name;

        %% Check battery reserve

        if SoC <= A.SoC_reserve && P_batt > 0

            feasible = false;

            failReason = sprintf( ...
                'Battery reached reserve level during %s at %.0f s', ...
                ph.name, t);

            break;

        end

    end

    % Stop simulation if mission becomes infeasible
    if ~feasible
        break;
    end

end

%% Save results

result.feasible = feasible;
result.failReason = failReason;

result.totalFuel = totalFuel;
result.finalSoC = SoC;
result.totalTime = t;

result.time = time_tr;
result.SoC = SoC_tr;
result.fuel = fuel_tr;

result.Pturb = Pturb_tr;
result.Pbatt = Pbatt_tr;

result.alt = alt_tr;
result.phase = phase_tr;

end