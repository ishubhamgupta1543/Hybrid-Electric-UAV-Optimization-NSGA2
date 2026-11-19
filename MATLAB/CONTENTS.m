% Hybrid UAV project files:
% assumptions.m        - fixed physical assumptions and mission requirements
% configure_design.m   - five design variables -> settings, motor rating and OEW adjustment
% atmosphere_model.m   - ISA density
% power_required.m     - lift, drag, shaft power
% mission_profile.m    - 6 continuous flight phases
% engine_model.m       - fuel model
% motor_model.m        - motor efficiency and rating
% battery_model.m      - state-of-charge integration
% power_split.m        - power-based EMS: cruise charging and controlled loiter assist
% mission_sim.m        - mission-time integration and feasibility checks
% evaluate_design.m    - actual fuel-budget search and two mission evaluations
% dashboard.m          - original 3x2 dashboard and diagnostics
% main.m               - run fixed 65-kW example
% optimizer.m          - NSGA-II via gamultiobj
% test_project.m       - physics and integration tests
% compare_pms.m        - compare turbine-only vs battery-assisted loiter
