%% This code will load and plot all the figures as the results of the Flight Tests
%% Author: Anh-Quang NGUYEN

function [ ] = VOR_processing_final(FTpath, VOR1, on_off)
ILS_enable = 0;
VOR_enable = 0;
VHF_enable = 0;
mkdir (strcat(FTpath,'/Output_files/Figures/FIG/VHF'))

%% Load data
if (exist(strcat(FTpath,'/Output_files/VHF/VOR2_saved_data.mat'), 'file') == 2)
    load (strcat(FTpath,'/Output_files/VHF/VOR2_saved_data.mat'))
    VOR_enable = 1;
else
    % ERROR notice should be placed here
end

if (exist(strcat(FTpath,'/Output_files/VHF/VOR1_saved_data.mat'), 'file') == 2)
    load (strcat(FTpath,'/Output_files/VHF/VOR1_saved_data.mat'))
    VOR_enable = 1;
else
    % ERROR notice should be placed here
end

if (exist(strcat(FTpath,'/Output_files/VHF/GPS_data.mat'), 'file') == 2)
    load (strcat(FTpath,'/Output_files/VHF/GPS_data.mat'))
else
    % ERROR notice should be placed here
end

if (exist(strcat(FTpath,'/Input_files/', 'VOR_Station.mat'), 'file') == 2)
    load (strcat(FTpath,'/Input_files/', 'VOR_Station.mat'));
else
    % ERROR notice should be placed here
    VOR_enable = 0;
end

if (exist(strcat(FTpath,'/Output_files/VHF/Error_VOR1.mat'), 'file') == 2)
    load (strcat(FTpath,'/Output_files/VHF/Error_VOR1.mat'));
else
    % ERROR notice should be placed here
end

if (exist(strcat(FTpath,'/Output_files/VHF/VHF_data.mat'), 'file') == 2)
    load (strcat(FTpath,'/Output_files/VHF/VHF_data.mat'));
    VHF_enable = 1;
else
    % ERROR notice should be placed here
end

if (exist(strcat(FTpath,'/Output_files/VHF/data_ILS_lock.mat'), 'file') == 2)
    load (strcat(FTpath,'/Output_files/VHF/data_ILS_lock.mat'));
    ILS_enable = 1;
else
    % ERROR notice should be placed here
end

if (exist(strcat(FTpath,'/Output_files/VHF/data_ILS_saved.mat'), 'file') == 2)
    load (strcat(FTpath,'/Output_files/VHF/data_ILS_saved.mat'))
    ILS_enable = 1;
else
	% ERROR notice should be placed here
end

if (exist(strcat(FTpath,'/Input_files/', 'Aeroport_Data.mat'), 'file') == 2)
    load (strcat(FTpath,'/Input_files/', 'Aeroport_Data.mat'));
else
    % ERROR notice should be placed here
    ILS_enable = 0;
    VHF_enable = 0;
end

if (exist(strcat(FTpath,'/Input_files/', 'Station_ID.mat'), 'file') == 2)
    load (strcat(FTpath,'/Input_files/', 'Station_ID.mat'));
else
    % ERROR notice should be placed here
    ILS_enable = 0;
    VOR_enable = 0;
end

%% Figure Parameters
legend_size = 12;
title_size = 20;
title_color = 'black';
label_size = 12;
line_size = 2;

