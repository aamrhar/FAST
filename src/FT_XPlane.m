% Class XPlane Definition
classdef FT_XPlane
    %% Define Properties
%UNTITLED16 Summary of this class goes here
    %   Detailed explanation goes here
    % TODO : replace GGA and VTG by functions
    properties
        info;
        vor;
        ils;
        xplane_data;
        colors='ymcrgbk'
        % default visibility of figures. on is visible
        vis='on';
        
        L; % logger class
        
        % Plot parameters
        title_size = 20;
        title_color = 'black';
        legend_size = 16;
        label_size = 16;
        line_size = 2;
        scatter_size = 2;
        textbox_size = 14;
        fig_size = [100 100 1280 720];
    end
    
    %% Define Methods
    methods
        function obj = FT_XPlane(x,drfs, info)
            % Output: 1 struct with 2 fields:
                % VOR: time, VOR1 Freq, VOR1 value, VOR1 state, VOR1 ref
                %            VOR2 Freq, VOR2 value, VOR2 state, VOR2 ref
                % ILS: time, LOC Freq, LOC Value, LOC Ref, 
                %             GS Freq,  GS Value, GS Ref,
                %             ILS state
            % Logger
            obj.L=log4m.getLogger('XPlane.log');
            obj.L.setFilename('XPlane.log');
            obj.L.setLogLevel(obj.L.ALL);
            
            obj.L.info('init','FT_Cessna created')                
            % Start with VOR
            out = struct();
            if (length(drfs.vor) > 1)   % Make sure that we have VOR
                idx = find(strcmp({drfs.vor.Var3}, 'UTC') == 1);
                for i=1:1:length(idx)
                    out.vor(i).epoch = drfs.vor(idx(i)).Var1;
                    out.vor(i).utc = drfs.vor(idx(i)).Var4;
                end
                idx = find([out.vor.utc] <= 0);
                out.vor(idx)= [];
                for i=1:1:length(out.vor)
                    out.vor(i).zulu = out.vor(i).utc/3600;
                end

                for i=1:1:length(out.vor)-1
                    current0 = find([drfs.vor.Var1] == out.vor(i).epoch);
                    if size(current0 > 1)
                       current0x = find(strcmp({drfs.vor(current0).Var3}, 'UTC') == 1);
                       current0 = current0(current0x);
                    end

                    current1 = find([drfs.vor.Var1] == out.vor(i+1).epoch);
                    if size(current1 > 1)
                       current1x = find(strcmp({drfs.vor(current1).Var3}, 'UTC') == 1);
                       current1 = current1(current1x);
                    end
                    two_points = {drfs.vor(current0:current1).Var2};
                    counter = 0;
                    counter2 = 0;
                    out.vor(i).vor1_f = 0;
                    out.vor(i).vor1_v = 0;
                    out.vor(i).vor1_state = 0;
                    out.vor(i).vor2_f = 0;
                    out.vor(i).vor2_v = 0;
                    out.vor(i).vor2_state = 0;                
                    for q=1:1:length(two_points)                     
                        % VOR 1
                        if (strcmp(two_points{q}(1:4), 'VOR1') == 1)
                            counter = counter + 1;
                            out.vor(i).vor1_f = str2num(two_points{1,q}(end-4:end));
                            out.vor(i).vor1_v = out.vor(i).vor1_v + drfs.vor(current0+q-1).Var4;
                            out.vor(i).vor1_state = out.vor(i).vor1_state + ...
                                                    strcmp(drfs.vor(current0+q-1).Var3, 'True');
                        end

                        % VOR 2
                        if (strcmp(two_points{q}(1:4), 'VOR2') == 1)
                            counter2 = counter2 + 1;
                            out.vor(i).vor2_f = str2num(two_points{1,q}(end-4:end));
                            out.vor(i).vor2_v = out.vor(i).vor2_v + drfs.vor(current0+q-1).Var4;
                            out.vor(i).vor2_state = out.vor(i).vor2_state + ...
                                                    strcmp(drfs.vor(current0+q-1).Var3, 'True');
                        end
                    end


                        % Correct value
                        if (counter > 0)
                            out.vor(i).vor1_v = out.vor(i).vor1_v/counter;
                        else
                            out.vor(i).vor1_v = NaN;
                        end

                        if (out.vor(i).vor1_state >= 2)
                            out.vor(i).vor1_state = 1;
                        end

                        if (counter2 > 0)
                            out.vor(i).vor2_v = out.vor(i).vor2_v/counter2;
                        else
                            out.vor(i).vor2_v = NaN;
                        end

                        if (out.vor(i).vor2_state >= 2)
                            out.vor(i).vor2_state = 1;
                        end
                end
                out.vor(length([out.vor.zulu])) = [];

                % Get the reference
                for q=1:1:length([out.vor.zulu])
                    idx = min(find([x.x_zulu__time] > out.vor(q).zulu));
                    if ~isnan(idx)
                        out.vor(q).ref1 = x(idx).NAV_1_m_crs;
                        out.vor(q).ref2 = x(idx).NAV_2_m_crs;
                        out.vor(q).integrity1 = 0;
                        out.vor(q).integrity2 = 0;
                        if ((abs(x(idx).x_zulu__time - out.vor(q).zulu) < 0.001) && (x(idx).NAV_1__freq == out.vor(q).vor1_f * 100)) %% check the integrity
                            out.vor(q).integrity1 = 1;
                        end
                        if ((abs(x(idx).x_zulu__time - out.vor(q).zulu) < 0.001) && (x(idx).NAV_2__freq == out.vor(q).vor2_f * 100)) %% check the integrity
                            out.vor(q).integrity2 = 1;
                        end     
                    else
                        out.vor(q).ref1 = NaN;
                        out.vor(q).ref2 = NaN;
                        out.vor(q).integrity1 = 0;
                        out.vor(q).integrity2 = 0;
                    end                    
                end
            else
                out.vor = struct();
            end
            
            % Continue with ILS
            if (length(drfs.ils) > 1)
                idx = find(strcmp({drfs.ils.Var3}, 'UTC') == 1);
                for i=1:1:length(idx)
                    out.ils(i).epoch = drfs.ils(idx(i)).Var1;
                    out.ils(i).utc = drfs.ils(idx(i)).Var4;
                end
                idx = find([out.ils.utc] <= 0);
                out.ils(idx)= [];
                for i=1:1:length(out.ils)
                    out.ils(i).zulu = out.ils(i).utc/3600;
                end

                for i=1:1:length(out.ils)-1
                    current0 = find([drfs.ils.Var1] == out.ils(i).epoch);
                    if size(current0 > 1)
                       current0x = find(strcmp({drfs.ils(current0).Var3}, 'UTC') == 1);
                       current0 = current0(current0x);
                    end

                    current1 = find([drfs.ils.Var1] == out.ils(i+1).epoch);
                    if size(current1 > 1)
                       current1x = find(strcmp({drfs.ils(current1).Var3}, 'UTC') == 1);
                       current1 = current1(current1x);
                    end
                    two_points = {drfs.ils(current0:current1).Var2};
                    counter = 0;
                    counter2 = 0;
                    out.ils(i).loc_f = 0;
                    out.ils(i).loc_v = 0;
                    out.ils(i).gs_f = 0;
                    out.ils(i).gs_v = 0;
                    out.ils(i).ils_state = 0;                
                    for q=1:1:length(two_points)                     
                        % LOC
                        if (strcmp(two_points{q}(1:4), 'LOC_') == 1)
                            counter = counter + 1;
                            out.ils(i).loc_f = str2num(two_points{1,q}(end-4:end));
                            out.ils(i).loc_v = out.ils(i).loc_v + drfs.ils(current0+q-1).Var4;
                            out.ils(i).ils_state = out.ils(i).ils_state + ...
                                                    strcmp(drfs.ils(current0+q-1).Var3, 'True');
                        end

                        % GS
                        if (strcmp(two_points{q}(1:2), 'GS') == 1)
                            counter2 = counter2 + 1;
                            out.ils(i).gs_f = str2num(two_points{1,q}(end-4:end));
                            out.ils(i).gs_v = out.ils(i).gs_v + drfs.ils(current0+q-1).Var4;
                            out.ils(i).ils_state = out.ils(i).ils_state + ...
                                                    strcmp(drfs.ils(current0+q-1).Var3, 'True');
                        end
                    end


                    % Correct value
                    if (counter > 0)
                        out.ils(i).loc_v = out.ils(i).loc_v/counter;
                    else
                        out.ils(i).loc_v = NaN;
                    end

                    if (out.ils(i).ils_state >= 2)
                        out.ils(i).ils_state = 1;
                    end

                    if (counter2 > 0)
                        out.ils(i).gs_v = out.ils(i).gs_v/counter2;
                    else
                        out.ils(i).gs_v = NaN;
                    end
                end

                out.ils(length([out.ils.zulu])) = [];

                % Get the reference
                for q=1:1:length([out.ils.zulu])
                    idx = min(find([x.x_zulu__time] > out.ils(q).zulu));
                    if ~isnan(idx)
                        out.ils(q).loc_ref = x(idx).NAV_1_h_def;
                        out.ils(q).gs_ref = x(idx).NAV_2_v_def;
                        out.ils(q).integrity1 = 0;
                        if ((abs(x(idx).x_zulu__time - out.ils(q).zulu) < 0.001) && (x(idx).NAV_1__freq == out.ils(q).loc_f * 100)) %% check the integrity
                            out.ils(q).integrity1 = 1;
                        end
                    else
                        out.ils(q).loc_ref = NaN;
                        out.ils(q).gs_ref = NaN;
                        out.ils(q).integrity1 = 0;
                    end                    
                end
            else
                out.ils = struct();
            end
        
        % Get other general information
           obj.xplane_data = x;
            
           obj.vor = out.vor;
           obj.ils = out.ils;
           obj.info = info;
