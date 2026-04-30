function extract_features_ffr_sidebands(subject, response, par, varargin)
% This function calculates features for each electrode and saves in a table. 
% 
% Parameters
% ----------
% response: str
%     response type (e.g. 'LFP' or 'biLFP') 
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

% load log file
clear datalog 
d_log = dir(fullfile(par.raw_path, sprintf('sub-%s', subject),'*log*.mat')); 
load(fullfile(d_log.folder, d_log.name))

% get FFR frequencies of interest
partials = datalog.params_stim.f0; 

crossmod_quad = [partials(2)-partials(1), 
                partials(3)-partials(1), 
                partials(3)-partials(2)]; 

crossmod_cub = [2*partials(1)-partials(2), 
                2*partials(2)-partials(3)]; 
            
crossmod_all = [crossmod_quad; crossmod_cub]; 
           
n_frex = length(par.fft.frex); 


%% LOAD

fpath = fullfile(par.experiment_path, 'features'); 

fname = fullfile(sprintf('response-%s_avg-%s_ffrAggrSidebands.tsv', response, avg_method)); 
if ~isfile(fullfile(fpath, fname))
    % table with values aggregated across sideband frequencies 
    var_names = {'subject','elec','crossmod','rhythm','task','z_snr','sum_magn','z_meterRel'}; 
    tbl_aggr_sidebands = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 
else
    tbl_aggr_sidebands = readtable(fullfile(fpath,fname), 'Delimiter','\t', ...
                             'ReadVariableNames',1, 'FileType','text');
end

fname = fullfile(sprintf('sub-%s_response-%s_avg-%s_ffrIndSidebands.tsv', response, avg_method)); 
if ~isfile(fullfile(fpath, fname))
    % table with data from indivudual sideband frequencies 
    var_names = {'subject','elec','freq','crossmod','rhythm','task','magn','z'}; 
    tbl_ind_sidebands = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 
else
    tbl_ind_sidebands = readtable(fullfile(fpath,fname), 'Delimiter','\t', ...
                             'ReadVariableNames',1, 'FileType','text');
end

warning('off','MATLAB:table:RowsAddedExistingVars')

% delete all rows for this subject
tbl_aggr_sidebands(strcmp(tbl_aggr_sidebands.subject, subject), :) = []; 
tbl_ind_sidebands(strcmp(tbl_ind_sidebands.subject, subject), :) = []; 


%% extract

for iRhythm=1:length(par.rhythms)

    for iTask=1:length(par.tasks)

        fpath = fullfile(par.experiment_path, 'derivatives', ...
                            sprintf('response-%s_FFT',response), subject); 

        % without SNR subtraction                 
        fname = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_snr-0-0_FFT',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method);
                        
        [header_no_snr, data_no_snr] = CLW_load(fullfile(fpath,fname)); 

        % with SNR subtraction 
        fname = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_snr-%d-%d_FFT',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method, ...
                            par.snr_bins_eeg(1), par.snr_bins_eeg(2));
        [header_snr, data_snr] = CLW_load(fullfile(fpath,fname)); 
       
        
        elec_labels = removeSpaces({header_no_snr.chanlocs.labels}'); 
        n_chan = length(elec_labels); 
        
        % sanity check that the channel order is the same! 
        assert(isequal({header_no_snr.chanlocs}, {header_snr.chanlocs})); 
               
        
        % go over crossmodulations 
        for iF0=1:length(crossmod_all)

            % extract amplitudes at frequencies of interest
            frex_plus = crossmod_all(iF0) + par.fft.frex; 
            frex_minus = crossmod_all(iF0) - par.fft.frex; 

            % above center frequency
            frex_idx = round(frex_plus / header_snr.xstep) + 1; 
            amps_plus = squeeze(data_snr(:,:,1,1,1,frex_idx));
            
            % below center frequency
            frex_idx = round(frex_minus / header_snr.xstep) + 1; 
            amps_minus = squeeze(data_snr(:,:,1,1,1,frex_idx));

            % merge them
            amps = mean( cat(3, amps_plus, amps_minus), 3); 

            sum_magn = sum(amps, 2); 

            z = zscore(amps, [], 2); 

            z_meterRel = mean(z(:, par.fft.idx_meterRel), 2); 
            
            freq = [0 : header_no_snr.datasize(end)-1] * header_no_snr.xstep; 
            
            [z_snr_sidebands, mean_snip, idx_snip] = get_z_snr(...
                                        data_no_snr, freq, [frex_plus, frex_minus], ...
                                        par.snr_bins_eeg(1), par.snr_bins_eeg(2)); 
            
            % features aggregated over sideband frequencies 
            new_rows = [...
                repmat({subject}, n_chan, 1), ...
                elec_labels, ...
                repmat({crossmod_all(iF0)}, n_chan, 1), ...
                repmat(par.rhythms(iRhythm), n_chan, 1), ...
                repmat(par.tasks(iTask), n_chan, 1), ...
                num2cell(ensure_col(z_snr_sidebands)), ...
                num2cell(ensure_col(sum_magn)), ...
                num2cell(ensure_col(z_meterRel)), ...
                ]; 

            tbl_aggr_sidebands = [tbl_aggr_sidebands; new_rows]; 

            % features for individual sideband frequencies 
            new_rows = [...
                repmat({subject}, n_chan*n_frex, 1), ...
                repmat(ensure_col(elec_labels), n_frex, 1), ...
                num2cell(ensure_col(repelem(par.fft.frex, n_chan))), ...
                repmat({crossmod_all(iF0)}, n_chan*n_frex, 1), ...
                repmat(par.rhythms(iRhythm), n_chan*n_frex, 1), ...
                repmat(par.tasks(iTask), n_chan*n_frex, 1), ...
                num2cell(reshape(amps, [], 1)), ...
                num2cell(reshape(z, [], 1)), ...
                ];

            tbl_ind_sidebands = [tbl_ind_sidebands; new_rows]; 

        end % end of f0
        
    end % end of task 

end % end of rhythm

%% 

% save the rest  
fpath = fullfile(par.experiment_path, 'features'); 
if ~isdir(fpath)
    mkdir(fpath);
end

fname = fullfile(sprintf('response-%s_avg-%s_ffrAggrSidebands.tsv', response, avg_method)); 
writetable(tbl_aggr_sidebands, fullfile(fpath,fname), 'Delimiter','\t', ...
           'FileType','text', 'WriteVariableNames',true)

fname = fullfile(sprintf('response-%s_avg-%s_ffrIndSidebands.tsv', response, avg_method)); 
writetable(tbl_ind_sidebands, fullfile(fpath,fname), 'Delimiter','\t', ...
           'FileType','text', 'WriteVariableNames',true)