%% Configurations
if (VOR_enable == 1)
    VOR1_Freq = VOR1;
    for i=1:1:size(VOR_station,1)
        if VOR1_Freq == VOR_station(i,1)
            station1 = i;
            i = size(VOR_station,1);
        end
    end


    %% Plot
    f = figure('visible',on_off, 'Color',[1 1 1]);
    plot(GPS_data(:,5), GPS_data(:,4), '--b')
    hold on
    scatter(VOR_station(station1,3), VOR_station(station1,2), 'rx', 'LineWidth',3)
    xlabel('Longitude (degree)', 'FontSize', label_size)
    ylabel('Latitude (degree)', 'FontSize', label_size)
    if (ILS_enable)
        scatter(Aeroport_data(1).Position(2),Aeroport_data(1).Position(1), 'bo', 'LineWidth',10)
        scatter(Aeroport_data(2).Position(2),Aeroport_data(2).Position(1), 'ro', 'LineWidth',10)
        scatter(Aeroport_data(3).Position(2),Aeroport_data(3).Position(1), 'co', 'LineWidth',10)         
    end
    hold off    
    if (ILS_enable)
        legend({'Trajectory',Station_ID(station1,:), 'CHYU', 'CYUL', 'CYMX'},'FontSize',legend_size)        
    else
        legend({'Trajectory',Station_ID(station1,:)},'FontSize',legend_size)
    end
    title(['2D Flight Path and VOR ',Station_ID(station1,:),' Station'], 'FontSize',title_size, 'color', title_color)
    set(f, 'Name', '2D_Trajectory');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','2D_Trajectory'))
    if (strcmp(on_off, 'off'))
        delete(f)
    end
    
    
    f = figure('visible',on_off, 'Color',[1 1 1]);
    plot3(GPS_data(:,5),GPS_data(:,4),GPS_data(:,6),'-b','LineWidth',2)
    hold on
    plot3(VOR_station(station1,3), VOR_station(station1,2), VOR_station(station1,4),'ro', 'LineWidth',5)
    hold on
    plot3(VOR_station(2,3), VOR_station(2,2), VOR_station(2,4),'bo', 'LineWidth',5)
    hold on
    plot3(VOR_station(3,3), VOR_station(3,2), VOR_station(3,4),'co', 'LineWidth',5)
    hold on
    plot3(VOR_station(4,3), VOR_station(4,2), VOR_station(4,4),'yo', 'LineWidth',5)
    xlabel('Longitude (degree)', 'FontSize', label_size)
    ylabel('Latitude (degree)', 'FontSize', label_size)
    zlabel('Altitude (ft)', 'FontSize', label_size)
    hold off
    legend({'Trajectory','YJN', 'YUL', 'BTV', 'YMX'},'FontSize',legend_size)
    title('Flight Path and VOR Stations', 'FontSize',title_size, 'color', title_color)
    set(f, 'Name', '3D_Trajectory');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','3D_Trajectory'))
    if (strcmp(on_off, 'off'))         
        delete(f)     
    end
    
    time_VOR = floor(VOR1_saved_data(:,1)/10000) + floor(mod(VOR1_saved_data(:,1),10000)/100)/60.0 + mod(VOR1_saved_data(:,1),100)/3600.0;

    f = figure('visible',on_off, 'Color',[1 1 1]);
    scatter((time_VOR-4)/24,VOR1_saved_data(:,6),'rx');
    hold on
    plot((time_VOR-4)/24,VOR1_saved_data(:,14), 'b');
    datetick('x', 'HH:MM:SS')
    xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
    ylabel('Radial (degree)', 'FontSize', label_size)
    hold off
    legend({'DRFS Results', 'GPS Bearing'} ,'FontSize',legend_size)
    title('GPS Radial vs DRFS Calculated Radial - VOR 1', 'FontSize',title_size, 'color', title_color)
    set(f, 'Name', 'VOR1_Radial_DRFS_GPS');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','VOR1_Radial_DRFS_GPS'))
    if (strcmp(on_off, 'off'))  
        delete(f)     
    end
    
    % figure
    % scatter(time_VOR2,VOR2_saved_data(:,9),'rx');
    % hold on
    % plot(time_VOR2,VOR2_saved_data(:,15), 'b');
    % xlabel('Time (h)', 'FontSize', label_size)
    % ylabel('Radial (degrees)', 'FontSize', label_size)
    % hold off
    % legend({'DRFS Results', 'GPS Bearing'} ,'FontSize',legend_size)
    % title('GPS Radial vs DRFS Calculated Radial - VOR 2', 'FontSize',title_size, 'color', title_color)      

    f = figure('visible',on_off, 'Color',[1 1 1]);
    subplot(211)
    plot((time_VOR(:,1)-4)/24,VOR1_saved_data(:,18), 'ob')
    datetick('x', 'HH:MM:SS')
    hold off
    xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
    ylabel('Distance to Station (NM)', 'FontSize', label_size)
    legend({'Distance to VOR1 station'} ,'FontSize',legend_size, 'Location','northeast')
    title('Distance between Airplane and VOR Station', 'FontSize',title_size*2/3, 'color', title_color)

    subplot(212)
    plot((time_VOR(:,1)-4)/24,VOR1_saved_data(:,16), '-b')
    datetick('x', 'HH:MM:SS')
    xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
    ylabel('Input Level (dBm)', 'FontSize', label_size)
    legend({'Signal Level (dBm)'} ,'FontSize',legend_size, 'Location','northeast')
    title('Received Signal Level', 'FontSize',title_size*2/3, 'color', title_color)
    set(f, 'Name', 'VOR1_Distance_Level');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','VOR1_Distance_Level'))
    if (strcmp(on_off, 'off'))      
        delete(f)    
    end
    
    %% Plot Distance and Power for VOR 2
    for i=1:1:size(VOR2_saved_data,2)
        if (~isempty(VOR2_saved_data{2,i}))
            f = figure('visible',on_off, 'Color',[1 1 1]);
            subplot(211)
            scatter((VOR2_saved_data{2,i}(:,24)-4)/24,VOR2_saved_data{2,i}(:,23), 'ob')
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Distance to Station (NM)', 'FontSize', label_size)
            legend('Distance between airplane and station' ,'FontSize',legend_size, 'Location','northeast')
            title(['Distance between Airplane and ',VOR2_saved_data{3,i}], 'FontSize',title_size*2/3, 'color', title_color)

            subplot(212)
            scatter((VOR2_saved_data{2,i}(:,24)-4)/24,VOR2_saved_data{2,i}(:,22), 'xr')
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)','FontSize', label_size)
            ylabel('Input Level (dBm)', 'FontSize', label_size)
            legend({'Signal Level (dBm)'} ,'FontSize',legend_size, 'Location','northeast')
            title(['Estimated Received Signal Level From ',VOR2_saved_data{3,i}], 'FontSize',title_size*2/3, 'color', title_color)
            set(f, 'Name', ['VOR2_Level_From_',VOR2_saved_data{3,i}]);
            set(f, 'tag', '1;VHF Result');
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','VOR2_Level_From_',VOR2_saved_data{3,i}))
            if (strcmp(on_off, 'off'))    
                delete(f)   
            end
            
            f = figure('visible',on_off, 'Color',[1 1 1]);
            scatter((VOR2_saved_data{2,i}(:,24)-4)/24,VOR2_saved_data{2,i}(:,20), 'ob')
            hold on
            scatter((VOR2_saved_data{2,i}(:,24)-4)/24,VOR2_saved_data{2,i}(:,14), 'xr')
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Bearing (degree)', 'FontSize', label_size)
            legend({'Reference', 'Measured'} ,'FontSize',legend_size, 'Location','northeast')
            title(['Bearing Results in VOR2 for ',VOR2_saved_data{3,i}], 'FontSize',title_size*2/3, 'color', title_color)
            set(f, 'Name', ['VOR2_Radial_From_',VOR2_saved_data{3,i}]);
            set(f, 'tag', '1;VHF Result');
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','VOR2_Radial_From_',VOR2_saved_data{3,i}))
            if (strcmp(on_off, 'off'))   
                delete(f)   
            end        
        end
    end


    f = figure('visible',on_off, 'Color',[1 1 1]);
    scatter((Error_VOR1(:,1)-4)/24, Error_VOR1(:,3), 'xr')
    hold on
    scatter((Error_VOR1(:,1)-4)/24, Error_VOR1(:,4), 'ob')
    hold off
    datetick('x', 'HH:MM:SS')
    xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
    ylabel('Absolute Error (degree)', 'FontSize', label_size)
    legend({'Measured','Reference'} ,'FontSize',legend_size, 'Location','northeast')
    title('Difference between GPS Bearing and Measured Bearing for VOR1', 'FontSize',title_size*2/3, 'color', title_color)
    set(f, 'Name', 'VOR1_Difference');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','VOR1_Difference'))
    if (strcmp(on_off, 'off'))  
        delete(f)   
    end   
    
    pd = fitdist(Error_VOR1(:,3),'Normal');
    plot_x = [0:1:30];
    plot_y = pdf(pd,plot_x);
    m = mean(pd);
    f = figure('visible',on_off, 'Color',[1 1 1]);
    scale = 1/max(plot_y);
    plot(plot_x, plot_y*100, 'LineWidth',line_size)
    xlabel('Difference in Degree', 'FontSize', label_size)
    ylabel('Percentage (%)', 'FontSize', label_size)
    legend('Measured','FontSize',legend_size, 'Location','northeast')
    title('Distribution of the Difference between GPS Bearing and Measured Bearing for VOR1', 'FontSize',title_size*2/3, 'color', title_color)
    set(f, 'Name', 'VOR1_Difference_Distribution');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','VOR1_Difference_Distribution'))
    if (strcmp(on_off, 'off'))  
        delete(f)   
    end   
