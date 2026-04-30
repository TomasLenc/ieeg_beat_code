function params=getParams()

% root directory of the experiment that contains source, raw, derivatives,
% etc.
experiment_path = '/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public'; 

% path to raw data 
raw_path = '/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/raw'; 

% letswave path
lw_path = '~/projects_git/letswave6';    

% code to do autocorrelation analysis
acf_tools_path = '~/projects_git/acf_tools'; 

% code to do rnb-lab toolbox
rnb_tools_path = '~/projects_git/rnb_tools'; 

%%
% path to derivatives
deriv_path = fullfile(raw_path, 'derivatives'); 

% freesurfer subjects dir
subjects_dir = fullfile(deriv_path, 'subjects_dir'); 

% path to subcortical model data
urear_path = fullfile(deriv_path, 'urear'); 

% path to features
feat_path = fullfile(deriv_path, 'features'); 

% path to results 
results_path = fullfile(deriv_path, 'results'); 

% path to figures
figures_path = fullfile(deriv_path, 'figures'); 


%% add paths 

% add library
addpath(genpath('lib'))

% add letwave
addpath(genpath(lw_path))

% add rnb tools
addpath(genpath(rnb_tools_path))

% add autocor tools
addpath(genpath(acf_tools_path))

%% set environment variables 

setenv('EXPERIMENT_DIR', experiment_path); 
setenv('SUBJECTS_DIR', subjects_dir); 

%%

tbl_subjects = read_tsv(fullfile(raw_path, 'participants.tsv')); 

% subjects = cellfun(@(x) sprintf('%02d', x), num2cell(tbl_subjects.subject), 'uni', 0)'; 
subjects = cellfun(@(x) str2num(get_bids_value(x,'sub')), tbl_subjects.participant_id, 'uni', 1); 

% list of subject for whom FFR cannot be extracted (because no electrodes
% in contacts implanted in HG
subjects_no_ffr = [12, 13]; 

% subjects without tapping task 
subjects_no_tap = find(~tbl_subjects.did_tapping_task); 

rhythms = {'sp', 'wp'}; 

tasks = {'listen', 'tap'}; 

trial_duration = 40.8;

cycle_duration = 2.4; 

grid_ioi = 0.2; 

rois = {"HG", "PT", "pSTG", "PP", "mSTG", 'SMG', 'SMC', 'IFG', 'MFG', 'SFG', 'SMA'}; 


%% preprocessing

% re-referencing
reref_method = 'avg'; % 'avg': common average

% notch filter
do_notchfilter = 1; 
notch_frequency = [50 100 150 200]; 
notch_width = 2; 
notch_slope_width = 2; 
notch_invert_filter = 0; 
notch_plot = 1; 

% trial segmentation
segm_buffer_dur = 5; 

%% filtering

erp_low_pass_cutoff = 20; 
erp_low_pass_order = 4; 

acf_low_pass_cutoff = 30; 
acf_low_pass_order = 2; 

erp_deci_fs = 128;
acf_deci_fs = 128; 

%% FFT 

fft = []; 

fft.snr_bins_eeg = [3,13]; % (1/2.4)/(1/40.8) = 17 bins between harmonics

fft.snr_bins_coch = [3,13]; 

% Theshold to categorize electrode as "significantly responsive". This refers to the value of 
% signal vs. noise zscore, taken from averaged "chunks" around all frequencies of interest. 
% _____|\_____
fft.z_snr_alpha = 0.01; 

fft.maxfreqlim = 5.5; 

fft.frex = 1/2.4 * [1:11]; 

fft.idx_meterRel = [3,6,9]; 

fft.idx_meterUnrel = setdiff([1:11], fft.idx_meterRel); 

assert(isempty(intersect(fft.idx_meterRel, fft.idx_meterUnrel)))


%% acf 

acf.ap_fit_method = 'irasa'; 

acf.fit_knee = false; 

acf.normalize_acf = true; 

acf.min_freq_ap_fit = 0.1; 
acf.max_freq_ap_fit = 9; 

acf.only_use_f0_harmonics = true; 

acf.keep_band_around_harmonics = [1,1]; %[2, 5]; 

acf.snr_bins = [2, 5]; 

% autocorrelation lags (in seconds) that are considered meter-related and
% meter-unrelated
acf.min_lag = 0;
acf.max_lag = trial_duration / 2; 

acf.lag_base_incl_meter_rel = [0.8]; 
acf.lag_base_excl_meter_rel = [0.6, 1.0, 1.4]; % [0.6, 1.0, 1.4]   [2.4]

acf.lag_base_incl_meter_unrel = [0.6, 1.0, 1.4]; % [0.6, 1.0, 1.4]   [0.2]
acf.lag_base_excl_meter_unrel = [0.4]; 

if ~exist('get_lag_harmonics', 'file')
    error('cant find function get_lag_harmonics: make sure you have added acf_tools to path...')
end

% meter-related lags 
% ------------------

% Make sure there's no overlap with muiltiples of meter-unrelated lags, and 
% also the pattern repetition period. 
acf.lags_meter_rel = get_lag_harmonics(...
                            acf.lag_base_incl_meter_rel, ...
                            acf.max_lag,...
                            'lag_harm_to_exclude', acf.lag_base_excl_meter_rel ...
                            ); 

% meter-unrelated lags 
% --------------------

% Make sure there's no overlap with muiltiples of meter-related lags 
% (even 0.4 seconds!), and also the pattern repetition period. 
acf.lags_meter_unrel = get_lag_harmonics(...
                            acf.lag_base_incl_meter_unrel, ...
                            acf.max_lag,...
                            'lag_harm_to_exclude', acf.lag_base_excl_meter_unrel ...
                            ); 

% make sure one more time that there's no overlap between meter-rel and -unrel !!! 
assert(~any( min(abs(bsxfun(@minus, acf.lags_meter_rel', acf.lags_meter_unrel))) < 1e-9 ))


%% FFR

ffr_extraction_Nbins = 2; 
ffr_extraction_method = 'closest'; % mean / max / closest


%% plotting 

col_meterRel = [222 45 38]/255; 
col_meterUnrel = [49, 130, 189]/255; 
col_neutral = repmat(0.5,1,3); 

col_acf_eeg = repmat(0, 1, 3);  
col_acf_urear = repmat(0, 1, 3);  
col_acf_hilbert = repmat(0.7, 1, 3);  

col_ap = [0 0 0]/255;  

col_time_eeg = [64,0,166; 201, 96, 26]/255; 
col_time_urear = [0,0,0]; 
col_time_sound = repmat(0.7, 1, 3);  

col_z_eeg = [brighten(col_time_eeg(1,:), 0.6), 
             brighten(col_time_eeg(2,:), 0.6)]; 
col_z_urear = repmat(0, 1, 3);
col_z_hilbert = repmat(0.7, 1, 3);

linew_fft = 1.7; 

fontsize = 12; 

prec = 100; 


%% return structure 

w = whos;
params = []; 
for a = 1:length(w) 
    params.(w(a).name) = eval(w(a).name); 
end


