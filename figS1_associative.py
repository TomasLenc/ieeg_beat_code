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

feat_path = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/raw/derivatives/features"

save_path = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/raw/derivatives/figures/anatomy"

subjects_dir = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/raw/derivatives/subjects_dir"

rois_assoc = ['SMG', 'SMC', 'IFG', 'MFG', 'SFG', 'preSMA', 'SMA']

subjects = np.arange(13) + 1

surf = "pial"

# ====================================================================================

os.makedirs(save_path, exist_ok=True)

# load anatomy
tbl_anat = pd.read_csv(
    op.join(
        feat_path,
        f"prefix-TDT_elecs_all_anatomy.csv",
    )
)

for subj in subjects:

    patient = img_pipe.freeCoG(
        subj=f"{subj:02d}",
        hem="lh",
        subj_dir=subjects_dir,
    )

    tbl_sub = tbl_anat[(tbl_anat["subject"] == subj)]

    if tbl_sub.shape[0] == 0:
        continue

    # find elecs that are in the ROIs
    mask = np.array([lab in rois_assoc for lab in tbl_sub["custom"]])

    # get shaft name for each electrode
    import re
    shafts = [
        re.match(r"^[^\d]*", lab).group(0) for lab in tbl_sub["elec"].to_list()
    ]
    shafts = np.array(shafts)
    tbl_sub['shaft'] = shafts
    shafts_to_use = np.unique(shafts[mask])

    mask = [shaft in shafts_to_use for shaft in tbl_sub["shaft"].to_list()]
    tbl_sub = tbl_sub[mask]

    for hem in ["lh", "rh"]:

        tbl_plot = tbl_sub[(tbl_sub["hem"] == hem)]

        elecmatrix = tbl_plot[
            ["xyz_native_1", "xyz_native_2", "xyz_native_3"]
        ].to_numpy()

        eleclabels = tbl_plot["elec"].to_numpy()

        anatomy = tbl_plot["custom"].to_numpy()

        mesh_kwargs = dict(
            opacity=0.5, color=(0.8, 0.8, 0.8), representation="surface", gaussian=False
        )

        plotter = patient.plot_brain(
            rois=[patient.roi(f"{hem}_{surf}", **mesh_kwargs)],
            elecs=elecmatrix,
            elecs_anatomy=anatomy,
            atlas="custom",
            showfig=False,
            show_ac=False,
        )

        # ----- lateral view -------

        img_pipe.plotting.ctmr_brain_plot.set_camera_position(
            plotter, hem=hem, view_type="lateral"
        )

        # take a screenshot
        arr = img_pipe.plotting.ctmr_brain_plot.screenshot(plotter, scale=5)

        # trim white space
        arr = img_pipe.plotting.ctmr_brain_plot.trim_white_space(arr)

        # save as image
        f, ax = plt.subplots()
        ax.imshow(arr)
        ax.axis("off")

        fname_fig = op.join(
            save_path, f"sub-{subj:02d}_hem-{hem}_surf-pial_view-lateral_anatomy.png"
        )
        f.savefig(fname_fig, dpi=700.0)

        # ----- medial view -------

        img_pipe.plotting.ctmr_brain_plot.set_camera_position(
            plotter, hem=hem, view_type="medial"
        )

        # take a screenshot
        arr = img_pipe.plotting.ctmr_brain_plot.screenshot(plotter, scale=5)

        # trim white space
        arr = img_pipe.plotting.ctmr_brain_plot.trim_white_space(arr)

        # save as image
        f, ax = plt.subplots()
        ax.imshow(arr)
        ax.axis("off")

        fname_fig = op.join(
            save_path, f"sub-{subj:02d}_hem-{hem}_surf-pial_view-medial_anatomy.png"
        )
        f.savefig(fname_fig, dpi=700.0)

    # ----- both hems, top view -------

    elecmatrix = tbl_sub[
        ["xyz_native_1", "xyz_native_2", "xyz_native_3"]
    ].to_numpy()

    eleclabels = tbl_sub["elec"].to_numpy()

    anatomy = tbl_sub["custom"].to_numpy()

    mesh_kwargs = dict(
        opacity=0.5, color=(0.8, 0.8, 0.8), representation="surface", gaussian=False
    )

    plotter = patient.plot_brain(
        rois=[
            patient.roi(f"lh_{surf}", **mesh_kwargs),
            patient.roi(f"rh_{surf}", **mesh_kwargs),
        ],
        elecs=elecmatrix,
        elecs_anatomy=anatomy,
        atlas="custom",
        showfig=False,
        show_ac=False,
    )

    plotter.camera_position = 'xy'

    # take a screenshot
    arr = img_pipe.plotting.ctmr_brain_plot.screenshot(plotter, scale=5)

    # trim white space
    arr = img_pipe.plotting.ctmr_brain_plot.trim_white_space(arr)

    # save as image
    f, ax = plt.subplots()
    ax.imshow(arr)
    ax.axis("off")

    fname_fig = op.join(
        save_path,
        f"sub-{subj:02d}_hem-stereo_surf-pial_view-top_anatomy.png",
    )
    f.savefig(fname_fig, dpi=700.0)
