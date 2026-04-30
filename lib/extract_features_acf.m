function extract_features_acf(subject, response, par, varargin)
% This function calculates features for each electrode and saves in a table. 
% 
% Parameters
% ----------
% response: str
%     response type (e.g. 'LFP' or 'HGB') 
% varargin: 
%     'avg_method' : kwarg, str (default is 'time')
%       method to average across trials and channels ('time' for time-domain 
%       averaging before FFT, or 'frequency' for frequency-domain averaging 
%       after the FFT) 

% parse kwargs
% ------------

% trial averaging method  
avg_method = 'time'; 
if any(strcmpi(varargin,'avg_method'))
    avg_method = varargin{find(strcmpi(varargin,'avg_method'))+1}; 
end

% force table overwrite
overwrite_tbl = false; 
if any(strcmpi(varargin,'overwrite_tbl'))
    overwrite_tbl = varargin{find(strcmpi(varargin,'overwrite_tbl'))+1}; 
end

sub_str = sub_num2str(subject); 

%% LOAD

if ~isdir(par.feat_path)
    mkdir(par.feat_path); 
end

if overwrite_tbl
    warning('Overwriting whole acf feature table!')
end

fname_tbl = fullfile(sprintf('response-%s_avg-%s_aggrACFtrial.csv', ...
                          response, avg_method)); 
                      
if ~isfile(fullfile(par.feat_path, fname_tbl)) || overwrite_tbl
    var_names = {
        'subject'
        'elec'
        'rhythm'
        'task'
        'z_meterRel'
        };
    tbl_aggr = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 
else
    tbl_aggr = readtable(fullfile(par.feat_path,fname_tbl)); 
end

warning('off','MATLAB:table:RowsAddedExistingVars')

% delete all rows for this subject
tbl_aggr(tbl_aggr.subject == subject, :) = []; 

%%

for iRhythm=1:length(par.rhythms)

    for iTask=1:length(par.tasks)
      
        fpath_eeg = fullfile(par.deriv_path, ...
                            sprintf('response-%s_ACF',response), sub_str); 
                        
        fprintf('extracting ACF response-%s sub-%s rhythm-%s task-%s\n', ...
             response, sub_str, par.rhythms{iRhythm}, par.tasks{iTask}); 
                    
        % subtracted ACF
        % --------------
                
        fname = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_ACFsubtr.lw6',...
                        sub_str, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                        response, avg_method);
                    
        if ~isfile(fullfile(fpath_eeg, fname))
            warning('%s \nfile doesnt exist! skipping\n', fname); 
            continue
        end        
        
        [header, data] = CLW_load(fullfile(fpath_eeg, fname)); 

        % prepare lags
        lags = [0 : header.datasize(end)-1] * header.xstep + header.xstart;  

        feat_acf_subtr = get_acf_features(...
                        data, ...
                        lags, ...
                        par.acf.lags_meter_rel, ...
                        par.acf.lags_meter_unrel);                               
                    
                                        
        % write to table 
        % --------------
        
        elec_labels = rm_spaces({header.chanlocs.labels}'); 
        n_elec = length(elec_labels); 

        for iEl=1:n_elec
            
            idx_el = find(strcmp({header.chanlocs.labels}, elec_labels{iEl})); 
            
            % features aggregated over frequencies 
            new_row = [...
                        {subject}, ...
                        elec_labels(iEl), ...
                        par.rhythms(iRhythm), ...
                        par.tasks(iTask), ...
                        {feat_acf_subtr.z_meter_rel_norm(idx_el)} ...
                        ];
            
            tbl_aggr = [tbl_aggr; new_row]; 
        end
                        
    end

end


%% SAVE 

writetable(tbl_aggr, fullfile(par.feat_path, fname_tbl)); 




