function erp_whole_brain(subject, response, par)
% Load data for "subject" and calculate cycle-erp for all electrodes. 
% 
% Parameters
% ----------
% 
% subject: str
%     subject name 
% response: str
%     label of the preproc response type that will be used for input (e.g. 'LFP' or 'HGB')

subject = sub_num2str(subject); 

fprintf('\nsub-%s ERP...\n',subject); 

% load EEG 
fpath = fullfile(par.deriv_path, ...
                sprintf('response-%s_preproc',response), subject); 

fname = sprintf('sub-%s_response-%s_preproc',subject,response); 

[header, data] = CLW_load(fullfile(fpath,fname)); 

% low-pass filter 
[header, data] = RLW_butterworth_filter(header, data, ...
                                        'filter_type', 'lowpass', ...
                                        'high_cutoff', par.erp_low_pass_cutoff, ...
                                        'filter_order', 4); 

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
        deci_R = (1/header_ep.xstep) / par.erp_deci_fs; 
        if deci_R > 1
            [header_ep, data_ep] = RLW_downsample(header_ep, data_ep, ...
                                                  'x_downsample_ratio', deci_R); 
        end

        % cut cycles
        [header_erp, data_erp] = RLW_segmentation_chunk(header_ep, data_ep, ...
                                                        'chunk_onset', 0, ...
                                                        'chunk_duration', par.cycle_duration,...
                                                        'chunk_interval', par.cycle_duration); 

        % average     
        [header_erp, data_erp] = RLW_average_epochs(header_erp, data_erp); 
        
        % save the ERP data 
        out_dir = fullfile(par.deriv_path, ...
                            sprintf('response-%s_ERPcycle',response), subject); 

        if ~isfolder(out_dir)
            mkdir(out_dir); 
        end

        out_name = sprintf('sub-%s_rhythm-%s_task-%s_response-%s_cycleERP.mat',...
                            subject, par.rhythms{iRhythm}, par.tasks{iTask}, ...
                            response);

        header_erp.name = out_name; 
        CLW_save(out_dir, header_erp, data_erp); 
                        
    end % end of task

end % end of rhythm 

end % end of function




