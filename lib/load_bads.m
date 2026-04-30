function [bad_chans, bad_trials, tbl_chans, tbl_partic] = loadBads(subject, par)

ieeg_path = fullfile(par.raw_path, ...
                     sprintf('sub-%s', subject), 'ieeg'); 

%% bad channels 

fname_chans = sprintf('sub-%s_task-rhythm_channels.tsv',subject); 

tbl_chans = readtable(fullfile(ieeg_path, fname_chans), ...
                    'Delimiter','\t','FileType','text'); 

idx_bad_chans = find(strcmpi(tbl_chans.status,'bad')); 

bad_chans = tbl_chans.name(idx_bad_chans); 

chan_types = tbl_chans.type;

%% bad trials

tbl_partic = readtable(fullfile(par.raw_path,'participants.tsv'), ...
                    'Delimiter','\t','FileType','text'); 

partic_idx = find(tbl_partic.subject == str2num(subject)); 

if isempty(partic_idx)
    error('sub-%s not found in subjects.tsv', subject); 
end
bad_trials = tbl_partic{partic_idx,'bad_trials'}; 

if isnan(bad_trials)
    bad_trials = []; 
end

