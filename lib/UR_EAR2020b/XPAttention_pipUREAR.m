function [out2save,cfg] = RhythmCateg_pipUREAR(s, inputcfg)


% sampling frequencies
cfg.Fs_old          = inputcfg.fs; % oroginal input sampling rate
cfg.Fs              = 100e3; % samples/sec
cfg.RsFs            = 1e3;  % resample rate for plots


% PLOT parameters
cfg.fontsize = 14; 


% allocate output structure
out2save = []; 


%% model parameters

% Model sampling rate (must be 100k, 200k or 500k for AN model):
Pref        = 20e-6; % reference pressure in pascals
cfg.spl     = 75;  % dB SPL of the stimulus

% assign the stimulus
output.stimulus = s; 

% resample to sampling rate required for AN model, and store in
output.stimulus = resample(output.stimulus, cfg.Fs, cfg.Fs_old);

% scale to desired RMS level
output.stimulus = output.stimulus * (Pref*10.^(cfg.spl/20)/rms(output.stimulus));

% stimulus length
output.N    = length(output.stimulus);
output.dur  = output.N/cfg.Fs;
output.dur2 = output.dur + 0.04;

dur     = output.dur; % duration of waveform in sec
dur2    = output.dur2;
T       = 1/cfg.Fs;

% check for NaN in the stimulus (otherwise Matlab will pass these to mex
% filex and crash hard)
if any(isnan(output.stimulus))
    error('NaN in the stimulus')
end

% AN fiber type. (1 = low SR, 2 = medium SR, 3 = high SR)
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

% number of fibres per CF (only for Bruce 2018 model)
% (By default, the generated population is only
% HSR. This can be changed easily to MSR or LSR, but you need to change the
% function "generate_neurogram_UREAR2.m" to set a combination)
cfg.fiber_num = 10; 

% set range and resolution of cfg.CFs here
CF_num = 20; 
CF_range = [130, 3000]; 
cfg.CFs = logspace(log10(CF_range(1)),log10(CF_range(2)),CF_num); 
cfg.CFs([1 end]) = CF_range; % force end points to be exact.

% IC best-modulation frequency
cfg.BMF = 16;

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
cfg.Which_AN = 1; 

% define which IC model will be used: 
%     1. SFIE model
%     2. Monoaural simple filter
cfg.Which_IC = 1; 







%% run model

num_iters = length(cfg.CFs);
iter = 0;

% allocate
N = output.dur2 * cfg.RsFs;  
VIHC_population = nan(num_iters, N); 
an_sout_population = nan(num_iters, N); 

Nplot = output.dur2 * cfg.Fs/16; 
an_sout_population_plot = nan(num_iters, N); 

% ther is 6-7 ms added in the output so we can allocate more...cut it
% within the loop before assigning
BE_sout_population = nan(num_iters,N); 
BS_sout_population = nan(num_iters,N); 


cfis = 1:length(cfg.CFs); 

parfor cfi=cfis
        
    % Get one element of each array.
    CF = cfg.CFs(cfi); % CF in Hz;
    fprintf('processing channel %d with CF = %g Hz \n',cfi,CF); 

    cohc = cohc_vals(cfi);
    cihc = cihc_vals(cfi);

    switch cfg.Which_AN
        case 1
            
            % Using ANModel_2014 (2-step process)
            vihc = model_IHC(output.stimulus,CF,cfg.nrep,T,dur2,cohc,cihc,cfg.species);
            
            % Save output waveform into matrices.
            VIHC_population(cfi,:) = resample(vihc,cfg.RsFs,cfg.Fs); 
            
            % an_sout is the auditory-nerve synapse output - a rate vs. time
            % function that could be used to drive a spike generator.
            [an_sout,~,~] = model_Synapse(vihc,CF,cfg.nrep,T,cfg.fiberType,cfg.noiseType,cfg.implnt);
            
            % Save synapse output waveform into a matrix.
            an_sout_population(cfi,:) = resample(an_sout,cfg.RsFs,cfg.Fs);

        case 2
            
            vihc = model_IHC_BEZ2018(output.stimulus,CF,cfg.nrep,T,dur2,cohc,cihc,cfg.species);      
            
            VIHC_population(cfi,:) = resample(vihc,cfg.RsFs,cfg.Fs);

            [psth,neurogram_ft] = generate_neurogram_UREAR2(output.stimulus,cfg.Fs,cfg.species,...
                ag_fs,ag_dbloss,CF_num,dur,cfi,cfg.fiber_num,CF_range,cfg.fiberType);

            an_sout = (100000*psth)/cfg.fiber_num;
            
            an_sout_population(cfi,:) = resample(an_sout,cfg.RsFs,cfg.Fs);
            
            an_sout_population_plot(cfi,:) = neurogram_ft;

    end
    
    
    switch cfg.Which_IC
        case 1 % Monaural SFIE
            
            [ic_sout_BE,ic_sout_BS,cn_sout_contra] = SFIE_BE_BS_BMF(an_sout,cfg.BMF,cfg.Fs);
            BE_sout_population_tmp = resample(ic_sout_BE,cfg.RsFs,cfg.Fs);
            BE_sout_population(cfi,:) = BE_sout_population_tmp(1:N);
            
            BS_sout_population_tmp = resample(ic_sout_BS,cfg.RsFs,cfg.Fs);
            BS_sout_population(cfi,:) = BS_sout_population_tmp(1:N);

        case 2 % Monaural Simple Filter
            
            % Now, call NEW unitgain BP filter to simulate bandpass IC cell with all BMFs.
            ic_sout_BE = unitgain_bpFilter(an_sout,cfg.BMF,cfg.Fs);
            
            BE_sout_population_tmp = resample(ic_sout_BE,cfg.RsFs,cfg.Fs); 
            BE_sout_population(cfi,:) = BE_sout_population_tmp(1:N);
    end
    
    
