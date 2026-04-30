"""
This script merges ALL electrodes that are part of the requested ROI across ALL
patients and plots over template brain.
"""

import os
import os.path as op

import matplotlib.pyplot as plt
import numpy as np
import img_pipe
import pandas as pd

from utils import shaft_mask_from_contacts

# ===================================== parameters =====================================

feat_path = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/derivatives/features"

save_path = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/derivatives/figures/anatomy"

subjects_dir = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/derivatives/subjects_dir"

rois_auditory = ["HG", "PT", "pSTG", "PP", "mSTG"]

subjects = np.arange(13) + 1

# ====================================================================================

# load anatomy
tbl_anat = pd.read_csv(
    op.join(
        feat_path,
        f"prefix-TDT_elecs_all_anatomy.csv",
    )
)

# load PAC
tbl_pac = pd.read_csv(
    op.join(
        feat_path,
        'selections',
        f"response-LFP_rhythm-wp_task-listen_atlas-functionalPAC_fft.csv",
    )
)
tbl_pac = tbl_pac[(tbl_pac["rhythm"] == 'wp') & (tbl_pac["task"] == 'listen')]

for subj in subjects:
    for hem in ['lh', 'rh']:

        patient = img_pipe.freeCoG(subj=f"{subj:02d}", hem="lh", subj_dir=subjects_dir)

        # get only this subject
        tbl_sub = tbl_anat[tbl_anat['subject'] == subj]

        # get elecs only in auditory ROIs
        tbl_auditory = tbl_sub[tbl_sub['custom'].isin(rois_auditory)]

        # get PAC elec labels
        mask_is_pac = tbl_sub.set_index(["subject", "elec"]).index.isin(
                tbl_pac.set_index(["subject", "elec"]).index
        )
        pac_elecs = tbl_sub.loc[mask_is_pac, 'elec'].to_numpy()

        # get all contacts that are on the relevant electrode shafts
        tbl = shaft_mask_from_contacts(tbl_sub, "elec", tbl_auditory["elec"].to_list())

        # get electrode xyz coords
        elecs = elecmatrix = tbl[
            ["xyz_native_1", "xyz_native_2", "xyz_native_3"]
        ].to_numpy()

        # elec labels
        eleclabels = tbl['elec'].to_list()

        # ROI labels
        anatomy = tbl["custom"].to_list()

        for i_el,lab in enumerate(eleclabels):
            if lab in pac_elecs:
                anatomy[i_el] = np.str_("PAC")

        surf = "STP"
        mesh_kwargs = dict(
            opacity=0.5, color=(0.8, 0.8, 0.8), representation="surface", gaussian=False
        )

        plotter = patient.plot_brain(
            rois=[patient.roi(f"{hem}_{surf}", **mesh_kwargs)],
            elecs=elecmatrix,
            elecs_anatomy=anatomy,
            atlas="chang",
            showfig=False,
            show_ac=False,
        )

        img_pipe.plotting.ctmr_brain_plot.set_camera_position(
            plotter, hem=hem, view_type='stp'
        )

        # take a screenshot
        arr = img_pipe.plotting.ctmr_brain_plot.screenshot(plotter, scale=5)

        # trim white space
        arr = img_pipe.plotting.ctmr_brain_plot.trim_white_space(arr)

        # save as image
        f,ax = plt.subplots()
        ax.imshow(arr)
        ax.axis('off')

        fname_fig = op.join(
            save_path, f"sub-{subj:02d}_hem-{hem}_surf-stp_anatomy.png"
        )
        os.makedirs(save_path, exist_ok=True)
        f.savefig(fname_fig, dpi=700.)
