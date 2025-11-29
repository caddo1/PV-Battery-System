% function [u0, e0] = pv_battery_ems(PV_forecast, SoC0, loadP, R, T)
% 
% % import yalmip.*
% 
% nLoads = length(loadP);
% 
% % Decision variables over horizon
% u = sdpvar(T,1);            % battery power
% e = binvar(nLoads, T);      % load enables
% SoC = sdpvar(T+1,1);        % state trajectory
% 
% % Initial SOC
% Constraints = (SoC(1) == SoC0);
% 
% % Parameters
% SoC_min = 0.2; SoC_max = 0.9;
% u_min = -2000; u_max = 2000;
% eta_c = 0.98; eta_d = 0.98;
% C_nom = 3600*100; % 100Ah
% dt = 60; % 1 min timestep
% 
% Objective = 0;
% 
% for k = 1:T
%     % Load power requirement
%     P_req = loadP' * e(:,k);
%     P_sup = PV_forecast(k) + u(k);
% 
%     % Build cost
%     Objective = Objective - (R' * e(:,k)) + 0.001*abs(P_req - P_sup);
% 
%     % Constraints
%     Constraints = [Constraints;
%         SoC(k+1) == SoC(k) + dt/C_nom*(eta_c*max(u(k),0) + 1/eta_d*min(u(k),0));
%         (SoC_min <= SoC(k+1)) <= SoC_max;
%         (u_min <= u(k)) <= u_max;
%     ];
% end
% 
% % ops = sdpsettings('solver','bnb','verbose',0);
% % optimize(Constraints, Objective, ops);
% % 
% % u0 = value(u(1));
% % e0 = value(e(:,1));
% ops = sdpsettings('solver','bnb','verbose',1);   % or 0 to be quiet
% 
% % Solve
% sol = optimize(Constraints, Objective, ops);
% 
% if sol.problem ~= 0
%     % Optimization failed - fall back to safe defaults
%     warning('EMS optimization failed: %s. Using fallback u=0, e=zeros.', sol.info);
%     u0 = 0;
%     e0 = zeros(nLoads,1);
% else
%     % Optimization successful
%     u0 = value(u(1));
%     e0 = value(e(:,1));
% end
% % ---------------------------------------------------------------------------
% 
% end
% 
function [u0, e0] = pv_battery_ems(PV_forecast, SoC0, loadP, R, T)

% import yalmip.*   % <- correctly commented out

nLoads = length(loadP);

% Decision variables over horizon
u   = sdpvar(T,1);          % battery power over horizon
e   = binvar(nLoads, T);    % load enables (0/1) over horizon
SoC = sdpvar(T+1,1);        % state of charge trajectory

% Initial SOC
Constraints = (SoC(1) == SoC0);

% Parameters
SoC_min = 0.2; SoC_max = 0.9;
u_min   = -2000; u_max = 2000;
eta_c   = 0.98; eta_d = 0.98;
C_nom   = 3600*100;   % 100Ah
dt      = 60;         % 1 min timestep

Objective = 0;

for k = 1:T
    % Load power requirement
    P_req = loadP' * e(:,k);      % total load you turn on
    P_sup = PV_forecast(k) + u(k);% PV + battery

    % Cost: reward for serving loads - mismatch penalty
    Objective = Objective - (R' * e(:,k)) + 1.0*abs(P_req - P_sup);

    % Constraints
    Constraints = [Constraints;
        SoC(k+1) == SoC(k) + dt/C_nom * (eta_c*max(u(k),0) + 1/eta_d*min(u(k),0));
        SoC_min <= SoC(k+1) <= SoC_max;
        u_min   <= u(k)     <= u_max;
    ];
end

% Solver options
ops = sdpsettings('solver','bnb','verbose',0,'bmibnb.maxiter', 40,'bmibnb.maxtime', 2);  
%  % 0 if you want it quiet
% ops = sdpsettings('solver','gurobi','verbose',0);
% Solve
sol = optimize(Constraints, Objective, ops);

if sol.problem ~= 0
    % Optimization failed - fall back to safe defaults
    warning('EMS optimization failed: %s. Using fallback u=0, e=zeros.', sol.info);
    u0 = 0;
    e0 = zeros(nLoads,1);
else
    % Optimization successful
    u0 = value(u(1));
    e0 = value(e(:,1));
end

end
