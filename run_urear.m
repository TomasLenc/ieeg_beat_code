% note: don't forget to compile the UR-EAR mex files before running this
% (look inside ./lib/UR_EAR2020b/source folder)

clear

addpath(genpath('lib/UR_EAR2020b')); 

par = get_par; 

if ~isdir(par.urear_path)
    mkdir(par.urear_path) 
end


%% start parpool

% set up parallel pool 
if isempty(gcp('nocreate'))
    clust = parcluster('local'); 
    n_workers = clust.NumWorkers; 
    parpool(n_workers-1); 
end

%% parameters
 
cfg = []; 

% sampling frequencies
cfg.Fs_old          = 44100; % original input sampling rate
cfg.Fs              = 100e3; % samples/sec
cfg.RsFs            = 100;  % resample rate for plots

% ---------------------------------------------------------------
% model parameters

% Model sampling rate (must be 100k, 200k or 500k for AN model):
Pref        = 20e-6; % reference pressure in pascals
cfg.spl     = 75;  % dB SPL of the stimulus

% AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR) (only for Zilany 2014 model)
cfg.fiberType = 3; 

% Set cfg.implnt = 0 => approximate model, 1 => exact power law
% implementation (See Zilany et al., 2009)
cfg.implnt = 0;

% number of repetitions
cfg.nrep = 1;

% Set cfg.noiseType to 0 for fixed fGn or 1 for variable fGn - this is the
% 'noise' associated with spontaneous activity of AN fibers - see Zilany
% et al., 2009. 0 lets you "freeze" it.
cfg.noiseType = 1;

% 1=cat; 2=human AN model parameters (with Shera tuning sharpness)
cfg.species = 2; 

% Number of [LSR, MSR, HSR] fibers at each CF in a healthy AN (only for Bruce 2018 model)
n_fibres = 51; % 51
cfg.numsponts = round([n_fibres*0.16, n_fibres*0.23, n_fibres*0.61]); % (based on Liberman 1978)

% set range and resolution of cfg.CFs here
CF_num = 128; % 128
CF_range = [130, 8000]; 
cfg.CFs = logspace(log10(CF_range(1)),log10(CF_range(2)),CF_num); 
cfg.CFs([1 end]) = CF_range; % force end points to be exact.

% Cell containing different IC units that will be simulated. 
% Example: 
%       icunits = {[16], [16,32,64]}; 
% Simulates two separate populations if IC units. 
% One will consist only of units with best-modulation frequency 16 Hz. 
% The other will contain 3 separate cell types tuned to [16, 32, 64] Hz. 
% The responses of the different cell types than can be summed for
% subsequent analysis. 
% Each IC type will be saved in a separate file. 
icunits = {[2], [4], [8], [16], [32], [64]};

% PSTH parameters (only for Bruce 2018)
psthbinwidth_mr = 100e-6; % mean-rate binwidth in seconds;
windur_ft       = 32;
smw_ft          = hamming(windur_ft);
windur_mr       = 128;
smw_mr          = hamming(windur_mr);
psthbins        = round(psthbinwidth_mr * cfg.Fs);  % number of psth_ft bins per psth bin

% audiogram (normal hearing)
ag_fs = [125, 250, 500, 1000, 2000, 4000, 8000]; 
ag_dbloss = [0,0,0,0,0,0,0]; 
dbloss = interp1(ag_fs,ag_dbloss,cfg.CFs,'linear','extrap');
[cohc_vals,cihc_vals] = fitaudiogram2(cfg.CFs,dbloss,cfg.species);
if cohc_vals(1) == 0
    % For a very low CF, a 0 may be returned by Bruce et al. fit
    % audiogram, but this is a bad default.  Set it to 1 here.
    cohc_vals(1) = 1;
end
if cihc_vals(1) == 0
    % For a very low CF, a 0 may be returned, but this is a bad default.
    % Set it to 1 here.
    cihc_vals(1) = 1;
end

% define which AN model will be used: 
%     1: Zilany 2014
%     2: Bruce 2018
cfg.Which_AN = 2; 

% define which IC model will be used: 
%     1. SFIE model
%     2. Monoaural simple filter
cfg.Which_IC = 1; 


