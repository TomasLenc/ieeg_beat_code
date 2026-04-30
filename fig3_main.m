clear

par = get_par(); 

%% parameters

response = 'LFP'; 
rhythm = 'wp'; 

%% prepare list of responsive contacts (for weakly-periodic rhythm) 

% load table with anatomy
load(fullfile(par.feat_path, 'prefix-TDT_elecs_all_anatomy.mat')); 
tbl_anat = struct2table(anat); 

% merge SMA and preSMA 
tbl_anat(strcmpi(tbl_anat.custom, 'preSMA'), 'custom') = {'SMA'}; 

% subset responsive (!!! this is always based on wp rhythm to have the same contacts across analyses)
z_snr_thr = norminv(1 - 0.01); 
tbl_fft = readtable(fullfile(par.feat_path, sprintf('response-%s_avg-time_fftAggrFreq.csv', response))); 
tbl_fft = tbl_fft(strcmpi(tbl_fft.rhythm, 'wp') & strcmpi(tbl_fft.task, 'listen'), :); 
tbl_responsive = tbl_fft(tbl_fft.z_snr > z_snr_thr, :); 

% add anatomy
tbl_responsive = innerjoin(tbl_responsive, tbl_anat, 'Keys', {'subject', 'elec'}); 


%% plot z-SNR 

tbl_example_elecs = []; 

for i_roi=1:length(par.rois)

    roi = par.rois{i_roi}; 
        
    tbl_roi = tbl_responsive(strcmp(tbl_responsive{:, 'custom'}, roi), :); 
    
    subjects = unique(tbl_roi.subject); 

    data_all = []; 

    for i_sub=1:length(subjects)

        sub = subjects(i_sub); 
        sub_str = sub_num2str(sub); 

        fpath = fullfile(par.deriv_path, sprintf('response-%s_FFT', response), sub_str); 
        fname = sprintf('sub-%s_rhythm-%s_task-listen_response-%s_avg-time_snr-0-0_FFT.lw6', ...
                         sub_str, rhythm, response); 
        [header, data] = CLW_load(fullfile(fpath, fname)); 

        % cut to maxfreqlim 
        maxfreqidx = round(100 / header.xstep) + 1; 
        header.datasize(end) = maxfreqidx; 
        data = data(:,:,:,:,:,1:maxfreqidx); 

        elecs = tbl_roi{tbl_roi.subject == sub, 'elec'}; 

        [header, data] = RLW_arrange_channels(header, data, elecs); 

        data_all{end+1} = data; 

    end

    mX = squeeze(cat(2, data_all{:})); 
    
    assert(size(mX,1) == size(tbl_roi,1))

    freq = [0 : size(mX,2)-1] * header.xstep; 

    [z_snr, mean_snip, idx_snip, mu, sd] = get_z_snr(mX, freq, par.fft.frex, ...
                    par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2)); 
                
    f = figure('color', 'w', 'pos', [620 918 174 129]); 
    pnl = panel(f); 
    ax = pnl.select(); 

    c = get_lut_color(roi); 
    
    snip_to_plot = mean((mean_snip - mu) ./ sd, 1); 

    plot(idx_snip, snip_to_plot, 'linew', 3, 'color', c)
    ax.TickLength = [0 0];
    ax.XTick = [-par.fft.snr_bins_eeg(2), 0, par.fft.snr_bins_eeg(2)]; 
    ax.XLim = [-par.fft.snr_bins_eeg(2), par.fft.snr_bins_eeg(2)]; 
    ax.YLim = [-2, 33]; 
    
    pnl.title(roi);     
    saveas(f, fullfile(par.figures_path, ...
        sprintf('response-%s_atlas-%s_roi-%s_rhythm-%s_zsnr.svg', ...
               response, 'custom', roi, rhythm))); 
    
    close(f); 

end


%% plot ACF 

for i_roi=1:length(par.rois)

    roi = par.rois{i_roi}; 
        
    tbl_roi = tbl_responsive(strcmp(tbl_responsive{:,'custom'}, roi), :); 
    
    subjects = unique(tbl_roi.subject); 

    data_all = []; 

    for i_sub=1:length(subjects)

        sub = subjects(i_sub); 
        sub_str = sub_num2str(sub); 

%         fpath = fullfile(par.deriv_path, sprintf('response-%s_ACFcycle', response), sub); 
%         fname = sprintf('sub-%s_rhythm-syncopated_task-listen_response-%s_ACFcycle.lw6', sub, response); 
        fpath = fullfile(par.deriv_path, sprintf('response-%s_ACF', response), sub_str); 
        fname = sprintf('sub-%s_rhythm-%s_task-listen_response-%s_avg-time_ACFsubtr.lw6',...
                        sub_str, rhythm, response); 
        
        [header, data] = CLW_load(fullfile(fpath, fname)); 

        elecs = tbl_roi{tbl_roi.subject == sub, 'elec'}; 
        [header, data] = RLW_arrange_channels(header, data, elecs); 

        data_all{end+1} = data; 

    end

    acf = squeeze(cat(2, data_all{:})); 
    
    assert(size(acf,1) == size(tbl_roi,1))
    
    c = get_lut_color(roi); 
    
    lags = [0 : size(acf,2)-1] * header.xstep;                     

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
        
    saveas(f, fullfile(par.figures_path, ...
        sprintf('response-%s_atlas-%s_roi-%s_rhythm-%s_acf.svg', ...
                response, 'custom', roi, rhythm))); 
    
    close(f); 

end


%% plot ERP 

% load stim 
fpath = fullfile(par.deriv_path, 'response-s_ERPcycle')
fname = sprintf('rhythm-%s_response-s_cycleERP.lw6', rhythm); 
[header, data] = CLW_load(fullfile(fpath, fname)); 
t_s = [0 : header.datasize(end)-1] * header.xstep;  
erp_s = squeeze(data)'; 