end % end of CF loop

                
     



% 
% output.VIHC_population = VIHC_population; 
% output.an_sout_population = an_sout_population; 
% output.an_sout_population_plot = an_sout_population_plot; 
% output.BE_sout_population = BE_sout_population; 
% output.BS_sout_population = BS_sout_population; 



%%
%% analysis
%%



%% AN model response
out2save.AN = []; 

% we need to cut the silence at the end (we put 40 ms)
if cfg.Which_AN == 1
    
    maxIdx          = round(inputcfg.SequenceDur*cfg.RsFs); 
    data            = an_sout_population(:,1:maxIdx);
    dataAvg         = mean(data,1); 
    N               = length(data);
    hN              = floor(N/2)+1; 
    timevec         = (0:N-1)/cfg.RsFs;
    
    out2save.AN.an_sout_population = data; 
    out2save.AN.fs = cfg.RsFs; 
    out2save.AN.timevec = timevec; 
     
    
elseif cfg.Which_AN == 2
    
    % an_sout_population_plot data has a sample rate = cfg.Fs/16, and is
    % delayed by 10 ms.
    cfg.FsPlot      = cfg.Fs/16;
    maxIdx          = round(inputcfg.SequenceDur*cfg.FsPlot); 
    data            = an_sout_population_plot(:,1:maxIdx);
    dataAvg         = mean(data,1); 
    N               = length(data);
    hN              = floor(N/2)+1; 
    timevec         = (0:N-1)/cfg.FsPlot - 0*10e-3; % shift by 10 ms
    
    out2save.AN.an_sout_population = data; 
    out2save.AN.fs = cfg.FsPlot;     
    out2save.AN.timevec = timevec; 
    
end




% % get FFT
% mX = abs(fft(dataAvg));
% mX = mX(1:length(freqvec)); 
% % set DC to 0
% mX(1) = 0; 
% % SNR subtraction 
% mX = subtractSNR(mX, cfg.snr(1), cfg.snr(2)); % SNR subtraction 
% % extract amplitudes
% amps = mX(frexidx); 
% 
% % assign to result structure
% output.AN_freq = freqvec; 
% output.AN_mX = mX; 
% output.AN_amps = amps; 








% 
% % PLOT
% f = figure('color','white','position',[680 448 875 650]); 
% ax_AN = subplot(3,3,[1:3,4:6]); 
% h_AN = surface(ax_AN,...
%                 timevec, ...
%                 cfg.CFs, ...
%                 zeros(size(data)), ...
%                 data, ...
%                 'FaceColor','interp',...
%                 'EdgeColor','none',...
%                 'HitTest','off');
% ax_AN.TickDir = 'out';
% ax_AN.XLim = [0,output.dur2];
% ax_AN.YLim = CF_range;
% xlabel('Time (s)')
% ylabel('AN BF (Hz)')
% title(ax_AN,'AN Model')
% set(gca,'fontsize',fontsize); 
% % colorbar
% AN_model_cb = colorbar();
% title(AN_model_cb,'sp/s');
% 
% 
% subplot(3,3,[7:8])
% plot(timevec, dataAvg,'color', 'r', 'linew',1);  
% xlim([0,20])
% box off
% ylabel('sp/s')
% xlabel('Time (s)')
% set(gca,'fontsize',fontsize); 
%   
% 
% subplot(3,3,[9])
% stem(freqvec, mX,'color', 'b', 'linew',1.7, 'marker','none');  
% hold on 
% stem(freqvec(frexidx), mX(frexidx),'color', 'r', 'linew',1.7, 'marker','none');  
% xlim([0,cfg.maxfreqlim])
% ylim([0,1.1*max(mX(1:cfg.maxfreqidx))])
% box off
% ylabel('magnitude')
% xlabel('Frequency (Hz)')
% set(gca,'fontsize',fontsize); 
% 
% 









