function P_motor = motor_model(A,P_req)

% Motor power cannot exceed its rated value

P_motor = min(P_req,A.motorMaxPower);

% Account for motor efficiency

P_motor = P_motor/A.motorEfficiency;

end