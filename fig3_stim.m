clear

par = get_par(); 


response = 'ic'; % hilbert, flux, ic
rhythm = 'wp'; % wp, sp


%% plot s 

f = figure('color', 'w', 'pos',[620 970 712 77]); 
pnl = panel(f); 
pnl.pack('v', 2); 

stim_path = fullfile(par.raw_path, 'stimuli'); 

ax = pnl(1).select(); 
[s,fs] = audioread(fullfile(stim_path, 'rhythm-wp_version-02.wav'));
s = s(:,1); 
t = [0 : length(s)-1] / fs; 
plot(t, s, 'linew', 1, 'color', [.5,.5,.5])
ax.YAxis.TickLength = [0 0];
ax.TickDir = 'out'; 
ax.XLim = [0, 4.8]; 
ax.Visible = 'off'; 


ax = pnl(2).select(); 
[s,fs] = audioread(fullfile(stim_path, 'rhythm-sp_version-02.wav'));
s = s(:,1); 
t = [0 : length(s)-1] / fs; 
plot(t, s, 'linew', 1, 'color', [.5,.5,.5])
ax.YAxis.TickLength = [0 0];
ax.TickDir = 'out'; 
ax.XLim = [0, 4.8]; 
ax.Visible = 'off'; 

pnl.margin = [1,1,1,1]; 


saveas(f, fullfile(par.figures_path, 'stimuli.svg')); 

close(f); 

%% plot ACF 
        
fpath = fullfile(par.deriv_path, sprintf('response-%s_ACF', response));  

fname = sprintf('rhythm-%s_response-%s_ACFraw.lw6', ...
                rhythm, response); 
      
[header, data] = CLW_load(fullfile(fpath, fname)); 

acf = ensure_row(squeeze(data)); 

c = [0, 0, 0]; 

lags = [0 : length(acf)-1] * header.xstep;                     

min_lag = 0.1; 
min_lag_idx = dsearchn(lags', min_lag); 
lags = lags(min_lag_idx : end); 
acf = acf(:, min_lag_idx : end); 

acf_grand = mean(acf, 1); 
sem_grand = std(acf,[],1) ./ sqrt(size(acf, 1)); 
ci_grand = norminv(1 - 0.05/2) * sem_grand;     

acf_grand = acf_grand - min(acf_grand); 
acf_grand = acf_grand ./ max(acf_grand); 

ci_grand = ci_grand - min(acf_grand); 
ci_grand = ci_grand ./ max(acf_grand); 

f = figure('color', 'w', 'pos', [620 918 174 129]); 
pnl = panel(f); 
ax = pnl.select(); 
hold on 
fill([lags, fliplr(lags)], ...
     [acf_grand+ci_grand, fliplr(acf_grand-ci_grand)], ...
     c, ...
    'facealpha',0.3, ...
    'LineStyle','none')
plot(lags, acf_grand, 'linew', 3, 'color', c)

ax.YAxis.TickLength = [0 0];
ax.TickDir = 'out'; 
ax.XLim = [min_lag, 1.4];
ax.XTick = [0.2 : 0.2 : 1.2]; 
ax.YLim = [0, 1];
ax.YTick = [];       


saveas(f, fullfile(par.figures_path, sprintf('response-%s_rhythm-%s_acf.svg', ...
            response, rhythm))); 

close(f); 



%% plot ERP 

% load stim 
fpath = fullfile(par.deriv_path, 'response-s_ERPcycle')
fname = sprintf('rhythm-%s_response-s_cycleERP.lw6', rhythm); 
[header, data] = CLW_load(fullfile(fpath, fname)); 
t_s = [0 : header.datasize(end)-1] * header.xstep;  
erp_s = squeeze(data)'; 

fpath = fullfile(par.deriv_path, sprintf('response-%s_ERPcycle', response)); 
fname = sprintf('rhythm-%s_response-%s_cycleERP.lw6', rhythm, response); 
[header, data] = CLW_load(fullfile(fpath, fname)); 

erp = squeeze(data); 

% plot     
c = [0,0,0]; 
t = [0 : header.datasize(end)-1] * header.xstep;                     

f = figure('color', 'w', 'pos', [620 918 174 129]); 
pnl = panel(f); 
ax = pnl.select(); 
hold on 

erp_s_to_plot = erp_s; 
erp_s_to_plot = erp_s_to_plot / max(abs(erp_s_to_plot)); 
erp_s_to_plot = erp_s_to_plot * max(abs(erp)); 

h = plot(t_s, erp_s_to_plot, 'linew', 0.5, 'color', [.5 .5 .5]); 
h.Color(4) = 0.2; 

plot(t, erp, 'linew', 3, 'color', c)
ax.YAxis.TickLength = [0 0];
ax.TickDir = 'out'; 
ax.XLim = [0, 2.4]; 
ax.XAxis.Visible = 'off'; 
ax.YLim = [-max(abs(erp)), max(abs(erp))];

saveas(f, fullfile(par.figures_path, sprintf('response-%s_rhythm-%s_erpCycle.svg', ...
        response, rhythm))); 

close(f); 


%% plot FFT 

fpath = fullfile(par.deriv_path, sprintf('response-%s_FFT', response));  
      
fname = sprintf('rhythm-%s_response-%s_snr-%d-%d_FFT.lw6',...
                rhythm, response, par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2)); 
            
[header, data] = CLW_load(fullfile(fpath, fname)); 

% cut to maxfreqlim 
maxfreqidx = round(30 / header.xstep) + 1; 
header.datasize(end) = maxfreqidx; 
data = data(:,:,:,:,:,1:maxfreqidx); 

mX = squeeze(data);
mX(1) = 0; 

freq = [0 : length(mX)-1] * header.xstep; 

c = [0,0,0];

f = figure('color', 'w', 'pos', [620 918 174 129]); 
pnl = panel(f); 
ax = pnl.select(); 

plot_fft(freq, mX, 'ax', ax, ...
    'maxfreqlim', 4.9, ...
    'frex_meter_rel', par.fft.frex(par.fft.idx_meterRel), ...
    'frex_meter_unrel', par.fft.frex(par.fft.idx_meterUnrel) ...
    ); 

ax.YLim(1) = 0; 
%     ax.YLim = [0, 6.7]; 
%     ax.YTick = [0, 6]; 


saveas(f, fullfile(par.figures_path, sprintf('response-%s_rhythm-%s_mX.svg', ...
                response, rhythm))); 

close(f); 





