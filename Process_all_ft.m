clear all
close all

datafiles = dir(fullfile('temp\', '**', '*.mat'));
names = {datafiles.name}'
paths = {datafiles.folder}'

full_paths = strcat(paths, repmat('\', length(names), 1), names);


for i = 1:size(full_paths, 1)
    
    
    ft = load(char(full_paths(i)))
    fnames = fieldnames(ft);
    for i = 1:length(fnames)
        if(isa(ft.(char(fnames(i))), 'FT_Interface'))
            ft = ft.(char(fnames(i)));
            break;
        end
    end
    
    disp('************************************')
    disp(['work: ' full_paths(i)])
    disp('************************************')
    
    try
        ft.run_analysis;
        ft.save_figs;
        
        save([obj.ft_info.ft_folder [obj.ft_info.name '.mat']], 'ft');
        
        save('full_paths.mat', 'full_paths');
        
        ft.generate_report;
        
        load('full_paths.mat')
        
    catch
        
        
    end
    
    
    close all
    
end