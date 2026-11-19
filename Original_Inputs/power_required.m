function [P_req, D, CL, q] = power_required(A, W, V, h, climbRate)
% POWER_REQUIRED  Aircraft point-performance power required.
% Adapted from Zong et al. (2022) Eq.(4), fixed-wing terms only
% (VTOL/hover momentum-theory term dropped - not applicable, no VTOL segment).
%
%   A         = assumptions struct (from assumptions.m)
%   W         = instantaneous aircraft weight, N
%   V         = true airspeed, m/s
%   h         = altitude, m
%   climbRate = dh/dt, m/s (0 for level flight)
%
% Returns:
%   P_req = total power required, W
%   D     = total drag, N
%   CL    = lift coefficient (for stall-margin sanity checks)
%   q     = dynamic pressure, Pa

[rho, ~, ~] = atmosphere_model(h);
q = 0.5 * rho * V^2;

parasiteDrag = q * A.S * A.CD0;
inducedDrag  = A.K * W^2 / (q * A.S);
D  = parasiteDrag + inducedDrag;
CL = W / (q * A.S);

P_drag  = D * V / A.etaP;
P_climb = W * climbRate / A.etaP;
P_req   = P_drag + P_climb;

end
