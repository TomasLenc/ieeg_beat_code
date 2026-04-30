function fft_whole_brain(subject, response, par, varargin)
% Load data for "subject" and calculate FFT for all electrodes. 
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

fprintf('\nsub-%s FFT...\n',subject); 

% parse kwargs
% ------------
% trial averaging method  
avg_method = 'time'; 
if any(strcmpi(varargin,'avg_method'))
    avg_method = varargin{find(strcmpi(varargin,'avg_method'))+1}; 
end

% load EEG 
fpath = fullfile(par.deriv_path, ...
                sprintf('response-%s_preproc',response), subject); 

fname = sprintf('sub-%s_response-%s_preproc',subject,response); 

[header, data] = CLW_load(fullfile(fpath,fname)); 
    
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
                                              
        % if time-domain averaging is requested, do it before the FFT 
        if strcmp(avg_method,'time')
            [header_ep, data_ep] = RLW_average_epochs(header_ep, data_ep);
        end 
        
        % ----------------
        % FFT (no SNR)    
        
        [header_fft, data_fft] = RLW_FFT(header_ep, data_ep);

        % if frequency-domain averaging is requested, do it after the FFT 
        if strcmp(avg_method,'frequency')
            [header_fft, data_fft] = RLW_average_epochs(header_fft, data_fft);
        end 
        
        % prepare output directory 
        out_dir = fullfile(par.deriv_path, ...
                            sprintf('response-%s_FFT',response), subject); 

        if ~isfolder(out_dir)
            mkdir(out_dir); 
        end

        % save mat file (no SNR)
        out_name = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_snr-0-0_FFT',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method);
                        
        header_fft.name = out_name; 
        CLW_save(out_dir, header_fft, data_fft); 
        
        % ----------------
        % FFT (with SNR)
        
        [header_fft, data_fft] = RLW_FFT(header_ep, data_ep);       
        
        [header_fft, data_fft] = RLW_SNR(header_fft, data_fft,...
                                         'xstart', par.fft.snr_bins_eeg(1), ...
                                         'xend', par.fft.snr_bins_eeg(2));

        % if frequency-domain averaging is requested, do it after the FFT 
        if strcmp(avg_method,'frequency')
            [header_fft, data_fft] = RLW_average_epochs(header_fft, data_fft);
        end 
        
        % prepare output directory
        out_dir = fullfile(par.deriv_path, ...
                            sprintf('response-%s_FFT',response), subject); 

        if ~isfolder(out_dir)
            mkdir(out_dir); 
        end
        
        % save mat file
        out_name = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_avg-%s_snr-%d-%d_FFT',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response, avg_method, ...
                            par.fft.snr_bins_eeg(1), par.fft.snr_bins_eeg(2));
                        
        header_fft.name = out_name; 
        CLW_save(out_dir, header_fft, data_fft); 
        
                        
    end % end of task

end % end of rhythm 

end % end of function