%             obj.L.info('init',['visibility is set to ' obj.vis])
        end
        
        % Get all figs
        function figs = get_all_figs(obj, save_path, ft_type)
            cmds ={};
            cmds{length(cmds)+1,1} = 'fig=obj.trajectory()';
            cmds{length(cmds)+1,1} = 'fig=obj.alt_utc()';
            if (length(obj.vor) > 1)
               cmds{length(cmds)+1,1} = 'fig=obj.vor_plot_full(1);';
               cmds{length(cmds)+1,1} = 'fig=obj.vor_plot_full(2);';
               cmds{length(cmds)+1,1} = 'fig=obj.vor_plot(1);';
               cmds{length(cmds)+1,1} = 'fig=obj.vor_plot(2);';
               cmds{length(cmds)+1,1} = 'fig=obj.vor_get_error();';
               cmds{length(cmds)+1,1} = 'fig=obj.vor_analysis(1);';
               cmds{length(cmds)+1,1} = 'fig=obj.vor_analysis(2);';
            end
            if (length(obj.ils) > 1)
                cmds{length(cmds)+1,1} = 'fig=obj.ils_plot();';
                cmds{length(cmds)+1,1} = 'fig=obj.loc_error();';
                cmds{length(cmds)+1,1} = 'fig=obj.loc_distribution();';
                cmds{length(cmds)+1,1} = 'fig=obj.gs_error();';
                cmds{length(cmds)+1,1} = 'fig=obj.gs_distribution();';
            end