end
    
%% VHF data section
if (VHF_enable == 1)
    f = figure('visible',on_off, 'Color',[1 1 1]);
    plot((VHF_data(:,9)-4)/24, VHF_data(:,4), 'b')
    hold on
    plot((VHF_data(:,9)-4)/24, VHF_data(:,5), '--r')
    hold off
    datetick('x', 'HH:MM:SS')
    xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
    ylabel('Estimated Input Level (dBm)', 'FontSize', label_size)
    legend({'VHF1','VHF2'} ,'FontSize',legend_size, 'Location','northeast')
    title('Estimated Input Level of VHF1 and VHF2', 'FontSize',title_size*2/3, 'color', title_color)
    set(f, 'Name', 'VHF_Estimated_Level');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','VHF_Estimated_Level'))
    if (strcmp(on_off, 'off'))  
        delete(f)   
    end   
    
    f = figure('visible',on_off, 'Color',[1 1 1]);
    plot(GPS_data(:,5), GPS_data(:,4), '--b')
    hold on
    scatter(VHF1_plot(:,5), VHF1_plot(:,4), 'rx', 'LineWidth',3)
    hold on
    scatter(VHF2_plot(:,5), VHF2_plot(:,4), 'g+', 'LineWidth',1)
    hold on
    %scatter(Aeroport_data(1).Position(2),Aeroport_data(1).Position(1), 'bo', 'LineWidth',10)
    %scatter(Aeroport_data(2).Position(2),Aeroport_data(2).Position(1), 'ro', 'LineWidth',10)
    %scatter(Aeroport_data(3).Position(2),Aeroport_data(3).Position(1), 'co', 'LineWidth',10)     
    xlabel('Longitude (degree)', 'FontSize', label_size)
    ylabel('Latitude (degree)', 'FontSize', label_size)
    %legend({'Trajectory','VHF1', 'VHF2', 'CHYU', 'CYUL', 'CYMX'},'FontSize',legend_size)
    legend({'Trajectory','VHF1', 'VHF2'},'FontSize',legend_size)
    title('2D Flight Path and VHF Radio Detection ', 'FontSize',title_size, 'color', title_color)
    set(f, 'Name', 'VHF_Flight_Path_Detection');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','VHF_Flight_Path_Detection'))
    if (strcmp(on_off, 'off'))  
        delete(f)   
    end       
