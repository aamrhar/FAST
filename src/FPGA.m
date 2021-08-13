classdef FPGA
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        logs=struct()
        L; % logger class
    end
    
    methods
        function obj=FPGA(fpga_csv_logs)
            obj.L=log4m.getLogger('mgs.log');
            obj.L.setFilename('mgs.log');
            obj.L.setLogLevel(obj.L.INFO);
            raw=readtable(fpga_csv_logs, 'delimiter', ',');
            %TODO: clean and check if utc exixsts
            raw.fpga_time=raw.utc;
            temp=obj.faster_slicer_raw(raw);
            obj.logs=temp.logs;
            1+1;
        end
        function result = faster_slicer_raw(obj,raw_table)
            %UNTITLED9 Summary of this function goes here
            %   Detailed explanation goes here
            % slicing
            raw=raw_table;
            temp=struct();
            %get all srcs
            src_list=setdiff(raw.src,''); %list src fields
            raw_temp=table2struct(raw);
            %raw_temp=rmfield(raw_temp,'src'); % rm src field
            %split src
            for i=1:length(src_list)
                indexes=find(strcmp(raw.src,src_list(i)));
                %result(i).logs=struct('records',raw_temp(indexes));
                temp.logs.(src_list{i})=[raw_temp(indexes)];
            end
            fields = fieldnames(temp.logs);
            for i = 1:length(fields) %loop over src
                sub_struct=temp.logs.(fields{i});
                lab_list=unique({sub_struct.label});
                result.logs.(fields{i})=struct();
                for j=1:length(lab_list) %loop over label
                    indexes=find(strcmp({sub_struct.label},lab_list(j)));
                    try
                        result.logs.(fields{i}).(lab_list{j})=[sub_struct(indexes)];
                    catch ME
                        %Matlab doesn't like fields starting w/ numbers
                        if (strcmp(ME.identifier,'MATLAB:AddField:InvalidFieldName'))
                            new_lab=['x' (lab_list{j})];
                            disp(['Warning changed ' lab_list{j} 'to ' new_lab] )
                            result.logs.(fields{i}).(new_lab)=[sub_struct(indexes)];
                        end
                        
                    end
                end
                
            end
            
        end
    end
    
end

