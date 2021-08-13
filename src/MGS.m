classdef MGS
    %UNTITLED15 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        sys_name;
        file_name;
        fit_res;
        fit_func;
        info;
        data;
        
        L; % logger class
        
    end
    
    methods
        
        function obj=MGS(file_name,msg_info)
            
            % set logger
            obj.L=log4m.getLogger2('mgs.log');
            obj.L.setFilename('mgs.log');
            obj.L.setLogLevel(obj.L.INFO);
            
            
            obj.L.info('init','initialising MGS')
            obj.file_name=file_name;
            obj.info=msg_info;
            raw=readtable(file_name, 'delimiter', ';');
            % fitting
            obj.L.info('init','MGS fiting...')
            try
                raw=obj.fitting2(raw);
            catch ME
                obj.L.warn('init',[ME.message ...
                    ' ' 'in ' ME.stack.name ' line:' str2double([ME.stack.line])]);
                warning('No GPS found')
                obj.fit_func=@(x) (mod(x/1000,24*3600));
                [raw.sdar_utc]=obj.fit_func([raw.sdar_time]);
            end
            
            %slicing
            disp('slicing...')
            obj.data=obj.faster_slicer_raw(raw);
            %deep slicing
            cmds={'obj.data.logs.SADSBin.data=obj.adsb_slicer(obj.data.logs.SADSBin.data);'
                'obj.data.logs.ADSBin.data=obj.adsb_slicer(obj.data.logs.ADSBin.data);'
                'start=obj.data.logs.SADSBin.data.icao_abde55.DF18.TC9(1).sdar_time;'
                'start=obj.data.logs.SADSBin.data.icao_abde55.DF18.TC18(1).sdar_time;'
                'start=start-(20 * 60 * 1000);'
                'obj.data.logs.SADSBin.Signature_RS_CRC=obj.sadsb_slicer(obj.data.logs.SADSBin.Signature_RS_CRC,start,@obj.rs_check2)'
                };
            for i=1:length(cmds)
                try
                    eval(cmds{i});
                catch ME
                    obj.L.warn('init',['cmd skipped:' cmds{i} ' ' ME.message ...
                        ' ' 'in ' ME.stack.name ' line:' str2double([ME.stack.line])]);
                end
            end
            % clean up
            disp('Cleaning data ...')
            obj.data.logs=obj.faster_cleaner(obj.data.logs);
            
        end
        %% for fitting
        function fig=plot_fiting(obj,sdar_time,utc_time)
            fig=figure;
            subplot(2,2,[1 2])
            hold on
            legend('show')
            title('time ajustement')
            plot(utc_time,utc_time)
            plot(utc_time,mod(sdar_time/1000,24*3600))
            plot(utc_time,obj.fit_func(sdar_time))
            legend('reference','original (medfilt1(:51))','ajusted')
            hold off
            subplot(2,2,3)
            histogram(utc_time-mod(sdar_time/1000,24*3600))
            title('original(medfilt1(:51) error distribution')
            subplot(2,2,4)
            histogram(utc_time-obj.fit_func(sdar_time))
            title('ajusted error distribution')
        end
        
        function fig=plot_filtered(obj,utc_time,utc_time_filered)
            fig=figure;
            hold on
            title('Filered data')
            plot(utc_time,'- .',...
                'DisplayName','Original')
            plot(utc_time_filered,'- .',...
                'DisplayName','Filtered')
            legend('show')
        end
        function raw2=fitting1(obj,raw)
            %old fitting funtion
            % find GPS field
            idx=find(strcmp([raw.label],'UTC'));
            
            if ~isempty(idx)
                utc_time=[raw.val(idx)];
                if iscell(utc_time)
                    utc_time=str2double(utc_time);
                end
                utc_time_filtred=medfilt1(utc_time,51);
                hhmmss2sec=@(x) mod(x,100)+60*mod(floor(x/100),100)+3600*floor(x/10000);
                [xData, yData] = prepareCurveData(mod([raw.sdar_time(idx)]/1000,24*3600),hhmmss2sec(utc_time_filtred));
                ft = fittype( 'smoothingspline' );
                [fit_res, ~] = fit( xData, yData, ft );
                obj.fit_func=@(x) fit_res(mod(x/1000,24*3600));
                obj.plot_filtered(utc_time,utc_time_filtred);
                obj.plot_fiting([raw.sdar_time(idx)],hhmmss2sec(utc_time_filtred));
            else
                warning('No GPS found')
                obj.fit_func=@(x) (mod(x/1000,24*3600));
            end
            %Apply fiting
            [raw.sdar_utc]=obj.fit_func([raw.sdar_time]);
            raw2=raw;
        end
        function raw2=fitting2(obj,raw)
            %linear regresion
            % find GPS field
            idx=find(strcmp([raw.label],'UTC'));
            
            if ~isempty(idx)
                utc_time=[raw.val(idx)];
                if iscell(utc_time)
                    utc_time=str2double(utc_time);
                end
                
                hhmmss2sec=@(x) mod(x,100)+60*mod(floor(x/100),100)+3600*floor(x/10000);
                t=table;
                t.sdar_time=raw.sdar_time(idx);
                t.sdar_sec=mod(t.sdar_time/1000,3600*24);
                t.gps=hhmmss2sec(utc_time);
                t.sdar_diff=[0;diff(t.sdar_sec)];
                t.gps_diff=[0;diff(t.gps)];
                t.diff_diff=t.sdar_diff-t.gps_diff;
                t(1,:)=[];
                [xData, yData] = prepareCurveData(t.sdar_sec((abs(t.diff_diff)<0.1)),...
                    t.gps((abs(t.diff_diff)<0.1)));
                ft = fittype( 'poly1' );
                [fit_res, ~] = fit( xData, yData, ft );
                obj.fit_func=@(x) fit_res(mod(x/1000,24*3600));
                
                obj.plot_fiting([raw.sdar_time(idx)],hhmmss2sec(utc_time));
            else
                warning('No GPS found')
                obj.fit_func=@(x) (mod(x/1000,24*3600));
            end
            %Apply fiting
            [raw.sdar_utc]=obj.fit_func([raw.sdar_time]);
            raw2=raw;
        end
        %% slicing
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
        %% slicers
        function result = adsb_slicer(obj, adsb_struct )
            %UNTITLED10 Summary of this function goes here
            %   Detailed explanation goes here
            icao_list=unique({adsb_struct.icao});
            for icao=icao_list %loop through icaos
                %get all record of this icao
                icao_data=adsb_struct(...
                    strcmp({adsb_struct.icao},icao));
                df_list=unique([icao_data.df]);
                for df=df_list %loop through df
                    icao_df_data=icao_data([icao_data.df]==df);
                    if df~=[17 18]
                        result.(['icao_' char(icao)]).(['DF'  num2str(df)])= [icao_df_data];
                    else
                        %ADSB
                        tc_list=unique([icao_df_data.typecode]);
                        for tc=tc_list %loop through typecode
                            icao_df_data_tc=icao_df_data([icao_df_data.typecode]==tc);
                            result.(['icao_' char(icao)]).(['DF' num2str(df)]).(['TC' num2str(tc)])= [icao_df_data_tc];
                        end
                    end
                end
            end
        end
        function result= sadsb_slicer(obj,sadsb_struct,...
                sdar_time_start,decoder_handler)
            disp('runing sadsb_slicer2 ...')
            %take data from start
            sadsb_data=sadsb_struct([sadsb_struct.sdar_time]>=sdar_time_start);
            rs_code=[];
            rx_decoded={};
            h = waitbar(0,'Parsing SADS-B. Please wait...');
            for i=1:length(sadsb_data)
                [check_result,rx_data] =decoder_handler(sadsb_data(i).val);
                rs_code=[rs_code check_result];
                rx_decoded(end+1)={rx_data};
                waitbar(i/length(sadsb_data));
            end
            close(h)
            sadsb_data=struct2table(sadsb_data);
            sadsb_data.rs_code=rs_code.';
            sadsb_data.decoded=rx_decoded.';
            result=table2struct(sadsb_data);
            %remove non valid data
            result=result([result.rs_code]>=0);
        end
        
        function [check_result,rx_data]=rs_check2(obj,data_hex)
            m = 8; % Number of bits per symbol
            n = 2^m-1; % Codeword length
            k = 247;% Message length
            sadsb_len=448; %number of bits
            wrong_lenght=-4;
            wrong_crc=-2;
            wrong_rs=-1;
            wrong_header=-3;
            
            % Formating
            if length(data_hex)~= 2+sadsb_len/4
                check_result=wrong_lenght;
                rx_data='';
                return
            end
            sig_bin=hexToBinaryVector(data_hex,448);
            sig_bin2=reshape(sig_bin,m,length(sig_bin)/m).';
            sig_int=bi2de(sig_bin2,'left-msb');
            % RS decode
            data=[zeros(1,n-length(sig_int)) sig_int.'];
            [rxcode,rsnumerr] = rsdec(gf(data,m),n,k);
            rxcode_array=rxcode.x;
            rxdata_hex_vect= dec2hex(rxcode_array(n-sadsb_len/m+1:end),2);
            rxdata_hex=reshape(rxdata_hex_vect.',1,length(rxdata_hex_vect)*2);
            if rsnumerr==-1
                check_result=wrong_rs;
                rx_data=rxdata_hex;
                return
            end
            %check crc
            poly_hex='0x04C11DB7';
            poly_bin=hexToBinaryVector(poly_hex);
            det = crc.detector('Polynomial', poly_hex, ...
                'ReflectInput', true, 'ReflectRemainder', true);
            
            rxpload_bin=hexToBinaryVector(rxdata_hex,384).';
            [rxdata, rxcrc_error] = detect(det, rxpload_bin);
            rx_data_hex=binaryVectorToHex(rxdata.');
            if rxcrc_error==1
                check_result=wrong_crc;
                rx_data=rx_data_hex;
                return
            end
            %check header
            if strfind(rx_data_hex, 'ABDE55')
                check_result=rsnumerr;
                rx_data=rx_data_hex;
            else
                check_result=wrong_header;
                rx_data=rx_data_hex;
            end
        end
        
        function result  = faster_cleaner(obj,nested_struct )
            %UNTITLED2 Summary of this function goes here
            %   Detailed explanation goes here
            field_list=fields(nested_struct);
            result=nested_struct;
            for i=1:length(field_list)
                if ~isstruct([nested_struct.(field_list{i})])
                    if sum(~isnan([nested_struct.(field_list{i})]))==0
                        result=rmfield(result,field_list{i});
                    end
                else
                    result.(field_list{i})=obj.faster_cleaner(result.(field_list{i}));
                end
            end
        end
        
        %% ploting
        function fig = wbr_plot_mod(obj,hour_diff)
            % Get important
            if (isfield(obj.data.logs.WTX, 'x8Rate'))
                
                decode_start = min([obj.data.logs.WTX.x8Rate.sdar_utc]);
                begin = find([obj.data.logs.WTX.MOD.sdar_utc] > decode_start);
                
                fig =figure('pos',[100 100 1280 720]);
                s1=subplot(211);
                t_days=([obj.data.logs.WTX.MOD(begin).sdar_utc]-hour_diff*3600)/3600/24;
                p1=stairs(t_days,[obj.data.logs.WTX.MOD(begin).val],'Color',[1 0 0]);
                ylim([0 18])
                title('GS Modulation & Codage')
                xlabel(['Time (UTC-' num2str(hour_diff) ')']);
                datetick('x', 'HH:MM:SS')
                ylabel('Mode');
                legend('Current WBR Mode');
                annotation(fig ,'textbox',...
                    [0.141104166666666 0.545757071547421 0.240666666666667 0.369384359400998],...
                    'String',{'Modulation And Codage:','0, 1: SDAR Control, DBPSK, 64 and 32 bit','2, 3: SDAR Control, DQPSK, 64 and 32 bit','4, 5: SDAR Control, D8PSK, 64 and 32 bit','6, 7: SDAR Control, D16QAM, 64 and 31 bit','','10, 11: Ground Control, DBPSK, 64 and 32 bit','12, 13: Ground Control, DQPSK, 64 and 31 bit','14, 15: Ground Control, D8PSK, 64 and 32 bit','16, 17: Ground Control, D16QAM, 64 and 32 bit'},...
                    'LineStyle','none',...
                    'FitBoxToText','off');
                
                s2=subplot(212);
                xl=xlim(s1);
                t_days=([obj.data.logs.WTX.x8Rate.sdar_utc]-hour_diff*3600)/3600/24;
                p2=plot([xl t_days],[nan nan [obj.data.logs.WTX.x8Rate.val]*8/1000],'.',...
                    'MarkerSize',8);
                title('GS Decode Rate')
                xlabel(['Time (UTC-' num2str(hour_diff) ')']);
                
                datetick('x', 'HH:MM:SS')
                ylabel('Kbit/s');
                legend('GS Decode Rate');
                linkaxes([s1,s2],'x')
                
            else
                fig =figure('pos',[100 100 1280 720]);
                t_days=([obj.data.logs.WTX.MOD.sdar_utc]-hour_diff*3600)/3600/24;
                stairs(t_days,[obj.data.logs.WTX.MOD.val],'Color',[1 0 0]);
                ylim([0 18])
                title('GS Modulation & Codage')
                xlabel(['Time (UTC-' num2str(hour_diff) ')']);
                datetick('x', 'HH:MM:SS')
                ylabel('Mode');
                legend('Current WBR Mode');
                annotation(fig ,'textbox',...
                    [0.141104166666666 0.545757071547421 0.240666666666667 0.369384359400998],...
                    'String',{'Modulation And Codage:','0, 1: SDAR Control, DBPSK, 64 and 32 bit','2, 3: SDAR Control, DQPSK, 64 and 32 bit','4, 5: SDAR Control, D8PSK, 64 and 32 bit','6, 7: SDAR Control, D16QAM, 64 and 32 bit','','10, 11: Ground Control, DBPSK, 64 and 31 bit','12, 13: Ground Control, DQPSK, 64 and 32 bit','14, 15: Ground Control, D8PSK, 64 and 31 bit','16, 17: Ground Control, D16QAM, 64 and 32 bit'},...
                    'LineStyle','none',...
                    'FitBoxToText','off');
            end
        end
    end
end
