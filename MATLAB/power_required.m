function [P_req,D,CL,q] = power_required(A,W,V,h,climbRate)
% Calculate required propulsion shaft power in W.
[rho,~,~] = atmosphere_model(h);
q = 0.5*rho*V^2;
parasiteDrag = q*A.S*A.CD0;
inducedDrag = A.K*W^2/(q*A.S);
D = parasiteDrag+inducedDrag;
CL = W/(q*A.S);
P_drag = D*V/A.etaP;
P_climb = W*climbRate/A.etaP;
P_req = P_drag+P_climb;
end