%             cmds={
%                 'fig=obj.vor_plot(1);'
%                 'fig=obj.vor_plot(2);'
%                 'fig=obj.vor_get_error();'
%                 'fig=obj.ils_plot();'
%                 };
            figs=[];
            for i=1:length(cmds)
                try
                    eval(cmds{i});
                    set(fig, 'Visible','off')
                    figs=[figs fig];
                catch ME
                    obj.L.warn('get_wbr_figs',['cmd skipped:' cmds{i} ' ' ME.message ...
                        ' in ' ME.stack(1).name ' line:' num2str(ME.stack(1).line)]);
                    for stack=ME.stack.'
                        obj.L.debug(cmds{i},[stack.name ' line: ' num2str(stack.line)] )
                    end
                end
            end
            
           recursave(figs,0, save_path);
        end
        
        % Plot General information
        function fig = trajectory(obj)
            fig = figure('pos',obj.fig_size);
            plot([obj.xplane_data.lon_1___deg],[obj.xplane_data.lat_1___deg])
%             hold on
            
            xlabel('Longitude (DD)','FontSize', obj.label_size);
            ylabel('Latitude (DD)','FontSize', obj.label_size);
            legend({'Trajectory X-Plane'},'FontSize',obj.legend_size)

            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, 'Trajectory', ...
                'VOR Results', 1, ['VOR']);
            
            % ------------------------------------------------------------%            
        end
        
        function fig = alt_utc(obj)
            fig = figure('pos',obj.fig_size);
            plot([obj.xplane_data.x_zulu__time]*3600,[obj.xplane_data.alt_1_ftmsl])
