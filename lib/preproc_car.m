function preproc_car(subject, par, varargin)

response = 'LFP'; 
if any(strcmp(varargin, 'response'))
    response = varargin{find(strcmp(varargin, 'response'))+1}; 
end
reference = 'avg'; 
if any(strcmp(varargin, 'reference'))
    reference = varargin{find(strcmp(varargin, 'reference'))+1}; 
end

subject = sub_num2str(subject); 

%% PATHS 

raw_path = fullfile(par.raw_path, sprintf('sub-%s', subject),'ieeg'); 

preproc_path = fullfile(par.deriv_path, ...
                        sprintf('response-%s_preproc', response) ,subject); 

if ~isfolder(preproc_path)
    mkdir(preproc_path); 
end

%% LOAD DATA

% load lw6 raw file    
fname = sprintf('sub-%s_task-rhythm_ieeg.vhdr',subject); 

fprintf('\n\nLOADING raw eeg...\nfilename:\t%s\n\n',fname); 

[header, data] = RLW_import_VHDR(fullfile(raw_path,fname)); 

fprintf('\n\nraw file loaded\n\n'); 

% allocate bad channels and trials
bad_chans = []; 
bad_trials = []; 

% load bad channels and trials defined by user
[bad_chans_usr, bad_trials, tbl_chans, tbl_partic] = load_bads(subject, par); 

%% prepare events 

% load events file 
fname = sprintf('sub-%s_task-rhythm_events.tsv',subject); 
tbl_events = read_tsv(fullfile(raw_path, fname)); 

events = []; 
for i_ev=1:size(tbl_events,1)
    events(i_ev).code = [tbl_events.rhythm{i_ev}, '-', tbl_events.task{i_ev}]; 
    events(i_ev).epoch = 1; 
    events(i_ev).latency = tbl_events.onset(i_ev); 
end

header.events = events; 

%% fix sampling rate 

fname = sprintf('sub-%s_task-rhythm_ieeg.json', subject); 
eeg_sidecar = jsondecode(fileread(fullfile(raw_path, fname)));
header.xstep = 1 / eeg_sidecar.SamplingFrequency;


%% REMOVE BAD CHANNELS

% convert to a column vector
if size(bad_chans_usr,1)<size(bad_chans_usr,2)
    bad_chans_usr = bad_chans_usr'; 
end

% find surface EEG channels 
eeg_chan_idx = ~cellfun(@isempty, regexp({header.chanlocs.labels},'^s\w{1,2}\d{0,2}')); 

% % if external reference is requested, look for FPz, Fp1 or Fp2
% if strcmpi(reference,'external')
%     ref_idx = find(~cellfun(@isempty, regexpi({header.chanlocs.labels}, 'sFp.'))); 
%     reref_ref_list = {header.chanlocs(ref_idx).labels}; 
%     eeg_chan_idx(ref_idx) = false; 
% end

% channels ending with + sign 
plus_chan_idx = ~cellfun(@isempty, regexp({header.chanlocs.labels},'+$')); 

% find all bad channel indices
bad_chan_idx = find(eeg_chan_idx | plus_chan_idx); 

bad_chans = {header.chanlocs(bad_chan_idx).labels}';

bad_chans_not_seeg = tbl_chans.name(~strcmp(tbl_chans.type, 'SEEG'));

% merge auto and user-defined bads
bad_chans = [bad_chans, 
            bad_chans_usr, 
            bad_chans_not_seeg]; 

% check if all user-defined bad channels were found
if ~all(ismember(bad_chans_usr,{header.chanlocs.labels}))
    chan_not_found = join(bad_chans_usr(~ismember(bad_chans_usr,{header.chanlocs.labels})),'  '); 
    warning(sprintf('User-defined bad channels were not found for %s. \nMost probable reason is a whitespace.\n%s',...
        subject, chan_not_found{1}));
end

