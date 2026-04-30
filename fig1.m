clear

par = get_par(); 

%%

response = 'LFP'; 
rhythm = 'wp';


%% Plot all electrodes on a template 

fpath = fullfile(par.feat_path); 

% load table with anatomy
anat = load(fullfile(fpath, 'prefix-TDT_elecs_all_anatomy.mat')); 
anat = anat.anat([anat.anat.in_gray]); 

tbl_anat = struct2table(anat); 
tbl_anat = tbl_anat(:, {'subject', 'elec', 'hem', 'xyz_warped', 'custom'}); 

% load functional data
tbl = readtable(fullfile(fpath, ...
    sprintf('response-%s_avg-time_fftAggrFreq.csv', response))); 

mask = strcmpi(tbl.rhythm, rhythm) & ...
       strcmpi(tbl.task, 'listen'); 
   
mask = mask & ...
    ismember(tbl(:, {'subject', 'elec'}),  tbl_anat(:, {'subject', 'elec'}), 'rows'); 

tbl = tbl(mask, :); 

tbl.responsive = tbl.z_snr > norminv(1-0.01); 

% only keep relevant columns
tbl = tbl(:, {'subject', 'elec', 'responsive', 'z_snr', 'z_meterRel'}); 

% merge with anat 
tbl = innerjoin(tbl, tbl_anat, 'keys', {'subject', 'elec'}); 

hems = {'lh', 'rh'};

%% 

f = figure('color','w','pos',[431 560 799 308]); 
pnl = panel(f); 
pnl.pack('h',2); 

for i_hem=1:2
    
        % load mesh 
        mesh_dir = fullfile(par.subjects_dir,'cvs_avg35_inMNI152','Meshes'); 
        
        tmp = load(fullfile(mesh_dir,sprintf('cvs_avg35_inMNI152_%s_pial_deci.mat', hems{i_hem}))); 
        
        cortex = tmp.cortex; 
        
        % plot brain 
        pnl(i_hem).select(); 
        c_h = ctmr_gauss_plot(cortex, [0 0 0], 0, hems{i_hem});
        alpha(c_h,0.2)
        
        % plot responsive elecs
        mask = strcmp(tbl.hem, hems{i_hem}) & ...
               tbl.responsive == true; 
           
        elecmatrix = tbl{mask, 'xyz_warped'}; 
        
        el_h = el_add(elecmatrix,  ...
                      'color', [255, 171, 106]/255, ...
                      'msize', 5, ...
                      'edgecol', [224, 115, 31]/255);

        % plot nonresponsive elecs
        mask = strcmp(tbl.hem, hems{i_hem}) & ...
               tbl.responsive == false; 
           
        elecmatrix = tbl{mask, 'xyz_warped'}; 
        
        el_h = el_add(elecmatrix,  ...
                      'color', [0, 0, 0], ...
                      'msize', 1, ...
                      'edgecol', [0, 0, 0]);
                  
                  
end

print(fullfile(par.figures_path, 'cvs_avg35_inMNI152_coverage.png'), ...
      '-dpng', '-painters', '-r600', f)


%% plot example elec in a ROI

% % roi = 'SMA'
% % sub = 13; 
% % el = 'AMS2'; 

% roi = 'SMA'
% sub = 9; 
% el = 'M2'; 

% roi = 'SMG'; 
% sub = 7; 
% el = 'E11'; 

% roi = 'IFG'; 
% sub = 10; 
% el = 'R''3'; 

roi = 'HG'; 
sub = 2; 
el = 'H''3'; 

% ----------------------

sub_str = sub_num2str(sub); 

tbl_ex = tbl(tbl.subject == sub & strcmpi(tbl.elec, el), :); 
assert(size(tbl_ex,1) == 1); 

f = figure('color','w','pos',[431 560 799 308]); 
pnl = panel(f); 
pnl.pack('h',2); 

hem = tbl_ex{:,'hem'}{:}; 
i_hem = find(strcmp(hems, hem)); 

% load mesh 
mesh_dir = fullfile(par.subjects_dir,'cvs_avg35_inMNI152','Meshes'); 
tmp = load(fullfile(mesh_dir,...
    sprintf('cvs_avg35_inMNI152_%s_pial_deci.mat', hem))); 
cortex = tmp.cortex; 

% plot brain 
pnl(i_hem).select(); 
c_h = ctmr_gauss_plot(cortex, [0 0 0], 0,  hem);
alpha(c_h,0.2)

elecmatrix = tbl_ex{:, 'xyz_warped'}; 

