function test_project()
% Run simple regression tests without the Global Optimization Toolbox.
A0 = assumptions();
x = [0.38,75,0.65,8,0.45];
A = configure_design(A0,x);
E = A.battMass_kg*A.battSpecificEnergy;

% 1. During climb the engine + motor must equal the shaft power needed.
[P0,~,~,~] = power_required(A,A.MTOW*A.g,A.climbSpeed,0,A.climbRate);
assert(P0>A.P_rated,'Expected hybrid assistance at initial climb.');
[Pt,Pb,Pm,ok] = power_split(A,P0,0.90,A.dt,E,'Climb');
assert(ok,'Reference motor/battery cannot supply initial climb power.');
assert(abs(Pt+Pm-P0)<1e-5,'Climb shaft power does not balance.');
assert(abs(Pb*A.motorEfficiency-Pm)<1e-5,'Motor efficiency mismatch.');

% 2. Charging should use actual engine shaft power and generator losses.
[Pcr,~,~,~] = power_required(A,A.MTOW*A.g,A.cruiseSpeed,A.cruiseAltitude,0);
[Pt,Pb,Pm,ok] = power_split(A,Pcr,0.25,A.dt,E,'Cruise');
assert(ok && Pb<0 && Pm==0,'Cruise battery charging did not start.');
assert(abs(Pt+Pb/A.generatorEfficiency-Pcr)<1e-5, ...
    'Charging shaft/DC power balance is incorrect.');

% 3. Loiter assist reduces turbine demand without breaking power balance.
[Pl,~,~,~] = power_required(A,A.MTOW*A.g,A.loiterSpeed,A.loiterAltitude,0);
[Pt,Pb,Pm,ok] = power_split(A,Pl,0.55,A.dt,E,'Loiter');
assert(ok && Pb>0 && Pm>0 && Pt<Pl,'Loiter assist did not operate.');
assert(abs(Pt+Pm-Pl)<1e-5,'Loiter shaft power does not balance.');

% 4. Assist must stop exactly at the 20 percent minimum landing SoC.
[Pt,Pb,Pm,ok] = power_split(A,Pl,A.finalSoC_min,A.dt,E,'Loiter');
assert(ok && Pb==0 && Pm==0,'Battery discharged below landing target.');
[Pt,Pb,Pm,ok] = power_split(A,Pl,A.finalSoC_min+1e-5,A.dt,E,'Loiter');
assert(ok,'Tapering near the landing target failed.');
[socAfter,~] = battery_model(A,A.finalSoC_min+1e-5,Pb,A.dt,E);
assert(socAfter>=A.finalSoC_min-1e-10, ...
    'Loiter step exceeded the remaining usable energy.');

% 5. Powertrain too small for takeoff must not be called feasible.
A_bad = configure_design(A0,[0.30,60,0.65,8,0.45]);
R_bad = mission_sim(A_bad,60*A_bad.battSpecificEnergy,0);
assert(~R_bad.feasible,'Undersized design incorrectly reported feasible.');

% 6. Complete reference design and mass constraints.
D = evaluate_design(A0,x);
assert(D.feasible,['Reference design infeasible: ' D.reason]);
assert(D.maxMission.finalSoC>=A0.finalSoC_min-1e-6);
assert(D.referenceMission.finalSoC>=A0.finalSoC_min-1e-6);
assert(D.massTotal_kg<=A0.MTOW+0.1,'MTOW exceeded.');
assert(D.cruiseDuration_s>=A0.missionCruise_min_s);
assert(D.maxMission.totalTime>=D.referenceMission.totalTime);

% 7. Check there are no teleportation jumps in the altitude profile.
ph = mission_profile(A,7200);
for i = 2:length(ph)
    assert(abs(ph(i).altStart-ph(i-1).altEnd)<1e-10, ...
        'Mission phase altitude discontinuity.');
end
D_noAssist = evaluate_design(A0,[0.38,75,0.65,8,0]);
assert(D_noAssist.feasible,'Engine-only loiter comparator failed.');
assert(D.referenceFuel_kg<D_noAssist.referenceFuel_kg, ...
    'Expected the example loiter assist to reduce fixed-mission fuel.');
fprintf('PASS: power balance, charge, loiter assist, SoC, MTOW, continuity.\n');
end
