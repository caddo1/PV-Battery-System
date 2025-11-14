classdef EMSController < matlab.System
    % EMS MPC controller using YALMIP

    methods(Access = protected)

        function [u_bat, e] = stepImpl(~, SoC, loadP, R, T, PV_forecast)
            % stepImpl is called every Simulink timestep

            % Call the MPC solver
            [u_bat, e] = pv_battery_ems(PV_forecast, SoC, loadP, R, T);
        end
    end
end
