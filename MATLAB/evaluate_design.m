function out = evaluate_design(A0,x)
% Evaluate one NSGA-II candidate using real mission simulations.
% Objective 1: maximum endurance with the available fuel mass.
% Objective 2: fuel needed for the SAME two-hour-cruise mission.
% Objective 3: battery mass.
%
% The new loiter battery assist changes fuel use depending on the SoC
% reached during cruise. We therefore solve cruise duration by simulating
% the whole mission, rather than assuming fixed non-cruise fuel consumption.
A = configure_design(A0,x);
out = struct('feasible',false,'reason','','A',A, ...
    'maxMission',[],'referenceMission',[],'endurance_hr',NaN, ...
    'referenceFuel_kg',NaN,'batteryMass_kg',A.battMass_kg, ...
    'fuelBudget_kg',NaN,'cruiseDuration_s',NaN,'massTotal_kg',NaN);

if numel(x)~=5 || any(~isfinite(x)) || x(1)<=0 || x(1)>=1 || ...
        x(2)<=0 || x(3)<A.finalSoC_min || x(3)>=1 || ...
        x(4)<0 || x(5)<0 || x(5)>1
    out.reason = 'Design variables outside physical limits';
    return;
end

capacity_Wh = A.battMass_kg*A.battSpecificEnergy;
fuelBudget_kg = A.MTOW-A.OEW_effective-A.payload-A.battMass_kg;
if fuelBudget_kg <= 0
    out.reason = 'Not enough mass available for fuel';
    return;
end

% Benchmark first: a fixed two-hour cruise with a fixed 2-hour loiter.
% This ensures fuel values are comparable across ALL NSGA-II candidates.
referenceMission = mission_sim(A,capacity_Wh,A.missionCruise_min_s);
if ~referenceMission.feasible
    out.reason = ['Benchmark mission failed: ' referenceMission.failReason];
    return;
end
if referenceMission.finalSoC < A.finalSoC_min-1e-7
    out.reason = 'Benchmark ends below the 20% SoC requirement';
    return;
end
if referenceMission.totalFuel > fuelBudget_kg+0.05
    out.reason = 'Benchmark fuel exceeds the MTOW budget';
    return;
end

% Find the longest feasible cruise while using the allocated fuel mass.
% The loiter fuel burn depends on charging and discharge choices, so a
% numerical cruise-duration search is more reliable than an analytic rate.
[P_cruise,~,~,~] = power_required(A,A.MTOW*A.g, ...
    A.cruiseSpeed,A.cruiseAltitude,0);
cruiseFuelRate = engine_model(A,P_cruise);
if P_cruise > A.P_rated || cruiseFuelRate <= 0
    out.reason = 'Cruise shaft power exceeds available engine power';
    return;
end

low = A.missionCruise_min_s;
remainingFuel = max(0,fuelBudget_kg-referenceMission.totalFuel);
high = low+max(1200,1.4*remainingFuel/cruiseFuelRate);

% Make sure the upper bracket burns more than the available fuel.
for k = 1:8
    Rhigh = mission_sim(A,capacity_Wh,high);
    if ~Rhigh.feasible
        out.reason = ['Extended mission failed: ' Rhigh.failReason];
        return;
    end
    if Rhigh.totalFuel >= fuelBudget_kg
        break;
    end
    high = low+2*(high-low);
end
if Rhigh.totalFuel < fuelBudget_kg
    out.reason = 'Could not bracket the maximum cruise duration';
    return;
end

% Keep the longest mission that uses no more than the available fuel.
maxMission = referenceMission;
for k = 1:18
    mid = 0.5*(low+high);
    Rmid = mission_sim(A,capacity_Wh,mid);
    if ~Rmid.feasible
        high = mid;
    elseif Rmid.totalFuel <= fuelBudget_kg
        low = mid;
        maxMission = Rmid;
    else
        high = mid;
    end
    if Rmid.feasible && abs(Rmid.totalFuel-fuelBudget_kg)<0.05
        break;
    end
end

if ~maxMission.feasible || maxMission.finalSoC < A.finalSoC_min-1e-7
    out.reason = 'Maximum-duration mission failed the SoC or power checks';
    return;
end
if maxMission.totalFuel > fuelBudget_kg+0.05
    out.reason = 'Maximum-duration fuel exceeds MTOW allowance';
    return;
end

out.feasible = true;
out.reason = 'All constraints passed';
out.maxMission = maxMission;
out.referenceMission = referenceMission;
out.endurance_hr = maxMission.totalTime/3600;
out.referenceFuel_kg = referenceMission.totalFuel;
out.batteryMass_kg = A.battMass_kg;
out.fuelBudget_kg = fuelBudget_kg;
out.cruiseDuration_s = low;
out.massTotal_kg = A.OEW_effective+A.payload+A.battMass_kg+maxMission.totalFuel;
end
