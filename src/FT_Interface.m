classdef FT_Interface
    %Interface: Provides an interface to the Flight test
    %           data structure
    
    properties
        
        %Flight test data structure
        ft_data
        
        %Flight test informations and parameters
        ft_info
        
        %Flight Type
        ft_type
        
        ft_gen_notes
        ft_rptappendix
        
        L; % logger class
        
        version='x.xx'
        
    end
    
    methods
        
        %% Constructor
        %
        % Input mode can be
        % specified through a name/value pair argument
        %
        % Ex.: set_ft_info('mode', 'GUI')
        %
        % Supported input modes:
        %
        % - Default: Get the flight test information from the command prompt
        % - GUI: Get the flight test information from a GUI
        %
        function obj = FT_Interface(varargin)
            
            % input parsing
            
            p = inputParser;
            addParameter(p,'mode', 'default');
            % set logger
            obj.L=log4m.getLogger2('interface.log');
            obj.L.setFilename('interface.log');
            obj.L.setLogLevel(obj.L.ALL);
            obj.L.info('init','start')
            try
                
                parse(p, varargin{:});
                
            catch ME
                
                warning('Error setting flight test info')
                obj.L.warn('init','Error setting flight test info')
                for stack=ME.stack.'
                    obj.L.debug('|_',[stack.name ' line: ' num2str(stack.line)] )
                end
                return
                
            end
            
            % Get flight test information
            disp(strcat({'Input mode: '}, p.Results.mode));
            if(strcmp(p.Results.mode, 'GUI'))
                all_modes = {'SDAR Cessna'; 'SDAR Piaggio';'SDAR X-Plane'; 'DRFS Cessna'; 'DRFS X-Plane'};
                [option, out] = listdlg('PromptString', 'SELECT INPUT OPTION: ', ...
                    'SelectionMode' , 'single', ...
                    'ListString', all_modes);
                if (out == 1)
                    switch option
                        case 1 %SDAR Cessna
                            obj.ft_type = 1;
                            obj = obj.info_from_UI; 
                        case 2 % SDAR Piaggio
                            % To-do: Put something here
                            obj.ft_type = 2;
                        case 3 % SDAR X-Plane
                            obj.ft_type = 3;
                            obj = obj.info_from_UI; 
                            disp('SDAR X-Plane inter')                           
                        case 4 % DRFS Cessna
                            obj = obj.info_from_DRFS_Cessna;
                            obj.ft_type = 4;
                        case 5 % DRFS X-Plane
                            obj = obj.info_from_DRFS_X_Plane;
                            obj.ft_type = 5;
                        otherwise
                            obj.ft_type = 0;
                    end
                else
                    % Do nothing here
                end
                
            elseif (strcmp(p.Results.mode, 'default'))
                
                obj = obj.info_from_prompt;
                
            end
            
            % Add option for flight type
            
            
            
            
            mkdir(obj.ft_info.ft_folder)
            
            ft = obj;
            save([obj.ft_info.ft_folder [obj.ft_info.name '.mat']], 'ft');
            
            obj.ft_rptappendix = table2cell(readtable('data\rpt_appendix.csv',...
                'Delimiter', ';',...
                'ReadVariableNames', false));
            
        end
        
        %% Main functions
        %
        % Creates the flight test analysis directory structure, the
        % directories are created in the relative path specified by the
        % ft_info.ft_folder property
        %
        function obj = create_dirs(obj)
            
            mkdir(obj.ft_info.ft_folder);
            
            % add to path
            addpath(genpath(obj.ft_info.ft_folder))
            
        end
        
        function obj = add_note(obj)
            
            [filename, pathname] = uigetfile('*.txt', 'Select a text file');
            obj.ft_gen_notes = fileread([pathname filename]);
            
        end
        
        % Saves the interface object inside the flight analysis directory
        %
        function obj = save_interface(obj)
            
            ft = obj;
            
            [filename, pathname] = uiputfile([obj.ft_info.name '.mat'], 'Save Flight test data');
            
            save([pathname filename], 'ft');
            
        end
        
        % export to zip
        %
        function obj = export(obj)
            
            ft = obj;
            
            pathname = [uigetdir(ft.ft_info.ft_folder, 'Export flight test data to:') '\']
            zip([pathname [ft.ft_info.full_name '.zip']], ft.ft_info.ft_folder);
            
            
        end
        
        
        
        % Creates the ft_data object from the previously loaded files
        %
        function [obj,errno] = run_analysis(obj)
            
            tic
            
            obj.L.info('run_analysis','Analysis started')
            
            luts
            errno=0;
            try
                % Ublox
                if(isfield(obj.ft_info, 'ublox_file'))
                    ref = Ublox( obj.ft_info.ublox_file );
                    ref.plot_fiting
                elseif isfield(obj.ft_info, 'xplane_sdar')
                    ref = Xplane( obj.ft_info.xplane_sdar );
                    ref.plot_fiting
                else
                    ref = struct();
                    obj.L.error('run_analysis','Ref file not');
                end
                % SDAR
                if(isfield(obj.ft_info, 'sdar_file'))
                    [t_utc,t_sdar]=ref.get_utc_time();
                    s = SDAR(obj.ft_info.sdar_file, t_sdar(1),lut,@ref.fit_fnc);
                else
                    s = struct();
                    obj.L.warn('run_analysis','SDAR file not');
                end
                
                % MGSs
                if(isfield(obj.ft_info, 'mgs_info'))
                    for i=1:length(obj.ft_info.mgs_info)
                        m(i) = MGS(obj.ft_info.mgs_info(i).file_name, obj.ft_info.mgs_info(i));
                    end
                else
                    m = struct();
                    obj.L.warn('run_analysis','MGSs file not');
                end
                
                % FPGA
                if isfield(obj.ft_info, 'fpga_file')&& ...
                        exist(obj.ft_info.fpga_file, 'file') == 2
                    f=FPGA(obj.ft_info.fpga_file);
                else
                    f=[];
                    obj.L.warn('run_analysis','FPGA log not found.');
                end
                
                % Main flight test object
                obj.ft_data = FT_SDAR(s,ref,m,f,obj.get_info_cessna,lut);
                % add transcript
                if isfield(obj.ft_info, 'transcript')&& ...
                        exist(obj.ft_info.transcript, 'file') == 2
                    obj.ft_data=obj.ft_data.set_transcipt(obj.ft_info.transcript);
                else
                    obj.L.warn('run_analysis','transcript file not found.');
                end
            catch ME
                obj.L.error('run_analysis',['error :' ME.message ...
                    ' in ' ME.stack(1).name ' line:' num2str(ME.stack(1).line)]);
                for stack=ME.stack.'
                    obj.L.debug('run_analysis',[stack.name ' line: ' num2str(stack.line)] )
                end
                errno=1;
            end
              
            toc_time=datestr((toc)/(24*3600), 'HH:MM:SS.FFF');
            obj.L.info('run_analysis',[ 'Analysis Complete - ' 'Elapsed time =' toc_time])
            beep
            msgbox({'Analysis Done!' ...
                ['Elapsed time =' toc_time]})
            
            ft = obj;
            
            % save all
            save([obj.ft_info.ft_folder [obj.ft_info.name '.mat']], 'ft');
            
        end
        
        % Analyze things of xplane
        %
        function obj = run_analysis_xplane(obj)
            try
                % X-Plane
                x = table2struct(readtable(obj.ft_info.get_xplane,'Delimiter','|')); 
                display('DONE with X-Plane input');

                % DRFS
                if(isfield(obj.ft_info, 'get_vor') && obj.ft_info.get_vor(1) ~= '*')
                    drfs.vor = table2struct(readtable(obj.ft_info.get_vor,'Delimiter', ';','ReadVariableNames',false));
                else
                    drfs.vor = struct();
                end
                
                if(isfield(obj.ft_info, 'get_ils') && obj.ft_info.get_ils(1) ~= '*')
                    drfs.ils = table2struct(readtable(obj.ft_info.get_ils,'Delimiter', ';','ReadVariableNames',false));
                else
                    drfs.ils = struct();
                end
                
                % Main flight test object
                obj.ft_data = FT_XPlane(x,drfs, obj.ft_info);
            
            catch ME
                warndlg('Analysis Failed, Check input files');
                obj.L.warn('init','Error setting flight test info')
                for stack=ME.stack.'
                    obj.L.debug('|_',[stack.name ' line: ' num2str(stack.line)] )
                end
            end
            
            ft = obj; 
            save([obj.ft_info.ft_folder [obj.ft_info.name '.mat']], 'ft');            
        end
        
        
        % Generates the automated report
        %
        function out = generate_report(obj)
            
            try
                
                tic
                
                report('data/generic_report', '-debug');
                
                toc_time=datestr((toc)/(24*3600), 'HH:MM:SS.FFF');
            obj.L.info('generate report',[ 'Complete - ' 'Elapsed time =' toc_time])
            beep
            msgbox({'Repport Done!' ...
                ['Elapsed time =' toc_time]})
                
            catch ME
                
                disp('Error generating report')
                disp(ME.message)
                
            end
            
            
        end
        
        % generates and saves all figures
        %
        function out = save_figs(obj)
            
            tic
            
            obj.ft_data.get_all_figs(obj.ft_info.ft_folder)
            
            toc_time=datestr((toc)/(24*3600), 'HH:MM:SS.FFF');
            obj.L.info('save_figs',[ 'Figures Done - ' 'Elapsed time =' toc_time])
            beep
            msgbox({'Figures Done!' ...
                ['Elapsed time =' toc_time]})
        end
        
        
        
        %% Utils
        
        function obj = set_logger(obj)
            
            % set logger
            obj.L=log4m.getLogger2('interface.log');
            obj.L.setFilename('interface.log');
            obj.L.setLogLevel(obj.L.ALL);
            obj.L.info('set_logger', ['logger set for: ' obj.ft_info.name])
            
        end
        
        function txt = ft_info_to_txt(obj)
            
            txt = evalc('disp(obj.ft_info)');
            txt = strsplit(txt, '\n')';
            txt = char(txt);
            if(size(txt, 2) > 45)
                txt = txt(:,1:45);
            end
            
        end
        
        
        % constructs info for the FT_Cesna object of the FT_Interface
        %
        function info = get_info_cessna(obj)
            
            info.name = obj.ft_info.name;
            info.date = obj.ft_info.date;
            
            info.departure.longitude = obj.ft_info.departure.longitude;
            info.departure.latitude = obj.ft_info.departure.latitude;
            info.departure.name = obj.ft_info.departure.name;
            info.departure.elevation_m = obj.ft_info.departure.elevation_m;
            
            info.arrival.longitude = obj.ft_info.arrival.longitude;
            info.arrival.latitude = obj.ft_info.arrival.latitude;
            info.arrival.name = obj.ft_info.arrival.name;
            info.arrival.elevation_m = obj.ft_info.arrival.elevation_m;
            
        end
        
        % gets info from the command window
        function obj = info_from_prompt(obj)
            
            %look up table with information about the fligth tests
            luts;
            
            prompt = 'Flight test name: ';
            obj.ft_info.name = input(prompt,'s');
            
            prompt = 'Flight test date (yyyymmdd): ';
            obj.ft_info.date = input(prompt,'s');
            
            obj.ft_info.full_name = [obj.ft_info.name, ' ', obj.ft_info.date];
            
            % place results in temp folder
            obj.ft_info.ft_folder = strcat('temp\', obj.ft_info.full_name, '\');
            
            % TO DO: Ask to fill all other info (departure, arrival, ...)
            
            % set defaults for now
            
            obj.ft_info.departure.name = 'CYHU';
            obj.ft_info.departure.id = 'cyhu';
            obj.ft_info.departure.latitude = 45.518333;
            obj.ft_info.departure.longitude = -73.416667;
            obj.ft_info.departure.elevation_m = 27.432;
            
            obj.ft_info.arrival = obj.ft_info.departure;
            
            
            disp('Note: departure and arrival set to default')
            
            disp('departure')
            disp(obj.ft_info.departure)
            
            disp('arrival')
            disp(obj.ft_info.arrival)
            
            try
                % --- load the files
                [ufile, upath, FilterIndex] = uigetfile({'*.txt'},'ublox file','B:\Collaboration\');
                obj.ft_info.ublox_file = [upath ufile];
                
                [sfile, spath, FilterIndex]  = uigetfile({'*.txt'},'sdar parsed file', obj.ft_info.ublox_file);
                obj.ft_info.sdar_file = [spath sfile];
                
                
            catch ME
                
                disp(ME.message)
                
            end
            
            % get mgs info in a loop
            done = false;
            i = 1;
            
            
            prompt = 'add an MGS system ? (y/n)';
            sel = input(prompt,'s');
            
            if(strcmp(sel, 'y'))
                
                while(~done)
                    
                    try
                        
                        
                        
                        prompt = 'MGS system name: ';
                        obj.ft_info.mgs_info(i).sys_name = input(prompt,'s');
                        
                        % Could use a loop to go throug all saved locations
                        prompt = [  'MGS location: ' char(10) '1)' lut.mgs(1).name ...
                            char(10) '2)' lut.mgs(2).name char(10) ];
                        
                        
                        indx = input(prompt);
                        
                        obj.ft_info.mgs_info(i).longitude = lut.mgs(indx).longitude;
                        obj.ft_info.mgs_info(i).latitude = lut.mgs(indx).latitude;
                        obj.ft_info.mgs_info(i).elevation_m = lut.mgs(indx).elevation_m;
                        
                        [mfile,mpath, FilterIndex]  = uigetfile({'*.txt'},[obj.ft_info.mgs_info(i).sys_name ' - mgs parsed file'], obj.ft_info.ublox_file);
                        
                        obj.ft_info.mgs_info(i).file_name = [mpath mfile];
                        
                        prompt = 'add an other ? (y/n)';
                        sel = input(prompt,'s');
                        
                        if(strcmp(sel, 'y'))
                            
                            i = i + 1;
                            
                        else
                            
                            done = true;
                            
                        end
                        
                        
                    catch ME
                        
                        disp(ME.message)
                        done = true;
                        
                    end
                    
                end
                
            else
                
                %empty struct
                obj.ft_info.mgs_info = struct();
                
                done = true;
                
            end
            
            
            
        end
        
        function obj = info_from_UI(obj)
            switch obj.ft_type
                case 1 % FT_SDAR
                    ft_info = load('data/form_ft_info.mat');
                case 3
                    ft_info = load('data/form_ft_info_xplane.mat');
                otherwise
                    error('no form is available for this type')
                    
            end
            obj.ft_info = ft_info.form_ft_info;
            mgs_info = obj.ft_info.mgs_info;
            obj.ft_info=rmfield(obj.ft_info,'mgs_info');
            obj.ft_info.number_of_ground_stations = 0;
            obj.ft_info=StructDlg(obj.ft_info);
            for i=1:obj.ft_info.number_of_ground_stations
                obj.ft_info.mgs_info(i) = StructDlg(mgs_info);
            end
            obj.ft_info.full_name = [obj.ft_info.name, ' ', obj.ft_info.date];
            % place results in temp folder
            obj.ft_info.ft_folder = strcat('temp\', obj.ft_info.full_name, '\');
            obj.ft_info=rmfield(obj.ft_info,'number_of_ground_stations');
        end
        
        function obj = info_from_DRFS_X_Plane(obj)
            ft_info = load('data/form_xplane_info.mat');
            obj.ft_info = ft_info.form_xplane_info;
            obj.ft_info=StructDlg(obj.ft_info);
            obj.ft_info.full_name = [obj.ft_info.name, ' ', obj.ft_info.date];
            % place results in temp folder
            obj.ft_info.ft_folder = strcat('temp\', obj.ft_info.full_name, '\');
        end
        
        function obj = info_from_DRFS_Cessna(obj)
            ft_info = load('data/form_drfs_cessna_info.mat');
            obj.ft_info = ft_info.form_drfs_cessna_info;
            obj.ft_info=StructDlg(obj.ft_info);
            obj.ft_info.full_name = [obj.ft_info.name, ' ', obj.ft_info.date];
            % place results in temp folder
            obj.ft_info.ft_folder = strcat('temp\', obj.ft_info.full_name, '\');
        end
        
        function obj = add_mgs(obj)
            
            % get mgs info in a loop
            done = false;
            i = length(obj.ft_info.mgs_info) + 1;
            
            while(~done)
                
                try
                    
                    prompt = 'MGS system name: ';
                    obj.ft_info.mgs_info(i).sys_name = input(prompt,'s');
                    
                    % Could use a loop to go throug all saved locations
                    prompt = [  'MGS location: ' char(10) '1)' lut.mgs(1).name ...
                        char(10) '2)' lut.mgs(2).name char(10) ];
                    
                    
                    indx = input(prompt);
                    
                    obj.ft_info.mgs_info(i).longitude = lut.mgs(indx).longitude;
                    obj.ft_info.mgs_info(i).latitude = lut.mgs(indx).latitude;
                    obj.ft_info.mgs_info(i).elevation_m = lut.mgs(indx).elevation_m;
                    
                    [mfile,mpath, FilterIndex]  = uigetfile({'*.txt'},[obj.ft_info.mgs_info(i).sys_name ' - mgs parsed file'], obj.ft_info.upath);
                    
                    obj.ft_info.mgs_info(i).file_name = [mpath mfile];
                    
                    prompt = 'add an other ? (y/n)';
                    sel = input(prompt,'s');
                    
                    if(strcmp(sel, 'y'))
                        
                        i = i + 1;
                        
                    else
                        
                        done = true;
                        
                    end
                    
                catch ME
                    
                    disp(ME.message)
                    done = true;
                    
                end
                
            end
            
        end
        
    end
    
    %% Static methods
    methods(Static)
        
        function ft = import()
            
            
            [filename, pathname] = uigetfile({'*zip'}, 'Import flight test data');
            %dest = uigetdir(ft.ft_info.ft_folder, 'Destination');
            unzip([pathname filename]);
            
            addpath(genpath('temp\'))
            
            fpath = char(strsplit(filename, '.'))
            fpath = ['temp\' fpath(1,:) '\']
            
            fpath = uigetfile([fpath '*.mat'], 'select the flight test mat file');
            
            ft = load(fpath);
            fnames = fieldnames(ft);
            for i = 1:length(fnames)
                if(isa(ft.(char(fnames(i))), 'FT_Interface'))
                    ft = ft.(char(fnames(i)));
                    break;
                end
            end
            
            
        end
        
        
        function ft = load_interface()
            
            [fname,fpath,filter] = uigetfile('*.mat', 'load a flight test mat file');
            
            ft = load([fpath fname]);
            fnames = fieldnames(ft);
            for i = 1:length(fnames)
                if(isa(ft.(char(fnames(i))), 'FT_Interface'))
                    ft = ft.(char(fnames(i)));
                    break;
                end
            end
        end
        
    end
    
end

