
%% plot ROI meshes

subject = 'cvs_avg35_inMNI152'; 

subjects_dir = par.subjects_dir; 

hem = 'lh'; 
surf_mesh_label = 'pial'; 
surf_alpha = 1; 

roi_labels = {'SMC', 'IFG', 'MFG', 'SMG'}; 
roi_labels_fs = {'sensorymotor', 'inferiorfrontal', 'middlefrontal', 'supramarginal'}; 

for i_roi=1:length(roi_labels)
    
    mesh_dir = fullfile(subjects_dir, subject, 'Meshes'); 

    roi_label = roi_labels_fs{i_roi}; 
    
    % load background surface mesh 
    fname = sprintf('%s_%s_trivert.mat', hem, surf_mesh_label); 
    background_mesh = load(fullfile(mesh_dir, fname)); 
    background_mesh.tri = background_mesh.tri+1; % fix python indexing

    % load roi mesh 
    fname = sprintf('%s_%s_trivert.mat', hem, roi_label); 
    roi_mesh = load(fullfile(mesh_dir, fname)); 
    roi_mesh.tri = roi_mesh.tri+1; % fix python indexing

    f = figure('color', 'white'); 

    % plot background surface 
    c_h = ctmr_gauss_plot(background_mesh, [0 0 0], 0, hem);
    c_h.FaceAlpha = surf_alpha; 
    
    hold on 

    % plot ROI mesh if passed
    c_h = ctmr_gauss_plot(roi_mesh, [0 0 0], 0, hem, 0, ...
        'mesh_col', get_lut_color(roi_labels{i_roi}));

    fname = sprintf('roi-%s_mesh.png', roi_label); 
    saveas(f, fullfile(par.figures_path, fname)); 

end

% ---
% PMC
% ---
f = figure('color', 'white'); 

% plot background surface 
c_h = ctmr_gauss_plot(background_mesh, [0 0 0], 0, hem);
c_h.FaceAlpha = surf_alpha; 
hold on 

% set view medial
if strcmp(hem,'lh')
    loc_view(-270,0);
elseif strcmp(hem,'rh')
    loc_view(270,0);
end

fname = sprintf('roi-PMC_mesh.png', roi_label); 
saveas(f, fullfile(par.figures_path, fname)); 