end

%% ILS section
if (ILS_enable == 1)
    % LOC Frequency vs Time
    f = figure('visible',on_off, 'Color',[1 1 1]);
    % marker = {'o','+','-','*','s','d'};
    for i=1:1:size(data_ILS_lock,2)
        a = scatter((data_ILS_lock{2,i}(:,12)-4)/24, data_ILS_lock{2,i}(:,9));
        hold on
    end
    hold off
    datetick('x', 'HH:MM:SS')
    xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
    ylabel('LOC Frequency (MHz)', 'FontSize', label_size)
    legend(data_ILS_lock{3,:},'FontSize',legend_size);
    title('Saved LOC Frequency', 'FontSize',title_size, 'color', title_color);
    set(f, 'Name', 'LOC_Frequency');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','LOC_Frequency'))
    if (strcmp(on_off, 'off'))  
        delete(f)   
    end         

    % Altitude vs Time (ILS data)
    f = figure('visible',on_off, 'Color',[1 1 1]);
    for i=1:1:size(data_ILS_lock,2)
        a = scatter((data_ILS_lock{2,i}(:,12)-4)/24, data_ILS_lock{2,i}(:,6));
        data_ILS_lock{3,i} = [num2str(data_ILS_lock{1,i}),' MHz'];
        hold on
    end
    hold off
    datetick('x', 'HH:MM:SS')
    xlabel('Time (VOR2_saved_data)', 'FontSize', label_size)
    ylabel('Altitude (feet)', 'FontSize', label_size)
    legend(data_ILS_lock{3,:},'FontSize',legend_size);
    title('Altitude vs Tested LOC Frequency', 'FontSize',title_size, 'color', title_color);
    set(f, 'Name', 'LOC_Frequency_Altitude');
    set(f, 'tag', '1;VHF Result');
    savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','LOC_Frequency_Altitude'))
    if (strcmp(on_off, 'off'))  
        delete(f)   
    end    
    
    % Lock LOC/GS value vs Time
    for i=1:1:size(data_ILS_lock,2)
