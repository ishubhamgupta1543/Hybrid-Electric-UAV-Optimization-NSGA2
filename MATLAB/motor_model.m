function [P_shaft,P_DC] = motor_model(A,P_shaft_request)
% Convert the motor's requested shaft assist to battery/DC-bus power.
% The limit is applied on the motor SHAFT side.
P_shaft = min(max(P_shaft_request,0),A.motorMaxPower);
P_DC = P_shaft/A.motorEfficiency;
end
