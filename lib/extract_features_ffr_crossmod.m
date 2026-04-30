function extract_features_ffr_crossmod(subject, response, par, varargin)
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

sub_str = sub_num2str(subject); 

% load  events file 
tbl_events = read_tsv(fullfile(par.raw_path, sprintf('sub-%s', sub_str), 'ieeg', ...
         sprintf('sub-%s_task-rhythm_events.tsv', sub_str)));
idx = find(strcmp(tbl_events.stim_type, 'tone')); 
stim_version = get_bids_value(tbl_events{idx(1), 'stim_file'}{1}, 'version'); 

% load stim file 
tbl_stim = read_tsv(fullfile(par.raw_path, 'stimuli', 'stimuli.tsv')); 
idx = find(tbl_stim.version == str2num(stim_version)); 
dp_above_130 = tbl_stim{idx(1), startsWith(tbl_stim.Properties.VariableNames, 'dp')}; 

assert(all(dp_above_130 > 130)); 

%% LOAD

fname = fullfile(sprintf('response-%s_avg-%s_ffrAggrCrossmod.csv', response, avg_method)); 
if ~isfile(fullfile(par.feat_path, fname))
    % table with aggregated values over crossmodulation frequencies larger than 100
    % Hz
    var_names = {'subject','elec','crossmod','rhythm','task','z_snr','magn'}; 
    tbl_aggr_crossmod = cell2table(cell(0,length(var_names)), 'VariableNames', var_names); 
else
    tbl_aggr_crossmod = readtable(fullfile(par.feat_path,fname)); 
end

warning('off','MATLAB:table:RowsAddedExistingVars')

% delete all rows for this subject
tbl_aggr_crossmod(tbl_aggr_crossmod.subject == subject, :) = []; 

%%

for iRhythm=1:length(par.rhythms)

    for iTask=1:length(par.tasks)

        fpath_eeg = fullfile(par.deriv_path, ...
                            sprintf('response-%s_FFT',response), sub_str); 

        % load no-SNR FFT                
        fname = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_snr-0-0_FFT',...
                            sub_str, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method);

        [header_no_snr, data_no_snr] = CLW_load(fullfile(fpath_eeg,fname)); 

        % load FFT with SNR subtraction 
        fname = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_snr-%d-%d_FFT',...
                            sub_str, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method, ...
                            par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2));

        [header_snr, data_snr] = CLW_load(fullfile(fpath_eeg,fname)); 
     
        % sanity check that the channel order is the same! 
        assert(isequal({header_snr.chanlocs}, {header_no_snr.chanlocs})); 
             
        %% aggregate measure of amplitude across crossmod frex
        
        elec_labels = rm_spaces({header_snr.chanlocs.labels}'); 

        n_chan = length(elec_labels); 
        
        freq = [0 : header_no_snr.datasize(end)-1] * header_no_snr.xstep; 
        
        [amp_crossmod_aggr] = get_amp_summary(data_snr, freq, dp_above_130, 'method', 'sum'); 
      
        [z_snr_crossmod_aggr, mean_snip, idx_snip] = get_z_snr(data_no_snr, freq, dp_above_130, ...
                                                 par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2));     
        
        new_rows = [...
            repmat({subject}, n_chan, 1), ...
            {header_no_snr.chanlocs.labels}', ...
            repmat(join(cellfun(@num2str, num2cell(dp_above_130), 'uni',0), ', '), n_chan, 1), ...
            repmat(par.rhythms(iRhythm), n_chan, 1), ...
            repmat(par.tasks(iTask), n_chan, 1), ...
            num2cell(z_snr_crossmod_aggr)' ...
            num2cell(amp_crossmod_aggr)', ...
            ]; 
        
        tbl_aggr_crossmod = [tbl_aggr_crossmod; new_rows]; 
        
        
    end % end of task 

end % end of rhythm

%% save tables

if ~isdir(par.feat_path)
    mkdir(par.feat_path)
end

if ~strcmp(class(tbl_aggr_crossmod.subject), 'string')
    tbl_aggr_crossmod.subject = string(tbl_aggr_crossmod.subject); 
end

fname = fullfile(sprintf('response-%s_avg-%s_ffrAggrCrossmod.csv', response, avg_method)); 
writetable(tbl_aggr_crossmod, fullfile(par.feat_path, fname))
       


