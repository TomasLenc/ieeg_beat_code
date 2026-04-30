function [psth,neurogram_ft,t_ft,neurogram_mr,t_mr] = generate_neurogram_UREAR2(stim,Fs_stim,species,ag_fs,ag_dbloss,CF_num,dur,iCF,fiber_num,CF_range)

% model fiber parameters
numcfs = CF_num;
%CFs   = logspace(log10(250),log10(16e3),numcfs);  % CF in Hz;
CFs = logspace(log10(CF_range(1)),log10(CF_range(2)),CF_num);
% cohcs  = ones(1,numcfs);  % normal ohc function
% cihcs  = ones(1,numcfs);  % normal ihc function

dbloss = interp1(ag_fs,ag_dbloss,CFs,'linear','extrap');

% mixed loss
[cohcs,cihcs,OHC_Loss] = fitaudiogram2(CFs,dbloss,species);

% OHC loss
% [cohcs,cihcs,OHC_Loss]=fitaudiogram(CFs,dbloss,species,dbloss);

% IHC loss
% [cohcs,cihcs,OHC_Loss]=fitaudiogram(CFs,dbloss,species,zeros(size(CFs)));

% Number of [LSR, MSR, HSR] fibers at each CF in a healthy AN
numsponts_healthy = fiber_num;

if exist('ANpopulation.mat','file')
    
	disp('Loading existing population of AN fibers saved in ANpopulation.mat')
	load('ANpopulation.mat','sponts','tabss','trels')    

	if (size(sponts.LS,2)<numsponts_healthy(1)) || (size(sponts.MS,2)<numsponts_healthy(2)) || (size(sponts.HS,2)<numsponts_healthy(3)) || (size(sponts.HS,1)<numcfs || ~exist('tabss','var'))
        
		disp('Saved population of AN fibers in ANpopulation.mat is too small - generating a new population');
		[sponts,tabss,trels] = generateANpopulation(numcfs,numsponts_healthy);
        
    end
    
else
	[sponts,tabss,trels] = generateANpopulation(numcfs,numsponts_healthy);
end

implnt = 0;    % "0" for approximate or "1" for actual implementation of the power-law functions in the Synapse
noiseType = 1;  % 0 for fixed fGn (1 for variable fGn)


% PSTH parameters

psthbinwidth_mr = 100e-6; % mean-rate binwidth in seconds;
windur_ft=32;
smw_ft = hamming(windur_ft);
windur_mr=128;
smw_mr = hamming(windur_mr);





pin = stim(:).';

% clear stim100k

simdur = ceil(dur*1.2/psthbinwidth_mr)*psthbinwidth_mr;


CFlp = iCF;

CF = CFs(CFlp);
cohc = cohcs(CFlp);
cihc = cihcs(CFlp);

numsponts = round([1 1 1].*numsponts_healthy); % Healthy AN
% numsponts = round([0.5 0.5 0.5].*numsponts_healthy); % 50% fiber loss of all types
% numsponts = round([0 1 1].*numsponts_healthy); % Loss of all LS fibers
% numsponts = round([cihc 1 cihc].*numsponts_healthy); % loss of LS and HS fibers proportional to IHC impairment

sponts_concat = [sponts.LS(CFlp,1:numsponts(1)) sponts.MS(CFlp,1:numsponts(2)) sponts.HS(CFlp,1:numsponts(3))];
tabss_concat = [tabss.LS(CFlp,1:numsponts(1)) tabss.MS(CFlp,1:numsponts(2)) tabss.HS(CFlp,1:numsponts(3))];
trels_concat = [trels.LS(CFlp,1:numsponts(1)) trels.MS(CFlp,1:numsponts(2)) trels.HS(CFlp,1:numsponts(3))];
nrep = 1;
vihc = model_IHC_BEZ2018(pin,CF,nrep,1/Fs_stim,simdur,cohc,cihc,species);



% PSTH parameters
psthbinwidth_mr = 100e-6; % mean-rate binwidth in seconds;
windur_ft=32;
smw_ft = hamming(windur_ft);
windur_mr=128;
smw_mr = hamming(windur_mr);

pin = stim(:).';

simdur = ceil(dur*1.2/psthbinwidth_mr)*psthbinwidth_mr;


for spontlp = 1:sum(numsponts)
	
	if exist ('OCTAVE_VERSION', 'builtin') ~= 0
		fflush(stdout);
	end
	
	spont = sponts_concat(spontlp);
	tabs = tabss_concat(spontlp);
	trel = trels_concat(spontlp);
	[psth_ft,~,~,~] = model_Synapse_BEZ2018(vihc,CF,nrep,1/Fs_stim,noiseType,implnt,spont,tabs,trel);
	
    psthbins = round(psthbinwidth_mr * Fs_stim);  % number of psth_ft bins per psth bin
    psth_mr  = sum( reshape( psth_ft, psthbins, length(psth_ft)/psthbins ) );
    
    
	if spontlp == 1
		psth = psth_ft;
		neurogram_ft = filter(smw_ft,1,psth_ft);
		neurogram_mr = filter(smw_mr,1,psth_mr);
	else
		psth = psth + psth_ft;
		neurogram_ft = neurogram_ft+filter(smw_ft,1,psth_ft);
		neurogram_mr = neurogram_mr+filter(smw_mr,1,psth_mr);
	end
	
end % end of for Spontlp

neurogram_ft = neurogram_ft(1:windur_ft/2:end); % 50% overlap in Hamming window
t_ft = 0 : windur_ft/2/Fs_stim : (size(neurogram_ft,2)-1)*windur_ft/2/Fs_stim; % time vector for the fine-timing neurogram

neurogram_mr = neurogram_mr(:,1:windur_mr/2:end); % 50% overlap in Hamming window
t_mr = 0 : windur_mr/2*psthbinwidth_mr : (size(neurogram_mr,2)-1)*windur_mr/2*psthbinwidth_mr; % time vector for the mean-rate neurogram