for i_roi=1:length(par.rois)

    roi = par.rois{i_roi}; 
        
    tbl_roi = tbl_responsive(strcmp(tbl_responsive{:, 'custom'}, roi), :); 
    
    subjects = unique(tbl_roi.subject); 

    data_all = []; 

    for i_sub=1:length(subjects)

        sub = subjects(i_sub); 
        sub_str = sub_num2str(sub); 
        
        fpath = fullfile(par.deriv_path, sprintf('response-%s_ERPcycle', response), sub_str); 
        fname = sprintf('sub-%s_rhythm-%s_task-listen_response-%s_cycleERP.lw6', ...
                        sub_str, rhythm, response); 
        
        [header, data] = CLW_load(fullfile(fpath, fname)); 

        elecs = tbl_roi{tbl_roi.subject == sub, 'elec'}; 
        [header, data] = RLW_arrange_channels(header, data, elecs); 

        data_all{end+1} = data; 

    end

    erp = squeeze(cat(2, data_all{:})); 
    assert(size(erp,1) == size(tbl_roi,1))
    
    % PCA to summarize the data 
    n_time = size(erp, 2); 
    n_chan = size(erp, 1); 

    data_pca = permute(erp, [2,1]); 
    data_pca = data_pca - mean(data_pca, 1); 

    C = data_pca' * data_pca; 
    [V, S, V] = svd(C); 

    eigs = diag(S); 
    var_explained = eigs / sum(eigs) * 100;  
    var_explained
    % figure
    % plot(var_explained, '-o'); 

    data_proj = data_pca * V(:,1); 
    
    % make max positive 
    if abs(min(data_proj)) > max(data_proj)
        data_proj = -data_proj; 
    end
    
    % normalize to 1 across par.rois
    data_proj = data_proj ./ 270; 
    
    % plot     
    c = get_lut_color(roi); 
    t = [0 : header.datasize(end)-1] * header.xstep;                     
    
    f = figure('color', 'w', 'pos', [620 918 174 129]); 
    pnl = panel(f); 
    ax = pnl.select(); 
    hold on 
    
    erp_s_to_plot = erp_s; 
    erp_s_to_plot = erp_s_to_plot / max(abs(erp_s_to_plot)); 
    erp_s_to_plot = erp_s_to_plot * max(abs(data_proj)); 
    
    h = plot(t_s, erp_s_to_plot, 'linew', 0.5, 'color', [.5 .5 .5]); 
    h.Color(4) = 0.2; 
    
    plot(t, data_proj, 'linew', 3, 'color', c)
    ax.YAxis.TickLength = [0 0];
    ax.TickDir = 'out'; 
    ax.XLim = [0, 2.4]; 
    ax.XAxis.Visible = 'off'; 
    ax.YLim = [-max(abs(data_proj)), max(abs(data_proj))];
        
    saveas(f, fullfile(par.figures_path, ...
        sprintf('response-%s_atlas-%s_roi-%s_rhythm-%s_erpCycle.svg', ...
                response, 'custom', roi, rhythm))); 
    
    close(f); 

end



%% plot FFT 

for i_roi=1:length(par.rois)

    roi = par.rois{i_roi}; 
        
    tbl_roi = tbl_responsive(strcmp(tbl_responsive{:, 'custom'}, roi), :); 
    
    subjects = unique(tbl_roi.subject); 

    data_all = []; 

    for i_sub=1:length(subjects)

        sub = subjects(i_sub);  
        sub_str = sub_num2str(sub); 

        fpath = fullfile(par.deriv_path, sprintf('response-%s_FFT', response), sub_str); 
        fname = sprintf('sub-%s_rhythm-%s_task-listen_response-%s_avg-time_snr-%d-%d_FFT.lw6',...
                        sub_str, rhythm, response, par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2)); 
        [header, data] = CLW_load(fullfile(fpath, fname)); 

        % cut to maxfreqlim 
        maxfreqidx = round(100 / header.xstep) + 1; 
        header.datasize(end) = maxfreqidx; 
        data = data(:,:,:,:,:,1:maxfreqidx); 

        elecs = tbl_roi{tbl_roi.subject == sub, 'elec'}; 

        [header, data] = RLW_arrange_channels(header, data, elecs); 

        data_all{end+1} = data; 

    end

    mX = squeeze(cat(2, data_all{:})); 
    
    assert(size(mX,1) == size(tbl_roi,1))

    freq = [0 : size(mX,2)-1] * header.xstep; 
    
    
    c = get_lut_color(roi); 
    
    mX_grand = mean(mX, 1); 
    mX_grand(1) = 0; 

    f = figure('color', 'w', 'pos', [620 918 174 129]); 
    pnl = panel(f); 
    ax = pnl.select(); 
    
    plot_fft(freq, mX_grand, 'ax', ax, ...
        'maxfreqlim', 4.9, ...
        'frex_meter_rel', par.fft.frex(par.fft.idx_meterRel), ...
        'frex_meter_unrel', par.fft.frex(par.fft.idx_meterUnrel) ...
        ); 
    
    ax.YLim(1) = 0; 
%     ax.YLim = [0, 6.7]; 
%     ax.YTick = [0, 1.8]; 
    ax.YTick = floor(ax.YTick*100)/100; 

    ax.YAxis.TickLength = [0,0]; 

     pnl.title(roi)
     
    saveas(f, fullfile(par.figures_path, ...
        sprintf('response-%s_atlas-%s_roi-%s_rhythm-%s_mX.svg', ...
            response, 'custom', roi, rhythm))); 
    
%     close(f); 

end

