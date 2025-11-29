% classdef EMSController < matlab.System
%     % EMS MPC controller using YALMIP
% 
%     methods(Access = protected)
% 
%         function [u_bat, e] = stepImpl(~, SoC, loadP, R, T, PV_forecast)
%             % stepImpl is called every Simulink timestep
% 
%             % Call the MPC solver
%             [u_bat, e] = pv_battery_ems(PV_forecast, SoC, loadP, R, T);
%         end
%     end
% end
classdef EMSController < matlab.System
    % EMS MPC controller using YALMIP

    methods(Access = protected)

        %--- Main step -----------------------------------------------
        function [u_bat, e] = stepImpl(~, SoC, loadP, R, T, PV_forecast)
            % Called every Simulink timestep (interpreted MATLAB)
            [u_bat, e] = pv_battery_ems(PV_forecast, SoC, loadP, R, T);
        end

        %--- Output characteristics for Simulink (size / type / etc.)-

        % Number of outputs
        function n = getNumOutputsImpl(~)
            n = 2;   % u_bat and e
        end

        % Output sizes
        function [sz1, sz2] = getOutputSizeImpl(~)
            sz1 = [1 1];   % u_bat is scalar
            sz2 = [4 1];   % e is 4x1 (because you have 4 loads)
        end

        % Output data types
        function [dt1, dt2] = getOutputDataTypeImpl(~)
            dt1 = 'double';
            dt2 = 'double';   % you can keep e as double 0/1
        end

        % Outputs are real (not complex)
        function [c1, c2] = isOutputComplexImpl(~)
            c1 = false;
            c2 = false;
        end

        % Outputs have fixed size
        function [fs1, fs2] = isOutputFixedSizeImpl(~)
            fs1 = true;
            fs2 = true;
        end

    end
end
