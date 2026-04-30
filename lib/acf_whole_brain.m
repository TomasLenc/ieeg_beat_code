function acf_whole_brain(subject, response, par, varargin)
% Load data for "subject" and calculate ACF for all electrodes. 
% 
% Parameters
% ----------
% 
% subject: str
%     subject name 
% response: str
%     label of the preproc response type that will be used for input (e.g. 'LFP' or 'HGB')
% varargin: 
%     'avg_method' : kwarg, str (default is 'time')
%       method to average across trials and channels ('time' for time-domain 
%       averaging before FFT, or 'frequency' for frequency-domain averaging 
%       after the FFT) 

subject = sub_num2str(subject); 

fprintf('\nsub-%s ACF...\n',subject); 

% parse arguments
% ---------------
parser = inputParser; 

addParameter(parser, 'avg_method', 'time'); % trial averaging method  

parse(parser, varargin{:})

avg_method = parser.Results.avg_method; 


% load EEG 
fpath = fullfile(par.deriv_path, ...
                 sprintf('response-%s_preproc',response), subject); 

fname = sprintf('sub-%s_response-%s_preproc',subject,response); 

[header, data] = CLW_load(fullfile(fpath,fname)); 

% low-pass filter (for downsampling later) 
[header, data] = RLW_butterworth_filter(header, data, ...
                                        'filter_type', 'lowpass', ...
                                        'high_cutoff', par.acf_low_pass_cutoff, ...
                                        'filter_order', par.acf_low_pass_order); 

for iRhythm=1:length(par.rhythms)

    for iTask=1:length(par.tasks)

        condition_label = [par.rhythms{iRhythm}, '-', par.tasks{iTask}]; 
        
        % check if the condition is present in the data (e.g. we have some 
        % patients who didn't do tapping...
        if ~any(strcmp(condition_label, {header.events.code}))
            warning('no events for: %s\nskipping...', condition_label)
            continue
        end

        % epoch 
        [header_ep, data_ep] = segment_safe(header, data, ...
                                          {condition_label}, ...
                                          'x_start', 0,...
                                          'x_duration', par.trial_duration);
                                      
        % downsample
        deci_R = (1/header_ep.xstep) / par.acf_deci_fs; 
        if deci_R > 1
            [header_ep, data_ep] = RLW_downsample(header_ep, data_ep, ...
                'x_downsample_ratio', deci_R); 
        end        
        
        fs = 1/header_ep.xstep; 
        
        % if time-domain averaging is requested, do it now
        if strcmp(avg_method,'time')
            [header_ep, data_ep] = RLW_average_epochs(header_ep, data_ep);
        end 
                
        % get ap and subtracted acf
        [data_acf_subtr, lags, data_ap, data_mX, freq] = ...
              get_acf(...
                      data_ep, ...
                      fs, ...
                      'rm_ap', true,...
                      'ap_fit_method', par.acf.ap_fit_method, ...
                      'only_use_f0_harmonics', par.acf.only_use_f0_harmonics, ...
                      'keep_band_around_f0_harmonics', par.acf.keep_band_around_harmonics, ...
                      'response_f0', 1/par.cycle_duration, ...
                      'fit_knee', par.acf.fit_knee, ...
                      'ap_fit_flims', [par.acf.min_freq_ap_fit, ...
                                       par.acf.max_freq_ap_fit], ...
                      'verbose', 1, ...
                      'plot_diagnostic', false, ...
                      'bins', par.acf.snr_bins, ...
                      'normalize_acf_to_1', par.acf.normalize_acf ...
                      ); 
                                    
        header_acf = header_ep; 
        header_acf.xstart = lags(1); 
        header_acf.datasize = size(data_acf_subtr); 
        header_acf.filetype = 'lag_amplitude'; 
        header_acf.events = [];       
        
        header_mX = header_ep; 
        header_mX.xstart = freq(1); 
        header_mX.xstep = freq(2) - freq(1); 
        header_mX.datasize = size(data_mX); 
        header_mX.filetype = 'frequency_amplitude'; 
        header_mX.events = [];       
                
        % if frequency-domain averaging is requested, do it now
        if strcmp(avg_method,'frequency')
            
            header_dummy = header_acf; 
            [header_acf, data_acf_subtr] = RLW_average_epochs(header_dummy, data_acf_subtr);
            
            header_dummy = header_mX; 
            [header_mX, data_mX] = RLW_average_epochs(header_dummy, data_mX);
            [~,         data_ap] = RLW_average_epochs(header_dummy, data_ap);
            
        end 
        
        % prepare output directory 
        out_dir = fullfile(par.deriv_path, ...
                            sprintf('response-%s_ACF',response), subject); 

        if ~isfolder(out_dir)
            mkdir(out_dir); 
        end
        
        % save 1/f-subtracted acf as mat file
        out_name = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_ACFsubtr',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method);
                        
        header_acf.name = out_name; 
        CLW_save(out_dir, header_acf, data_acf_subtr); 
        
        % save mX
        out_name = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_mX',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method);
                        
        header_mX.name = out_name; 
        CLW_save(out_dir, header_mX, data_mX);        
        
        % save estimated 1/f component as mat file
        out_name = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_AP',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method);
                        
        header_mX.name = out_name; 
        CLW_save(out_dir, header_mX, data_ap); 
        
        % save analysis parameters
        out_name = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_par.mat',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method);
        save(fullfile(out_dir, out_name), 'par');         
                        
    end % end of task

end % end of rhythm 

end % end of function