%             hold on
            
            xlabel('UTC (s)','FontSize', obj.label_size);
            ylabel('Altitude (ft)','FontSize', obj.label_size);
            legend({'Altitude X-Plane'},'FontSize',obj.legend_size)

            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, 'Altitude vs. UTC', ...
                'VOR Results', 1, ['VOR']);
            
            % ------------------------------------------------------------%            
        end
        
        % Plot VOR1 Results
        function fig = vor_plot(obj, vor_type)
            switch vor_type
                case 1
                    fig = figure('pos',obj.fig_size);
                    dist_struct = obj.vor;
                    idx  = find([dist_struct.integrity1] == 1);
                    scatter([dist_struct(idx).utc], [dist_struct(idx).ref1], 'ob');
                    hold on
                    
                    idx = find([dist_struct.vor1_state] == 1);
                    scatter([dist_struct(idx).utc], [dist_struct(idx).vor1_v], 'rx');                   
                    xlabel('UTC (s)','FontSize', obj.label_size);
                    ylabel('Radial (degree)','FontSize', obj.label_size);
                    legend({'Reference', 'Measured'},'FontSize',obj.legend_size)
                    title(['VOR ',num2str(vor_type),' Results'], 'FontSize',obj.title_size, 'color', obj.title_color)
                     
                otherwise
                    fig = figure('pos',obj.fig_size);
                    dist_struct = obj.vor;
                    idx  = find([dist_struct.integrity2] == 1);
                    scatter([dist_struct(idx).utc], [dist_struct(idx).ref2], 'ob');
                    hold on
                    
                    idx = find([dist_struct.vor2_state] == 1);
                    scatter([dist_struct(idx).utc], [dist_struct(idx).vor2_v], 'rx');                         
                    xlabel('UTC (s)','FontSize', obj.label_size);
                    ylabel('Radial (degree)','FontSize', obj.label_size);
                    legend({'Reference', 'Measured'},'FontSize',obj.legend_size)
                    title(['VOR ',num2str(vor_type),' Results'], 'FontSize',obj.title_size, 'color', obj.title_color)
            end
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['VOR ',num2str(vor_type),' Results'], ...
                'VOR Results', 1, ['VOR']);
            
            % ------------------------------------------------------------%            
        end
        
        function fig = vor_plot_full(obj, vor_type)
            switch vor_type
                case 1
                    fig = figure('pos',obj.fig_size);
                    dist_struct = obj.vor;
                    idx  = find([dist_struct.integrity1] == 1);
                    scatter([dist_struct(idx).utc], [dist_struct(idx).ref1], 'ob');
                    hold on
                    
                    %idx = find([dist_struct.vor1_state] == 1);
                    scatter([dist_struct(idx).utc], [dist_struct(idx).vor1_v], 'rx');                   
                    xlabel('UTC (s)','FontSize', obj.label_size);
                    ylabel('Radial (degree)','FontSize', obj.label_size);
                    legend({'Reference', 'Measured'},'FontSize',obj.legend_size)
                    title(['VOR ',num2str(vor_type),' Results'], 'FontSize',obj.title_size, 'color', obj.title_color)
                     
                otherwise
                    fig = figure('pos',obj.fig_size);
                    dist_struct = obj.vor;
                    idx  = find([dist_struct.integrity2] == 1);
                    scatter([dist_struct(idx).utc], [dist_struct(idx).ref2], 'ob');
                    hold on
                    
                    %idx = find([dist_struct.vor2_state] == 1);
                    idx = 1:1:length(dist_struct);
                    scatter([dist_struct(idx).utc], [dist_struct(idx).vor2_v], 'rx');                         
                    xlabel('UTC (s)','FontSize', obj.label_size);
                    ylabel('Radial (degree)','FontSize', obj.label_size);
                    legend({'Reference', 'Measured'},'FontSize',obj.legend_size)
                    title(['VOR ',num2str(vor_type),' Full'], 'FontSize',obj.title_size, 'color', obj.title_color)
            end
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['VOR ',num2str(vor_type),' Full'], ...
                'VOR Results', 1, ['VOR']);
            
            % ------------------------------------------------------------%            
        end
        
        function fig = vor_get_error(obj)
            fig = figure('pos',obj.fig_size);
            dist_struct = obj.vor;
            % VOR1
            idx1  = find([dist_struct.integrity1] == 1);
            idx2  = find([dist_struct.vor1_state] == 1);
            idx = intersect(idx1, idx2);
            if (length(idx>0))
                error1 = abs([dist_struct(idx).vor1_v] - [dist_struct(idx).ref1]);
                for q=1:1:length(error1)
                    if (error1(q) > 180)
                        error1(q) = 360 - error1(q);
                    end
                end
                scatter([dist_struct(idx).utc], error1,'xb');              
            end
            
            hold on
            
            % VOR 2
            idx1  = find([dist_struct.integrity2] == 1);
            idx2  = find([dist_struct.vor2_state] == 1);
            idx = intersect(idx1, idx2);
            if (length(idx)>0)
                error2 = abs([dist_struct(idx).vor2_v] - [dist_struct(idx).ref2]);
                for q=1:1:length(error2)
                    if (error2(q) > 180)
                        error2(q) = 360 - error2(q);
                    end
                end
                scatter([dist_struct(idx).utc], error2,'xr')                
            end
            
            xlabel('UTC (s)','FontSize', obj.label_size);
            ylabel('Radial (degree)','FontSize', obj.label_size);
            legend({'VOR1', 'VOR2'},'FontSize',obj.legend_size);
            title(['Difference Between Reference and Measured Results'], 'FontSize',obj.title_size, 'color', obj.title_color)            
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['Difference Between Reference and Measured Results'], ...
                'VOR Results', 1, ['VOR']);
            
            % ------------------------------------------------------------%               
        end

        function fig = vor_analysis(obj, vor_type)
            switch vor_type
                case 1
                    fig = figure('pos',obj.fig_size);
                    dist_struct = obj.vor;
                    idx  = find([dist_struct.integrity1] == 1);
                    error = abs([dist_struct(idx).ref1] - [dist_struct(idx).vor1_v]);
                    idx_err = find([error] < 10);
                    error_f1 = error(idx_err);
                    error_f1 = medfilt1(error_f1, 7);
                    count_f1 = find([error_f1] < 3);
                    str_1 = strcat('Met standard:', num2str(length(count_f1)/length(error_f1)*100), '%');
                    str_2 = 'Out of Boundary';
                    pie([length(count_f1), length(error_f1) - length(count_f1)], {str_1, str_2})
                    
