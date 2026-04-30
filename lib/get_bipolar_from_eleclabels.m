function [new_chan_labels, M_ref] = get_bipolar_from_eleclabels(eleclabels)
% This function takes a cell array of electrode labels (e.g. H1, H2, H3) and
% generates a new list of bipolar channels by combining neighbouring pairs of
% electrodes (e.g. H1-H2, H2-H3, ...). It also prepares a reference matrix that
% can be used to multiply data in order to reference it to the bipolar montage.
% 
% 
% Returns
% -------
% new_chan_labels : cell of str
%     List of new bipolar channels
% M_ref : array_like
%     Referenceing matrix M, each column represents a linear combination of
%     old channels to form one new channel. To obtain rereferenced data, 
%     multiply D @ M, where D is data matrix [time, chan]. 

% prepare a referencing matrix (i.e. a projection matrix that will multiply 
% the data matrix to perform the rereferencing) 
M_ref = []; 

% get a list of shaft names 
shaftlabels = unique(cellfun(@(x) ...
                        regexp(x,'[a-zA-Z]+''?','match'), eleclabels)); 

c_new_chan = 1; 

new_chan_labels = {}; 

% for each shaft, 
for iShaft=1:length(shaftlabels)
    
    % find which electrodes correspond to this shaft 
    shaft = shaftlabels{iShaft}; 
    el_idx = find(~cellfun(@isempty, ...
                regexp(eleclabels, sprintf('^%s[0-9]+',shaft)),'uni',1)); 
    
    % get their labels 
    el_labels = eleclabels(el_idx); 
    
    % get their numbers 
    el_numbers = cellfun(@(x) regexp(x,'[0-9]+','match'), el_labels); 
    el_numbers = cellfun(@str2num, el_numbers, 'uni',1); 
    
    % sort by increasing electrode number 
    [el_numbers_sorted, sort_idx] = sort(el_numbers, 'ascend'); 
    
    el_labels = el_labels(sort_idx); 
    
    % go over electrodes from the most insternal to the most external contact
    % on the shaft 
    for i_el=1:length(el_labels)-1
        
        % get the closest electrode on the electrode shaft (outwards)
        this_el_label = el_labels{i_el}; 
        this_el_idx = find(strcmp(this_el_label, eleclabels)); 
        
        closest_el_label = el_labels{i_el+1}; 
        closest_el_idx = find(strcmp(closest_el_label, eleclabels)); 
        
        % update the referencing matrix 
        M_ref(this_el_idx, c_new_chan) = 1; 
        M_ref(closest_el_idx, c_new_chan) = -1; 
        
        c_new_chan = c_new_chan+1; 
        
        % create the label of the new bipolar channel (e.g. "H5-H4")
        new_chan_label = sprintf('%s-%s',this_el_label,closest_el_label); 
        new_chan_labels = [new_chan_labels, {new_chan_label}]; 
        
    end
    
end

% imagesc(M_ref)