%         disp('PAST');
        if (size(data_ILS_lock{4,i},1) > 1)   
            disp('PAST 2');
            f = figure('visible',on_off, 'Color',[1 1 1]);
            a = scatter((data_ILS_lock{4,i}(:,12)-4)/24, data_ILS_lock{4,i}(:,10));
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('LOC DDM (DDM)', 'FontSize', label_size)
            legend('LOC value','FontSize',legend_size);
            title(['LOC DDM results at ', data_ILS_lock{3,i}], 'FontSize',title_size, 'color', title_color);
            disp('PAST 2.5');
            set(f, 'Name', ['LOC_DDM_Results_',data_ILS_lock{8,i}]);
            set(f, 'tag', '1;VHF Result');          
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','LOC_DDM_Results_',data_ILS_lock{8,i}))
            if (strcmp(on_off, 'off'))  
                delete(f)   
            end  
            disp('PAST 3');
        end
    end

    for i=1:1:size(data_ILS_lock,2)
        if (size(data_ILS_lock{4,i},1) > 1)
            f = figure('visible',on_off, 'Color',[1 1 1]);
            a = scatter((data_ILS_lock{4,i}(:,12)-4)/24, data_ILS_lock{4,i}(:,8));
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('GS DDM (DDM)', 'FontSize', label_size)
            legend('GS value','FontSize',legend_size);
            title(['GS results at ', data_ILS_lock{5,i}], 'FontSize',title_size, 'color', title_color);
            set(f, 'Name', ['GS_Result_',data_ILS_lock{8,i}]);
            set(f, 'tag', '1;VHF Result');           
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','GS_Result_',data_ILS_lock{8,i}))
            if (strcmp(on_off, 'off'))  
                delete(f)   
            end        
        end
    end

    % GS real and reference altitude
    for i=1:1:size(data_ILS_lock,2)
        if (size(data_ILS_lock{4,i},1) > 1)
            f = figure('visible',on_off, 'Color',[1 1 1]);
            scatter((data_ILS_lock{4,i}(:,12)-4)/24, data_ILS_lock{4,i}(:,20));
            hold on
            scatter((data_ILS_lock{4,i}(:,12)-4)/24, data_ILS_lock{4,i}(:,6));
            hold off
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Altitude(feet)', 'FontSize', label_size)
            legend({'Reference Altitude', 'GPS Altitude'},'FontSize',legend_size);
            title(['GS Reference Altitude and GPS Altitude for ', data_ILS_lock{5,i}], 'FontSize',title_size, 'color', title_color);
            set(f, 'Name', ['GS_Reference_Altitude_',data_ILS_lock{8,i}]);
            set(f, 'tag', '1;VHF Result');
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','GS_Reference_Altitude_',data_ILS_lock{8,i}))
            if (strcmp(on_off, 'off'))  
                delete(f)   
            end         
        end
    end


    % for i=1:1:size(data_ILS_lock,2)
    %     if (size(data_ILS_lock{4,i},1) > 1)
    %         figure
    %         scatter(data_ILS_lock{4,i}(:,12), data_ILS_lock{4,i}(:,21));
    %         hold on
    %         scatter(data_ILS_lock{4,i}(:,12), -data_ILS_lock{4,i}(:,30));
    %         xlabel('Time (Hour)', 'FontSize', label_size)
    %         ylabel('GS value (Degree)', 'FontSize', label_size)
    %         legend({'Reference Value', 'Measured Value'},'FontSize',legend_size);
    %         title(['GS Reference Degree and Measured Results for ', data_ILS_lock{5,i}], 'FontSize',title_size, 'color', title_color);
    %     end
    % end
    for i=1:1:size(data_ILS_lock,2)
        if (size(data_ILS_lock{7,i},1) > 1)
            f = figure('visible',on_off, 'Color',[1 1 1]);
            subplot(2,2,[1:2])
            scatter((data_ILS_lock{7,i}(:,12)-4)/24, data_ILS_lock{7,i}(:,21));
            hold on
            scatter((data_ILS_lock{7,i}(:,12)-4)/24, data_ILS_lock{7,i}(:,31));
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('GS value (degree)', 'FontSize', label_size)
            legend({'Reference Value', 'Measured Value'},'FontSize',legend_size);
            title(['DRFS Result and Reference for GS test at ', data_ILS_lock{8,i}], 'FontSize',title_size, 'color', title_color);

            subplot(2,2,3)
            scatter((data_ILS_lock{7,i}(:,12)-4)/24, data_ILS_lock{7,i}(:,32));
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Difference (degree)', 'FontSize', label_size)
            legend({'Ref vs Measured Difference in Degree'},'FontSize',legend_size);
            title(['Absolute Difference'], 'FontSize',title_size, 'color', title_color);

            subplot(2,2,4)
            scatter((data_ILS_lock{7,i}(:,12)-4)/24, data_ILS_lock{7,i}(:,33));
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Difference (degree)', 'FontSize', label_size)
            legend({'Ref vs Measured Difference in degree'},'FontSize',legend_size);
            title(['Corresponding Channel Level at  ', data_ILS_lock{5,i}], 'FontSize',title_size, 'color', title_color);
            set(f, 'Name', ['GS_Difference_Level_',data_ILS_lock{8,i}]);
            set(f, 'tag', '1;VHF Result');
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','GS_Difference_Level_',data_ILS_lock{8,i}))
            if (strcmp(on_off, 'off'))  
                delete(f)   
            end         
        end
    end

    % Trajectory
    for i=1:1:size(data_ILS_lock,2)
        if (size(data_ILS_lock{4,i},1) > 1)
            f = figure('visible',on_off, 'Color',[1 1 1]);
            scatter(data_ILS_lock{4,i}(1,14), data_ILS_lock{4,i}(1,13));
            hold on
            scatter(data_ILS_lock{4,i}(:,5), data_ILS_lock{4,i}(:,4));
            xlabel('Longitude (degree)', 'FontSize', label_size)
            ylabel('Latitude (degree)', 'FontSize', label_size)
    %         legend({'Reference Value', 'Measured Value'},'FontSize',legend_size);
            title(['Trajectory in ILS Test ', data_ILS_lock{5,i}], 'FontSize',title_size, 'color', title_color);
            set(f, 'Name', ['ILS_Trajectory_Test_',data_ILS_lock{8,i}]);
            set(f, 'tag', '1;VHF Result');
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','ILS_Trajectory_Test_',data_ILS_lock{8,i}))
            if (strcmp(on_off, 'off'))  
                delete(f)   
            end            
        end
    end

    % LOC reference and measured results
    for i=1:1:size(data_ILS_lock,2)
        if (size(data_ILS_lock{4,i},1) > 1)
            f = figure('visible',on_off, 'Color',[1 1 1]);
            scatter((data_ILS_lock{4,i}(:,12)-4)/24, data_ILS_lock{4,i}(:,16));
            hold on
            scatter((data_ILS_lock{4,i}(:,12)-4)/24, data_ILS_lock{4,i}(:,28));
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Bearing value (degree)', 'FontSize', label_size)
            legend({'Reference Value', 'GPS Value'},'FontSize',legend_size);
            title(['Reference Bearing and GPS Results for ', data_ILS_lock{3,i}], 'FontSize',title_size, 'color', title_color);
            set(f, 'Name', ['LOC_Reference_',data_ILS_lock{8,i}]);
            set(f, 'tag', '1;VHF Result');
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','LOC_Reference_',data_ILS_lock{8,i}))
            if (strcmp(on_off, 'off'))  
                delete(f)   
            end         
        end
    end
    
    % Distance to Airport
    for i=1:1:size(data_ILS_lock,2)
        if (size(data_ILS_lock{4,i},1) > 1)
            f = figure('visible',on_off, 'Color',[1 1 1]);
            scatter((data_ILS_lock{4,i}(:,12)-4)/24, data_ILS_lock{4,i}(:,19));
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Distance (NM)', 'FontSize', label_size)
            legend({'Distance to Airport'},'FontSize',legend_size);
            title(['Distance from Airplane to ', data_ILS_lock{3,i}], 'FontSize',title_size, 'color', title_color);
            set(f, 'Name', ['LOC_Distance_to',data_ILS_lock{8,i}]);
            set(f, 'tag', '1;VHF Result');
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','LOC_Distance_to',data_ILS_lock{8,i}))
            if (strcmp(on_off, 'off'))  
                delete(f)   
            end           
        end
    end 

    for i=1:1:size(data_ILS_lock,2)
        if (size(data_ILS_lock{6,i},1) > 1)
            f = figure('visible',on_off, 'Color',[1 1 1]);
            subplot(2,2,1)
            %set(subplot(2,2,[1 2]), 'Position', [0.1, 0.5, 0.7, 0.3])
            scatter((data_ILS_lock{6,i}(:,12)-4)/24, data_ILS_lock{6,i}(:,29));
            hold on
            scatter((data_ILS_lock{6,i}(:,12)-4)/24, data_ILS_lock{6,i}(:,10)*9.8561);
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Bearing value (degree)', 'FontSize', label_size)
            legend({'GPS Reference Value', 'Measured Value'},'FontSize',legend_size);
            title(['DRFS Result and Reference for LOC test at ', data_ILS_lock{8,i}], 'FontSize',title_size, 'color', title_color);

            subplot(2,2,2)
            scatter((data_ILS_lock{6,i}(:,12)-4)/24, data_ILS_lock{6,i}(:,34));
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Input Level (dBm)', 'FontSize', label_size)
            legend({'Estimated Level', 'Measured Value'},'FontSize',legend_size);
            title(['Corresponding LOC Level at ', data_ILS_lock{8,i}], 'FontSize',title_size, 'color', title_color);
    
            subplot(2,2,3)
            scatter((data_ILS_lock{6,i}(:,12)-4)/24, data_ILS_lock{6,i}(:,30),'rx');
            hold on
            ref = 0.093*0.11*4;
