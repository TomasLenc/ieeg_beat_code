function prepare_anat_bipolar(par)
% Load the 'TDT_elecs_all.mat' file, which contains original electrode
% coordinates, and also ROI labels. 
% 
% For each bipolar channel, we prepare: 
%     (1) new 3D coordinates, exactly at the midpoint between the two original
%     elecs
%     (2) ROI label based on the different atlases
% 
% The result is saved into a new file 'bipolar_elecs_all.mat'

% list of anatomical labels outside of gray matter
anat_unknown = {'unknown', 'Inf-Lat-Vent', 'White-Matter', 'WM-hypointensities'}; 
   
%% load anatomical data

load(fullfile(par.feat_path, 'prefix-TDT_elecs_all_anatomy.mat'))

atlases = {'desikan_killiany', 'destrieux', 'custom'}; 

subjects = unique([anat.subject]); 

anat_bi = []; 

for i_sub=1:length(subjects)
    
    subject = subjects(i_sub); 
    
    anat_sub = anat([anat.subject] == subject); 

    % get bipolar channel labels 
    bi_eleclabels = get_bipolar_from_eleclabels({anat_sub.elec}); 

    new_rows = [repmat({subject}, length(bi_eleclabels), 1), bi_eleclabels']; 
    anat_bi = [anat_bi; new_rows]; 
end

anat_bi = cell2struct(anat_bi', {'subject', 'elec'}); 


% go over all atlases and for each generate the corresponding bipolar file
for i_atlas=1:length(atlases)
        
    % save mapping table for visual debugging 
    bi_mapping_debug = []; 
    
    for i_el=1:length(anat_bi)

        % which subject is this 
        subject = anat_bi(i_el).subject; 
        
        % which were the two original electrodes for this channel 
        bi_el_labels = strsplit(anat_bi(i_el).elec, '-'); 
        shaft_name = regexp(bi_el_labels{1}, '^\D+', 'match'); 
        shaft_name = shaft_name{1}; 

        % and where they are in our original anatomy table 
        idx_el1 = find(subject == [anat.subject] & strcmp(bi_el_labels{1}, {anat.elec})); 
        idx_el2 = find(subject == [anat.subject] & strcmp(bi_el_labels{2}, {anat.elec})); 

        assert(length(idx_el1) == 1)
        assert(length(idx_el2) == 1)
        
        % use the midpoint between electrodes as the xyz coordinate for the new
        % bipolar channel
        anat_bi(i_el).xyz_native = anat(idx_el1).xyz_native - ...
                    0.5 * (anat(idx_el1).xyz_native - anat(idx_el2).xyz_native); 

        anat_bi(i_el).xyz_warped = anat(idx_el1).xyz_warped - ...
                    0.5 * (anat(idx_el1).xyz_warped - anat(idx_el2).xyz_warped); 

        anat_bi(i_el).xyz_tal = anat(idx_el1).xyz_tal - ...
                    0.5 * (anat(idx_el1).xyz_tal - anat(idx_el2).xyz_tal); 
                
        % get the atlas label for each electrode in the pair 
        anat_el1 = anat(idx_el1).(atlases{i_atlas});  
        anat_el2 = anat(idx_el2).(atlases{i_atlas});  
        
        % determine if the contact is not in gray matter      
        unknown_el1 = contains(anat_el1, anat_unknown, 'IgnoreCase', true); 
        unknown_el2 = contains(anat_el2, anat_unknown, 'IgnoreCase', true); 
        
        % hemisphere should be always the same 
        anat_bi(i_el).hem = anat(idx_el1).hem; 
        
        % if we have both electrodes with the same anatomical label, use it for
        % the bipolar channel too
        if strcmp(anat_el1, anat_el2)

            anat_bi(i_el).(atlases{i_atlas}) = anat_el1; 

        % if we have one electrode with a anatomical label, but the other
        % one is in the white matter or unknown, we'll use the anat label
        % (!!! this is a very liberal way to do this - same as Corentin;
        % unlike Liegeois-Chauvel !!!)
        elseif ~unknown_el1 && unknown_el2

            anat_bi(i_el).(atlases{i_atlas}) = anat_el1; 

        elseif unknown_el1 && ~unknown_el2

            anat_bi(i_el).(atlases{i_atlas}) = anat_el2; 

        % if we have non-matching anatomical labels, we will use the label
        % of the active channel 
        elseif ~strcmp(anat_el1, anat_el2) && ~unknown_el1 && ~unknown_el2
            
            anat_bi(i_el).(atlases{i_atlas}) = anat_el1; 
            
        % otherwise, we mark the bipolar channel as unknown (e.g. this will
        % match if we have white matter and unkonwn)
        else
            
            anat_bi(i_el).(atlases{i_atlas}) = 'unknown'; 
            
        end 

        bi_mapping_debug(i_el).el1 = anat_el1; 
        bi_mapping_debug(i_el).el2 = anat_el2; 
        bi_mapping_debug(i_el).new = anat_bi(i_el).(atlases{i_atlas}); 
        
    end
    
end

%% gray matter

in_gray = zeros(length(anat_bi), 1, 'logical'); 

% then check manual labeling - let it override D&K
mask = strcmpi({anat_bi.custom}, 'unknown'); 
in_gray(~mask) = true; 

in_gray = num2cell(in_gray); 

[anat_bi.in_gray] = deal(in_gray{:}); 


%% save

new_order = [
    {'subject'         }
    {'elec'            }
    {'hem'             }
    {'in_gray'         }
    {'desikan_killiany'}
    {'destrieux'       }
    {'custom'          }
    {'xyz_native'      }
    {'xyz_warped'      }
    {'xyz_tal'         }
    ]; 

anat = orderfields(anat_bi, new_order);
 
% tmp = anat_bi([anat_bi.subject] == 12); 
% struct2table(tmp)

save(fullfile(par.feat_path, 'prefix-bipolar_elecs_all_anatomy.mat'), 'anat'); 

tbl = struct2table(anat); 
writetable(tbl, fullfile(par.feat_path, 'prefix-bipolar_elecs_all_anatomy.csv')); 





