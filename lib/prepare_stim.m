function prepare_stim(data_type)

par = get_par(); 

for iRhythm=1:length(par.rhythms)
    
    % load and prepare data 
    if strcmpi(data_type, 'ic')
        bmfs = [2, 4, 8, 16, 32, 64]; 
        IC = {}; 
        for i_bmf=1:length(bmfs)
            fname = sprintf('model-urear_stage-ic_rhythm-%s_bmf-%d.mat', par.rhythms{iRhythm}, bmfs(i_bmf)); 
            tmp = load(fullfile(par.urear_path, fname)); 
            data = tmp.data; 
            IC{i_bmf} = data.BE_sout;             
        end
    else
        fname = sprintf('model-urear_stage-an_rhythm-%s.mat', par.rhythms{iRhythm}); 
        tmp = load(fullfile(par.urear_path, fname)); 
        data = tmp.data; 
    end

    if strcmp(data_type, 'an')
        x = sum(data.an_sout,1); 
        fs = data.fs; 
    elseif strcmp(data_type, 'ic')
        x = cat(1, IC{:}); 
        x = ensure_row(squeeze(sum(sum(x, 1), 2)));
        fs = data.fs;         
    elseif strcmp(data_type, 'hilbert')
        x = abs(hilbert(data.stim'));
        fs = data.fs_stim;
        decim_ratio = 1000; 
        x = decimate(x, decim_ratio); 
        fs = fs / decim_ratio; 
    elseif strcmp(data_type, 'flux')
        x = ensure_col(data.stim); 
        decim_ratio = 100; 
        fs = data.fs_stim / decim_ratio; 
        N = round(par.trial_duration * fs); 
        x = get_spectral_flux(x, data.fs_stim, 'fs_target', fs, 'N_target', N); 
        % figure
        % plot([0:length(data.stim)-1] / data.fs_stim, data.stim ./ max(abs(data.stim)), 'color', [0.9, 0.9, 0.9])
        % hold on 
        % plot([0:length(x)-1]/fs, x ./ max(abs(x)), 'linew', 2)      
    elseif strcmp(data_type, 's')
        x = data.stim'; 
        fs = data.fs_stim;
        decim_ratio = 50; 
        x = decimate(x, decim_ratio); 
        fs = fs / decim_ratio; 
    else
        error('data type "%s" invalid', data_type)
    end
    
    % normalize to 1
    x = x ./ max(abs(x)); 
    
%     % remove first cycle for initialization
%     cycle_N = round(par.cycle_duration * fs); 
%     x = x(cycle_N+1 : end); 
    
    %% ERP 

    % chunk cycles
    x_chunked = epoch_chunks(x, fs, par.cycle_duration); 

    % average (skip first cycle)
    erp = mean(x_chunked(2:end,:), 1); 
    t = [0 : length(erp)-1] / fs; 
    
    % create lw6 format and save to file 
    header_erp = []; 
    header_erp.filetype = 'time_amplitude'; 
    header_erp.name = sprintf('rhythm-%s_response-%s_cycleERP', ...
                              par.rhythms{iRhythm}, data_type); 
    header_erp.tags = ''; 
    header_erp.history = []; 
    header_erp.datasize = [1, 1, 1, 1, 1, length(erp)]; 
    header_erp.xstart = 0; 
    header_erp.xstep = 1/fs; 
    header_erp.ystart = 0; 
    header_erp.ystep = 1; 
    header_erp.zstart = 0; 
    header_erp.zstep = 1; 
    header_erp.chanlocs = struct('labels', data_type, ...
                                 'topo_enabled', 0, ...
                                 'SEEG_enabled', 0); 
    header_erp.events = []; 
    
    data_erp = []; 
    data_erp(1, 1, 1, 1, 1, :) = erp; 
    
    % save
    out_dir = fullfile(par.deriv_path, ...
                    sprintf('response-%s_ERPcycle', data_type)); 

    if ~isdir(out_dir)
        mkdir(out_dir)
    end
    CLW_save(out_dir, header_erp, data_erp); 
    
    
    % if this is the raw sound waveform, don't do FFT or ACF...
    if strcmp(data_type, 's')
       continue 
    end
    
    
    %% FFT 
    
    [X, freq] = get_X(x, fs, 'dc_zero', true); 
    
    mX = abs(X); 
    
    mX = subtract_noise_bins(mX, par.fft.snr_bins_coch(1), par.fft.snr_bins_coch(2)); 
        
    % create lw6 format and save to file 
    header_fft = []; 
    header_fft.filetype = 'frequency_amplitude'; 
    header_fft.name = sprintf('rhythm-%s_response-%s_snr-%d-%d_FFT', ...
                              par.rhythms{iRhythm}, ...
                              data_type, ...
                              par.fft.snr_bins_coch(1), par.fft.snr_bins_coch(2) ...
                              ); 
    header_fft.tags = ''; 
    header_fft.history = []; 
    header_fft.datasize = [1, 1, 1, 1, 1, length(mX)]; 
    header_fft.xstart = 0; 
    header_fft.xstep = freq(2) - freq(1); 
    header_fft.ystart = 0; 
    header_fft.ystep = 1; 
    header_fft.zstart = 0; 
    header_fft.zstep = 1; 
    header_fft.chanlocs = struct('labels', data_type, ...
                                 'topo_enabled', 0, ...
                                 'SEEG_enabled', 0); 
    header_fft.events = []; 
    
    data_fft = []; 
    data_fft(1, 1, 1, 1, 1, :) = mX; 
    
    out_dir = fullfile(par.deriv_path, ...
                    sprintf('response-%s_FFT', data_type)); 

    if ~isdir(out_dir)
        mkdir(out_dir)
    end
    CLW_save(out_dir, header_fft, data_fft); 

    %% ACF 
    
    % get raw acf
    [acf_raw, lags, ~, ~, ~, ~] = get_acf(x, fs, ...
                                          'plot_diagnostic', false);

    header_acf = header_erp; 
    header_acf.xstart = lags(1); 
    header_acf.datasize(end) = length(acf_raw); 
    header_acf.filetype = 'lag_amplitude'; 
    
    data_acf = [];
    data_acf(1, 1, 1, 1, 1, :) = acf_raw; 

    % create lw6 format and save to file 
    header_acf.name = sprintf('rhythm-%s_response-%s_ACFraw',...
                        par.rhythms{iRhythm}, data_type);
                    
    out_dir = fullfile(par.deriv_path, ...
                    sprintf('response-%s_ACF', data_type)); 

    if ~isdir(out_dir)
        mkdir(out_dir)
    end

    CLW_save(out_dir, header_acf, data_acf); 

end