%             for q=1:1:length(ref)
%                 if (ref(q) < 0.093*0.05*4)
%                     ref(q) = 0.093*0.05*4;
%                 end
%             end
            plot((data_ILS_lock{6,i}(:,12)-4)/24, ref,'bo');
            datetick('x', 'HH:MM:SS')
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            ylabel('Error (degree)', 'FontSize', label_size)
            legend({'Error', 'Standard'},'FontSize',legend_size);
            title(['Absolute Error vs. Standard'], 'FontSize',title_size, 'color', title_color);

            subplot(2,2,4)
            scatter((data_ILS_lock{6,i}(:,12)-4)/24, data_ILS_lock{6,i}(:,19));        
            datetick('x', 'HH:MM:SS')
            ylabel('Distance (NM)', 'FontSize', label_size)
            xlabel('Time (HH:MM:SS)', 'FontSize', label_size)
            legend(['Distance to ',data_ILS_lock{8,i}],'FontSize',legend_size);
            set(f, 'Name', ['LOC_Summary_for_',data_ILS_lock{8,i}]);
            set(f, 'tag', '1;VHF Result');
            title(['Distance to ',data_ILS_lock{8,i},' (NM)'], 'FontSize',title_size, 'color', title_color);
            savefig(f,strcat(FTpath,'/Output_files/Figures/FIG/VHF/','LOC_Summary_for_',data_ILS_lock{8,i}))
            if (strcmp(on_off, 'off'))  
                delete(f)   
            end    
        end
    end
end
end