%                     title(['VOR ',num2str(vor_type),' Analysis'], 'FontSize',obj.title_size, 'color', obj.title_color)
                     
                otherwise
                    fig = figure('pos',obj.fig_size);
                    dist_struct = obj.vor;
                    idx  = find([dist_struct.integrity2] == 1);
                    error = abs([dist_struct(idx).ref2] - [dist_struct(idx).vor2_v]);
                    idx_err = find([error] < 10);
                    error_f1 = error(idx_err);
                    error_f1 = medfilt1(error_f1, 7);
                    count_f1 = find([error_f1] < 3);
                    str_1 = strcat('Met standard:', num2str(length(count_f1)/length(error_f1)*100), '%');
                    str_2 = 'Out of Boundary';
                    pie([length(count_f1), length(error_f1) - length(count_f1)], {str_1, str_2})
                    
%                     title(['VOR ',num2str(vor_type),' Analysis'], 'FontSize',obj.title_size, 'color', obj.title_color)

            end
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['VOR ',num2str(vor_type),' Analysis'], ...
                'VOR Results', 1, ['VOR']);
            
            % ------------------------------------------------------------%            
        end
        
       % Plot ILS results
       function fig = ils_plot(obj)
           dist_struct = obj.ils;
           idx1 = find([dist_struct.integrity1] == 1);
           fig = figure('pos',obj.fig_size);
           if ~isempty(idx1)
               scatter([dist_struct(idx1).utc], -[dist_struct(idx1).loc_ref]*0.155, 'ob');
               hold on
               scatter([dist_struct(idx1).utc], -[dist_struct(idx1).gs_ref]*0.155, 'or');      
               hold on
           end
           idx2 = find([dist_struct.ils_state] == 1);
           if ~isempty(idx2)
               scatter([dist_struct(idx2).utc], [dist_struct(idx2).loc_v], 'xb');
               hold on
               scatter([dist_struct(idx2).utc], [dist_struct(idx2).gs_v], 'xr');                
           end
           
           xlabel('UTC (s)','FontSize', obj.label_size);
           ylabel('Difference in Depth of Modulation (DDM)','FontSize', obj.label_size);
           legend({'Ref LOC', 'Ref GS', 'Measured LOC', 'Measured GS'},'FontSize',obj.legend_size);
           title(['ILS Results'], 'FontSize',obj.title_size, 'color', obj.title_color)           

           % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['ILS Results'], ...
                'ILS Results', 2, ['ILS Results']);
            
            % ------------------------------------------------------------%    
       end
       
       function fig = loc_error(obj)
           dist_struct = obj.ils;
           idx1 = find([dist_struct.integrity1] == 1);
           idx2 = find([dist_struct(idx1).ils_state] == 1);
           fig = figure('pos',obj.fig_size);
           if ~isempty(idx2) 
               error = abs(-[dist_struct(idx2).loc_ref]*0.155 - [dist_struct(idx2).loc_v]);
               scatter([dist_struct(idx2).utc], error, 'xb');
           end
                      
           xlabel('UTC (s)','FontSize', obj.label_size);
           ylabel('Difference in Depth of Modulation for LOC (DDM)','FontSize', obj.label_size);
           legend('Error','FontSize',obj.legend_size);
           title(['LOC Error'], 'FontSize',obj.title_size, 'color', obj.title_color)           

           % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['LOC Error'], ...
                'ILS Results', 2, ['ILS Results']);
            
            % ------------------------------------------------------------%    
       end
       
       function fig = loc_distribution(obj)
           dist_struct = obj.ils;
           idx1 = find([dist_struct.integrity1] == 1);
           idx2 = find([dist_struct(idx1).ils_state] == 1);
           fig = figure('pos',obj.fig_size);
           if ~isempty(idx2) 
               error1 = abs(-[dist_struct(idx2).loc_ref]*0.155 - [dist_struct(idx2).loc_v]);
               error = find([error1]<0.4);
               idx_f1 = find([error1(error)] <= 0.00465);
               str1 = strcat('Met standard:', num2str(length(idx_f1)/length(error)*100), '%');
               str2 = 'Out of Boundary';
               pie([length(idx_f1), length(error)-length(idx_f1)], {str1, str2})