el_h = el_add(elecmatrix,  ...
              'color', [0 0 0], ...
              'msize', 5, ...
              'edgecol', [0 0 0]);

fname = sprintf('roi-%s_sub-%s_el-%s_loc.png', ...
                roi, sub_str, el); 
          
print(fullfile(par.figures_path, fname), ...
      '-dpng', '-painters', '-r600', f)

  
  
% ---------
% PLOT ERP 
% ---------

fpath = fullfile(par.deriv_path, 'response-s_ERPcycle')
fname = sprintf('rhythm-%s_response-s_cycleERP.lw6', rhythm); 
[header, data] = CLW_load(fullfile(fpath, fname)); 
t_s = [0 : header.datasize(end)-1] * header.xstep;  
erp_s = squeeze(data)'; 

fpath = fullfile(par.deriv_path, sprintf('response-%s_ERPcycle', response), sub_str); 
fname = sprintf('sub-%s_rhythm-%s_task-listen_response-%s_cycleERP.lw6', sub_str, rhythm, response); 
[header, data] = CLW_load(fullfile(fpath, fname)); 
[header, data] = RLW_arrange_channels(header, data, {el}); 
erp = squeeze(data); 
erp = erp - mean(erp); 

c = get_lut_color(roi); 
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

fname = sprintf('roi-%s_sub-%s_el-%s_erp.svg', ...
                roi, sub, el); 
saveas(f, fullfile(par.figures_path, fname))

  
% ---------
% PLOT FFT 
% ---------

fpath = fullfile(par.deriv_path, sprintf('response-%s_FFT', response), sub_str); 
fname = sprintf('sub-%s_rhythm-%s_task-listen_response-%s_avg-time_snr-%d-%d_FFT.lw6',...
                sub_str, rhythm, response, par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2)); 
[header, data] = CLW_load(fullfile(fpath, fname)); 
[header, data] = RLW_arrange_channels(header, data, {el}); 

% cut to maxfreqlim 
maxfreqidx = round(100 / header.xstep) + 1; 
header.datasize(end) = maxfreqidx; 
data = data(:,:,:,:,:,1:maxfreqidx); 
mX = squeeze(data);     
freq = [0 : length(mX)-1] * header.xstep; 
frex_idx = dsearchn(ensure_col(freq), ensure_col(par.fft.frex));  
c = get_lut_color(roi); 
f = figure('color', 'w', 'pos', [620 918 174 129]); 
pnl = panel(f); 
ax = pnl.select(); 
plot_fft(freq, mX, 'ax', ax, ...
    'maxfreqlim', 4.9, ...
    'frex_meter_rel', par.fft.frex(par.fft.idx_meterRel), ...
    'frex_meter_unrel', par.fft.frex(par.fft.idx_meterUnrel) ...
    ); 
ax.YLim(1) = 0; 
ax.YLim(2) = 1.2 * max(mX(frex_idx)); 
ax.YTick = [0, ax.YLim(2)]; 
ax.YTickLabel = [0, round(ax.YLim(2),2)]; 
ax.YAxis.TickLength = [0,0]; 

fname = sprintf('roi-%s_sub-%s_el-%s_fft.svg', ...
                roi, sub_str, el); 
saveas(f, fullfile(par.figures_path, fname))



% --------
% PLOT ACF 
% --------

fpath = fullfile(par.deriv_path, sprintf('response-%s_ACF', response), sub_str); 
fname = sprintf('sub-%s_rhythm-%s_task-listen_response-%s_avg-time_ACFsubtr.lw6', sub_str, rhythm, response); 
[header, data] = CLW_load(fullfile(fpath, fname)); 
[header, data] = RLW_arrange_channels(header, data, {el}); 
lags = [0 : header.datasize(end)-1] * header.xstep; 
acf = squeeze(data); 

min_lag = 0.1; 
min_lag_idx = dsearchn(lags', min_lag); 
lags = lags(min_lag_idx : end); 
acf = acf(min_lag_idx : end); 
acf = acf - min(acf); 
acf = acf ./ max(acf); 

f = figure('color', 'w', 'pos', [620 918 174 129]); 
pnl = panel(f); 
ax = pnl.select(); 
plot(lags, acf, 'linew', 3, 'color', c)
ax.YAxis.TickLength = [0 0];
ax.TickDir = 'out'; 
ax.YLim = [0, 1];
ax.YTick = []; 
ax.XLim = [min_lag, 1.2];
ax.XTick = [0.8]; 

fname = sprintf('roi-%s_sub-%s_el-%s_acf.svg', ...
                roi, sub_str, el); 
saveas(f, fullfile(par.figures_path, fname))

  


