
clear

par = get_par; 

%% process stimuli and brainstem model 

% preprocess 
prepare_stim('s')
prepare_stim('hilbert')
prepare_stim('an')
prepare_stim('ic')
prepare_stim('flux')

% FFT
extract_features_stim_fft('hilbert', par)
extract_features_stim_fft('an', par)
extract_features_stim_fft('ic', par)
extract_features_stim_fft('flux', par)

% ACF  
extract_features_stim_acf('hilbert', par)
extract_features_stim_acf('an', par)
extract_features_stim_acf('ic', par)
extract_features_stim_acf('flux', par)

%% anatomy 

% prepare bipolar labels 
prepare_anat_bipolar(par); 

%% run preprocessing to obtain continous timecourses for different responses

for i_sub=1:length(par.subjects)    
    
    % common aveage reference
    preproc_car(par.subjects(i_sub), par); 

    % bipolar reference 
    preproc_bipolar(par.subjects(i_sub), par)

end

%% get ERP, FFT, ACF

responses = {'LFP', 'biLFP'}; 

parpool(4); 

for i_resp=1:length(responses)
    parfor i_sub=1:length(par.subjects)      
    
        sub = par.subjects(i_sub); 
        response = responses{i_resp}; 
        
        % get FFT for each electrode and save to disk 
        fft_whole_brain(sub, response, par)    

        % get ERP for each electrode and save to disk 
        erp_whole_brain(sub, response, par)    

        % get ACF for each electrode and save to disk 
        acf_whole_brain(sub, response, par)    
        
    end
end    

%% extract features 

for i_sub=1:length(par.subjects)      
    for i_resp=1:length(responses)
    
        sub = par.subjects(i_sub); 
        response = responses{i_resp}; 
    
        % FFR above 130 Hz (PAC physiological criterion)
        % (skip subject 12 and 13: they didn't have anything implanted in
        % HG)
        if ~ismember(sub, [12, 13]) 
            extract_features_ffr_crossmod(par.subjects(i_sub), response, par);
        end
        
        % extract features from the FFT
        extract_features_fft(par.subjects(i_sub), response, par)   

        % ACF 
        extract_features_acf(par.subjects(i_sub), response, par)   
        
    end
end


