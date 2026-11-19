function [P_turb,P_batt_DC,P_motor_shaft,powerOK] = power_split(A,P_req,SoC,dt,battCapacity_Wh,phaseName)
% Decide how the turbine and motor supply aircraft shaft power.
% Turbine / motor are SHAFT powers; battery is DC bus power.
% Positive battery power = discharge; negative = charging.
% Cruise: allow charging. Loiter: allow controlled electric assistance.
P_turb = 0;
P_batt_DC = 0;
P_motor_shaft = 0;
powerOK = true;

packMax_W = A.battMass_kg*A.battPowerDensity*1000;

if P_req > A.P_rated
    % At high demand, turbine operates at its limit and motor assists.
    P_turb = A.P_rated;
    [P_motor_shaft,P_batt_DC] = motor_model(A,P_req-P_turb);

    % If the hardware cannot provide the missing shaft power, reject it.
    if P_batt_DC > packMax_W+1e-7 || ...
            P_turb+P_motor_shaft < P_req-1e-6
        powerOK = false;
    end

elseif strcmp(phaseName,'Loiter') && SoC > A.finalSoC_min
    % Use some of the stored battery energy to save fuel in loiter.
    % Do not discharge below the experimental 20% landing target.
    energyAboveTarget_Wh = max(0,SoC-A.finalSoC_min)*battCapacity_Wh;
    maxDCfromEnergy_W = energyAboveTarget_Wh*3600*A.battEfficiency/dt;

    % The requested electric assist must obey every physical limit.
    assistRequest_W = A.loiterAssistFraction*max(P_req,0);
    maxMotor_W = min([assistRequest_W,A.motorMaxPower, ...
        packMax_W*A.motorEfficiency, ...
        maxDCfromEnergy_W*A.motorEfficiency]);
    [P_motor_shaft,P_batt_DC] = motor_model(A,maxMotor_W);
    P_turb = P_req-P_motor_shaft;

else
    % Turbine normally follows the required flight power.
    P_turb = P_req;

    % During cruise, charging may be worthwhile before the loiter segment.
    if strcmp(phaseName,'Cruise') && SoC < A.chargeStartSoC
        spareShaft_W = max(0,A.P_rated-P_req);
        chargeDC_W = min([A.maxChargePower,A.generatorMaxPower, ...
            packMax_W,spareShaft_W*A.generatorEfficiency]);

        % Prevent a numerical overshoot above the charging target.
        spaceInBattery_Wh = max(0,A.chargeStartSoC-SoC)*battCapacity_Wh;
        maxDCforStep_W = spaceInBattery_Wh*3600/(dt*A.chargerEfficiency);
        chargeDC_W = min(chargeDC_W,maxDCforStep_W);

        P_batt_DC = -chargeDC_W;
        P_turb = P_req+chargeDC_W/A.generatorEfficiency;
    end
end

% Check shaft power accounting and engine limits for every flight step.
shaftToGenerator_W = max(-P_batt_DC,0)/A.generatorEfficiency;
shaftBalance_W = P_turb+P_motor_shaft-shaftToGenerator_W;
if abs(shaftBalance_W-P_req)>1e-5 || ...
        P_turb>A.P_rated+1e-6 || P_turb < -1e-6
    powerOK = false;
end
end
