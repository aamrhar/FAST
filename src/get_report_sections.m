%get all the figures

figs = dir([ft.ft_info.ft_folder '*.fig']);
figs = {figs.name}';

for i=1:length(figs)
    
    figs_h(i) = openfig([ft.ft_info.ft_folder char(figs(i,:))], 'invisible');
    
end

chapters_tags = unique({figs_h.Tag});
chapters_tags = sort(chapters_tags)

%remove empty
chapters_tags = chapters_tags(~cellfun('isempty',chapters_tags))  

% remove numeric priority ids

tmp = cell(length(chapters_tags), 2);
for i =1:length(chapters_tags)
tmp(i,:) = strsplit(char(chapters_tags(i)), ';');
end

chapters_names = tmp(:,2)