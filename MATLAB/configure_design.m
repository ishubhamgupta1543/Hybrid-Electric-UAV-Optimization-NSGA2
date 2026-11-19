function A = configure_design(A0,x)
% NSGA-II variables: [DoH, battery kg, charge target SoC, charge kW, loiter assist].
A = A0;
A.DoH = x(1);
A.battMass_kg = x(2);
A.chargeStartSoC = x(3);
A.maxChargePower = x(4)*1000;
A.loiterAssistFraction = x(5);

% Installed-power DoH, measured using engine and motor shaft ratings.
A.motorMaxPower = A.DoH/(1-A.DoH)*A.P_rated;
referenceMotor_W = A.DoH_reference/(1-A.DoH_reference)*A.P_rated;

% The 550 kg reference OEW includes the original motor.
% Count only the change in installed motor mass, not its entire mass again.
A.motorMass_kg = A.motorMaxPower/1000/A.motorPowerDensity;
A.referenceMotorMass_kg = referenceMotor_W/1000/A.motorPowerDensity;
A.OEW_effective = A.OEW+A.motorMass_kg-A.referenceMotorMass_kg;
end
