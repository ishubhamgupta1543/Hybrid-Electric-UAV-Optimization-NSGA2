function [P_turb,P_batt] = power_split(A,phaseName,P_req,SoC)

% This function decides how the required power is shared
% between the turbine and the battery during each mission phase.

switch phaseName

    case {'Takeoff','Climb'}

        P_turb=min(P_req,A.P_rated);

        batteryNeeded=max(0,P_req-P_turb);

        P_batt=min(batteryNeeded,A.motorMaxPower);

    case 'Cruise'
        % Run the engine at its rated power during cruise
        P_turb = A.P_rated;

        % Extra power available for charging
        surplusPower = P_turb - P_req;

        if surplusPower > 0 && SoC < A.chargeStartSoC

            % Limit charging power
            chargePower = min(surplusPower, A.maxChargePower);

            % Battery charges (negative sign)
            P_batt = -chargePower;

        else

            % No charging
            P_batt = 0;

        end



    case {'Loiter','Descent'}

        P_turb=P_req;

        P_batt=0;

    otherwise

        P_turb=P_req;

        P_batt=0;

end
end