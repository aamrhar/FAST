function varargout = FAST(varargin)
% FAST MATLAB code for FAST.fig
%      FAST, by itself, creates a new FAST or raises the existing
%      singleton*.
%
%      H = FAST returns the handle to a new FAST or the handle to
%      the existing singleton*.
%
%      FAST('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FAST.M with the given input arguments.
%
%      FAST('Property','Value',...) creates a new FAST or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FAST_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FAST_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FAST

% Last Modified by GUIDE v2.5 27-Nov-2017 15:36:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @FAST_OpeningFcn, ...
    'gui_OutputFcn',  @FAST_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FAST is made visible.
function FAST_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FAST (see VARARGIN)

% Choose default command line output for FAST
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
clc



% Get software version

[stat, v_str]=system('git describe --tag');

if(stat)
    
    v_str = 'ERROR fetching version';
    
end

set(handles.version_tag, 'string', v_str)

% Load interface pictures

I = imread(strcat('Docs', '\', 'background.jpg'));
J = imread(strcat('Docs', '\', 'FAST_Logo_Bleu.png'));

axes(handles.FAST_photo);
imshow(I);
axes(handles.FAST_logo);
imshow(J);


%initialize listboxes
list2 = cell(0);
set(handles.listbox2, 'String', list2);
set(handles.listbox2, 'Value', 0);



% UIWAIT makes FAST wait for user response (see UIRESUME)
% uiwait(handles.FAST_root);

% --- Outputs from this function are returned to the command line.
function varargout = FAST_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2
if strcmp(get(handles.FAST_root,'SelectionType'),'open')
    display_fig_Callback(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
    
end


% --- Executes on button press in report_generator.
function report_generator_Callback(hObject, eventdata, handles)
% hObject    handle to report_generator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% tic
% freeze
% h = msgbox('Please wait...');
sbar=findobj('tag','status_bar');
set(sbar,'String','Busy...')
InterfaceObj=findobj('Enable','on');
set(InterfaceObj, 'Enable', 'off')

assignin('base', 'ft', handles.ft)
handles.ft.generate_report
%release
set(InterfaceObj, 'Enable', 'on')
% close(h);
set(sbar,'String','Ready')
% beep
% msgbox({'Repport Done!' ...
%     ['Elapsed time =' datestr(toc/(24*3600), 'HH:MM:SS.FFF')]})


% --------------------------------------------------------------------
function User_Manual_Callback(hObject, eventdata, handles)
% hObject    handle to User_Manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

winopen('Docs/User Manual.pdf')

% --------------------------------------------------------------------
function New_Callback(hObject, eventdata, handles)
% hObject    handle to New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ft = FT_Interface('mode', 'GUI');
ft.create_dirs;


% save to handle
handles.ft = ft;
% Save the change to the handle structure
guidata(hObject, handles);

% update the display
set(handles.ft_info, 'String', ft.ft_info_to_txt);
Refresh_Selection_Callback(hObject, eventdata, handles);




% --------------------------------------------------------------------
function support_mail_Callback(hObject, eventdata, handles)
% hObject    handle to support_mail (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%email




% --------------------------------------------------------------------
function Tools_Callback(hObject, eventdata, handles)
% hObject    handle to Tools (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in Refresh_Selection.
function Refresh_Selection_Callback(hObject, eventdata, handles)
% hObject    handle to Refresh_Selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




%clear listbox
list2 = {'Refreshing please wait...'};
set(handles.listbox2, 'String', list2);
set(handles.listbox2, 'Value', 1);


disp('REFRESHING FIGURES')

%TO DO: Create method in ft_interface
%Refresh other figures
if ((exist(handles.ft.ft_info.ft_folder, 'dir') == 7) && isfield(handles, 'ft'))
    figs = dir([handles.ft.ft_info.ft_folder '*.fig']);
    
    
    handles.figures = {};
    
    if(~isempty(figs))
        % save figures paths
        % TO DO: do not use .folder field with dir
        handles.figures(:,1) = strcat(repmat(handles.ft.ft_info.ft_folder, length({figs.name}), 1), {figs.name}');
        
        
        
        % get figures names
        figs = {figs.name}';
        for i=1:length(figs)
            
            figs_h(i) = openfig([handles.ft.ft_info.ft_folder char(figs(i,:))], 'invisible');
            
        end
        
        %list = {figs_h.Name};
        
        handles.figures(:,2) = {figs_h.Name};
        handles.figures(:,3) = {figs_h.Tag};
        
        %set space between sections
        [tags, idxs] = unique(handles.figures(:,3));
        i = 1;
        j = 1;
        tmp = handles.figures;
        
        tmp = sortrows(tmp, 3);
        tags = sort(tags);
        
        while(j <= length(tags))
            if( strcmp(tmp(i, 3), tags(j)) )
                
                tag = strsplit(char(tags(j)),';');
                
                htmlname = sprintf('<HTML><FONT color="blue" size="+0.5"><b>%s<b></FONT> ', char(tag(1,2)));
                append = [{''} {htmlname} {''}];
                
                if(i == 1)
                    tmp = [append; tmp(i:end, :)];
                    j=j+1;
                else
                    tmp = [tmp(1:i-1, :); append; tmp(i:end, :)];
                    j=j+1;
                end
                
            end
            i= i+1;
        end
        handles.figures = tmp;
        
        set(handles.listbox2, 'string', handles.figures(:,2));
        set(handles.listbox2, 'Value', length(handles.figures(:,2)));
        
        clearvars figs_h
        clearvars tmp
        
    else
        
        list2 = {'Empty'};
        set(handles.listbox2, 'String', list2);
        set(handles.listbox2, 'Value', 1);
        
    end
    % clean
    a=findobj(0,'Type','Figure');
    for i=1:length(a)
        try
            if ~strcmpi(a(i).Name,'fast')
                figure(a(i).Number)
                close(gcf)
            end
        catch
        end
    end
    
    % Save the change to the handle structure
    guidata(hObject, handles)
end

% --- Executes on button press in display_fig.
function display_fig_Callback(hObject, eventdata, handles)
% hObject    handle to display_fig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%on récupere la liste dans la listebox2
list2 = get(handles.listbox2, 'string');

if(~isempty(list2))
    
    %recuperer le graphique selectionne
    ind_liste = get(handles.listbox2, 'value');
    nom_graph_sel = list2(ind_liste);
    
    if(~isempty(char(handles.figures(ind_liste, 1))))
        f = openfig(char(handles.figures(ind_liste, 1)));
        set(f, 'visible', 'on');
    end
end



% --- Executes on button press in Edit_FT.
function Edit_FT_Callback(hObject, eventdata, handles)
% hObject    handle to Edit_FT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in New.
function pushbutton23_Callback(hObject, eventdata, handles)
% hObject    handle to New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in Load.
function Load_Callback(hObject, eventdata, handles)
% hObject    handle to Load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% save to handle
handles.ft = FT_Interface.load_interface();
% freeze
h = msgbox('Please wait...');
sbar=findobj('tag','status_bar');
set(sbar,'String','Busy...')
InterfaceObj=findobj('Enable','on');
set(InterfaceObj, 'Enable', 'off')

% update the display
set(handles.ft_info, 'String', handles.ft.ft_info_to_txt);


% Save the change to the handle structure
guidata(hObject, handles);

% update display
Refresh_Selection_Callback(hObject, eventdata, handles);
%release
set(InterfaceObj, 'Enable', 'on')
close(h);
set(sbar,'String','Ready')



% --- Executes on button press in Import.
function Import_Callback(hObject, eventdata, handles)
% hObject    handle to Import (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.ft = FT_Interface.import();

h = msgbox('Please wait...');

% update the display
set(handles.ft_info, 'String', handles.ft.ft_info_to_txt);


% Save the change to the handle structure
guidata(hObject, handles);

% update display
Refresh_Selection_Callback(hObject, eventdata, handles);

close(h);


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.ft.save_interface;

% --- Executes on button press in Export.
function Export_Callback(hObject, eventdata, handles)
% hObject    handle to Export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.ft.export;

% --- Executes on selection change in FT_info_listbox.
function FT_info_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to FT_info_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FT_info_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FT_info_listbox


% --- Executes during object creation, after setting all properties.
function FT_info_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FT_info_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Edit.
function Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

assignin('base', 'ft', handles.ft)

% --- Executes on button press in View_Details.
function View_Details_Callback(hObject, eventdata, handles)
% hObject    handle to View_Details (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(isfield(handles, 'ft'))
    assignin('base', 'ft', handles.ft);
    evalin('base','openvar(''ft'')')
    
    
end

% --- Executes on button press in Run.
function Run_Callback(hObject, eventdata, handles)
% hObject    handle to Run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%tic
%Freeze
sbar=findobj('tag','status_bar');
set(sbar,'String','Busy...')
pause(1)
% h = msgbox('Please wait...');
InterfaceObj=findobj('Enable','on');
set(InterfaceObj, 'Enable', 'off')

% Create branch for analysis
if(~isempty(handles.ft.ft_type))
    switch handles.ft.ft_type
        case 1 % SDAR Cessna
            disp('run SDAR Cessna')
            [handles.ft,errno] = handles.ft.run_analysis;
        case 2 % SDAR Piaggio
            %TO-DO: We need something here;
        case 3 % SDAR X-Plane
            disp('run SDAR Cessna')
            [handles.ft,errno] = handles.ft.run_analysis;
        case 4 % DRFS Cessna
            VOR_processing_final(handles.ft.ft_info.input_path);
            copyfile([handles.ft.ft_info.input_path,'\Input_files'], [handles.ft.ft_info.ft_folder,'\Input_files'])
            copyfile([handles.ft.ft_info.input_path,'\Output_files\Figures\FIG\VHF'], [handles.ft.ft_info.ft_folder])
        case 5 % DRFS X-Plane
            handles.ft = handles.ft.run_analysis_xplane;
        otherwise
            %TO-DO: We should not fall into this place
    end
    
else
    
    %Default analysis
    [handles.ft,errno] = handles.ft.run_analysis;
    
end

%Release
set(InterfaceObj, 'Enable', 'on')
set(sbar,'String','Ready')
% Save the change to the handle structure
guidata(hObject, handles)

% close(h);
% if errno==0
%     msgbox({'Processing Done!' ...
%         ['Elapsed time =' datestr((toc-1)/(24*3600), 'HH:MM:SS.FFF')]})
% else
%     beep
%     msgbox(['An error has occured! please read logs'])
% end


% --- Executes on button press in Get_Figs.
function Get_Figs_Callback(hObject, eventdata, handles)
% hObject    handle to Get_Figs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set handle visibility of FAST to off to prevent unwanted gui modification
set(handles.FAST_root, 'HandleVisibility', 'off')
% Update handles structure
guidata(hObject, handles);

if(ismethod(handles.ft.ft_data, 'get_all_figs'))
    
    sbar=findobj('tag','status_bar');
    set(sbar,'String','Busy...')
    InterfaceObj=findobj('Enable','on');
    set(InterfaceObj, 'Enable', 'off')
    
    %handles.ft.ft_data.get_all_figs(handles.ft.ft_info.ft_folder);
    handles.ft.save_figs();
    
    Refresh_Selection_Callback(hObject, eventdata, handles);
    %release
    set(InterfaceObj, 'Enable', 'on')
    
    set(sbar,'String','Ready')
    
end

% set back handle visibility to callback
set(handles.FAST_root, 'HandleVisibility', 'callback')
% Update handles structure
guidata(hObject, handles);



% --------------------------------------------------------------------
function File_Callback(hObject, eventdata, handles)
% hObject    handle to File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Help_Callback(hObject, eventdata, handles)
% hObject    handle to Help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function to_workspace_Callback(hObject, eventdata, handles)
% hObject    handle to to_workspace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(isfield(handles, 'ft'))
    assignin('base', 'ft', handles.ft);
    
end