% merge it together and print to terminal
bad_chans_idx = find(ismember({header.chanlocs.labels},bad_chans));
fprintf('\nremoving following channels: \n'); 
disp({header.chanlocs(bad_chans_idx).labels}')

% find which channels to keep
chan_idx = find(~ismember([1:header.datasize(2)],bad_chans_idx));

% remove channels 
[header,data] = RLW_arrange_channels(header, data, {header.chanlocs(chan_idx).labels}); 

%% REMOVE BAD TRIALS

if size(bad_trials,1)<size(bad_trials,2)
    bad_trials = bad_trials'; 
end

% remove trials
header.events(bad_trials) = []; 

%% REREFERENCE

% to common average
if strcmpi(reference,'avg')
    
    fprintf('re-referencing to common average of %d electrodes\n',...
        length({header.chanlocs.labels})); 
    
    reref_apply_list = {header.chanlocs.labels}; 
    reref_ref_list = {header.chanlocs.labels}; 
    % run
    [header,data] = RLW_rereference(header,data, ...
                                    'apply_list',reref_apply_list, ...
                                    'reference_list',reref_ref_list);
                                
elseif strcmpi(reference,'white')
    
    fpath = fullfile(par.raw_path, ...
                     sprintf('sub-%s', subject), ...
                     'ieeg', ...
                     'white_matter_contact.txt'); 
    if ~isfile(fpath)
        error('cannot find white matter contact in raw folder of sub-%s', subject); 
    else
        fid_white = fopen(fpath, 'r'); 
        reref_ref_list = {fgetl(fid_white)}; 
        fclose(fid_white); 
    end
    fprintf('re-referencing to %s electrodes (white matter contact)\n',...
        strjoin(reref_ref_list)); 
    
    reref_apply_list = {header.chanlocs.labels};       
    reref_apply_list(ismember(reref_apply_list, reref_ref_list)) = []; 
    % run
    [header,data] = RLW_rereference(header,data, ...
                                    'apply_list',reref_apply_list, ...
                                    'reference_list',reref_ref_list);
    % remove ref chans
    [header,data] = RLW_arrange_channels(header, data, reref_apply_list); 

elseif strcmpi(reference,'external')
        
    fprintf('external reference already applied in the raw data: I will not do anything...\n'); 
%     if isempty(reref_ref_list)
%         warning('sub-%s external channels not found...looking for white matter contact', subject); 
%         fpath = fullfile(par.raw_path, subject, 'ieeg', 'white_matter_contact.txt'); 
%         if ~isfile(fpath)
%             error('cannot find white matter contact in raw folder of sub-%s', subject); 
%         else
%             fid_white = fopen(fpath, 'r'); 
%             reref_ref_list = {fgetl(fid_white)}; 
%             fclose(fid_white); 
%         end
%     end
%     fprintf('re-referencing to %s electrodes\n',...
%         strjoin(reref_ref_list)); 
%     
%     reref_apply_list = {header.chanlocs.labels};       
%     reref_apply_list(ismember(reref_apply_list, reref_ref_list)) = []; 
%     % run
%     [header,data] = RLW_rereference(header,data, ...
%                                     'apply_list',reref_apply_list, ...
%                                     'reference_list',reref_ref_list);
%     % remove ref chans
%     [header,data] = RLW_arrange_channels(header, data, reref_apply_list); 

    
else
    warning('no re-reference method selected...'); 
end

%% NOTCH FILTER to remove power line

fprintf('notch filter at \n')
disp(par.notch_frequency')

% run
[header,data] = RLW_FFT_notch_filter(header,data, ... 
                                     'notch_frequency',par.notch_frequency, ...
                                     'notch_width',par.notch_width, ...
                                     'notch_slope_width',par.notch_slope_width, ...
                                     'invert_filter',par.notch_invert_filter); 


% check that the notch filter worked
f = figure('color','w'); 
fs = 1/header.xstep; 
N = length(data); 
hN = floor(N/2)+1; 
freq = [0:round(500/fs*N)]/N*fs; 
mX = abs(fft(squeeze(data(1,1,1,1,1,:)))); 
plot(freq, mX(1:length(freq))); 
box off
fname = fullfile(preproc_path,'notch_filter.fig'); 
saveas(f, fname); 
close(f); 


%% SEGMENT

% epoch 
[header, data] = segment_safe(header, data, ...
                              unique({header.events.code}), ...
                              'x_start', -par.segm_buffer_dur,...
                              'x_duration', par.trial_duration+2*par.segm_buffer_dur, ...
                              'out_of_range', 'zero_pad' ...
                              );

%% SAVE

fname = sprintf('sub-%s_response-%s_preproc', subject, response); 

fprintf('saving file %s\n', fname);
header.name = fname; 
CLW_save(preproc_path, header, data); 