%% IC model response

maxIdx          = round(inputcfg.SequenceDur*cfg.RsFs); 
data            = BE_sout_population(:,1:maxIdx);
dataAvg         = mean(data,1); 
N               = length(data); 
timevec         = [0:N-1]/cfg.RsFs; 

out2save.IC = []; 
out2save.IC.BE_sout_population = BE_sout_population(:,1:maxIdx);
out2save.IC.fs = cfg.RsFs; 
out2save.IC.timevec = timevec; 


%     
% % get FFT
% mX = abs(fft(dataAvg));
% mX = mX(1:length(freqvec)); 
% % set DC to 0
% mX(1) = 0; 
% % SNR subtraction 
% mX = subtractSNR(mX, cfg.snr(1), cfg.snr(2)); % SNR subtraction 
% % extract amplitudes
% amps = mX(frexidx); 
% 
% % assign to result structure
% output.BE_freq = freqvec; 
% output.BE_mX = mX; 
% output.BE_amps = amps; 


% 
% % PLOT
% f = figure('color','white','position',[680 448 875 650]); 
% ax_IC = subplot(3,3,[1:3,4:6]); 
% h_VIHC = surface(ax_IC,...
%                 timevec, ...
%                 cfg.CFs, ...
%                 zeros(size(data)), ...
%                 data, ...
%                 'FaceColor','interp',...
%                 'EdgeColor','none',...
%                 'HitTest','off');
% ax_IC.TickDir = 'out';
% ax_IC.XLim    = [0,output.dur2];
% ax_IC.YLim    = CF_range;
% caxis(ax_IC,[0,max(output.BE_sout_population(:))])
% xlabel('Time (s)')
% ylabel('IC BF (Hz)'); 
% title(ax_IC,'IC Model (BE Cell)')
% set(gca,'fontsize',fontsize); 
% % colorbar
% IC_cb = colorbar();
% title(IC_cb,'sp/s');
% 
% 
% subplot(3,3,[7:8])
% plot(timevec, dataAvg,'color', 'r', 'linew',1);  
% xlim([0,20])
% box off
% ylabel('sp/s')
% xlabel('Time (s)')
% set(gca,'fontsize',fontsize); 

% 
% subplot(3,3,[9])
% dataAvg = dataAvg - mean(dataAvg); 
% mX = abs(fft(dataAvg));
% mX = subtractSNR(mX, cfg.snr(1), cfg.snr(2)); % SNR subtraction 
% stem(freqvec, mX(1:length(freqvec)),'color', 'b', 'linew',1.7, 'marker','none');  
% hold on 
% stem(freqvec(frexidx), mX(frexidx),'color', 'r', 'linew',1.7, 'marker','none');  
% xlim([0,cfg.maxfreqlim])
% ylim([0,1.1*max(mX(1:cfg.maxfreqidx))])
% box off
% ylabel('magnitude')
% xlabel('Frequency (Hz)')
% set(gca,'fontsize',fontsize); 
% 



% % get output name
% outName = sprintf('pip7-UREAR-IC(BMF%gHz)-w%g-snr%d-%d_%dmod%dHz_%dmod%dHz', cfg.BMF, cfg.w, cfg.snr(1), cfg.snr(2), cfg.f0_1, cfg.fmod1, cfg.f0_2,  cfg.fmod2); 
% 
% % save figure
% saveas(f, fullfile('..','output',[outName,'.fig'])); 
% close(f); 
% 
% % write to text file
% outPath = fullfile('..','tsv',[outName,'.tsv']); 
% write2tsv(outPath, cfg, amps); 









%% SAVE .mat


% % sanity-check plots
% figure
% subplot 211
% plot(out2save.AN.timevec, mean(out2save.AN.an_sout_population,1))
% xlim([1,20])
% 
% subplot 212
% plot(out2save.IC.timevec, mean(out2save.IC.BE_sout_population,1))
% xlim([1,20])

 





