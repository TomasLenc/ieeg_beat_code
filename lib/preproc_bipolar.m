function preprocBipolar(subject, par)
% This loads the functional data that were preprocessed for LFPs and changes the
% reference to bipolar. 
% 
% Inputs: 
% -------
% subject: str
%     subject name 
% 

subject = sub_num2str(subject); 

fprintf('processing sub-%s\n',subject); 

% load 
% ----

load_path = fullfile(par.deriv_path,...
                        'response-LFP_preproc',subject); 
                    
fname = sprintf('sub-%s_response-LFP_preproc',subject); 


[header, data] = CLW_load(fullfile(load_path,fname)); 

%% run

eleclabels = {header.chanlocs.labels}'; 

[new_chan_labels, M_ref] = get_bipolar_from_eleclabels(eleclabels); 

% imagesc(M_ref)

%% re-reference the data 

data_reref_shape = size(data); 
data_reref_shape(2) = length(new_chan_labels); 

data_reref = nan(data_reref_shape); 

% if we have more epochs, we need to do this one epoch at a time 
for i_ep=1:size(data, 1)   
    % apply the transformation matrix 
    data_reref(i_ep,:,:,:,:,:) = (squeeze(data(i_ep,:,:,:,:,:))' * M_ref)'; 
end

% prepare header 
header_reref = header; 

header_reref.datasize = size(data_reref); 

chanlocs = []; 
for i=1:length(new_chan_labels)
    chanlocs(i).labels = new_chan_labels{i}; 
    chanlocs(i).topo_enabled = 0;
    chanlocs(i).SEEG_enabled = 0;
end
header_reref.chanlocs = chanlocs; 

%% save

response_out = 'biLFP'; 

out_path = fullfile(par.deriv_path, ...
                   sprintf('response-%s_preproc',response_out), subject); 

if ~isfolder(out_path)
   mkdir(out_path); 
end

% save the rereferenced data 
out_name = sprintf('sub-%s_response-%s_preproc',...
                   subject, response_out);

header_reref.name = out_name; 

CLW_save(out_path, header_reref, data_reref); 

% save also the referencing matrix 
header_original = header; 
save(fullfile(out_path, [out_name,'_referenceMatrix.mat']), 'M_ref', 'header_original'); 