%                scatter([dist_struct(idx3).utc], error, 'xb');
           end         

%            legend('Error','FontSize',obj.legend_size);
           title(['LOC Distribution'], 'FontSize',obj.title_size, 'color', obj.title_color)           

           % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['LOC Distribution'], ...
                'ILS Results', 2, ['ILS Results']);
            
            % ------------------------------------------------------------%    
       end
       
       function fig = gs_error(obj)
           dist_struct = obj.ils;
           idx1 = find([dist_struct.integrity1] == 1);
           idx2 = find([dist_struct(idx1).ils_state] == 1);
           fig = figure('pos',obj.fig_size);
           if ~isempty(idx2) 
               error = abs(-[dist_struct(idx2).gs_ref]*0.155 - [dist_struct(idx2).gs_v]);
               scatter([dist_struct(idx2).utc], error, 'xr');
           end 

           xlabel('UTC (s)','FontSize', obj.label_size);
           ylabel('Difference in Depth of Modulation for GS (DDM)','FontSize', obj.label_size);
           legend('Error','FontSize',obj.legend_size);
           title(['GS Error'], 'FontSize',obj.title_size, 'color', obj.title_color)           

           % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['GS Error'], ...
                'ILS Results', 2, ['ILS Results']);
            
            % ------------------------------------------------------------%    
       end
       
       function fig = gs_distribution(obj)
           dist_struct = obj.ils;
           idx1 = find([dist_struct.integrity1] == 1);
           idx2 = find([dist_struct(idx1).ils_state] == 1);
           fig = figure('pos',obj.fig_size);
           if ~isempty(idx2) 
               error1 = abs(-[dist_struct(idx2).gs_ref]*0.155 - [dist_struct(idx2).gs_v]);
               error = find([error1]<0.4);
               idx_f1 = find([error1(error)] <= 0.01183);
               str1 = strcat('Met standard:', num2str(length(idx_f1)/length(error)*100), '%');
               str2 = 'Out of Boundary';
               pie([length(idx_f1), length(error)-length(idx_f1)], {str1, str2})