for i_rhythm=1:length(par.rhythms)

    % allocate output structure
    output = []; 
    
    fprintf('\nprocessing %s\n\n', par.rhythms{i_rhythm}); 
    
    % get stimulus
    [s, cfg.Fs_old] = audioread(fullfile(par.raw_path, 'stimuli', sprintf('rhythm-%s_version-02.wav', par.rhythms{i_rhythm}))); 

    % L and R are the same, just take one of them
    s = s(:,1); 
    
    % resample to sampling rate required for AN model, and store in
    s = resample(s, cfg.Fs, cfg.Fs_old);

    % scale to desired RMS level
    s = s * (Pref*10.^(cfg.spl/20)/rms(s));

    % stimulus length
    N               = length(s);
    stimDur         = N/cfg.Fs;
    stimDurPadded   = stimDur + 0.04;
    T               = 1/cfg.Fs;

    % check for NaN in the stimulus (otherwise Matlab will pass these to mex
    % filex and crash hard)
    if any(isnan(s))
        error('NaN in the stimulus')
    end

    
    %% model AN stage
    
    % Run through this once, because this will be the same for any
    % IC unit. 
    % After the AN is done, go to another, separate loop across IC units. 
    
    % initialize variables
    numCF = length(cfg.CFs);
    cfis = 1:numCF; 

    % allocate AN
    if cfg.Which_AN==1
        
        N                   = round(stimDurPadded * cfg.RsFs);  
        an_sout_plot        = nan(numCF, N); % this will be for plotting
        an_sout             = zeros(numCF, stimDurPadded*cfg.Fs); % this will be input to IC unit
        
    elseif cfg.Which_AN==2
        
        [sponts,tabss,trels] = generateANpopulation(CF_num,cfg.numsponts);

        CFlp=1; spontlp=1; CF = cfg.CFs(CFlp);

        sponts_concat       = [sponts.LS(CFlp,1:cfg.numsponts(1)) sponts.MS(CFlp,1:cfg.numsponts(2)) sponts.HS(CFlp,1:cfg.numsponts(3))];
        tabss_concat        = [tabss.LS(CFlp,1:cfg.numsponts(1))  tabss.MS(CFlp,1:cfg.numsponts(2))  tabss.HS(CFlp,1:cfg.numsponts(3))];
        trels_concat        = [trels.LS(CFlp,1:cfg.numsponts(1))  trels.MS(CFlp,1:cfg.numsponts(2))  trels.HS(CFlp,1:cfg.numsponts(3))];
        
        cohc = cohc_vals(CFlp);
        cihc = cihc_vals(CFlp);

        [vihc]              = model_IHC_BEZ2018(s',CF,cfg.nrep,T,stimDurPadded,cohc,cihc,cfg.species); 

        spont               = sponts_concat(spontlp);
        tabs                = tabss_concat(spontlp);
        trel                = trels_concat(spontlp);    
        
        [psth_ft]           = model_Synapse_BEZ2018(vihc, CF, cfg.nrep, T, cfg.noiseType, cfg.implnt, spont, tabs, trel);

        psth_mr             = sum( reshape( psth_ft, psthbins, length(psth_ft)/psthbins ) );

        neurogram_ft        = zeros(numCF, length(psth_ft)); % fuck this must be initialized to zeros, do'nt do NaN cause you're summing!!!
        neurogram_mr        = zeros(numCF, length(psth_mr)); 
        
        cfg.FsFt            = 1 / 1.6000e-04; 
        cfg.FsMr            = 1 / 0.0064; 
       
        N                   = ceil(stimDurPadded * cfg.FsMr);  
        an_sout_plot        = zeros(numCF, N); % this will be the mean rate (to save space) 
        an_sout             = zeros(numCF, length(psth_ft)); % this will be input to IC unit
        
    end

    % CF loop
    parfor cfi=cfis

        % Get one element of each array.
        CF = cfg.CFs(cfi); % CF in Hz;
        fprintf('processing channel %d with CF = %g Hz \n',cfi,CF); 

        cohc = cohc_vals(cfi);
        cihc = cihc_vals(cfi);

        switch cfg.Which_AN

            case 1

                % Using ANModel_2014 (2-step process)
                vihc = model_IHC(s',CF,cfg.nrep,T,stimDurPadded,cohc,cihc,cfg.species);

                % an_sout is the auditory-nerve synapse output - a rate vs. time
                % function that could be used to drive a spike generator.
                [an_sout(cfi,:),~,~] = model_Synapse(vihc,CF,cfg.nrep,T,cfg.fiberType,cfg.noiseType,cfg.implnt);

                % Save synapse output waveform into a matrix.
                an_sout_plot(cfi,:) = resample(an_sout(cfi,:), cfg.RsFs, cfg.Fs);

                
            case 2

                % 2018 model
                vihc = model_IHC_BEZ2018(s',CF,cfg.nrep,T,stimDurPadded,cohc,cihc,cfg.species);      


                for spontlp = 1:sum(cfg.numsponts)

                    spont = sponts_concat(spontlp);
                    tabs = tabss_concat(spontlp);
                    trel = trels_concat(spontlp);

                    [psth_ft,~,~,~] = model_Synapse_BEZ2018(vihc, CF, cfg.nrep, T, cfg.noiseType, cfg.implnt, spont, tabs, trel);

                    if spontlp==1
                        psth = psth_ft; 
                    else
                        psth = psth + psth_ft; 
                    end

                    psth_mr  = sum( reshape( psth_ft, psthbins, length(psth_ft)/psthbins ) );

                    neurogram_ft(cfi,:) = neurogram_ft(cfi,:) + filter(smw_ft,1,psth_ft);
                    neurogram_mr(cfi,:) = neurogram_mr(cfi,:) + filter(smw_mr,1,psth_mr);

                end 

                an_sout(cfi,:) = (100000*psth)/sum(cfg.numsponts);

        end

    end % end of CF loop

    % if 2018 AN model
    if cfg.Which_AN==2

        neurogram_ft = neurogram_ft(:, 1:windur_ft/2:end); % 50% overlap in Hamming window
        t_ft = 0 : windur_ft/2/cfg.Fs : (size(neurogram_ft,2)-1)*windur_ft/2/cfg.Fs; % time vector for the fine-timing neurogram

        neurogram_mr = neurogram_mr(:, 1:windur_mr/2:end); % 50% overlap in Hamming window
        t_mr = 0 : windur_mr/2*psthbinwidth_mr : (size(neurogram_mr,2)-1)*windur_mr/2*psthbinwidth_mr; % time vector for the mean-rate neurogram

        an_sout_plot = neurogram_mr; 
    end    
    
    % --------------------------------------------------------------------------------
    % save AN response
    AN = []; 

    % we need to cut the silence at the end (we put 40 ms)
    if cfg.Which_AN == 1

        maxIdx              = round(stimDur * cfg.RsFs); 
        data                = an_sout_plot(:,1:maxIdx);
        N                   = size(data,2);
        timevec             = (0:N-1)/cfg.RsFs;

        AN.an_sout   = data; 
        AN.fs        = cfg.RsFs; 
        AN.t         = timevec; 

    elseif cfg.Which_AN == 2

        maxIdx              = round(stimDur * cfg.FsMr); 
        data                = an_sout_plot(:,1:maxIdx);
        N                   = size(data,2);
        timevec             = (0:N-1)/cfg.FsMr; 

        AN.an_sout   = data; 
        AN.fs        = cfg.FsMr;     
        AN.t         = timevec; 

        AN.stim = s; 
        AN.fs_stim = cfg.Fs; 
        
    end
    
    data = AN; 
    data.cfg = cfg; 
    
    fname = sprintf('model-urear_stage-an_rhythm-%s.mat', par.rhythms{i_rhythm}); 

    save(fullfile(par.urear_path, fname), 'data', '-v7.3') 
     
     
    %% IC
     
    for icuniti=1:length(icunits)

        % allocate IC
        IC = []; 
        
        % (there is 6-7 ms added in the output so we can allocate more...cut it
        % within the loop before assigning)
        cfg.BMFs = icunits{icuniti}; 
        
        numBMF                  = length(cfg.BMFs);    
        N                       = round(stimDurPadded * cfg.RsFs);  
        BE_sout_population      = nan(numBMF, numCF, N); 
        BS_sout_population      = nan(numBMF, numCF, N); 
        
        for bmfi=1:numBMF

            BMF = cfg.BMFs(bmfi); 
            fprintf('processing IC (iter %d) with BMF = %g Hz \n',bmfi,BMF); 

            for cfi=cfis

                switch cfg.Which_IC

                    case 1 % Monaural SFIE

                        [ic_sout_BE,ic_sout_BS,cn_sout_contra] = SFIE_BE_BS_BMF(an_sout(cfi,:), BMF, cfg.Fs);
                        BE_sout_population_tmp = resample(ic_sout_BE, cfg.RsFs, cfg.Fs);
                        BE_sout_population(bmfi,cfi,:) = BE_sout_population_tmp(1:N);

                        BS_sout_population_tmp = resample(ic_sout_BS,cfg.RsFs,cfg.Fs);
                        BS_sout_population(bmfi,cfi,:) = BS_sout_population_tmp(1:N);

                    case 2 % Monaural Simple Filter

                        % Now, call NEW unitgain BP filter to simulate bandpass IC cell with all BMFs.
                        ic_sout_BE = unitgain_bpFilter(an_sout(cfi,:), BMF, cfg.Fs);

                        BE_sout_population_tmp = resample(ic_sout_BE, cfg.RsFs, cfg.Fs); 
                        BE_sout_population(bmfi,cfi,:) = BE_sout_population_tmp(1:N);
                end

            end
            
        end
        
        maxIdx              = round(stimDur * cfg.RsFs); 
        data                = BE_sout_population(:,:,1:maxIdx);
        N                   = length(data); 
        timevec             = [0:N-1]/cfg.RsFs; 

        IC           = []; 
        IC.BE_sout   = data;
        IC.fs        = cfg.RsFs; 
        IC.t         = timevec; 

        IC.stim = s; 
        IC.fs_stim = cfg.Fs; 

        % save
        data = IC; 
        data.cfg = cfg; 

        fname = sprintf('model-urear_stage-ic_rhythm-%s_bmf-%d.mat', par.rhythms{i_rhythm}, icunits{icuniti}); 
        
        save(fullfile(par.urear_path, fname), 'data', '-v7.3') 
             
    end % end icunit loop
    
end % end of condition loop


