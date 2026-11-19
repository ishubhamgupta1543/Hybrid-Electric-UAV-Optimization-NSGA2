function result = mission_sim(A,battCapacity_Wh,cruiseDuration_s)
% Fly each phase with a constant MTOW aerodynamic weight (conservative).
% Missing power, battery power violations, and SoC reserve violations FAIL.
phases = mission_profile(A,cruiseDuration_s);
W = A.MTOW*A.g;
N = 0;
for p = 1:numel(phases)
    if phases(p).duration > 0
        N = N+max(1,ceil(phases(p).duration/A.dt));
    end
end
% Allocate memory before running the loop.
time = zeros(1,N); alt = zeros(1,N); SoC_tr = zeros(1,N);
fuel = zeros(1,N); Pturb = zeros(1,N); Pbatt = zeros(1,N);
Pmotor = zeros(1,N); Preq = zeros(1,N); CL_tr = zeros(1,N);
phase = cell(1,N);
SoC = A.SoC_initial;
t = 0;
totalFuel = 0;
kout = 0;
feasible = true;
failReason = '';

for i = 1:numel(phases)
    ph = phases(i);
    if ph.duration <= 0
        continue;
    end
    nsteps = max(1,ceil(ph.duration/A.dt));
    step = ph.duration/nsteps;
    for k = 1:nsteps
        midTime = (k-0.5)*step;
        h = ph.altStart+(ph.altEnd-ph.altStart)*midTime/ph.duration;
        if strcmp(ph.mode,'descent')
            [P_aero,~,CL,~] = power_required(A,W,ph.speed,h,ph.climbRate);
            P_required = max(A.descentPowerFrac*A.P_rated,P_aero);
        else
            [P_required,~,CL,~] = power_required(A,W,ph.speed,h,ph.climbRate);
        end

        [Pt,Pb,PM,ok] = power_split(A,P_required,SoC,step,battCapacity_Wh,ph.name);
        nextSoC = SoC;
        if ok
            [nextSoC,~] = battery_model(A,SoC,Pb,step,battCapacity_Wh);
        end
        t = t+step;
        totalFuel = totalFuel+engine_model(A,Pt)*step;
        kout = kout+1;
        time(kout) = t; alt(kout) = h; SoC_tr(kout) = nextSoC;
        fuel(kout) = totalFuel; Pturb(kout) = Pt;
        Pbatt(kout) = Pb; Pmotor(kout) = PM;
        Preq(kout) = P_required; CL_tr(kout) = CL;
        phase{kout} = ph.name;

        if ~ok
            feasible = false;
            failReason = sprintf('Insufficient power during %s at %.0f s',ph.name,t);
        elseif Pb > 0 && nextSoC < A.SoC_reserve-1e-8
            feasible = false;
            failReason = sprintf('Battery below 15%% reserve during %s at %.0f s',ph.name,t);
        elseif CL > A.CLmax+1e-9
            feasible = false;
            failReason = sprintf('Stall-margin failure during %s at %.0f s',ph.name,t);
        end
        SoC = nextSoC;
        if ~feasible
            break;
        end
    end
    if ~feasible
        break;
    end
end

% Trim to the actual executed steps.
result.feasible = feasible;
result.failReason = failReason;
result.totalFuel = totalFuel;
result.finalSoC = SoC;
result.totalTime = t;
result.time = time(1:kout);
result.alt = alt(1:kout);
result.SoC = SoC_tr(1:kout);
result.fuel = fuel(1:kout);
result.Pturb = Pturb(1:kout);
result.Pbatt = Pbatt(1:kout);
result.Pmotor = Pmotor(1:kout);
result.Preq = Preq(1:kout);
result.CL = CL_tr(1:kout);
result.phase = phase(1:kout);
end