%                scatter([dist_struct(idx3).utc], error, 'xb');
           end         

%            legend('Error','FontSize',obj.legend_size);
           title(['GS Distribution'], 'FontSize',obj.title_size, 'color', obj.title_color)           

           % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['GS Distribution'], ...
                'ILS Results', 2, ['ILS Results']);
            
            % ------------------------------------------------------------%    
       end       

               %% utils
        function set_report_content(obj, fig, title, desc, section_priority, tag, varargin )
            
            p = inputParser;
            addParameter(p,'table', table());
            
            try
                parse(p, varargin{:});
            catch ME
                
                warning('Error setting report content')
                disp(ME.message)
                return
                
            end
            % -- Title
            main_title = [obj.info.date '  ' title];
            
            if(isempty(p.Results.table))
                suptitle(main_title);
            end
            set(fig, 'Name', main_title);
            
            %Bug: report generator won't take fig.Name for table
            fig_info.table_title = main_title;
            
            % -- Description
            fig_info.description = desc;
            % -- Set fig info
            set(fig, 'UserData', fig_info);
            
            % -- Section Tag [ 'Priority' ';' 'name' ]
            set(fig, 'tag', [num2str(section_priority, '%d') ';' tag]);
            
        end


    end
    
    %% Define Enumeration
%     enumeration
%     end
end