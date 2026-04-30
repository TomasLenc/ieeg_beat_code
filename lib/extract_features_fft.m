function extract_features_fft(subject, response, par, varargin)
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

sub_str = sub_num2str(subject); 

%% LOAD

if ~isdir(par.feat_path)
    mkdir(par.feat_path) 
end

% prepare table with aggregated-frequency features
fname = fullfile(sprintf('response-%s_avg-%s_fftAggrFreq.csv', ...
                          response, avg_method)); 
if ~isfile(fullfile(par.feat_path, fname))
    var_names = {'subject','elec','rhythm','task','z_snr','sum_magn','z_meterRel'}; 
    tbl_fft_aggr = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 
else
    tbl_fft_aggr = readtable(fullfile(par.feat_path,fname));
end

% delete all rows for this subject
tbl_fft_aggr(tbl_fft_aggr.subject == subject, :) = []; 

%%
warning('off','MATLAB:table:RowsAddedExistingVars')

for iTask=1:length(par.tasks)
    
    for iRhythm=1:length(par.rhythms)
        

        % load FFT 
        par.feat_path_fft = fullfile(par.deriv_path, ...
                            sprintf('response-%s_FFT',response), sub_str); 
        fname_fft = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_snr-%d-%d_FFT.lw6',...
                            sub_str, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method, ...
                            par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2));
        if ~isfile(fullfile(par.feat_path_fft, fname_fft)) 
            warning('%s \nfile doesnt exist! skipping', fname_fft); 
            continue
        end
        [header_fft, data_fft] = CLW_load(fullfile(par.feat_path_fft, fname_fft)); 
        mX = squeeze(data_fft); 

        % load FFT without SNR
        fname_no_snr = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_snr-0-0_FFT.lw6',...
                            sub_str, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method);
        if ~isfile(fullfile(par.feat_path_fft, fname_no_snr))
            warning('%s \nfile doesnt exist! skipping', fname_no_snr); 
            continue
        end
        [header_no_snr, data_no_snr] = CLW_load(fullfile(par.feat_path_fft, fname_no_snr)); 
        mXnoSNR = squeeze(data_no_snr); 
        
        % get contact labels 
        elec_labels = rm_spaces({header_fft.chanlocs.labels}'); 
        n_elec = length(elec_labels); 

        % MAGNITUDES
        % ----------
        frex_idx = round(par.fft.frex/header_fft.xstep)+1; 
        amps = mX(:, frex_idx);
        sum_magn = sum(amps, 2); 
                
        % ZSCORES
        % -------
        z = zscore(amps,[],2); 
        z_meterRel = mean(z(:,par.fft.idx_meterRel), 2); 
        
        z_meterRel_norm = normalize_zscore(z_meterRel, ...
                        numel(par.fft.idx_meterRel) + numel(par.fft.idx_meterUnrel), ...
                        numel(par.fft.idx_meterRel)); 
                
        % Z_SNR
        % -----
        freq = [0 : header_no_snr.datasize(end)-1] * header_no_snr.xstep;
        z_snr = get_z_snr(mXnoSNR, freq, par.fft.frex, par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2)); 
                       
        % write to table 
        % -------------- 
        
        % features aggregated over frequencies 
        new_rows = [repmat({subject}, n_elec, 1), ...
                    elec_labels, ...
                    repmat(par.rhythms(iRhythm), n_elec, 1), ...
                    repmat(par.tasks(iTask), n_elec, 1), ...
                    num2cell(z_snr), ...
                    num2cell(sum_magn), ...
                    num2cell(z_meterRel_norm) ...
                    ];
                
        tbl_fft_aggr = [tbl_fft_aggr; new_rows]; 
    
    end        
end


%% SAVE 

fname = fullfile(sprintf('response-%s_avg-%s_fftAggrFreq.csv', ...
                          response, avg_method)); 
writetable(tbl_fft_aggr, fullfile(par.feat_path, fname));
                     
