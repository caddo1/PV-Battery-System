function [u0, e0] = pv_battery_ems(PV_forecast, SoC0, loadP, R, T)

import yalmip.*

nLoads = length(loadP);

% Decision variables over horizon
u = sdpvar(T,1);            % battery power
e = binvar(nLoads, T);      % load enables
SoC = sdpvar(T+1,1);        % state trajectory

% Initial SOC
Constraints = (SoC(1) == SoC0);

% Parameters
SoC_min = 0.2; SoC_max = 0.9;
u_min = -2000; u_max = 2000;
eta_c = 0.98; eta_d = 0.98;
C_nom = 3600*100; % 100Ah
dt = 60; % 1 min timestep

Objective = 0;

for k = 1:T
    % Load power requirement
    P_req = loadP' * e(:,k);
    P_sup = PV_forecast(k) + u(k);

    % Build cost
    Objective = Objective - (R' * e(:,k)) + 0.001*abs(P_req - P_sup);

    % Constraints
    Constraints = [Constraints;
        SoC(k+1) == SoC(k) + dt/C_nom*(eta_c*max(u(k),0) + 1/eta_d*min(u(k),0));
        (SoC_min <= SoC(k+1)) <= SoC_max;
        (u_min <= u(k)) <= u_max;
    ];
end

ops = sdpsettings('solver','gurobi','verbose',0);
optimize(Constraints, Objective, ops);

u0 = value(u(1));
e0 = value(e(:,1));

end
