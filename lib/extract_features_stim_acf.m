function extract_features_stim_acf(data_type, par)

% ACF
var_names = {'rhythm','z_meterRel','ratio_meterRel','contrast_meterRel'};

tbl_acf_aggr = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 


%% 

for iRhythm=1:length(par.rhythms)
        
    fpath = fullfile(par.deriv_path, ...
                sprintf('response-%s_ACF', data_type)); 
            
    fname = sprintf('rhythm-%s_response-%s_ACFraw', ...
                      par.rhythms{iRhythm}, ...
                      data_type ...
                      ); 
                  
    [header_acf, data_acf] = CLW_load(fullfile(fpath, fname)); 
    
    lags = [0 : header_acf.datasize(end)-1] * header_acf.xstep  ...
                + header_acf.xstart;  
    
    feat = get_acf_features(...
                    data_acf, ...
                    lags, ...
                    par.acf.lags_meter_rel, ...
                    par.acf.lags_meter_unrel);                               

    % write to table 
    % features aggregated over frequencies 
    new_rows = [repmat(par.rhythms(iRhythm), 1, 1), ...
                num2cell(feat.z_meter_rel_norm), ...
                num2cell(feat.ratio_meter_rel), ...
                num2cell(feat.contrast_meter_rel) ...
                ];

    tbl_acf_aggr = [tbl_acf_aggr; new_rows]; 
    
end


%%

fpath = par.feat_path; 
if ~isdir(fpath); mkdir(fpath); end

% acf
fname = sprintf('response-%s_aggrACFtrial.csv', data_type); 
writetable(tbl_acf_aggr, fullfile(fpath, fname)); 

