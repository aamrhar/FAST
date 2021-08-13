classdef FT_Cessna
    %UNTITLED16 Summary of this class goes here
    %   Detailed explanation goes here
    % TODO : replace GGA and VTG by functions
    properties
        info; % genral info regarding flight
        sdar; % sdar class
        ref_data; % ref data obj. can be xplane, ublox or aid
        luts;
        mgs;
        fpga; % logs from FPGA
        transcript; % transcript of audio log
        colors='ymckgbr'
        markers='+o*.xsd^v<>ph'
        % default visibility of figures. on is visible
        vis='off';
        L; % logger class
        
        % Plot parameters
        title_size = 20;
        title_color = 'black';
        legend_size = 16;
        label_size = 16;
        line_size = 2;
        scatter_size = 2;
        textbox_size = 14;
        fig_size = [100 100 1600 900];
        fig_bg = [1,1,1] %figure background color
    end
    
    methods
        function obj=FT_Cessna(sdar,ref_data,mgs,fpga,info,luts)
            
            % set logger
            obj.L=log4m.getLogger2('FT_Cessna.log');
            obj.L.setFilename('FT_Cessna.log');
            obj.L.setLogLevel(obj.L.ALL);
            obj.L.info('init','FT_Cessna created')
            obj.sdar=sdar;
            obj.ref_data=ref_data;
            obj.info=info;
            obj.luts=luts;
            obj.mgs=mgs;
            obj.fpga=fpga;
            obj.L.info('init',['visibility is set to ' obj.vis])
            % correct wbr modulation
            wbr_idx=-1;
            if isfield(obj.mgs,'data')
                for i=1:length(obj.mgs)
                    if isfield(obj.mgs(i).data.logs,'WTX')
                        wbr_idx=i;
                    end
                end
                obj = correct_data_wbr(obj,wbr_idx);
                obj.L.warn('init','FT_Cessna no MGS found')
            end
            %set defaults
            set(groot,'defaultAxesFontSize',16)
            set(groot,'defaultLineLineWidth',2)
            set(groot,'defaultAxesFontName','Arial')
            set(groot,'defaultAxesFontWeight','bold')
        end
        function obj=set_transcipt(obj,transcript_csv)
            raw=readtable(transcript_csv, 'delimiter', ',');
            [Y, M, D, H, MN, S] = datevec(raw.utc);
            raw.utc_sec=H*3600+MN*60+S;
            obj.transcript=raw;
        end
        %% Basic functions
        function fig=plot_gps_3Dtrajectory(obj)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            [lon,lat,alt]= obj.ref_data.get_all_pos();
            plot3(lon,lat,alt,...
                'DisplayName','GPS position (UBlox)');
            xlabel('Longitude (DD)');
            ylabel('Latitude (DD)');
            zlabel('Altitude (m)');
            legend('show','Location','NorthEastOutside');
            
        end
        function fig= plot_gps_3Dtrajectory_all(obj)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            % add marker
            p2=plot3(obj.info.arrival.longitude,obj.info.arrival.latitude,...
                obj.info.arrival.elevation_m,...
                '+','MarkerSize',15,...
                'DisplayName',[obj.info.arrival.name ' (Arrival)']);
            p3=plot3(obj.info.departure.longitude,obj.info.departure.latitude,...
                obj.info.departure.elevation_m,...
                'o','MarkerSize',15,...
                'DisplayName',[obj.info.departure.name ' (Departure)']);
            % add dme stations
            nav_f=unique([obj.sdar.data.other.nav1.value ...
                obj.sdar.data.other.nav2.value]);
            for i=1:length(nav_f)
                if obj.luts.nav_lut.isKey(nav_f(i))
                    nav=obj.luts.nav_lut(nav_f(i));
                    p(i)=plot3(nav.lon_dd,nav.lat_dd,...
                        nav.elevation_m,...
                        's','MarkerSize',15,...
                        'DisplayName',[upper(nav.id) ' (DME)']);
                end
            end
            % add MGS
            if isfield(obj.mgs(1).info)
                p4=plot3(obj.mgs(1).info.longitude,obj.mgs.info(1).latitude,...
                    obj.mgs(1).info.elevation_m,'d','MarkerSize',15,...
                    'DisplayName','MGS');
                %refresh legend
                legend('off');
                legend('show','Location','NorthEastOutside');
            end
        end
        function fig= plot_gps_2Dtrajectory_all(obj)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            % add marker
            p2=plot(obj.info.arrival.longitude,obj.info.arrival.latitude,...
                '+','MarkerSize',15,...
                'DisplayName',[obj.info.arrival.name ' (Arrival)']);
            p3=plot(obj.info.departure.longitude,obj.info.departure.latitude,...
                'o','MarkerSize',15,...
                'DisplayName',[obj.info.departure.name ' (Departure)']);
            % add dme stations
            nav_f=unique([obj.sdar.data.other.nav1.value ...
                obj.sdar.data.other.nav2.value]);
            for i=1:length(nav_f)
                if obj.luts.nav_lut.isKey(nav_f(i))
                    nav=obj.luts.nav_lut(nav_f(i));
                    p(i)=plot(nav.lon_dd,nav.lat_dd,...
                        's','MarkerSize',15,...
                        'DisplayName',[upper(nav.id) ' (DME)']);
                end
            end
            % add MGS
            if isfield(obj.mgs(1).info)
                p4=plot(obj.mgs(1).info.longitude,obj.mgs(1).info.latitude,...
                    'DisplayName','MGS');
                %refresh legend
                legend('off');
                l=legend('show','Location','NorthEastOutside');
            end
        end
        function fig=plot_gps_2Dtrajectory(obj)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            [lon,lat,alt]= obj.ref_data.get_all_pos();
            plot(lon,lat)
            xlabel('Longitude (DD)');
            ylabel('Latitude (DD)');
            legend('GPS position (UBlox)','Location','NorthEastOutside');
            
        end
        function fig=plot_modes_trajectory_r1(obj)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            % add marker
            obj.mark_airports
            obj.mark_dme_station
            obj.mark_mgs
            % get modes
            modes=unique([obj.sdar.data.other.radio1.value]);
            for mod=modes
                t_spans=obj.sdar.data.other.radio1(...
                    strcmp([obj.sdar.data.other.radio1.value],mod));
                [t,lon,lat,alt]=obj.ref_data.event_struct2pos([t_spans]);
                color=obj.colors(obj.luts.mode_lut(char(mod)));
                plot(lon,lat,...
                    [color '.'],'MarkerSize',8,'DisplayName',char(mod))
            end
            l=legend('show','Location','NorthEastOutside');
            xlabel('Longitude (DD)');
            ylabel('Latitude (DD)');
        end
        function fig=plot_modes_trajectory_r2(obj)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            % add marker
            obj.mark_airports
            obj.mark_dme_station
            obj.mark_mgs
            % get modes
            modes=unique([obj.sdar.data.other.radio2.value]);
            for mod=modes
                t_spans=obj.sdar.data.other.radio2(...
                    strcmp([obj.sdar.data.other.radio2.value],mod));
                [t,lon,lat,alt]=obj.ref_data.event_struct2pos([t_spans]);
                color=obj.colors(obj.luts.mode_lut(char(mod)));
                plot(lon,lat,...
                    [color '.'],'MarkerSize',8,'DisplayName',char(mod))
            end
            l=legend('show','Location','NorthEastOutside');
            xlabel('Longitude (DD)');
            ylabel('Latitude (DD)');
        end
        function fig=plot_modes_trajectory(obj)
            
            h1=obj.plot_modes_trajectory_r1;
            set(h1,'Visible','off');
            ax1 = gca;
            h2=obj.plot_modes_trajectory_r2;
            set(h2,'Visible','off');
            ax2 = gca;
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            s1 = subplot(2,1,1);
            s2 = subplot(2,1,2);
            fig1 = get(ax1,'children');
            fig2 = get(ax2,'children');
            copyobj(fig1,s1);
            copyobj(fig2,s2);
            s1 = subplot(2,1,1);
            xlabel('Longitude (DD)');
            ylabel('Latitude (DD)');
            title('Radio 1')
            l1=legend('show','Location','NorthEastOutside');
            s2 = subplot(2,1,2);
            xlabel('Longitude (DD)');
            ylabel('Latitude (DD)');
            title('Radio 2')
            l2=legend('show','Location','NorthEastOutside');
            suptitle([obj.info.date '  ' 'Radios Mode vs Position'])
            linkaxes([s1,s1],'xy')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content( fig, 'Radios Mode vs Position', ...
                fileread('data/plot_modes_trajectory.txt'), 1, 'SDAR General' );
            
            % ------------------------------------------------------------%
            
            
        end
        
        function fig=plot_modes_time(obj,hour_diff)
            
            fig_name = [obj.info.date ' ' 'MM-SDAR Mode vs time'];
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            
            
            set(fig, 'Visible',obj.vis)
            fig11=subplot(2,1,1);
            % Radio1
            values=[];
            for i=1:length(obj.sdar.data.other.radio1)
                values=[values ...
                    obj.luts.mode_lut(char(obj.sdar.data.other.radio1(i).value))];
            end
            stairs(([obj.sdar.data.other.radio1.start]-hour_diff*3600)/3600/24....
                ,values,'LineWidth',3)
            datetick('x', 'HH:MM:SS')
            set(gca, 'Ytick',1:7,'YTickLabel',...
                {'OFF' 'SBY' 'TMS' 'ADSB' 'DME1' 'DME2' 'WBR'})
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('Radio Mode');
            title('Radio 1')
            % Radio2
            values=[];
            for i=1:length(obj.sdar.data.other.radio2)
                values=[values ...
                    obj.luts.mode_lut(char(obj.sdar.data.other.radio2(i).value))];
            end
            fig21=subplot(2,1,2);
            stairs(([obj.sdar.data.other.radio2.start]-hour_diff*3600)/3600/24....
                ,values,'LineWidth',3)
            datetick('x', 'HH:MM:SS')
            set(gca, 'Ytick',1:7,'YTickLabel',...
                {'OFF' 'SBY' 'TMS' 'ADSB' 'DME1' 'DME2' 'WBR'})
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('Radio Mode');
            title('Radio2')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content( fig, 'MM-SDAR Mode vs time', ...
                fileread('data/plot_modes_time.txt'), 1, 'SDAR General' );
            
            % ------------------------------------------------------------%
            
        end
        function fig=plot_symon_time(obj,hour_diff)
            % copied from plot_modes_time
            
            fig_name = [obj.info.date ' ' 'MM-SDAR CPUs'];
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            
            set(fig, 'Visible',obj.vis)
            fig12=subplot(3,1,2);
            % Radio1
            values=[];
            for i=1:length(obj.sdar.data.other.radio1)
                values=[values ...
                    obj.luts.mode_lut(char(obj.sdar.data.other.radio1(i).value))];
            end
            stairs(([obj.sdar.data.other.radio1.start]-hour_diff*3600)/3600/24....
                ,values,'LineWidth',6)
            datetick('x', 'HH:MM:SS')
            set(gca, 'Ytick',1:7,'YTickLabel',...
                {'OFF' 'SBY' 'TMS' 'ADSB' 'DME1' 'DME2' 'WBR'})
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('Radio Mode');
            title('Radio 1 Mode')
            % Radio2
            values=[];
            for i=1:length(obj.sdar.data.other.radio2)
                values=[values ...
                    obj.luts.mode_lut(char(obj.sdar.data.other.radio2(i).value))];
            end
            fig13=subplot(3,1,3);
            stairs(([obj.sdar.data.other.radio2.start]-hour_diff*3600)/3600/24....
                ,values,'LineWidth',6)
            datetick('x', 'HH:MM:SS')
            set(gca, 'Ytick',1:7,'YTickLabel',...
                {'OFF' 'SBY' 'TMS' 'ADSB' 'DME1' 'DME2' 'WBR'})
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('Radio Mode');
            title('Radio 2 Mode')
            % added part
            temp=str2double({obj.sdar.data.logs.sysmon.temp_max.val});
            cpus=str2double({obj.sdar.data.logs.sysmon.CPUs.val});
            fig11=subplot(3,1,1);
            set(fig11,'defaultAxesColorOrder',[[0 0 1]; [1 0 0]]);
            yyaxis left
            plot(([obj.sdar.data.logs.sysmon.temp_max.sdar_utc]-hour_diff*3600)/3600/24,...
                temp,'r')
            ylabel('CPUs Core Temperature (°C)');
            yyaxis right
            plot(([obj.sdar.data.logs.sysmon.CPUs.sdar_utc]-hour_diff*3600)/3600/24,cpus,...
                'b')
            datetick('x', 'HH:MM:SS')
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('CPUs Load (%)');
            title('CPU Load and Temperature vs Time')
            legend('CPUs Temperature','CPUs Load')
            % finishing touch
            linkaxes([fig11,fig12,fig13],'x')
            suptitle([obj.info.date '::' 'MM-SDAR CPUs'])
            
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content( fig, 'MM-SDAR CPUs', ...
                fileread('data/plot_symon_time.txt'), 1, 'SDAR General' );
            
            % ------------------------------------------------------------%
            
        end
        
        function res=get_table_modes_time(obj)
            
            modes=unique([obj.sdar.data.other.radio1.value...
                obj.sdar.data.other.radio2.value ]);
            Radio1=[];
            Radio2=[];
            for mode=modes
                filter1=obj.sdar.data.other.radio1( ...
                    strcmp([obj.sdar.data.other.radio1.value],mode));
                filter2=obj.sdar.data.other.radio2( ...
                    strcmp([obj.sdar.data.other.radio2.value],mode));
                Radio1=[Radio1;...
                    sum([filter1.end]-[filter1.start])];
                Radio2=[Radio2;...
                    sum([filter2.end]-[filter2.start])];
            end
            res = table(Radio1,Radio2,'RowNames',modes.');
            
        end
        function fig=fig_table_modes_time(obj)
            
            % Table
            res=obj.get_table_modes_time();
            
            Radio1=cellstr(datestr(table2array(res(:,1))/3600/24,'HH:MM:SS.FFF'));
            Radio2=cellstr(datestr(table2array(res(:,2))/3600/24,'HH:MM:SS.FFF'));
            tab=table(Radio1,Radio2,'RowNames',res.Row);
            
            
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            obj.table_figure(tab);
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, 'MM-SDAR modes total run times', ...
                fileread('data/fig_table_modes_time.txt'), 1, 'SDAR General', ...
                'table', tab);
            % ------------------------------------------------------------%
            
            
        end
        function fig=pie_modes_time(obj)
            res=obj.get_table_modes_time();
            %radio 1
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            
            %radio 1
            subplot(1,2,1)
            p=[res.Radio1]/sum([res.Radio1])*100;
            group_idx=find(p>0 & p < 1);% variables to group
            vals=res.Radio1;
            nlabs=res.Row;
            if length(group_idx)>1
                temp1=vals;
                temp2=nlabs;
                vals(group_idx)=[];
                nlabs(group_idx)=[];
                vals=[vals; sum(temp1(group_idx))];
                nlabs=[nlabs; {strjoin(temp2(group_idx),'|')}];
            end
            lab=strcat(char(nlabs));
            h=pie(vals,cellstr(lab));
            set(h(2:2:end),'FontSize',...
                16,'FontName','Arial','FontWeight','Bold')
            for idx=2:2:length(h)
                sys_idx=find(strcmp(res.Row,h(idx).String));
                if isempty(sys_idx)
                    sys_idx=4;% OFF
                    sys_val=vals(end);
                else
                    sys_val=res.Radio1(sys_idx);
                end
                h(idx-1).FaceColor=obj.colors(sys_idx);
                h(idx).String=[h(idx).String ' (' ...
                    num2str(floor(sys_val/sum(res.Radio1)*100)) '%)'];
            end
            title('Radio 1')
            
            %radio 2
            subplot(1,2,2)
            p=[res.Radio2]/sum([res.Radio2])*100;
            vals=res.Radio2;
            nlabs=res.Row;
            group_idx=find(p>0 & p < 1);% variables to group
            if length(group_idx)>1
                temp1=vals;
                temp2=nlabs;
                vals(group_idx)=[];
                nlabs(group_idx)=[];
                vals=[vals; sum(temp1(group_idx))];
                nlabs=[nlabs; {strjoin(temp2(group_idx),'|')}];
            end
            lab=char(nlabs);
            h=pie(vals,cellstr(lab));
            set(h(2:2:end),'FontSize',...
                16,'FontName','Arial','FontWeight','Bold')
            for idx=2:2:length(h)
                sys_idx=find(strcmp(res.Row,h(idx).String));
                if isempty(sys_idx)
                    sys_idx=4;% OFF
                    sys_val=vals(end);
                else
                    sys_val=res.Radio2(sys_idx);
                end
                h(idx-1).FaceColor=obj.colors(sys_idx);
                h(idx).String=[h(idx).String ' (' ...
                    num2str(floor(sys_val/sum(res.Radio2)*100)) '%)'] ;
            end
            title('Radio 2')
            suptitle([obj.info.date '::' 'MM-SDAR Mode Summary']);
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, 'MM-SDAR Mode Summary', ...
                fileread('data/pie_modes_time.txt'), 1, 'SDAR General');
            
            % ------------------------------------------------------------%
        end
        
        function fig=plot_gains(obj,radio_num,ref,hour_diff)
            rn=num2str(radio_num);
            fig_name = ['Radio ' rn ' AGC Performance'];
            
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            
            u2d=@(u)(u-hour_diff*3600)/3600/24;
            gains_t=struct2table(...
                obj.sdar.data.logs.(['AGC' rn]).(['Rx' rn 'gains']));
            if isfield(obj.sdar.data.logs.(['AGC' rn]),'dec')
                gains_t=[gains_t;struct2table(...
                    obj.sdar.data.logs.(['AGC' rn]).dec)];
            end
            if isfield(obj.sdar.data.logs.(['AGC' rn]),'dec')
                gains_t=[gains_t;struct2table(...
                    obj.sdar.data.logs.(['AGC' rn]).inc)];
            end
            gains_t=sortrows(gains_t);
            [C,ia,ic] = unique(gains_t.sdar_utc);
            gains_t=gains_t(ia,:);
            
            s3=subplot(313);
            hold on
            p1=plot(u2d(gains_t.sdar_utc),gains_t.gain1,...
                'DisplayName','Gain1');
            p2=plot(u2d(gains_t.sdar_utc),gains_t.gain2,...
                'DisplayName','Gain2');
            p3=plot(u2d(gains_t.sdar_utc),gains_t.gain3,...
                'DisplayName','Gain3');
            legend('show')
            datetick('x', 'HH:MM:SS')
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('Gain (dB)');
            title('RX gains')
            s2=subplot(312);
            rssi_t=struct2table(obj.sdar.data.logs.(['AGC' rn]).RSSI);
            if iscellstr(rssi_t.val)
                rssi_t.val=str2double(rssi_t.val);
            end
            rssi_t=rssi_t(rssi_t.val>-200,:);
            igains=interp1(gains_t.sdar_utc,...
                gains_t.gain1+gains_t.gain2+gains_t.gain3,...
                rssi_t.sdar_utc,'previous','extrap');
            hold on
            yyaxis left
            plot(u2d(rssi_t.sdar_utc),rssi_t.val,...
                'DisplayName','RSSI')
            ylabel('RSSI (dBFS)');
            yyaxis right
            plot(u2d(rssi_t.sdar_utc),igains,...
                'DisplayName','gains')
            legend('show')
            datetick('x', 'HH:MM:SS')
            ylabel('Gain (dB)');
            title('Sum of RX gains vs. RSSI')
            s1=subplot(311);
            plot(u2d(rssi_t.sdar_utc),rssi_t.val-igains+ref,...
                'DisplayName',['RSSI - gains +(' num2str(ref) ')'])
            ylabel('Power (dBm)');
            title('Estimated RX power')
            legend('show')
            datetick('x', 'HH:MM:SS')
            linkaxes([s1,s2,s3],'x')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, fig_name, ...
                fig_name, 1, 'SDAR General');
            
            % ------------------------------------------------------------%
        end
        %% DME
        function fig=plot_dme_distance(obj,dme_id,station,hour_diff)
            %dme id ex. 'DME1'
            
            fig_name = [[obj.info.date ' ' dme_id ...
                ' Range Relative to ' upper(station)]];
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            
            
            set(fig, 'Visible',obj.vis)
            hold on
            dist_struct=obj.sdar.data.logs.(dme_id).DME_dist.(station);
            %plot GPS slant
            ref_slant=obj.utc2slant_range([dist_struct.sdar_utc],...
                obj.luts.nav_info.(station).lon_dd,...
                obj.luts.nav_info.(station).lat_dd,...
                obj.luts.nav_info.(station).elevation_m);
            t_days=([dist_struct.sdar_utc]-hour_diff*3600)/3600/24;
            p1=scatter(t_days,ref_slant/1852,...
                'DisplayName','GPS Slant Range (Interpn)');
            %plot DME
            p2=scatter(t_days,[dist_struct.val],...
                'DisplayName',[dme_id ' Slant Range']);
            
            datetick('x', 'HH:MM:SS')
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('Distance in NM');
            legend('show')
            
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [dme_id ' Range Relative to ' upper(station)], ...
                fileread('data/plot_dme_distance.txt'), 2, ['SDAR ' dme_id])
            
            % ------------------------------------------------------------%
            
            
        end
        function fig=plot_dme_error(obj,dme_id,station,hour_diff)
            %dme id ex. 'DME1'
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            dist_struct=obj.sdar.data.logs.(dme_id).DME_dist.(station);
            %plot dme error
            ref_slant=obj.utc2slant_range([dist_struct.sdar_utc],...
                obj.luts.nav_info.(station).lon_dd,...
                obj.luts.nav_info.(station).lat_dd,...
                obj.luts.nav_info.(station).elevation_m);
            t_days=([dist_struct.sdar_utc]-hour_diff*3600)/3600/24;
            p1=scatter(t_days,ref_slant/1852-[dist_struct.val],...
                'DisplayName','GPS Slant Range (Interpn) - DME');
            %plot ref
            p2=plot(t_days,0.17*ones(1,length(t_days)),...
                'DisplayName','MOPS Error High Bound');
            p3=plot(t_days,-0.17*ones(1,length(t_days)),...
                'DisplayName','MOPS Error Low Bound');
            
            datetick('x', 'HH:MM:SS')
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('Absolute Distance Error in NM');
            legend('show')
            
            
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [dme_id ...
                ' Error Relative to ' upper(station)], ...
                'plot_dme_error.txt', 2, ['SDAR ' dme_id])
            
            % ------------------------------------------------------------%
            
            
        end
        function fig=hist_dme_error(obj,dme_id,station)
            %dme id ex. 'DME1'
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            dist_struct=obj.sdar.data.logs.(dme_id).DME_dist.(station);
            %plot dme error
            ref_slant=obj.utc2slant_range([dist_struct.sdar_utc],...
                obj.luts.nav_info.(station).lon_dd,...
                obj.luts.nav_info.(station).lat_dd,...
                obj.luts.nav_info.(station).elevation_m);
            %             p1=histogram(ref_slant/1852-[dist_struct.val],...
            %                 [min(ref_slant/1852-[dist_struct.val]):0.08:max(ref_slant/1852-[dist_struct.val])],...
            %                 'DisplayName','DME distance count (bin=0.08)');
            p1=histogram(ref_slant/1852-[dist_struct.val],...
                'DisplayName','DME distance count (bin=0.08)');
            m_count=max(p1.BinCounts);
            p2=area([-0.17 0.17],[m_count m_count],'FaceColor','none',...
                'EdgeColor',[0 1 0],'LineStyle',':',...
                'LineWidth',3,...
                'DisplayName','MOPS Valid DME values');
            uistack(p1,'top')
            xlabel('Absolute Distance Error in NM');
            ylabel('Number of records');
            legend('show')
            
            
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [dme_id ...
                ' Error Distribution Relative to ' upper(station)], ...
                'hist_dme_error.txt', 2, ['SDAR ' dme_id])
            
            % ------------------------------------------------------------%
            
        end
        function fig=plot_dme_enu(obj,dme_id,station)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            % get pos when DME & station are in current mode
            %position for when station is active
            event_struct0=obj.sdar.data.other.(dme_id)(...
                [obj.sdar.data.other.(dme_id).value]==...
                obj.luts.nav_info.(station).navf);
            [utc_time0,lon0,lat0,alt0]=obj.ref_data.event_struct2pos([event_struct0]);
            %position for when DME is active
            %for radio 1
            event_struct1=obj.sdar.data.other.radio1(...
                strcmp(dme_id,[obj.sdar.data.other.radio1.value]));
            event_struct2=obj.sdar.data.other.radio2(...
                strcmp(dme_id,[obj.sdar.data.other.radio2.value]));
            %for radio 2
            event_struct3=[event_struct1 event_struct2];
            [utc_time3,lon3,lat3,alt3]=obj.ref_data.event_struct2pos([event_struct3]);
            %combine when dme_id and station are valide
            [utc_time,idx0,idx3]=intersect(utc_time0,utc_time3);
            [xr,yr,zr]=obj.utc2enu(utc_time,...
                obj.luts.nav_info.(station).lat_dd,...
                obj.luts.nav_info.(station).lon_dd,...
                obj.luts.nav_info.(station).elevation_m);
            plot3(xr/1852,yr/1852,zr/1852,'.',...
                'DisplayName',['Position when ' dme_id '=' station])
            plot3(0,0,0,'s','MarkerSize',15,...
                'DisplayName',[upper(station) 'Station'])
            text(0,0,0,['\leftarrow ' upper(station)],'FontSize',15)
            % plot DME records
            dme_utc=[obj.sdar.data.logs.(dme_id).DME_dist.(station).sdar_utc];
            [xr,yr,zr]=obj.utc2enu(dme_utc,...
                obj.luts.nav_info.(station).lat_dd,...
                obj.luts.nav_info.(station).lon_dd,...
                obj.luts.nav_info.(station).elevation_m);
            
            plot3(xr/1852,yr/1852,zr/1852,'+',...
                'DisplayName','DME records position(interpn)')
            xlabel('West \leftrightarrow East (NM)');
            ylabel('South \leftrightarrow North (NM)');
            zlabel('Down \leftrightarrow Up (NM)');
            legend('show')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [dme_id ' ENU Position for ' upper(station)], ...
                'plot_dme_enu.txt', 2, ['SDAR ' dme_id])
            
            % ------------------------------------------------------------%
            
            
        end
        function fig=pie_dme_error(obj,dme_id,station)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            dist_struct=obj.sdar.data.logs.(dme_id).DME_dist.(station);
            %plot dme error
            ref_slant=obj.utc2slant_range([dist_struct.sdar_utc],...
                obj.luts.nav_info.(station).lon_dd,...
                obj.luts.nav_info.(station).lat_dd,...
                obj.luts.nav_info.(station).elevation_m);
            error=ref_slant/1852-[dist_struct.val];
            s_good=sum(abs(error)<=0.17);
            s_bad=sum(abs(error)>0.17);
            p=pie([s_good; s_bad],[0 0]);
            legend({'Measures Within MOPS Tolerances' 'Measures Beyond MOPS Tolerances'},...
                'FontSize',obj.legend_size,'Location','northeastoutside')
            
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [dme_id ...
                ' Errors for ' upper(station)], ...
                'pie_dme_error.txt', 2, ['SDAR ' dme_id])
            
            % ------------------------------------------------------------%
            
        end
        function fig=hist_dme_rate(obj,dme_id,station,hour_diff,...
                window_lenght)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            u2d=@(u)(u-hour_diff*3600)/3600/24;
            winlen=window_lenght;
            res=obj.dme_track(dme_id,station,winlen);
            s1=subplot(8,1,[1:6]);
            gps_dist=(1/1852)*obj.utc2slant_range(res.utc_bins,...
                obj.luts.nav_info.(station).lon_dd,...
                obj.luts.nav_info.(station).lat_dd,...
                obj.luts.nav_info.(station).elevation_m);
            
            yyaxis left
            p1(1)=bar(u2d(res.utc_bins),res.count,'BarWidth',1,...
                'FaceColor','b','EdgeColor','b',...
                'DisplayName','DME Records');
            ylabel('Number of Records')
            
            yyaxis right
            hold on
            p1(3)=plot(u2d(res.utc_bins(~res.dme_on)),...
                gps_dist(~res.dme_on),...
                'sk','MarkerFaceColor','k',...
                'DisplayName','GPS distance: DME Off');
            p1(4)=plot(u2d(res.utc_bins(res.dme_on & res.is_tracking)),...
                gps_dist(res.dme_on & res.is_tracking),...
                'sg','MarkerFaceColor','g',...
                'DisplayName','GPS distance: DME Tracking');
            p1(5)=plot(u2d(res.utc_bins(res.dme_on & ~res.is_tracking)),...
                gps_dist(res.dme_on & ~res.is_tracking),...
                'sr','MarkerFaceColor','r',...
                'DisplayName','GPS distance: DME Not Tracking');
            ylabel('Distance in NM')
            legend('show')
            set(s1,'XTick',[])
            hold on
            
            s2=subplot(8,1,[7:8]);
            hold on
            p2(1)=bar(u2d(res.utc_bins),~res.dme_on,'BarWidth',1,...
                'FaceColor','k',...
                'DisplayName','DME Off');
            p2(2)=bar(u2d(res.utc_bins),res.is_tracking,'BarWidth',1,...
                'FaceColor','g',...
                'DisplayName','DME Tracking');
            p2(3)=bar(u2d(res.utc_bins),res.dme_on&~res.is_tracking,...
                'BarWidth',1,...
                'FaceColor','r',...
                'DisplayName','DME Not Tracking');
            datetick('x', 'HH:MM:SS')
            ylim([0.25 2])
            set(s2,'YTick',[])
            %s2.Visible='off';
            legend('show')
            grid('minor')
            xlabel(['UTC Time - ' num2str(hour_diff)])
            hold off
            linkaxes([s2,s1],'x')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [dme_id ...
                ' Tracking Time for ' upper(station)], ...
                'hist_dme_rate.txt', 2, ['SDAR ' dme_id])
            
            % ------------------------------------------------------------%
        end
        function fig=tab_dme_summary(obj,dme_id,station,window_lenght)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            % General
            dme_st=obj.sdar.data.logs.(dme_id).DME_dist.(station);
            res.p={'Max Distance'};
            res.v=max([dme_st.val]);
            res.u={' NM'};
            
            res.p=[res.p; 'Min Distance']; res.u=[res.u; ' NM'];
            res.v=[res.v; min([dme_st.val])];
            res.p=[res.p; 'Num of samples'];res.u=[res.u; ' '];
            res.v=[res.v; length([dme_st.val])];
            % Error
            ref_slant=obj.utc2slant_range([dme_st.sdar_utc],...
                obj.luts.nav_info.(station).lon_dd,...
                obj.luts.nav_info.(station).lat_dd,...
                obj.luts.nav_info.(station).elevation_m)/1852;
            dme_diff=[dme_st.val]-ref_slant;
            res.p=[res.p; 'Error: Max'];res.u=[res.u; ' NM'];
            res.v=[res.v; max(abs(dme_diff))];
            res.p=[res.p; 'Error: Min'];res.u=[res.u; ' NM'];
            res.v=[res.v; min(abs(dme_diff))];
            res.p=[res.p; 'Error: Mean'];res.u=[res.u; ' NM'];
            res.v=[res.v; mean(dme_diff)];
            res.p=[res.p; 'Error: Median'];res.u=[res.u; ' NM'];
            res.v=[res.v; median(dme_diff)];
            res.p=[res.p; 'Error: Variance'];res.u=[res.u; ' NM²'];
            res.v=[res.v; var(dme_diff)];
            res.p=[res.p; 'Error: Std Deviation '];res.u=[res.u; ' NM'];
            res.v=[res.v; std(dme_diff)];
            res.p=[res.p; 'Error: Correct'];res.u=[res.u; ' %'];
            res.v=[res.v; round(...
                sum(abs(dme_diff)<0.17)/length(dme_diff)*100,...
                0)];
            % Tracking
            trx_res=obj.dme_track(dme_id,station,window_lenght);
            res.p=[res.p; 'Tracking Time '];res.u=[res.u; ' %'];
            res.v=[res.v; round(...
                100*sum(trx_res.is_tracking)/sum(trx_res.dme_on),...
                0)];
            res_tab=struct2table(res);
            res_tab.Properties.VariableNames={'Param','Value','Unit'};
            obj.table_figure(res_tab);
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [dme_id ...
                ' Summary for ' upper(station)], ...
                'Summary', 2, ['SDAR ' dme_id],'table',res_tab)
            
            % ------------------------------------------------------------%
        end
        function result=dme_track(obj,dme_id,station,...
                window_lenght)
            winlen=window_lenght;
            utc_time=obj.ref_data.get_position;
            utc_bins=[utc_time(1):winlen:utc_time(end)];
            dme_utc=[obj.sdar.data.logs.(dme_id).DME_dist.(station).sdar_utc];
            dme_cnt=histc(dme_utc,utc_bins);
            % get dme on/off time
            % 1 . filter by radio
            r1_ui=[obj.sdar.data.other.radio1(...
                strcmp([obj.sdar.data.other.radio1.value],dme_id))];
            r2_ui=[obj.sdar.data.other.radio2(...
                strcmp([obj.sdar.data.other.radio2.value],dme_id))];
            dme_ui=[r1_ui r2_ui];
            dme_on=zeros(1,length(utc_bins));
            for i=1:length(dme_ui)
                dme_on=dme_on |...
                    (utc_bins>=dme_ui(i).start & utc_bins<=dme_ui(i).end);
            end
            % 2 . filter by station
            statation_ui=obj.sdar.data.other.(dme_id)(...
                [obj.sdar.data.other.(dme_id).value]==obj.luts.nav_info.(station).navf);
            st_on=zeros(1,length(utc_bins));
            for i=1:length(statation_ui)
                st_on=st_on |...
                    (utc_bins>=statation_ui(i).start & utc_bins<=statation_ui(i).end);
            end
            result=table();
            result.utc_bins=utc_bins.';
            result.count=dme_cnt.';
            result.dme_on=dme_on.';
            result.station_on=st_on.';
            result.is_tracking= [dme_cnt>0 & st_on &dme_on].';
            %             figure
            
            
        end
        %% markers
        function mark_airports(obj)
            p2=plot3(obj.info.arrival.longitude,obj.info.arrival.latitude,...
                obj.info.arrival.elevation_m,...
                '+','MarkerSize',15,...
                'DisplayName',[obj.info.arrival.name ' (Arrival)']);
            p3=plot3(obj.info.departure.longitude,obj.info.departure.latitude,...
                obj.info.departure.elevation_m,...
                'o','MarkerSize',15,...
                'DisplayName',[obj.info.departure.name ' (Departure)']);
        end
        function mark_dme_station(obj)
            % add all stations
            nav_f=unique([obj.sdar.data.other.DME1.value ...
                obj.sdar.data.other.DME2.value]);
            if length(nav_f) ==1 && nav_f == 0;return;end
            for i=1:length(nav_f)
                if obj.luts.nav_lut.isKey(nav_f(i))
                    nav=obj.luts.nav_lut(nav_f(i));
                    p(i)=plot3(nav.lon_dd,nav.lat_dd,...
                        nav.elevation_m,...
                        's','MarkerSize',15,...
                        'DisplayName',[upper(nav.id) ' (DME)']);
                end
            end
        end
        function mark_mgs(obj)
            % add MGS
            if isfield(obj.mgs(1),'info')&& isstruct(obj.mgs(1).info)
                p4=plot3(obj.mgs(1).info.longitude,obj.mgs(1).info.latitude,...
                    obj.mgs(1).info.elevation_m,'d','MarkerSize',15,...
                    'DisplayName','MGS');
            end
        end
        
        %% WBR
        function rate_return = get_data_rate(obj, value)
            rate_return = obj.luts.wbr_modcod(value+1);
        end
        
        % Correct things
        function correct_obj = correct_data_wbr(obj,wbr_idx)
            % Avoid 0
            if wbr_idx==-1
                return;
            end
            correct_obj = obj;
            if (isfield(obj.sdar.data.logs,'WRX'))
                if(isfield(obj.sdar.data.logs.WRX, 'BER'))
                    dist_struct = obj.sdar.data.logs.WRX.BER;
                    l = fieldnames(dist_struct);
                    for p=1:1:length(l)
                        for q=1:1:length(dist_struct.(l{p}))
                            if (dist_struct.(l{p})(q).val == 0)
                                dist_struct.(l{p})(q).val = 10e-9;
                            end
                        end
                    end
                    obj.sdar.data.logs.WRX.BER = dist_struct;
                    
                    correct_obj = obj;
                    new_obj = obj;
                    dist_struct = obj.sdar.data.other.wbr_modcode;
                    if (size(dist_struct,1) == 1)   % Maybe having a problem with the log
                        try
                            new_struct = obj.sdar.data.logs.UI.MODW;
                            if isfield(obj.sdar.data.logs.UI,'CODW')
                                for q=1:1:size(obj.sdar.data.logs.UI.CODW,1)
                                    new_struct(size(new_struct,1)+1) = obj.sdar.data.logs.UI.CODW(q);
                                end
                                list_sort = sort([new_struct.sdar_utc]);
                                new_struct2 = new_struct(1);
                                for q=2:1:size(list_sort,2)
                                    for m=2:1:size(new_struct,1)
                                        if ((new_struct(m).sdar_utc) == list_sort(q))
                                            new_struct2(q) = new_struct(m);
                                        end
                                    end
                                end
                            else
                                new_struct2 = new_struct;
                            end
                            
                            new_struct = [];
                            new_struct.value = 0;
                            new_struct.start = dist_struct(1).start;
                            flag_32 = 0;
                            if (new_struct2(1).val ~= '1')
                                new_struct.end = new_struct2(1).sdar_utc;
                            end
                            get_size = size(new_struct2);
                            run_size = get_size(2);
                            if (get_size(1) > get_size(2))
                                run_size = get_size(1);
                            end
                            for q=1:1:run_size
                                % Get COD
                                if ((new_struct2(q).label(1) == 'C') && (str2num(new_struct2(q).val) == 32))
                                    flag_32 = 1;
                                else if (str2num(new_struct2(q).val) == 64)
                                        flag_32 = 0;
                                    end
                                end
                                % Update Mod
                                if ((new_struct2(q).label(1) == 'M') && (str2num(new_struct2(q).val) ~= 0))
                                    new_struct(size(new_struct,2)).end = new_struct2(q).sdar_utc;
                                    new_struct(size(new_struct,2)+1).value = (str2num(new_struct2(q).val)-1)*2 + flag_32;
                                    new_struct(size(new_struct,2)).start = new_struct2(q).sdar_utc;
                                end
                                if (new_struct2(q).label(1) == 'C')
                                    new_struct(size(new_struct,2)).end = new_struct2(q).sdar_utc;
                                    if ((mod(new_struct(size(new_struct,2)).value,2) == 0) && (str2num(new_struct2(q).val) == 32))
                                        new_struct(size(new_struct,2)+1).value = new_struct(size(new_struct,2)).value + 1;
                                    end
                                    if ((mod(new_struct(size(new_struct,2)).value,2) == 1) && (str2num(new_struct2(q).val) == 64))
                                        new_struct(size(new_struct,2)+1).value = new_struct(size(new_struct,2)).value - 1;
                                    end
                                    new_struct(size(new_struct,2)).start = new_struct2(q).sdar_utc;
                                end
                            end
                            new_struct(size(new_struct,2)).end = dist_struct.end;
                            % Delete repeatation
                            q = 2;
                            while (q <= size(new_struct,2))
                                if (new_struct(q).value == new_struct(q-1).value)
                                    new_struct(q-1).end = new_struct(q).end;
                                    new_struct(q) = [];
                                end
                                q = q+1;
                            end
                            
                            
                            % Try to update using WBR MGS
                            try
                                mgs_mod  = [];
                                mgs_mod.value = 0;
                                mgs_mod.start = 0;
                                mgs_mod.end = 0;
                                
                                if isfield(obj.mgs(wbr_idx).data.logs.WTX, 'MOD')
                                    cur_str = obj.mgs(wbr_idx).data.logs.WTX.MOD;
                                    mgs_mod(1).value = cur_str.val;
                                    mgs_mod(1).start = cur_str.sdar_utc;
                                    for i=2:1:size(cur_str,1)
                                        if (cur_str(i).val ~= cur_str(i-1).val)
                                            mgs_mod(length(mgs_mod)).end     = cur_str(i-1).sdar_utc;
                                            mgs_mod(length(mgs_mod)+1).value = cur_str(i).val;
                                            mgs_mod(length(mgs_mod)).start   = cur_str(i).sdar_utc;
                                        end
                                    end
                                    mgs_mod(length(mgs_mod)).end = cur_str(size(cur_str,1)).sdar_utc;
                                end
                                
                                %
                                %                                 % See if new_struct has problem with ACM
                                idx_acm = find([obj.sdar.data.other.wbr_mode.value] == 1);
                                if (idx_acm == length([obj.sdar.data.other.wbr_mode.value])) %% See how to update this
                                    for acm_list=1:1:length(idx_acm)
                                        to_be_update = find(obj.sdar.data.other.wbr_mode(idx_acm(acm_list)).end >= [new_struct.start] & ...
                                            obj.sdar.data.other.wbr_mode(idx_acm(acm_list)).end <= [new_struct.end]);
                                        new_mod =  find([mgs_mod.start] >= [new_struct(to_be_update).start] & ...
                                            [mgs_mod.end] <= [new_struct(to_be_update).end]);
                                        if (to_be_update < length(new_struct) && length(new_mod)>0)
                                            save = new_struct(to_be_update+1:end);
                                            new_struct(to_be_update).end = mgs_mod(new_mod(1)).end;
                                            for new_mod_value=2:1:length(new_mod)
                                                new_struct(to_be_update+new_mod_value-1) = mgs_mod(new_mod(new_mod_value));
                                            end
                                            new_struct(length(new_struct)+1 : length(new_struct) + length(save)) = save;
                                        else if (length(new_mod)>0)
                                                new_struct(to_be_update).end = mgs_mod(new_mod(1)).end;
                                                for new_mod_value=2:1:length(new_mod)
                                                    new_struct(to_be_update+new_mod_value-1) = mgs_mod(new_mod(new_mod_value));
                                                end
                                            end
                                        end
                                    end
                                end
                            catch ME
                                %                                 obj.L.warn('update_WBR_section',['cmd skipped:' cmds{i} ' ' ME.message ...
                                %                                     ' in ' ME.stack(1).name ' line:' num2str(ME.stack(1).line)]);
                                %                                 for stack=ME.stack.'
                                %                                     obj.L.debug(cmds{i},[stack.name ' line: ' num2str(stack.line)] )
                                %                                 end
                            end
                            
                            
                            
                            % Update obj.sdar.data.other.wbr_modcode;
                            if (run_size > 1)
                                new_obj.sdar.data.other.wbr_modcode = new_struct';
                                
                                dist_struct = obj.sdar.data.logs.WRX.x8Rate;
                                new_struct2 = [];
                                new_struct2.DBPSK64= dist_struct.DBPSK64(1);
                                new_struct2.DBPSK32= dist_struct.DBPSK64(1);
                                new_struct2.DQPSK64= dist_struct.DBPSK64(1);
                                new_struct2.DQPSK32= dist_struct.DBPSK64(1);
                                new_struct2.D8PSK64= dist_struct.DBPSK64(1);
                                new_struct2.D8PSK32= dist_struct.DBPSK64(1);
                                new_struct2.D16QAM64=dist_struct.DBPSK64(1);
                                new_struct2.D16QAM32=dist_struct.DBPSK64(1);
                                for q=1:1:size(dist_struct.DBPSK64,1)
                                    a = find((([new_struct.start]<=dist_struct.DBPSK64(q).sdar_utc) + ([new_struct.end]>=dist_struct.DBPSK64(q).sdar_utc)) == 2);
                                    if (length(a) > 0)
                                        switch new_struct(1,max(a)).value
                                            case 0
                                                new_struct2.DBPSK64(size(new_struct2.DBPSK64,2)+1) = dist_struct.DBPSK64(q);
                                            case 1
                                                new_struct2.DBPSK32(size(new_struct2.DBPSK32,2)+1) = dist_struct.DBPSK64(q);
                                            case 2
                                                new_struct2.DQPSK64(size(new_struct2.DQPSK64,2)+1) = dist_struct.DBPSK64(q);
                                            case 3
                                                new_struct2.DQPSK32(size(new_struct2.DQPSK32,2)+1) = dist_struct.DBPSK64(q);
                                            case 4
                                                new_struct2.D8PSK64(size(new_struct2.D8PSK64,2)+1) = dist_struct.DBPSK64(q);
                                            case 5
                                                new_struct2.D8PSK32(size(new_struct2.D8PSK32,2)+1) = dist_struct.DBPSK64(q);
                                            case 6
                                                new_struct2.D16QAM64(size(new_struct2.D16QAM64,2)+1) = dist_struct.DBPSK64(q);
                                            case 7
                                                new_struct2.D16QAM32(size(new_struct2.D16QAM32,2)+1) = dist_struct.DBPSK64(q);
                                        end
                                    end
                                end
                                
                                new_struct2.DBPSK32(1) = [];
                                new_struct2.DQPSK64(1) = [];
                                new_struct2.DQPSK32(1) = [];
                                new_struct2.D8PSK64(1) = [];
                                new_struct2.D8PSK32(1) = [];
                                new_struct2.D16QAM64(1) = [];
                                new_struct2.D16QAM32(1) = [];
                                
                                l = fieldnames(new_struct2);
                                for q=1:1:length(l)
                                    if (size(new_struct2.(l{q}),2) == 0)
                                        new_struct2 = rmfield(new_struct2,l{q});
                                    end
                                end
                                
                                % Update struct
                                new_obj.sdar.data.logs.WRX.x8Rate = new_struct2;
                                
                                dist_struct = obj.sdar.data.logs.WRX.BER;
                                new_struct2 = [];
                                new_struct2.DBPSK64= dist_struct.DBPSK64(1);
                                new_struct2.DBPSK32= dist_struct.DBPSK64(1);
                                new_struct2.DQPSK64= dist_struct.DBPSK64(1);
                                new_struct2.DQPSK32= dist_struct.DBPSK64(1);
                                new_struct2.D8PSK64= dist_struct.DBPSK64(1);
                                new_struct2.D8PSK32= dist_struct.DBPSK64(1);
                                new_struct2.D16QAM64=dist_struct.DBPSK64(1);
                                new_struct2.D16QAM32=dist_struct.DBPSK64(1);
                                for q=1:1:size(dist_struct.DBPSK64,1)
                                    a = find((([new_struct.start]<=dist_struct.DBPSK64(q).sdar_utc) + ([new_struct.end]>=dist_struct.DBPSK64(q).sdar_utc)) == 2);
                                    if (length(a) > 0)
                                        switch new_struct(1,max(a)).value
                                            case 0
                                                new_struct2.DBPSK64(size(new_struct2.DBPSK64,2)+1) = dist_struct.DBPSK64(q);
                                            case 1
                                                new_struct2.DBPSK32(size(new_struct2.DBPSK32,2)+1) = dist_struct.DBPSK64(q);
                                            case 2
                                                new_struct2.DQPSK64(size(new_struct2.DQPSK64,2)+1) = dist_struct.DBPSK64(q);
                                            case 3
                                                new_struct2.DQPSK32(size(new_struct2.DQPSK32,2)+1) = dist_struct.DBPSK64(q);
                                            case 4
                                                new_struct2.D8PSK64(size(new_struct2.D8PSK64,2)+1) = dist_struct.DBPSK64(q);
                                            case 5
                                                new_struct2.D8PSK32(size(new_struct2.D8PSK32,2)+1) = dist_struct.DBPSK64(q);
                                            case 6
                                                new_struct2.D16QAM64(size(new_struct2.D16QAM64,2)+1) = dist_struct.DBPSK64(q);
                                            case 7
                                                new_struct2.D16QAM32(size(new_struct2.D16QAM32,2)+1) = dist_struct.DBPSK64(q);
                                        end
                                    end
                                end
                                
                                new_struct2.DBPSK32(1) = [];
                                new_struct2.DQPSK64(1) = [];
                                new_struct2.DQPSK32(1) = [];
                                new_struct2.D8PSK64(1) = [];
                                new_struct2.D8PSK32(1) = [];
                                new_struct2.D16QAM64(1) = [];
                                new_struct2.D16QAM32(1) = [];
                                
                                l = fieldnames(new_struct2);
                                for q=1:1:length(l)
                                    if (size(new_struct2.(l{q}),2) == 0)
                                        new_struct2 = rmfield(new_struct2,l{q});
                                    end
                                end
                                
                                
                                % Update struct
                                new_obj.sdar.data.logs.WRX.BER = new_struct2;
                            end
                            
                        catch ME % TO_DO: What to put here ??
                            %                             obj.L.warn('update_WBR_section',['cmd skipped:' cmds{i} ' ' ME.message ...
                            %                                 ' in ' ME.stack(1).name ' line:' num2str(ME.stack(1).line)]);
                            %                             for stack=ME.stack.'
                            %                                 obj.L.debug(cmds{i},[stack.name ' line: ' num2str(stack.line)] )
                            %                             end
                        end
                    end
                    correct_obj = new_obj;
                end
            end
        end
        
        function fig=plot_wbr_8rate(obj, hour_diff)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            % Mod + Code - Throughput
            s1 = subplot(2,1,1);
            dist_struct = obj.sdar.data.other.wbr_modcode;
            t_days = [];
            values = [];
            sync_time(1) = dist_struct(1).start;
            sync_time(2) = dist_struct(length(dist_struct)).end;
            for i = 1:1:length(dist_struct)
                t_days(2*i-1) = (dist_struct(i).start - hour_diff*3600)/3600/24;
                t_days(2*i) = (dist_struct(i).end - hour_diff*3600)/3600/24;
                values(2*i-1:2*i) = obj.get_data_rate(dist_struct(i).value);
            end
            plot(t_days,values*8/1000.0,'--black', 'LineWidth',obj.line_size)
            hold on
            dist_struct = obj.sdar.data.logs.WRX.x8Rate;
            i=fieldnames(dist_struct);
            t_days = [];
            for q=1:1:length(i)
                if (isfield(dist_struct.(i{q}), 'sdar_utc'))
                    t_days = ([dist_struct.(i{q}).sdar_utc] - hour_diff*3600)/3600/24;
                    scatter(t_days,[dist_struct.(i{q}).val]*8/1000.0,...
                        ['x',obj.colors(q)],...
                        'LineWidth',obj.scatter_size)
                    hold on
                end
            end
            datetick('x', 'HH:MM:SS')
            xlabel(['Time (UTC-' num2str(hour_diff) ')'],'FontSize', obj.label_size);
            ylabel('kbit/s','FontSize', obj.label_size);
            out_legend = [i];
            out_legend = ['Theory Throughput'; out_legend];
            
            legend(out_legend,'FontSize',obj.legend_size,'Location','northeastoutside')
            title('WBR Decode Rate By Modulation', 'FontSize',obj.title_size, 'color', obj.title_color)
            
            % Distance
            s2 = subplot(2,1,2);
            q =sync_time(1):10:sync_time(2);
            ref_slant = obj.utc2slant_range(q,...
                obj.mgs(1).info.longitude,...
                obj.mgs(1).info.latitude,...
                obj.mgs(1).info.elevation_m)/1000*0.539957;
            t_days=(q-hour_diff*3600)/3600/24;
            plot(t_days, ref_slant,'b', 'LineWidth',obj.line_size);
            datetick('x', 'HH:MM:SS')
            title('Distance between Airplane and MGS During WBR Test', 'FontSize',obj.title_size, 'color', obj.title_color)
            xlabel(['Time (UTC-' num2str(hour_diff) ')'],'FontSize', obj.label_size);
            ylabel('Distance (NM)','FontSize', obj.label_size);
            legend({'Distance to MGS'},'FontSize',obj.legend_size,'Location','bestoutside');
            linkaxes([s1,s2],'x')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['WBR Bit Rate'], ...
                'WBR Bit Rate', 3, ['WBR (air)']);
            % ------------------------------------------------------------%
            
            
        end
        
        function fig = plot_wbr_ber(obj, hour_diff)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            % Mod + Code - Throughput
            s1 = subplot(2,1,1);
            dist_struct = obj.sdar.data.other.wbr_modcode;
            t_days = [];
            values = [];
            sync_time(1) = dist_struct(1).start;
            sync_time(2) = dist_struct(length(dist_struct)).end;
            for i = 1:1:length(dist_struct)
                t_days(2*i-1) = (dist_struct(i).start - hour_diff*3600)/3600/24;
                t_days(2*i) = (dist_struct(i).end - hour_diff*3600)/3600/24;
                values(2*i-1:2*i) = obj.get_data_rate(dist_struct(i).value);
            end
            plot(t_days,values*8/1000.0,'--black', 'LineWidth',obj.line_size)
            hold on
            dist_struct = obj.sdar.data.logs.WRX.x8Rate;
            i=fieldnames(dist_struct);
            t_days = [];
            %             sync_time = [];
            for q=1:1:length(i)
                if (isfield(dist_struct.(i{q}), 'sdar_utc'))
                    %                    a sync_time(length(sync_time)+1:length(sync_time)+length([dist_struct.(i{q}).sdar_utc])) = [dist_struct.(i{q}).sdar_utc];
                    t_days = ([dist_struct.(i{q}).sdar_utc] - hour_diff*3600)/3600/24;
                    scatter(t_days,[dist_struct.(i{q}).val]*8/1000.0,...
                        ['x',obj.colors(q)],...
                        'LineWidth',obj.scatter_size)
                    hold on
                end
            end
            datetick('x', 'HH:MM:SS')
            xlabel(['Time (UTC-' num2str(hour_diff) ')'],'FontSize', obj.label_size);
            ylabel('KBit/s','FontSize', obj.label_size);
            out_legend = [i];
            out_legend = ['Theory Throughput'; out_legend];
            
            legend(out_legend,'FontSize',obj.legend_size,'Location','northeastoutside')
            title('WBR Decode Rate By Modulation', 'FontSize',obj.title_size, 'color', obj.title_color)
            
            s2 = subplot(2,1,2);
            dist_struct = obj.sdar.data.logs.WRX.BER;
            i=fieldnames(dist_struct);
            t_days = [];
            %             sync_time = [];
            for q=1:1:length(i)
                if (isfield(dist_struct.(i{q}), 'sdar_utc'))
                    %                    a sync_time(length(sync_time)+1:length(sync_time)+length([dist_struct.(i{q}).sdar_utc])) = [dist_struct.(i{q}).sdar_utc];
                    t_days = ([dist_struct.(i{q}).sdar_utc] - hour_diff*3600)/3600/24;
                    scatter([xlim(s1) t_days],[0 0 [dist_struct.(i{q}).val]],...
                        ['x',obj.colors(q)],...
                        'LineWidth',obj.scatter_size)
                    hold on
                end
            end
            datetick('x', 'HH:MM:SS')
            xlabel(['Time (UTC-' num2str(hour_diff) ')'],'FontSize', obj.label_size);
            ylabel('BER','FontSize', obj.label_size);
            legend([i],'FontSize',obj.legend_size)
            title('WBR Bit Error Rate By Modulation', 'FontSize',obj.title_size, 'color', obj.title_color)
            set(s2,'YScale','log');
            m = scatter([s1.XLim(1) s1.XLim(2)], [10e-3 10e-2],'x','w');
            set(get(get(m,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
            datetick('x', 'HH:MM:SS')
            linkaxes([s1,s2],'x')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['WBR Bit Error Rate By Modulation'], ...
                'WBR BER', 3, ['WBR (air)']);
            
            % ------------------------------------------------------------%
            
        end
        
        % Plot SNR vs Distance
        function fig = plot_snr_distance(obj, hour_diff)
            if isfield(obj.sdar.data.logs.WRX, 'SNR')
                output_data = [];
                dist_struct = obj.sdar.data.logs.WRX.SNR;
                l = fieldnames(dist_struct);
                for q=1:1:length(l)
                    output_data = [output_data; dist_struct.(l{q})];
                end
                
                t_days=([output_data.sdar_utc]-hour_diff*3600)/3600/24;
                fig = figure('pos',obj.fig_size);
                s1 = subplot(2,1,1);
                scatter(t_days,[output_data.val], 'MarkerFaceColor',[0 0 1]);
                title('Estimated Signal-to-Noise Value', 'FontSize',obj.title_size, 'color', obj.title_color)
                xlabel(['Time (UTC-' num2str(hour_diff) ')'], 'FontSize', obj.label_size);
                datetick('x', 'HH:MM:SS')
                ylabel('SNR Level (dB)', 'FontSize', obj.label_size);
                set(s1,'FontSize', obj.label_size,'XColor', [0 0 0], 'YColor',[0 0 0],'ZColor',[0 0 0]);
                
                s2 = subplot(2,1,2);
                scatter(t_days,[obj.utc2slant_range([output_data.sdar_utc], ...
                    obj.mgs(1).info.longitude, obj.mgs(1).info.latitude, ...
                    obj.mgs(1).info.elevation_m)]*0.539957/1000.0, ...
                    'MarkerFaceColor',[0.600000023841858 0.200000002980232 0],...
                    'MarkerEdgeColor',[0.600000023841858 0.200000002980232 0]);
                title('Corresponding Distance from MGS (NM)', 'FontSize',obj.title_size, 'color', obj.title_color)
                xlabel(['Time (UTC-' num2str(hour_diff) ')'], 'FontSize', obj.label_size);
                datetick('x', 'HH:MM:SS')
                ylabel('Distance (NM)', 'FontSize', obj.label_size);
                set(s2,'FontSize', obj.label_size,'XColor', [0 0 0], 'YColor',[0 0 0],'ZColor',[0 0 0]);
                linkaxes([s1,s2],'x')
                
                
                % ------------------ Report content --------------------------%
                obj.set_report_content(fig, [ 'SNR - Distance' ], ...
                    'SNR - Distance', 4, ['WBR (MGS)']);
                % ------------------------------------------------------------%
            end
            
        end
        
        function fig = plot_power_sdar(obj, hour_diff)
            % String to Int
            error('Forced: Must review this function')
            if ischar(obj.sdar.data.logs.AGC1.RSSI(1).val)
                for q=1:1:length([obj.sdar.data.logs.AGC1.RSSI])
                    obj.sdar.data.logs.AGC1.RSSI(q).val = str2num(obj.sdar.data.logs.AGC1.RSSI(q).val);
                end
            end
            if ischar(obj.sdar.data.logs.AGC2.RSSI(1).val)
                for q=1:1:length([obj.sdar.data.logs.AGC2.RSSI])
                    obj.sdar.data.logs.AGC2.RSSI(q).val = str2num(obj.sdar.data.logs.AGC2.RSSI(q).val);
                end
            end
            
            % Slice the RSSI data
            l = [obj.sdar.data.other.radio2.value];
            l2 = unique(l);
            working_data = [];
            for q=1:1:length(l2)
                working_data.(l2{q})(1) = obj.sdar.data.logs.AGC2.RSSI(1);
            end
            working_data = working_data';
            for q=1:1:length(l)
                idx = find([obj.sdar.data.logs.AGC2.RSSI.sdar_utc] > obj.sdar.data.other.radio2(q).start & [obj.sdar.data.logs.AGC2.RSSI.sdar_utc] < obj.sdar.data.other.radio2(q).end);
                for p=1:1:length(l2)
                    if (strcmp(obj.sdar.data.other.radio2(q).value, (l2{p})))
                        working_data.(l2{p}) = [working_data.(l2{p}) obj.sdar.data.logs.AGC2.RSSI(idx)'];
                    end
                end
            end
            
            % Get the corresponding gain
            ref_struct = obj.sdar.data.logs.AGC2.Rx2gains;
            for q=1:1:length([working_data.WBR.val])
                working_data.WBR(q).gain1 = ref_struct(min(find(working_data.WBR(q).sdar_utc < [obj.sdar.data.logs.AGC2.Rx2gains.sdar_utc]))).gain1;
                working_data.WBR(q).gain2 = ref_struct(min(find(working_data.WBR(q).sdar_utc < [obj.sdar.data.logs.AGC2.Rx2gains.sdar_utc]))).gain2;
                working_data.WBR(q).gain3 = ref_struct(min(find(working_data.WBR(q).sdar_utc < [obj.sdar.data.logs.AGC2.Rx2gains.sdar_utc]))).gain3;
                working_data.WBR(q).power = -(working_data.WBR(q).gain1 + working_data.WBR(q).gain2 + working_data.WBR(q).gain3) + working_data.WBR(q).val;
                if (working_data.WBR(q).power < -100)
                    working_data.WBR(q).power = NaN;
                end
            end
            working_data2 =  working_data.WBR';
            m = medfilt1([working_data2.power],7);
            for q=1:1:length(m)
                working_data2(q).power = m(q);
            end
            working_data =[];
            
            % Figure
            fig = figure('pos',obj.fig_size);
            set(fig, 'Visible',obj.vis)
            s1 = subplot(2,1,1);
            t_days=([working_data2.sdar_utc]-hour_diff*3600)/3600/24;
            scatter(t_days, [working_data2.power],  'MarkerFaceColor',[0 0 1]);
            title('Received dBFS without Gain RX for WBR', 'FontSize',obj.title_size, 'color', obj.title_color);
            xlabel(['Time (UTC-' num2str(hour_diff) ')'], 'FontSize', obj.label_size);
            datetick('x', 'HH:MM:SS')
            ylabel('dBFS Level (dB)', 'FontSize', obj.label_size);
            set(s1,'FontSize', obj.label_size,'XColor', [0 0 0], 'YColor',[0 0 0],'ZColor',[0 0 0]);
            
            s2 = subplot(2,1,2);
            dist=utc2slant_range(obj,[working_data2.sdar_utc],obj.mgs(1).info.longitude, ...
                obj.mgs(1).info.latitude, ...
                obj.mgs(1).info.elevation_m);
            for q=1:1:length(dist)
                if isnan([working_data2(q).power])
                    dist(q) = NaN;
                end
            end
            scatter(t_days, dist*0.539957/1000.0, ...
                'MarkerFaceColor',[0.600000023841858 0.200000002980232 0],...
                'MarkerEdgeColor',[0.600000023841858 0.200000002980232 0]);
            title('Corresponding Distance (NM) from MGS', 'FontSize',obj.title_size, 'color', obj.title_color);
            xlabel(['Time (UTC-' num2str(hour_diff) ')'], 'FontSize', obj.label_size);
            datetick('x', 'HH:MM:SS')
            ylabel('Distance (NM)', 'FontSize', obj.label_size);
            set(s2,'FontSize', obj.label_size,'XColor', [0 0 0], 'YColor',[0 0 0],'ZColor',[0 0 0]);
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [ 'WBR SDAR Input Level without RX Gain' ], ...
                'WBR SDAR Input Level without Gain', 4, [ 'WBR (MGS)']);
            
            % ------------------------------------------------------------%
            
        end
        %% TMS
        function fig=plot_tms_distance(obj,hour_diff)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            ax1 = axes('Parent',fig);
            set(fig, 'Visible',obj.vis);
            fig_name=['TMS Performance Relative to ' obj.info.departure.name];
            % Display mode 0-----
            rad_event=[obj.sdar.data.other.radio1 obj.sdar.data.other.radio2];
            tms_event=rad_event(strcmp([rad_event.value],'TMS'));
            [ref_utc,lon,lat,alt] = obj.ref_data.event_struct2pos(tms_event);
            u2d=@(u)(u-hour_diff*3600)/3600/24;
            % Transcript
            if istable(obj.transcript)
                s1=subplot(4,1,1);
                hold on
                axis off
                %set(s1,'Visible','off')
                tms_idx=strcmp(obj.transcript.system,'TMS');
                tms_t=obj.transcript(tms_idx,:);
                % 1 tms found 0 tms lost
                tag_map=zeros(length(tms_t.utc_sec),1);
                tag_map(contains(tms_t.tag,'O'))=1;
                tms_t.tag_map=tag_map;
                % hold last interpolation
                start_utc=tms_t.utc_sec(strcmpi(tms_t.tag,'start'));
                end_utc=tms_t.utc_sec(strcmpi(tms_t.tag,'End'));
                itag_utc=ref_utc(ref_utc>=start_utc & ref_utc<=end_utc);
                [uutc_sec,ia,ic] = unique(tms_t.utc_sec);
                utag=tms_t.tag(ia);
                utag_map=tms_t.tag_map(ia);
                itag_map = interp1(...
                    uutc_sec(~contains(utag,'A')),...
                    utag_map(~contains(utag,'A')),...
                    itag_utc,...
                    'previous');
                found_utc=itag_utc(itag_map==1);
                lost_utc=itag_utc(itag_map==0);
                plot(u2d(found_utc),ones(length(found_utc),1),'g+',...
                    'MarkerSize',15,'MarkerFaceColor','g',...
                    'DisplayName','Found')
                plot(u2d(lost_utc),ones(length(lost_utc),1),'r+',...
                    'MarkerSize',15,'MarkerFaceColor','r',...
                    'DisplayName','Lost')
                % annotate
                tms_idx=strcmp(obj.transcript.system,'TMS');
                tms_t=obj.transcript(tms_idx,:);
                t_days=(tms_t.utc_sec-hour_diff*3600)/3600/24;
                pos_vect=[0.25 1.5 0.5 1.25];
                rot_vect=repmat(pos_vect,...
                    ceil(length(t_days)/length(pos_vect)));
                rot_vect=rot_vect(1,[1:1:length(t_days)]).';
                text_pos= rot_vect;
                stem(t_days,text_pos,'.:k',...
                    'DisplayName','TWR info')
                text(t_days,text_pos,tms_t.tag,...
                    'FontSize',12,'FontWeight','bold')
                legend('show')
                datetick('x', 'HH:MM:SS');
                title('Detected TMS replies (TWR from audio log)')
                ylim([-0.5 1.5]);
                s2=subplot(4,1,[2 3 4]);
            end
            hold on
            % mode A high
            utc=[obj.fpga.logs.TMS.ModeA(...
                strcmp({obj.fpga.logs.TMS.ModeA.val},'high')).fpga_time];
            if ~isempty(utc)
                slant=obj.utc2slant_range(utc,...
                    obj.info.departure.longitude,...
                    obj.info.departure.latitude,...
                    obj.info.departure.elevation_m);
                t_days=(utc-hour_diff*3600)/3600/24;
                p(1)=plot(t_days,slant/1852,'o',...
                    'MarkerSize',8,'MarkerFaceColor','b',...
                    'MarkerEdgeColor','b',...
                    'DisplayName',['ModeA ' 'high']);
            end
            % mode A low
            utc=[obj.fpga.logs.TMS.ModeA(...
                strcmp({obj.fpga.logs.TMS.ModeA.val},'low')).fpga_time];
            if ~isempty(utc)
                slant=obj.utc2slant_range(utc,...
                    obj.info.departure.longitude,...
                    obj.info.departure.latitude,...
                    obj.info.departure.elevation_m);
                t_days=(utc-hour_diff*3600)/3600/24;
                p(2)=plot(t_days,slant/1852,'o',...
                    'MarkerSize',8,'MarkerFaceColor','none',...
                    'MarkerEdgeColor','b',...
                    'DisplayName',['ModeA ' 'low']);
            end
            % mode A missed
            utc=[obj.fpga.logs.TMS.ModeA(...
                strcmp({obj.fpga.logs.TMS.ModeA.val},'missed')).fpga_time];
            if ~isempty(utc)
                slant=obj.utc2slant_range(utc,...
                    obj.info.departure.longitude,...
                    obj.info.departure.latitude,...
                    obj.info.departure.elevation_m);
                t_days=(utc-hour_diff*3600)/3600/24;
                p(3)=plot(t_days,slant/1852,'x',...
                    'MarkerSize',8,'MarkerFaceColor','none',...
                    'MarkerEdgeColor','b',...
                    'DisplayName',['ModeA ' 'missed']);
            end
            % mode C high
            if ~isempty(utc)
                utc=[obj.fpga.logs.TMS.ModeC(...
                    strcmp({obj.fpga.logs.TMS.ModeC.val},'high')).fpga_time];
                slant=obj.utc2slant_range(utc,...
                    obj.info.departure.longitude,...
                    obj.info.departure.latitude,...
                    obj.info.departure.elevation_m);
                t_days=(utc-hour_diff*3600)/3600/24;
                p(4)=plot(t_days,slant/1852,'o',...
                    'MarkerSize',8,'MarkerFaceColor','r',...
                    'MarkerEdgeColor','r',...
                    'DisplayName',['ModeC ' 'high']);
            end
            % mode C low
            
            utc=[obj.fpga.logs.TMS.ModeC(...
                strcmp({obj.fpga.logs.TMS.ModeC.val},'low')).fpga_time];
            if ~isempty(utc)
                slant=obj.utc2slant_range(utc,...
                    obj.info.departure.longitude,...
                    obj.info.departure.latitude,...
                    obj.info.departure.elevation_m);
                t_days=(utc-hour_diff*3600)/3600/24;
                p(5)=plot(t_days,slant/1852,'o',...
                    'MarkerSize',8,'MarkerFaceColor','none',...
                    'MarkerEdgeColor','r',...
                    'DisplayName',['ModeC ' 'low']);
            end
            
            % mode A missed
            utc=[obj.fpga.logs.TMS.ModeC(...
                strcmp({obj.fpga.logs.TMS.ModeC.val},'missed')).fpga_time];
            if ~isempty(utc)
                slant=obj.utc2slant_range(utc,...
                    obj.info.departure.longitude,...
                    obj.info.departure.latitude,...
                    obj.info.departure.elevation_m);
                t_days=(utc-hour_diff*3600)/3600/24;
                p(6)=plot(t_days,slant/1852,'x',...
                    'MarkerSize',8,'MarkerFaceColor','none',...
                    'MarkerEdgeColor','r',...
                    'DisplayName',['ModeC ' 'missed']);
            end
            % Mode S
            utc=[obj.fpga.logs.TMS.ModeS.fpga_time];
            if ~isempty(utc)
                slant=obj.utc2slant_range(utc,...
                    obj.info.departure.longitude,...
                    obj.info.departure.latitude,...
                    obj.info.departure.elevation_m);
                t_days=(utc-hour_diff*3600)/3600/24;
                p(6)=plot(t_days,slant/1852,'s',...
                    'MarkerSize',8,'MarkerFaceColor','g',...
                    'MarkerEdgeColor','g',...
                    'DisplayName',['ModeS ' 'All call']);
            end
            % add gps
            slant=obj.utc2slant_range(ref_utc,...
                obj.info.departure.longitude,...
                obj.info.departure.latitude,...
                obj.info.departure.elevation_m);
            t_days=(ref_utc-hour_diff*3600)/3600/24;
            p(6)=plot(t_days,slant/1852,...
                'DisplayName','GPS when TMS is On');
            % transcript
            if istable(obj.transcript)
                tms_idx=strcmp(obj.transcript.system,'TMS');
                tms_t=obj.transcript(tms_idx,:);
                t_days=(tms_t.utc_sec-hour_diff*3600)/3600/24;
                maxy=ylim();
                stem(t_days,maxy(end)*ones(length(t_days),1),':k',...
                    'Marker','none',...
                    'DisplayName','TWR info')
                linkaxes([s1,s2],'x')
            end
            legend('show')
            datetick('x', 'HH:MM:SS');
            title('Detected TMS Interrogations (SDAR''s FPGA)')
            xlabel(['Time (UTC-' num2str(hour_diff) ')']);
            ylabel('Distance in NM');
            suptitle([obj.info.date '  ' fig_name])
            % ------------------ Report content --------------------------%
            obj.set_report_content(...
                fig, ['TMS Performance relative to ' obj.info.departure.name], ...
                'TODO add description',...
                1, ['SDAR ' 'TMS'])
            % ------------------------------------------------------------%
        end
        
        function fig=plot_tms_enu(obj)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            ax1 = axes('Parent',fig);
            set(fig, 'Visible',obj.vis)
            fig_name=['TMS reception ENU relative to ' obj.info.departure.name];
            hold on
            % Display mode 0-----
            % mode A high
            utc=[obj.fpga.logs.TMS.ModeA(...
                strcmp({obj.fpga.logs.TMS.ModeA.val},'high')).fpga_time];
            if ~isempty(utc)
                [xr,yr,zr]=obj.utc2enu(utc,...
                    obj.info.departure.latitude,...
                    obj.info.departure.longitude,...
                    obj.info.departure.elevation_m);
                p(1)=plot(xr/1852,yr/1852,'o',...
                    'MarkerSize',8,'MarkerFaceColor','b',...
                    'MarkerEdgeColor','b',...
                    'DisplayName',['ModeA ' 'high']);
            end
            % mode A low
            utc=[obj.fpga.logs.TMS.ModeA(...
                strcmp({obj.fpga.logs.TMS.ModeA.val},'low')).fpga_time];
            if ~isempty(utc)
                [xr,yr,zr]=obj.utc2enu(utc,...
                    obj.info.departure.latitude,...
                    obj.info.departure.longitude,...
                    obj.info.departure.elevation_m);
                p(2)=plot(xr/1852,yr/1852,'o',...
                    'MarkerSize',8,'MarkerFaceColor','none',...
                    'MarkerEdgeColor','b',...
                    'DisplayName',['ModeA ' 'low']);
            end
            % mode A missed
            utc=[obj.fpga.logs.TMS.ModeA(...
                strcmp({obj.fpga.logs.TMS.ModeA.val},'missed')).fpga_time];
            if ~isempty(utc)
                [xr,yr,zr]=obj.utc2enu(utc,...
                    obj.info.departure.latitude,...
                    obj.info.departure.longitude,...
                    obj.info.departure.elevation_m);
                p(3)=plot(xr/1852,yr/1852,'x',...
                    'MarkerSize',8,'MarkerFaceColor','none',...
                    'MarkerEdgeColor','b',...
                    'DisplayName',['ModeA ' 'missed']);
            end
            % mode C high
            utc=[obj.fpga.logs.TMS.ModeC(...
                strcmp({obj.fpga.logs.TMS.ModeC.val},'high')).fpga_time];
            if ~isempty(utc)
                [xr,yr,zr]=obj.utc2enu(utc,...
                    obj.info.departure.latitude,...
                    obj.info.departure.longitude,...
                    obj.info.departure.elevation_m);
                p(4)=plot(xr/1852,yr/1852,'o',...
                    'MarkerSize',8,'MarkerFaceColor','r',...
                    'MarkerEdgeColor','r',...
                    'DisplayName',['ModeC ' 'high']);
            end
            
            % mode C low
            utc=[obj.fpga.logs.TMS.ModeC(...
                strcmp({obj.fpga.logs.TMS.ModeC.val},'low')).fpga_time];
            if ~isempty(utc)
                [xr,yr,zr]=obj.utc2enu(utc,...
                    obj.info.departure.latitude,...
                    obj.info.departure.longitude,...
                    obj.info.departure.elevation_m);
                p(5)=plot(xr/1852,yr/1852,'o',...
                    'MarkerSize',8,'MarkerFaceColor','none',...
                    'MarkerEdgeColor','r',...
                    'DisplayName',['ModeC ' 'low']);
            end
            % mode A missed
            utc=[obj.fpga.logs.TMS.ModeC(...
                strcmp({obj.fpga.logs.TMS.ModeC.val},'missed')).fpga_time];
            if ~isempty(utc)
                [xr,yr,zr]=obj.utc2enu(utc,...
                    obj.info.departure.latitude,...
                    obj.info.departure.longitude,...
                    obj.info.departure.elevation_m);
                p(6)=plot(xr/1852,yr/1852,'x',...
                    'MarkerSize',8,'MarkerFaceColor','none',...
                    'MarkerEdgeColor','r',...
                    'DisplayName',['ModeC ' 'missed']);
            end
            % Mode S
            utc=[obj.fpga.logs.TMS.ModeS.fpga_time];
            if ~isempty(utc)
                [xr,yr,zr]=obj.utc2enu(utc,...
                    obj.info.departure.latitude,...
                    obj.info.departure.longitude,...
                    obj.info.departure.elevation_m);
                p(6)=plot(xr/1852,yr/1852,'s',...
                    'MarkerSize',8,'MarkerFaceColor','g',...
                    'MarkerEdgeColor','g',...
                    'DisplayName',['ModeS ' 'All call']);
            end
            % add gps
            rad_event=[obj.sdar.data.other.radio1 obj.sdar.data.other.radio2];
            tms_event=rad_event(strcmp([rad_event.value],'TMS'));
            [utc,lon,lat,alt] = obj.ref_data.event_struct2pos(tms_event);
            [xr,yr,zr]=obj.utc2enu(utc,...
                obj.info.departure.latitude,...
                obj.info.departure.longitude,...
                obj.info.departure.elevation_m);
            p(6)=plot(xr/1852,yr/1852,...
                'DisplayName','GPS when TMS on');
            % transcript
            if istable(obj.transcript)
                tms_idx=strcmp(obj.transcript.system,'TMS');
                tms_t=obj.transcript(tms_idx,:);
                [xr,yr,zr]=obj.utc2enu(tms_t.utc_sec,...
                    obj.info.departure.latitude,...
                    obj.info.departure.longitude,...
                    obj.info.departure.elevation_m);
                text(xr/1852,yr/1852,tms_t.tag,...
                    'FontSize',12,'FontWeight','bold')
            end
            legend('show')
            
            xlabel('West \leftrightarrow East (NM)');
            ylabel('South \leftrightarrow North (NM)');
            % ------------------ Report content --------------------------%
            
            %             obj.set_report_content(...
            %                 fig, ['TMS Perfromance relative to ' obj.info.departure.name], ...
            %                 'TODO add description',...
            %                 1, ['SDAR ' 'TMS'],...
            %                 'table',obj.tab_tms_position(hour_diff))
            
            obj.set_report_content(...
                fig, fig_name, ...
                'TODO add description',...
                1, ['SDAR ' 'TMS'])
            % ------------------------------------------------------------%
        end
        function tab=tab_tms_position(obj,hour_diff)
            % fields=time,local,source,label,lat,lon,alt,dist,desc
            % transcript
            tab=table();
            tms_idx=strcmp(obj.transcript.system,'TMS');
            tms_t=obj.transcript(tms_idx,:);
            u2d=@(u)(u-hour_diff*3600)/3600/24;
            tab.utc=tms_t.utc_sec;
            tab.local=datestr(u2d(tms_t.utc_sec),'HH:MM:SS');
            tab.source=tms_t.speaker;
            tab.label=tms_t.tag;
            [lon,lat,alt]= obj.ref_data.utc2pos(tms_t.utc_sec);
            tab.lat=lat;tab.lon=lon;tab.alt_ft=alt*3.28084;
            slant=obj.utc2slant_range(tms_t.utc_sec,...
                obj.info.departure.longitude,...
                obj.info.departure.latitude,...
                obj.info.departure.elevation_m);
            tab.(['NM_dist_' obj.info.departure.name])=slant/1852;
            tab.desc=tms_t.text;
            %obj.table_figure_2(tab)
            1+1;
            % FPGA
            t=table();
            t.utc=[[obj.fpga.logs.TMS.ModeA.fpga_time].';...
                [obj.fpga.logs.TMS.ModeC.fpga_time].';...
                [obj.fpga.logs.TMS.ModeS.fpga_time].'];
            t.local=datestr(u2d(t.utc),'HH:MM:SS');
            t.source=repmat({'FPGA'},length(t.utc),1);
            t.label=[{obj.fpga.logs.TMS.ModeA.label}.';...
                {obj.fpga.logs.TMS.ModeC.label}.';...
                {obj.fpga.logs.TMS.ModeS.label}.'];
            [lon,lat,alt]= obj.ref_data.utc2pos(t.utc);
            t.lat=lat;t.lon=lon;t.alt_ft=alt*3.28084;
            slant=obj.utc2slant_range(t.utc,...
                obj.info.departure.longitude,...
                obj.info.departure.latitude,...
                obj.info.departure.elevation_m);
            t.(['NM_dist_' obj.info.departure.name])=slant/1852;
            t.desc=[{obj.fpga.logs.TMS.ModeA.val}.';...
                {obj.fpga.logs.TMS.ModeC.val}.';...
                {obj.fpga.logs.TMS.ModeS.val}.'];
            tab=[tab;t];
            tab=sortrows(tab);
        end
        function fig=tab_tms_summary(obj)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            t=obj.tab_tms_position(4);
            
            res=table;
            res.p={'Detected Interrogations'};
            res.v=sum(strcmpi(t.desc,'high') | strcmpi(t.label,'ModeS'));
            res.u={' '};
            
            res=[res;...
                [{'Detected ModeA'} ...
                sum(strcmpi(t.desc,'high') & strcmpi(t.label,'ModeA')) ...
                {' '}]];
            
            res=[res;...
                [{'Detected ModeC'} ...
                sum(strcmpi(t.desc,'high') & strcmpi(t.label,'ModeC')) ...
                {' '}]];
            
            res=[res;...
                [{'Detected ModeS'} ...
                sum(strcmpi(t.label,'ModeS')) ...
                {' '}]];
            obj.table_figure(res);
            
            res=[res;...
                [{'Missed ModeA/C'} ...
                sum(strcmpi(t.desc,'missed')) ...
                {' '}]];
            
            res=[res;...
                [{'False Alerts'} ...
                sum(strcmpi(t.desc,'low')) ...
                {' '}]];
            
            res=[res;...
                [{'Range'} ...
                max(t.NM_dist_CYHU(strcmpi(t.desc,'high') | strcmpi(t.label,'ModeS'))) ...
                {' NM'}]];
            res.Properties.VariableNames={'Param' 'Value' 'Unit'};
            obj.table_figure(res);
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig,'TMS Summary', ...
                'TMS', 1, ['SDAR ' 'TMS'],...
                'table',res)
            
            % ------------------------------------------------------------%
        end
        %% ADSB
        function fig=hist_adsbin(obj,mgs_num)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            if mgs_num == 0
                %do sdar
            else
                if isfield(obj.mgs(mgs_num).data.logs,'ADSBin')
                    adsb=obj.mgs(1).data.logs.ADSBin.data;
                else
                    adsb=obj.mgs(1).data.logs.SADSBin.data;
                end
            end
            s1=subplot(121);
            
            rr2=tab_adsb_count(obj,adsb);
            rr2=sortrows(rr2,'sum','descend');
            srr=rr2(1:10,:); % change here to set size
            srr.id_map=[1:1:height(srr)].';
            barh(srr.id_map,table2array(srr(:,3:width(srr)-1)))
            callsign=obj.adsb_icao2callsign(srr.icao,adsb);
            set(s1,'YTick',srr.id_map) % check
            set(s1,'YTickLabel',strrep(callsign,'_',' ')) % check
            legend(strrep(srr.Properties.VariableNames(3:end-1),'_',' '))
            title('ADS-B/In messages count (top 10)')
            s2=subplot(122);
            totals=sum(table2array(srr(:,3:width(srr)-1)));
            bar([-10 10],[totals; totals]);
            xlim([-1 4])
            xlim([-20 0])
            set(s2,'XTickLabel',{})
            legend(strrep(srr.Properties.VariableNames(3:end-1),'_',' '))
            title('ADS-B/In messages count (total)')
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [ 'ADS-B/In Messages Count' ], ...
                'adsb in plot', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ]);
            % ------------------------------------------------------------%
        end
        function res=tab_adsb_count(obj,adsb_struct)
            % Crawling loop
            t=struct('adr','','res',[]);
            f=@(x) struct('cnt',length(x));
            r=crawler(adsb_struct,t,f);
            r=struct2table(r);
            r(~cellfun(@isstruct,r.res),:)=[];
            f=@(x) {strsplit(char(x),'.')};
            temp=cellfun(f,r.adr);
            f=@(x) {x{2}};
            r.icao=cellfun(f,temp);
            f=@(x) {x{end}};
            r.type=cellfun(f,temp);
            f=@(x) x.cnt;
            r.cnt=cellfun(f,r.res);
            icaos=unique(r.icao);
            id_map=containers.Map(icaos,1:length(icaos));
            f=@(x) id_map(x);
            r.id_map=cellfun(f,r.icao);
            param=unique(r.type);
            rr=table();
            rr.icao=icaos;
            rr.id_map=cellfun(f,rr.icao);
            rr=[rr array2table(zeros(height(rr),length(param)))];
            rr.Properties.VariableNames=['icao' 'id_map' param.'];
            %rr.sum=sum(table2array(rr(:,3:end)).').';
            for i=1:length(rr.id_map)
                for j=1:length(param)
                    cnt=r.cnt(...
                        r.id_map==rr.id_map(i) & ...
                        strcmp(r.type,param{j}));
                    if ~isempty(cnt)
                        rr{i,j+2}=cnt;
                    end
                end
            end
            rr.sum=sum(table2array(rr(:,3:end)).').';
            % compress table
            rr2=table();
            rr2.icao=rr.icao;rr2.id_map=rr.id_map;
            
            tc1={'TC1' 'TC2' 'TC3' 'TC4'}; %Aircraft identification
            [c,ia,ib]=intersect(rr.Properties.VariableNames,tc1);
            rr2.Aircraft_identification=...
                sum(table2array(rr(:,ia)).',1).';
            
            tc2={'TC5' 'TC6' 'TC7' 'TC8'}; %Surface position
            [c,ia,ib]=intersect(rr.Properties.VariableNames,tc2);
            rr2.Surface_position=...
                sum(table2array(rr(:,ia)).',1).';
            
            tc3={'TC9' 'TC10' 'TC11' 'TC12' 'TC13' 'TC14' ...
                'TC15' 'TC16' 'TC18'}; % Airborne position (w/ Baro Altitude)
            [c,ia,ib]=intersect(rr.Properties.VariableNames,tc3);
            rr2.Airborne_position_baro=...
                sum(table2array(rr(:,ia)).',1).';
            
            tc4={'TC19'}; % Airborne velocities
            [c,ia,ib]=intersect(rr.Properties.VariableNames,tc4);
            rr2.Airborne_velocities=...
                sum(table2array(rr(:,ia)).',1).';
            
            tc5={'TC20' 'TC21' 'TC22'}; % Airborne position (w/ GNSS Height)
            [c,ia,ib]=intersect(rr.Properties.VariableNames,tc5);
            rr2.Airborne_position_GNSS=...
                sum(table2array(rr(:,ia)).',1).';
            %get df
            idx=find(~isempty(strfind(rr.Properties.VariableNames,'DF')));
            rr2=[rr2 rr(:,idx+2)];
            rr2.sum=sum(table2array(rr(:,3:end)).').';
            rr2(:,logical([0 0 sum(table2array(rr2(:,3:end)))==0 0]))=[];
            res =rr2;
        end
        function [callsign,df,tc,cat]=adsb_icao2callsign(obj,...
                icaos,adsb_struct)
            callsign=icaos;
            df=cell(size(callsign));
            df(:)={'DF11'};
            tc=cell(size(callsign));
            tc(:)={'No ADSB'};
            cat=-ones(size(callsign));
            for i=1:length(callsign)
                fields=fieldnames(adsb_struct.(callsign{i}));
                [c,ia,ib]=intersect(fields,{'DF18','DF17'});
                if isempty(c);continue;end
                df{i}=c;
                tc{i}='No CallSign';
                cat(i)=-2;
                temp=adsb_struct.(callsign{i}).(char(c));
                fields=fieldnames(temp);
                [c,ia,ib]=intersect(fields,{'TC1' 'TC2' 'TC3' 'TC4'});
                if isempty(c);continue;end
                tc{i}=char(c);
                callsign{i}=temp.(char(c))(1).callsign;
                cat(i)=temp.(char(c))(1).category;
            end
        end
        
        function fig=hist_adsb_distances(obj,mgs_num)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            if mgs_num == 0
                %do sdar
                error('Not implemented') %TODO
            else
                if isfield(obj.mgs(mgs_num).data.logs,'ADSBin')
                    adsb=obj.mgs(mgs_num).data.logs.ADSBin.data;
                else
                    adsb=obj.mgs(mgs_num).data.logs.SADSBin.data;
                end
                r=obj.tab_adsb_all_position(adsb);
                r=r(~any(ismissing(r),2),:); % magicly removes NaN
                r(r.lon==-1,:)=[];
                spheroid = referenceEllipsoid('WGS 84');
                [~,~,r.dist]=geodetic2aer(r.lat,r.lon,r.alt/3.28084,...
                    obj.mgs(mgs_num).info.latitude,...
                    obj.mgs(mgs_num).info.longitude,...
                    obj.mgs(mgs_num).info.elevation_m,spheroid);
                r.dist=r.dist/1852;
                r(abs(r.time_diff)>2000,:)=[];
                k=r(r.dist<=prctile(r.dist,99)*3,:);
                
                h=histogram(k.dist);
                xlabel('Slant Distance (NM)')
                ylabel('Records Count')
                a=annotation('textbox',[.5 .5 .3 .3],...
                    'String',['Number of outliers(>' ...
                    num2str(prctile(r.dist,99)*3) ' NM)'...1
                    '= ' num2str(height(r)-height(k))],...
                    'FitBoxToText','on','Units','normalized',...
                    'FontName','Arial','FontWeight','bold','FontSize',15);
            end
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [ 'ADS-B/In Range' ], ...
                'adsb in range', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ]);
            % ------------------------------------------------------------%
            
        end
        function res=tab_adsb_all_position(obj,adsb_struct)
            adsb=adsb_struct;
            f=@(x) struct('lon',[x.longi].','lat',[x.lati].',...
                'alt',[x.altitude].',...
                'utc',[x.sdar_utc].','epoch',[x.sdar_time].',...
                'time_diff',[x.time_diff].');
            s=struct('adr','','res',[]);
            r=crawler(adsb,s,f);
            r=struct2table(r);
            r(~cellfun(@isstruct,r.res),:)=[];
            res=table();
            f=@(x) {strsplit(char(x),'.')};
            temp=cellfun(f,r.adr);
            f=@(x) {x{2}};
            r.icao=cellfun(f,temp);
            r.callsign=obj.adsb_icao2callsign(r.icao,adsb);
            f=@(x) {x{end}};
            r.type=cellfun(f,temp);
            res=table();
            for i=1:height(r)
                t=struct2table(r.res{i});
                c=cell(height(t),1);
                c(:)=r.icao(i);t.icao=c;
                c(:)=r.callsign(i);t.callsign=c;
                c(:)=r.type(i);t.type=c;
                res=[res;t];
            end
            
        end
        function fig=pie_adsbin_id(obj,mgs_num)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            ax1 = axes('Parent',fig);
            set(fig, 'Visible',obj.vis)
            if mgs_num == 0
                %do sdar
            else
                if isfield(obj.mgs(mgs_num).data.logs,'ADSBin')
                    adsb=obj.mgs(mgs_num).data.logs.ADSBin.data;
                else
                    adsb=obj.mgs(mgs_num).data.logs.SADSBin.data;
                end
                icaos=fieldnames(adsb);
                tc_lut=containers.Map({'TC4' 'TC3' 'TC2' 'TC1'},[1:8:25]);
                type_lut=reshape(table2array(obj.luts.adsb_cat),1,8*4);
                [callsign,df,tc,cat]=obj.adsb_icao2callsign(icaos,adsb);
                f=@(x) tc_lut(x);
                type_map=cellfun(f,tc(cat>=0))+cat(cat>=0);
                r=table();
                r.type=tc;
                r{cat>=0,1}=type_lut(type_map).';
                r.icao=icaos;
                r.tc=tc;
                r.cat=cat;
                r.df=df;
                r.callsign=callsign;
                utypes=unique(r.type);
                type_remap=containers.Map(utypes,1:length(utypes));
                f=@(x) type_remap(x);
                r.type_map=cellfun(f,r.type);
                h=histcounts(r.type_map);
                [~,I]=sort(h,'ascend');
                idx=zeros(1,2*length(h));
                idx(1:2:end)=I;
                idx(2:2:end)=fliplr(I);
                idx=idx(1:length(h));
                h=h(idx);
                utypes=utypes(idx);
                labels=strcat(utypes,...
                    ' (',num2str(h.'),'|',...
                    num2str(round(100*h.'/sum(h))),'%)');
                p=pie(h,labels);
                p_text=p([2:2:end]);
                set(p_text,'FontSize',14,'FontName','Arial',...
                    'FontWeight','bold')
                annotation('textbox',[.8 .6 .3 .3],...
                    'String',['Number of Aircrafts:' num2str(sum(h))],...
                    'Units','normalized','FitBoxToText','on',...
                    'FontName','Arial','FontSize',15,'FontWeight','bold')
                % ------------------ Report content --------------------------%
                
                obj.set_report_content(fig, [ 'ADSB/In Aircrafts Count' ], ...
                    'adsb in plot', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ]);
                
                % ------------------------------------------------------------%
                
            end
            
        end
        
        function fig=plot_adsbin_fl(obj,mgs_num,callsign)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            ax1 = axes('Parent',fig);
            set(fig, 'Visible',obj.vis)
            colormap(jet);
            hold on
            r_id={};
            r_lon=[];
            r_lat=[];
            r_alt=[];
            r_s=[];
            
            %default adsbin type
            adsb_type = 'SADSBin';
            
            if(isfield(obj.mgs(mgs_num).data.logs, 'SADSBin') && strcmp(obj.mgs(mgs_num).info.sys_name, 'SADS-B'))
                adsb_type = 'SADSBin';
            elseif(isfield(obj.mgs(mgs_num).data.logs, 'ADSBin') && strcmp(obj.mgs(mgs_num).info.sys_name, 'ADS-B'))
                adsb_type = 'ADSBin';
            end
            
            icaos=fieldnames(obj.mgs(mgs_num).data.logs.(adsb_type).data);
            %get max position
            for idx=1:length(icaos)
                ac=obj.mgs(mgs_num).data.logs.(adsb_type).data.(icaos{idx});
                if isfield(ac,'DF17')
                    for tc_num=[[9:18] [20:22]]%airborn position type codes
                        tc=['TC' num2str(tc_num)];
                        if isfield(ac.DF17,tc) && isfield(ac.DF17.(tc),'longi')
                            lon=[ac.DF17.(tc).longi];
                            lat=[ac.DF17.(tc).lati];
                            alt=[ac.DF17.(tc).altitude];
                            pos_idx=find(~isnan(lon) & ~isnan(lat) & ~isnan(alt) & ...
                                lon~=-1 & lat~=-1);
                            lon=lon(pos_idx);
                            lat=lat(pos_idx);
                            alt=alt(pos_idx);
                            [e,s,a]=elevation(lat(lat~=-1),lon(lon~=-1),alt/3.28084,...
                                obj.mgs(mgs_num).info.latitude,...
                                obj.mgs(mgs_num).info.longitude,...
                                obj.mgs(mgs_num).info.elevation_m);
                            M=max(s(s<200e3));
                            
                            if ~isnan(M)
                                r_id=horzcat(r_id,icaos{idx});
                                m_lon=lon(s==M);
                                m_lat=lat(s==M);
                                m_alt=alt(s==M);
                                r_lon=[r_lon m_lon(1)];
                                r_lat=[r_lat m_lat(1)];
                                r_alt=[r_alt m_alt(1)];
                                r_s=[r_s M];
                            end
                        end
                    end
                end
            end
            %get icao to callsign
            for idx=1:length(r_id)
                for tc_num=[1:4]%airborn id type codes
                    ac=obj.mgs(mgs_num).data.logs.(adsb_type).data.(r_id{idx});
                    tc=['TC' num2str(tc_num)];
                    if isfield(ac.DF17,tc) && isfield(ac.DF17.(tc),'callsign')
                        r_id{idx}=ac.DF17.(tc)(1).callsign;
                    end
                end
            end
            % to ENU
            wgs84 = wgs84Ellipsoid('meters');
            [x,y,z]=geodetic2ecef(wgs84,r_lat,r_lon,r_alt);
            [xr,yr,zr]=ecef2enu(x,y,z,...
                obj.mgs(mgs_num).info.latitude,...longitude
                obj.mgs(mgs_num).info.longitude,...
                obj.mgs(mgs_num).info.elevation_m,...
                wgs84);
            
            p1=scatter(xr/1852,yr/1852,15,r_alt/100,'filled','LineWidth',10);
            p2=plot(0,0,'d','MarkerSize',15,'MarkerFaceColor','b');
            c=colorbar('peer',ax1);
            c.Label.String='Altitude x100 ft';
            xl=xlim(ax1);
            yl=ylim(ax1);
            ylim([-max(abs([xl yl])) max(abs([xl yl]))]);
            xlim([-max(abs([xl yl])) max(abs([xl yl]))]);
            xlabel('West \leftrightarrow East (NM)');
            ylabel('South \leftrightarrow North (NM)');
            % anontate
            if callsign
                for i=1:length(r_id)
                    text(xr(i)/1852,yr(i)/1852,...
                        ['   ' strrep(char(r_id{i}),'_','')],...
                        'FontSize',8,'FontWeight','bold')
                end
            end
            xl=xlim(ax1);
            for i=25:25:xl(2)
                viscircles([0 0],i,'LineStyle','--')
                text(0,i,num2str(i),'Color','red','FontSize',15)
                text(0,-i,num2str(i),'Color','red','FontSize',15)
            end
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [ 'ADSB/In Detected Aircrafts' ], ...
                'ADS-B/In in plot', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ]);
            
            % ------------------------------------------------------------%
            
            
        end
        
        function fig=tab_adsb_summary(obj,mgs_num)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            if mgs_num == 0
                %do sdar
                error('Not emplemented')
            else
                if isfield(obj.mgs(mgs_num).data.logs,'ADSBin')
                    adsb=obj.mgs(mgs_num).data.logs.ADSBin.data;
                else
                    adsb=obj.mgs(mgs_num).data.logs.SADSBin.data;
                end
                % count
                res=table();
                t=obj.tab_adsb_count(adsb);
                res.p={'Total of records'};
                res.v={sum(t.sum)};
                res.u={' '};
                
                res=[res;...
                    [{'Nb. Aircrafts'} height(t) {' '}]];
                
                r=obj.tab_adsb_all_position(adsb);
                r=r(~any(ismissing(r),2),:); % magicly removes NaN
                r(r.lon==-1,:)=[];
                spheroid = referenceEllipsoid('WGS 84');
                [~,~,r.dist]=geodetic2aer(r.lat,r.lon,r.alt/3.28084,...
                    obj.mgs(mgs_num).info.latitude,...
                    obj.mgs(mgs_num).info.longitude,...
                    obj.mgs(mgs_num).info.elevation_m,spheroid);
                r.dist=r.dist/1852;
                r(abs(r.time_diff)>2000,:)=[];
                k=r(r.dist<=prctile(r.dist,99)*3,:);
                
                res=[res;...
                    [{'Nb. of Possition Records'} height(r) {' '}]];
                [m,I]=max(k.dist);
                res=[res;...
                    [{'Max Distance'} m {' NM'}]];
                res=[res;...
                    [{'Furthest Aircraft'} k.callsign(I) {' '}]];
                [m,I]=min(k.dist);
                res=[res;...
                    [{'Min Distance'} min(k.dist) {' NM'}]];
                res=[res;...
                    [{'Closest Aircraft'} k.callsign(I) {' NM'}]];
                res=[res;...
                    [{'Nb. of Outliers'} height(r)-height(k) {' '}]];
                res=[res;...
                    [{'Outliers Threshold'} prctile(r.dist,99)*3 {' NM'}]];
                res=[res;...
                    [{'Distance Median'} median(k.dist) {' NM'}]];
                
                res=[res;...
                    [{'Max UUT Distance'} ...
                    max(k.dist(strcmp(k.callsign,'LASSENA_'))) ...
                    {' NM'}]];
                res.Properties.VariableNames=({'Param' 'Value' 'Unit'});
                obj.table_figure(res);
                
                % ------------------ Report content --------------------------%
                
                obj.set_report_content(fig,'ADS-B/In Summary', ...
                    'Summary', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ],...
                    'table',res)
                
                % ------------------------------------------------------------%
                
            end
        end
        function fig=plot_hist_RS(obj, mgs_num)
            
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            
            rs_codes = cell2mat({obj.mgs(mgs_num).data.logs.SADSBin.Signature_RS_CRC.rs_code});
            
            histogram(rs_codes, 'BinEdges', [-0.5000 0.5000 1.5000 2.5000 3.5000 4.5000]);
            xticks([0 1 2 3 4])
            % labels, from left to right
            lbls = {'Zero error', '1 byte correction', '2 byte correction', ...
                '3 byte correction', '4 byte correction', ''};
            set(gca,'xticklabel',lbls)
            
            suptitle('Reed Solomon decoding results')
            ylabel('Number of elements')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [ 'Reed Solomon decoding results' ], ...
                'adsb in plot', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ]);
            
            % ------------------------------------------------------------%
        end
        
        
        function fig=pie_sadsb_RS(obj, mgs_num)
            
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            subplot(1,2,1);
            set(fig, 'Visible',obj.vis)
            
            num_mess = 0;
            typecodes = fieldnames(obj.mgs(mgs_num).data.logs.SADSBin.data.icao_abde55.DF18);
            for i =1:length(typecodes)
                tc = char(typecodes(i,:));
                num_mess = num_mess + length(obj.mgs(mgs_num).data.logs.SADSBin.data.icao_abde55.DF18.(tc));
            end
            
            rs_codes = cell2mat({obj.mgs(mgs_num).data.logs.SADSBin.Signature_RS_CRC.rs_code});
            
            zero_correction = length(find((rs_codes == 0)));
            corrected_sign = length(find((rs_codes == 1 |...
                rs_codes == 2 |...
                rs_codes == 3 |...
                rs_codes == 4)));
            
            %             b1 = bar(num_mess, 'y');
            %             b2 = bar(zero_correction+corrected_sign, 'cyan');
            %             b3 = bar(zero_correction, 'FaceColor', [0 0 0.5]);
            %
            %             xlim([0.5 1.5]);
            
            p = pie([(num_mess - (zero_correction+corrected_sign)) corrected_sign zero_correction]);
            
            legend('Missed signatures', 'Corrected signatures', 'Valid signatures (without correction)')
            set(gca,'xticklabel',{''})
            ylabel('Number of elements')
            
            
            counts = [
                zero_correction ...
                corrected_sign ...
                num_mess - (zero_correction+corrected_sign) ...
                num_mess ...
                ];
            counts = counts';
            
            percnts = (counts ./ num_mess) * 100;
            
            stats_desc = {
                'Valid signatures (without correction)', ...
                'Corrected signatures', ...
                'Missed signatures' ...
                'Total'
                };
            
            stats_desc = stats_desc';
            
            t1 = table(counts, percnts,'RowNames', stats_desc,  'VariableNames', {'Count', 'Percent'});
            %subplot(1,2,2);
            
            %obj.table_figure(t1);
            
            % Get the table in string form.
            TString = evalc('disp(t1)');
            % Use TeX Markup for bold formatting and underscores.
            TString = strrep(TString,'<strong>','\bf');
            TString = strrep(TString,'</strong>','\rm');
            TString = strrep(TString,'_','\_');
            % Get a fixed-width font.
            FixedWidth = get(0,'FixedWidthFontName');
            % Output the table using the annotation command.
            annotation(gcf,'Textbox','String',TString,'Interpreter','Tex',...
                'FontName',FixedWidth,'Units','Normalized','Position',[0.5 0.4 0.35 0.25], 'FitBoxToText', 'on',...
                'BackgroundColor', 'w', 'FontSize', 12.0);
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [ 'Secure ADS-B Received signatures' ], ...
                'sads-b in plot', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ]);
            
            % ------------------------------------------------------------%
            
            
        end
        
        function fig=plot_sadsb_enu(obj,mgs_num)
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            % get pos when ADSBout is active
            
            ev0.start = obj.sdar.data.logs.SADSBout.BDS_Data(1).sdar_utc;
            ev0.end = obj.sdar.data.logs.SADSBout.BDS_Data(end).sdar_utc;
            ev0.value = 1;
            [SADDBout_utc,lon0,lat0,alt0]=obj.ref_data.event_struct2pos([ev0]);
            
            [xr,yr,zr]=obj.utc2enu(SADDBout_utc,...
                obj.mgs(mgs_num).info.latitude,...
                obj.mgs(mgs_num).info.longitude,...
                obj.mgs(mgs_num).info.elevation_m);
            
            plot3(xr/1852,yr/1852,zr/1852,'-',...
                'DisplayName','SDAR SADS-B out active')
            
            % plot sign records
            
            sadsb_utc = cell2mat({obj.mgs(mgs_num).data.logs.SADSBin.Signature_RS_CRC.sdar_utc});
            
            
            [xr,yr,zr]=obj.utc2enu(sadsb_utc,...
                obj.mgs(mgs_num).info.latitude,...
                obj.mgs(mgs_num).info.longitude,...
                obj.mgs(mgs_num).info.elevation_m);
            
            plot3(xr/1852,yr/1852,zr/1852,'+',...
                'DisplayName','Signature Records (interpn)')
            xlabel('West \leftrightarrow East (NM)');
            ylabel('South \leftrightarrow North (NM)');
            zlabel('Down \leftrightarrow Up (NM)');
            legend('show')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['SADS-B Detected Signatures'], ...
                'SADSB', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ])
            
            % ------------------------------------------------------------%
            
            
        end
        
        
        function fig=plot_sadsb_records_vs_slant(obj,mgs_num, hour_diff)
            
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            set(fig, 'Visible',obj.vis)
            hold on
            % get pos when ADSBout is active
            
            a ={obj.sdar.data.other.radio1.value};
            a = cellfun(@char, a, 'UniformOutput', false);
            idx = find(strcmp(a, 'ADSB'));
            event_struct = obj.sdar.data.other.radio1(idx);
            
            [SADDBout_utc,lon0,lat0,alt0]=obj.ref_data.event_struct2pos( event_struct );
            
            dist=utc2slant_range(obj,SADDBout_utc,obj.mgs(mgs_num).info.longitude, ...
                obj.mgs(mgs_num).info.latitude, ...
                obj.mgs(mgs_num).info.elevation_m);
            
            t_days=([SADDBout_utc]-hour_diff*3600)/3600/24;
            
            plot(t_days, dist/1852, '.', 'DisplayName','SDAR SADS-B out active')
            datetick('x', 'HH:MM:SS')
            
            % plot sign records
            
            sadsbin_utc = cell2mat({obj.mgs(mgs_num).data.logs.SADSBin.Signature_RS_CRC.sdar_utc});
            
            dist_iterpn=utc2slant_range(obj,sadsbin_utc,obj.mgs(mgs_num).info.longitude, ...
                obj.mgs(mgs_num).info.latitude, ...
                obj.mgs(mgs_num).info.elevation_m);
            t_days=([sadsbin_utc]-hour_diff*3600)/3600/24;
            
            plot(t_days,dist_iterpn/1852,'+',...
                'DisplayName','Signature records (interpn)')
            xlabel('Time');
            ylabel('Slant range (NM)');
            legend('show')
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, ['SADS-B Detected Signature vs Slant Range'], ...
                'SADSB', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ])
            
            % ------------------------------------------------------------%
        end
        
        
        function fig=tab_stats_RS(obj, mgs_num)
            
            num_mess = 0;
            typecodes = fieldnames(obj.mgs(mgs_num).data.logs.SADSBin.data.icao_abde55.DF18);
            for i =1:length(typecodes)
                tc = char(typecodes(i,:));
                num_mess = num_mess + length(obj.mgs(mgs_num).data.logs.SADSBin.data.icao_abde55.DF18.(tc));
            end
            
            
            rs_codes = cell2mat({obj.mgs(mgs_num).data.logs.SADSBin.Signature_RS_CRC.rs_code});
            
            zero_correction = length(find((rs_codes == 0)));
            corrected_sign = length(find((rs_codes == 1 |...
                rs_codes == 2 |...
                rs_codes == 3 |...
                rs_codes == 4)));
            
            Stats = [num_mess zero_correction zero_correction/num_mess ...
                corrected_sign zero_correction+corrected_sign ...
                (zero_correction+corrected_sign)/num_mess];
            Stats = Stats';
            
            stats_desc = {'Received ADS-B messages', ...
                'Valid signatures (without correction)', ...
                'Valid signatures (without correction) % over received messages', ...
                'Corrected signatures', 'Valid signatures (after correction)', ...
                'Valid signatures (after correction) % over received messages'};
            stats_desc = stats_desc';
            
            t1 = table(Stats, 'RowNames', stats_desc, 'VariableNames', {'Value'});
            fig = obj.table_figure_2(t1);
            set(fig, 'Visible',obj.vis)
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [ 'Reed Solomon correction summary' ], ...
                'sads-b in plot', 4, [ 'MGS ' obj.mgs(mgs_num).info.sys_name ], 'table', t1);
            
            % ------------------------------------------------------------%
            
            
        end
        
        %% MGS WBR
        
        function fig = plot_mgs_wbr_mod(obj, mgs_num, hour_diff)
            % Get important
            if (isfield(obj.mgs(mgs_num).data.logs.WTX, 'x8Rate'))
                % Check the correctness of sdar_utc
                for q=1:1:length([obj.mgs(mgs_num).data.logs.WTX.x8Rate.sdar_utc])
                    esti_utc = mod((obj.mgs(mgs_num).data.logs.WTX.x8Rate(q).sdar_time/1000 - (2017-1970)*365*86400),86400);
                    if (abs(esti_utc - obj.mgs(mgs_num).data.logs.WTX.x8Rate(q).sdar_utc) > 60) % More than 1 minute error
                        obj.mgs(mgs_num).data.logs.WTX.x8Rate(q).sdar_utc = mod((obj.mgs(mgs_num).data.logs.WTX.x8Rate(q).sdar_time/1000 - (2017-1970)*365*86400),86400);
                    end
                end
                for q=1:1:length([obj.mgs(mgs_num).data.logs.WTX.MOD.sdar_utc])
                    esti_utc = mod((obj.mgs(mgs_num).data.logs.WTX.MOD(q).sdar_time/1000 - (2017-1970)*365*86400),86400);
                    if (abs(esti_utc - obj.mgs(mgs_num).data.logs.WTX.MOD(q).sdar_utc) > 60)
                        obj.mgs(mgs_num).data.logs.WTX.MOD(q).sdar_utc = mod((obj.mgs(mgs_num).data.logs.WTX.MOD(q).sdar_time/1000 - (2017-1970)*365*86400),86400);
                    end
                end
                
                
                decode_start = min([obj.mgs(mgs_num).data.logs.WTX.x8Rate.sdar_utc]);
                begin = find([obj.mgs(mgs_num).data.logs.WTX.MOD.sdar_utc] > decode_start);
                
                fig =figure('pos',obj.fig_size);
                s1=subplot(2,5,1:4);
                t_days=([obj.mgs(mgs_num).data.logs.WTX.MOD([begin]).sdar_utc]-hour_diff*3600)/3600/24;
                p1=stairs(t_days,[obj.mgs(mgs_num).data.logs.WTX.MOD(begin).val],'Color',[1 0 0]);
                ylim([0 18])
                title('GS Modulation & Coding', 'FontSize', obj.title_size)
                xlabel(['Time (UTC-' num2str(hour_diff) ')'], 'FontSize', obj.label_size);
                datetick('x', 'HH:MM:SS')
                ylabel('Mode', 'FontSize', obj.label_size);
                legend('Current WBR Mode', 'Location', 'northeast');
                set(s1,'FontSize', obj.label_size,'XColor', [0 0 0], 'YColor',[0 0 0],'ZColor',[0 0 0]);
                s3 = subplot(2,5,5);
                axis off
                annotation(fig,'textbox',...
                    'Position',[0.754166666666667 0.723266224906481 0.154687495545174 0.201342276212086],...
                    'String',{'Modulation and Coding:','0, 1: SDAR Control, DBPSK, 64 and 32 bit','2, 3: SDAR Control, DQPSK, 64 and 32 bit','4, 5: SDAR Control, D8PSK, 64 and 32 bit','6, 7: SDAR Control, D16QAM, 64 and 31 bit','','10, 11: Ground Control, DBPSK, 64 and 32 bit','12, 13: Ground Control, DQPSK, 64 and 31 bit','14, 15: Ground Control, D8PSK, 64 and 32 bit','16, 17: Ground Control, D16QAM, 64 and 32 bit'},...
                    'LineStyle','none',...
                    'FitBoxToText','on',...
                    'FontSize', 12);
                
                s2 = subplot(2,5,6:9);
                xl=xlim(s1);
                t_days=([obj.mgs(mgs_num).data.logs.WTX.x8Rate.sdar_utc]-hour_diff*3600)/3600/24;
                p2=plot([xl t_days],[nan nan [obj.mgs(mgs_num).data.logs.WTX.x8Rate.val]*8/1000],'.',...
                    'MarkerSize',8);
                title('GS Decode Rate', 'FontSize', obj.title_size)
                xlabel(['Time (UTC-' num2str(hour_diff) ')'], 'FontSize', obj.label_size);
                
                datetick('x', 'HH:MM:SS')
                ylabel('kbit/s', 'FontSize', obj.label_size);
                legend('GS Decode Rate', 'Location', 'northeast');
                set(s2,'FontSize', obj.label_size,'XColor', [0 0 0], 'YColor',[0 0 0],'ZColor',[0 0 0]);
                linkaxes([s1,s2],'x')
                
            else
                for q=1:1:length([obj.mgs(mgs_num).data.logs.WTX.MOD.sdar_utc])
                    esti_utc = mod((obj.mgs(mgs_num).data.logs.WTX.MOD(q).sdar_time/1000 - (2017-1970)*365*86400),86400);
                    if (abs(esti_utc - obj.mgs(mgs_num).data.logs.WTX.MOD(q).sdar_utc) > 60)
                        obj.mgs(mgs_num).data.logs.WTX.MOD(q).sdar_utc = mod((obj.mgs(mgs_num).data.logs.WTX.MOD(q).sdar_time/1000 - (2017-1970)*365*86400),86400);
                    end
                end
                fig = figure('pos',obj.fig_size);
                s1 = subplot(1,5,1:4);
                t_days=([obj.mgs(mgs_num).data.logs.WTX.MOD.sdar_utc]-hour_diff*3600)/3600/24;
                stairs(t_days,[obj.mgs(mgs_num).data.logs.WTX.MOD.val],'Color',[1 0 0]);
                ylim([0 18])
                suptitle('GS Modulation & Coding')
                xlabel(['Time (UTC-' num2str(hour_diff) ')'], 'FontSize', obj.label_size);
                datetick('x', 'HH:MM:SS')
                ylabel('Mode', 'FontSize', obj.label_size);
                set(s1,'FontSize', obj.label_size,'XColor', [0 0 0], 'YColor',[0 0 0],'ZColor',[0 0 0]);
                
                legend('Current WBR Mode');
                
                subplot(1,5,5);
                axis off
                annotation(fig,'textbox',...
                    'Position',[0.754166666666667 0.723266224906481 0.154687495545174 0.201342276212086],...
                    'String',{'Modulation And Coding:','0, 1: SDAR Control, DBPSK, 64 and 32 bit','2, 3: SDAR Control, DQPSK, 64 and 32 bit','4, 5: SDAR Control, D8PSK, 64 and 32 bit','6, 7: SDAR Control, D16QAM, 64 and 31 bit','','10, 11: Ground Control, DBPSK, 64 and 32 bit','12, 13: Ground Control, DQPSK, 64 and 31 bit','14, 15: Ground Control, D8PSK, 64 and 32 bit','16, 17: Ground Control, D16QAM, 64 and 32 bit'},...
                    'LineStyle','none',...
                    'FitBoxToText','on',...
                    'FontSize', 12);
            end
            
            % ------------------ Report content --------------------------%
            
            obj.set_report_content(fig, [ 'GS WBR Modulation & Coding' ], ...
                'mgs wbr', 4, ['WBR (MGS)']);
            
            % ------------------------------------------------------------%
            
            
        end
        
        % Create the summary table
        function fig = get_wbr_summary(obj, mgs_num, hour_diff)
            % Initial Parameters
            obj.mgs(mgs_num).data.logs.WTX; % to force error
            if (isfield(obj.mgs(mgs_num).data.logs, 'WTX'))
                info_table = {'Flight'; 'Date'; 'Duration (second)'; ...
                    'Air-Ground Available'; 'Ground-Air Available'; ...
                    'Modulation & Coding'; ...
                    'Video Mode Available'; ...
                    'Air-Ground Load (kbit)'; ...
                    'Ground-Air Load (kbit)'; ...
                    'Total Load (kbit)'; ...
                    'Average Throughput (kbit/s)'};
                Parameter = {''; ''; ''; ''; ''; ''; ''; ''; ''; ''; ''};
                Parameter{1} = obj.info.name;
                Parameter{2} = obj.info.date;
                if (isfield(obj.sdar.data.logs.WRX, 'x8Rate')) % If have data for WBR
                    % Parameter 3
                    min1 = 86400;
                    max1 = 0;
                    l = fieldnames(obj.sdar.data.logs.WRX.x8Rate);
                    for q=1:1:length(l)
                        min1 = min(min([min1]), min([obj.sdar.data.logs.WRX.x8Rate.(l{q}).sdar_utc]));
                    end
                    for q=1:1:length(l)
                        max1 = max(max([max1]), max([obj.sdar.data.logs.WRX.x8Rate.(l{q}).sdar_utc]));
                    end
                    Parameter{3} = num2str(round(max1-min1));
                    
                    % Parameter 4
                    Parameter{4} = 'Yes';
                    
                    % Parameter 5
                    Parameter{5} = 'No Recorded Data';
                    if isfield(obj.mgs(mgs_num).data.logs.WTX, 'x8Rate')
                        Parameter{5} = 'Yes';
                    end
                    
                    % Parameter 6
                    Parameter{6} = l{q};
                    for q=1:1:length(l)
                        Parameter{6} = strcat(Parameter{6}, {' '}, l{q});
                    end
                    Parameter{6} = char(Parameter{6});
                    
                    % Parameter 7: TO-DO: Update this section
                    dlg_title = 'Video Mode';
                    num_lines = 1;
                    defaultans = {'No'};
                    %Parameter{7} = char(inputdlg({'Do you have Video Mode with this flight:'},dlg_title,num_lines,defaultans));
                    
                    % Parameter 8
                    data_t = 0;
                    for q=1:1:length(l)
                        data_t = data_t + sum([obj.sdar.data.logs.WRX.x8Rate.(l{q}).val]*8/1000.0);
                    end
                    Parameter{8} = num2str(data_t);
                    
                    % Parameter 9
                    data_t2 = 0;
                    if (isfield(obj.mgs(mgs_num).data.logs.WTX, 'x8Rate'))
                        data_t2 = sum([obj.mgs(mgs_num).data.logs.WTX.x8Rate.val])*8/1000.0;
                    end
                    Parameter{9} = num2str(data_t2);
                    
                    % Parameter 10
                    Parameter{10} = num2str(data_t + data_t2);
                    
                    % Parameter 11
                    Parameter{11} = num2str((data_t + data_t2)/round(max1-min1));
                    
                else % If do not have data for WBR
                    Parameter{3} = num2str(0);
                    Parameter{4} = 'No Recorded Data';
                    Parameter{5} = 'No Recorded Data';
                    Parameter{6} = 'N/A';
                    Parameter{7} = 'No';
                    Parameter{8} = num2str(0);
                    Parameter{9} = num2str(0);
                    Parameter{10} = num2str(0);
                    Parameter{11} = num2str(0);
                end
                T = table(Parameter,'RowNames',info_table);
                fig = figure;
                % Output the Table
                
                TString = evalc('disp(T)');
                TString = strrep(TString,'<strong>','\bf');
                TString = strrep(TString,'</strong>','\rm');
                TString = strrep(TString,'_','\_');
                FixedWidth = get(0,'FixedWidthFontName');
                annotation(fig,'Textbox','String',TString,'Interpreter','Tex',...
                    'FontName',FixedWidth,'Units','Normalized',...
                    'Position',[0.181249999999999 0.376947052103704 0.6494791474659 0.399792304074901], ...
                    'FontSize',obj.label_size, 'FitBoxToText','on');
                annotation(fig,'textbox',...
                    [0.419270833333333 0.86988217039477 0.24401040954981 0.0637583876949562],...
                    'String','WBR Result Summary',...
                    'LineStyle','none',...
                    'FontWeight','bold',...
                    'FontSize',30,...
                    'FontName','Courier New');
                
                % ------------------ Report content --------------------------%
                obj.set_report_content( fig, 'WBR Flight Test Summary', ...
                    'WBR Summary', 3, 'WBR (air)', 'table', T);
                % ------------------------------------------------------------%
                
            end
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
            
            if(~isempty(p.Results.table))
                
                fig_info.istable = true;
                fig_info.table = p.Results.table;
                
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
            
            if(exist(['data/' desc]))
                
                fig_info.description = fileread(['data/' desc]);
                
            else
                
                fig_info.description = desc;
                
            end
            
            
            % -- Set fig info
            set(fig, 'UserData', fig_info);
            
            % -- Section Tag [ 'Priority' ';' 'name' ]
            set(fig, 'tag', [num2str(section_priority, '%d') ';' tag]);
            
        end
        
        function fig=table_figure(obj,t)
            fig=uitable('Data',table2cell(t),...
                'ColumnName',strcat('<html><h1>',t.Properties.VariableNames,'</h1></html>'),...
                'RowName',strcat('<html><h1>',t.Properties.RowNames,'</h1></html>'),...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],'OuterPosition',[0 0 1 1],...
                'ColumnWidth',{300},...
                'FontWeight','bold','FontSize',18,'FontName','Arial');
            
        end
        
        function fig=table_figure_2(obj, t)
            
            % Creates a figure with a table
            
            %fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            fig =figure('pos',obj.fig_size,'Color',obj.fig_bg);
            
            % Get the table in string form.
            TString = evalc('disp(t)');
            % Use TeX Markup for bold formatting and underscores.
            TString = strrep(TString,'<strong>','\bf');
            TString = strrep(TString,'</strong>','\rm');
            TString = strrep(TString,'_','\_');
            % Get a fixed-width font.
            FixedWidth = get(0,'FixedWidthFontName');
            % Output the table using the annotation command.
            %             annotation(gcf,'Textbox','String',TString,'Interpreter','Tex',...
            %                 'FontName',FixedWidth,'Units','Normalized','Position',[0 0 1 1], 'FitBoxToText', 'on');
            annotation(gcf,'Textbox','String',TString,'Interpreter','Tex',...
                'FontName','FixedWidth','Units','Normalized','Position',[0 0 1 1], 'FitBoxToText', 'on');
            
            
        end
        
        function dist=utc2slant_range(obj,sdar_utc,ref_lon,ref_lat,ref_alt)
            % get interpolated distance
            wgs84 = referenceEllipsoid('wgs84','meters');
            [ilon,ilat,ialt]= obj.ref_data.utc2pos(sdar_utc);
            [elevationangle,slantrange,azimuthangle] = ...
                elevation(ilat,ilon,ialt,ref_lat,ref_lon,ref_alt,'degrees',wgs84);
            dist=slantrange;
        end
        function [xr,yr,zr]=utc2enu(obj,utc,ref_lat,ref_lon,ref_alt)
            %get gps data
            [lon,lat,alt]=obj.ref_data.utc2pos(utc);
            wgs84 = wgs84Ellipsoid('meters');
            [x,y,z]=geodetic2ecef(wgs84,lat,lon,alt);
            [xr,yr,zr]=ecef2enu(x,y,z,ref_lat,ref_lon,ref_alt,wgs84);
        end
        
        function figs=get_general_figs(obj)
            obj.L.info('get_general_figs','Start')
            cmds={
                'fig=obj.plot_symon_time(4);'
                'fig=obj.plot_modes_time(4);'
                'fig=obj.pie_modes_time;'
                'fig=obj.fig_table_modes_time;'
                'fig=obj.plot_modes_trajectory;'
                'fig=obj.plot_gains(1,-17,4);'
                'fig=obj.plot_gains(2,-17,4);'
                };
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
        end
        
        function figs=get_dme_figs(obj,dme_id)
            figs=[];
            obj.L.info('get_dme_figs',['Init ' dme_id])
            if (~isfield(obj.sdar.data.logs,dme_id))
                return
            end
            if(~isfield(obj.sdar.data.logs.(dme_id),'DME_dist'))
                return
            end
            dme_struct=obj.sdar.data.logs.(dme_id).DME_dist;
            sts=fieldnames(dme_struct);
            valid_sts={};
            for idx=1:length(sts)
                if ~isempty(dme_struct.(sts{idx}))
                    valid_sts=horzcat(valid_sts,sts{idx});
                end
            end
            %generate cmds
            
            for idx=1:length(valid_sts)
                st=valid_sts{idx};
                obj.L.info('get_dme_figs',['Start ' dme_id ' ' st])
                cmds={};
                cmds=horzcat(cmds,...
                    {['fig=obj.plot_dme_distance(''' dme_id ''',''' st ''',4);']
                    ['fig=obj.plot_dme_error(''' dme_id ''',''' st ''',4);']
                    ['fig=obj.hist_dme_error(''' dme_id ''',''' st ''');']
                    ['fig=obj.pie_dme_error(''' dme_id ''',''' st ''');']
                    ['fig=obj.plot_dme_enu(''' dme_id ''',''' st ''');']
                    ['fig=obj.hist_dme_rate(''' dme_id ''',''' st ''',4,15);']
                    ['fig=obj.tab_dme_summary(''' dme_id ''',''' st ''',15);']});
                figs.(st)=[];
                for i=1:length(cmds)
                    try
                        eval(cmds{i});
                        set(fig, 'Visible','off')
                        figs.(st)=[figs.(st) fig];
                    catch ME
                        obj.L.warn('get_dme_figs',['cmd skipped:' cmds{i} ' ' ME.message ...
                            ' in ' ME.stack(1).name ' line:' num2str(ME.stack(1).line)]);
                        for stack=ME.stack.'
                            obj.L.debug(cmds{i},[stack.name ' line: ' num2str(stack.line)] )
                        end
                    end
                end
            end
        end
        function figs=get_tms_figs(obj)
            obj.L.info('get_tms_figs','Start')
            cmds={
                'fig=obj.plot_tms_distance(4);';
                'fig=obj.plot_tms_enu();'
                'fig=obj.tab_tms_summary()'
                };
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
        end
        function figs=get_wbr_figs(obj)
            for q=1:length(obj.mgs)
                obj.L.info('get_wbr_figs',['Start MGS' num2str(q)])
                cmds={
                    'fig=obj.plot_wbr_ber(4);'
                    'fig=obj.plot_wbr_8rate(4);'
                    'fig=obj.get_wbr_summary(q,4);'
                    'fig=obj.plot_snr_distance(4);'
                    'fig=obj.plot_power_sdar(4);'
                    };
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
            end
        end
        
        
        function figs=get_mgs_figs(obj)
            
            figs=[];
            
            for i=1:length(obj.mgs)
                obj.L.info('get_mgs_figs',['Start MGS' num2str(i)])
                cmds={
                    'fig=obj.plot_adsbin_fl(i,true);'
                    'fig=obj.pie_sadsb_RS(i);'
                    'fig=obj.tab_stats_RS(i);'
                    'fig=obj.plot_hist_RS(i);'
                    'fig=obj.plot_sadsb_enu(i);'
                    'fig=obj.plot_sadsb_records_vs_slant(i, 4);'
                    'fig=obj.plot_mgs_wbr_mod(i, 4);'
                    'fig=obj.hist_adsbin(i);'
                    'fig=obj.hist_adsb_distances(i);'
                    'fig=obj.pie_adsbin_id(i);'
                    'fig=obj.tab_adsb_summary(i);'
                    };
                
                
                for j=1:length(cmds)
                    try
                        eval(cmds{j});
                        set(fig, 'Visible','off')
                        figs=[figs fig];
                    catch ME
                        obj.L.warn('get_mgs_figs',['cmd skipped:' cmds{j} ' ' ME.message ...
                            ' in ' ME.stack(1).name ' line:' num2str(ME.stack(1).line)]);
                        for stack=ME.stack.'
                            obj.L.debug(cmds{i},[stack.name ' line: ' num2str(stack.line)] )
                        end
                    end
                end
                
            end
        end
        
        
        function figs=get_all_figs(obj, save_path)
            obj.L.info('get_all_figs',['Start ' obj.info.name])
            
            %set defaults
            set(groot,'defaultAxesFontSize',16)
            set(groot,'defaultLineLineWidth',3)
            set(groot,'defaultAxesFontName','Arial')
            set(groot,'defaultAxesFontWeight','bold')
            % Flush old
            figs_dir=dir(fullfile(save_path,'*.fig'));
            cellfun(@delete,fullfile({figs_dir.folder}.',{figs_dir.name}.'));
            % SDAR-General
            figs.sdar.general=obj.get_general_figs();
            % SDAR-DME
            figs.sdar.dme1=obj.get_dme_figs('DME1');
            figs.sdar.dme2=obj.get_dme_figs('DME2');
            %TMS
            figs.sdar.tms=obj.get_tms_figs();
            % SDAR-ADS-B/in
            % SDAR-WBR
            figs.sdar.wbr=obj.get_wbr_figs();
            % MGS
            figs.mgs = obj.get_mgs_figs();
            
            recursave(figs,0, save_path);
            
            %stats
            figs_dir=dir(fullfile(save_path,'*.fig'));
            obj.L.info('get_all_figs',[num2str(length(figs_dir)) ...
                ' figure(s) were generated'])
            
        end
    end
end

