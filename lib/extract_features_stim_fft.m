function extract_features_stim_fft(data_type, par)

% FFT
var_names = {'rhythm','z_meterRel'}; 
tbl_fft_aggr = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 

var_names = {'freq','rhythm','magn','z'}; 
tbl_fft_ind = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 

var_names = {'magn_dist','z_dist'}; 
tbl_fft_dist = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 

%% 

% prepare variable that will hold magnitude and z values for the two
% rhythms so we can calculate distance between them
amps_both_rhythms = cell(1, 2); 
z_both_rhythms = cell(1, 2); 

for iRhythm=1:length(par.rhythms)
    
        
    %% FFT 

    fpath = fullfile(par.deriv_path, ...
                sprintf('response-%s_FFT', data_type)); 
            
    fname = sprintf('rhythm-%s_response-%s_snr-%d-%d_FFT', ...
                      par.rhythms{iRhythm}, ...
                      data_type, ...
                      par.fft.snr_bins_coch(1), par.fft.snr_bins_coch(2) ...
                      ); 
                  
    [header_fft, data_fft] = CLW_load(fullfile(fpath, fname)); 
    
    mX = squeeze(data_fft); 
    if iscolumn(mX)
        mX = mX'; 
    end
    
    frex_idx = round(par.fft.frex/header_fft.xstep)+1; 
    
    amps = mX(:, frex_idx);
    amps_both_rhythms{iRhythm} = amps;
    
    z = zscore(amps); 
    z_both_rhythms{iRhythm} = z;
    
    z_meterRel = mean(z(par.fft.idx_meterRel), 2); 
    
    z_meterRel_norm = normalize_zscore(z_meterRel, ...
                    numel(par.fft.idx_meterRel) + numel(par.fft.idx_meterUnrel), ...
                    numel(par.fft.idx_meterRel)); 

    % write to table 
    % features aggregated over frequencies 
    new_rows = [repmat(par.rhythms(iRhythm), 1, 1), ...
                num2cell(z_meterRel_norm)];

    tbl_fft_aggr = [tbl_fft_aggr; new_rows]; 

    % features for individual frequencies 
    for fi=1:length(par.fft.frex)

        new_rows = [repmat({par.fft.frex(fi)}, 1, 1), ...
                    repmat(par.rhythms(iRhythm), 1, 1), ...
                    num2cell(amps(:,fi)), ...
                    num2cell(z(:,fi))];

        tbl_fft_ind = [tbl_fft_ind; new_rows]; 

    end
  
end

amps_both_rhythms = cat(1, amps_both_rhythms{:});
z_both_rhythms = cat(1, z_both_rhythms{:});

amps_dist_rhythms = pdist(amps_both_rhythms); 
z_dist_rhythms = pdist(z_both_rhythms); 

new_rows = [num2cell(amps_dist_rhythms), ...
            num2cell(z_dist_rhythms)
            ];

tbl_fft_dist = [tbl_fft_dist; new_rows]; 


%%

fpath = par.feat_path; 

if ~isdir(fpath) 
    mkdir(fpath); 
end

% fft
fname = sprintf('response-%s_fftAggrFreq.csv', data_type); 
writetable(tbl_fft_aggr, fullfile(fpath, fname))

fname = sprintf('response-%s_fftIndFreq.csv', data_type); 
writetable(tbl_fft_ind, fullfile(fpath, fname))

fname = sprintf('response-%s_fftRhythmDist.csv', data_type); 
writetable(tbl_fft_dist, fullfile(fpath, fname))
