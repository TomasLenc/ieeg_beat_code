import numpy as np
import scipy
import matplotlib.pyplot as plt 
from mne.transforms import apply_trans
import nibabel as nib
import os.path as op 
import os
import sys
import subprocess
from scipy.io import loadmat

import img_pipe

from img_pipe.plotting.ctmr_brain_plot import _weight_to_color, plot_cbar_mpl
from img_pipe.plotting.mlab_3D_to_2D import _project_3d_to_2d


def get_2d_coords(
    tbl,
    patient,
    mesh_name,
    mesh_opacity=0.8,
    camera_pos=[
        (-74.68034645854485, 119.1907740286485, 67.70814361165047),
        (-45.519513126241506, 10.298037127629854, -19.540167843575123),
        (0.7069051760796773, -0.31722054979099734, 0.6321836717458447),
    ],
):
    # This function returns a 2D coordinates of eletrodes projected onto a given camera
    # position
    elecmatrix = tbl[["xyz_warped_1", "xyz_warped_2", "xyz_warped_3"]].to_numpy()

    # flip RH
    rh_mask = tbl["hem"].to_numpy() == "rh"
    elecmatrix[rh_mask, 0] *= -1

    roi_lh = patient.roi(f"lh_{mesh_name}", opacity=mesh_opacity, color=(0.8, 0.8, 0.8))

    # plot 3D with electrodes
    plotter = patient.plot_brain(
        rois=[roi_lh],
        elecs=elecmatrix,
        showfig=False,
    )
    plotter.camera_position = camera_pos

    # gethe projected electrode positions in 2D
    pixel_coords = _project_3d_to_2d(plotter, elecmatrix)

    # plot again without electrodes
    plotter = patient.plot_brain(
        rois=[roi_lh],
        showfig=False,
    )
    plotter.camera_position = camera_pos

    # take a screenshot plotter.show() # show needs to be called first, if not running
    # interactive jupyter session
    img = plotter.screenshot()

    plotter.close()

    return img, pixel_coords


def add_elecs_2d(
    ax,
    pixel_coords,
    vals=None,
    feat_name=None,
    cmap="Reds",
    vmin=0.0,
    vmax=1.0,
    color=(0, 0, 0),
    point_size=20,
    marker="o",
):
    if feat_name:
        # prepare color of each electrode based on its feature value
        cols = _weight_to_color(vals, vmin=vmin, vmax=vmax, cmap=cmap)
        for i, xy in enumerate(pixel_coords):
            ax.scatter(xy[0], xy[1], color=cols[i], s=point_size, marker=marker)
        ax_cbar = f.add_subplot(gs[0, -1])
        plot_cbar_mpl(vmin=0.0, vmax=30.0, ax=ax_cbar, label=feat_name, cmap=cmap)
    else:
        ax.scatter(
            pixel_coords[:, 0],
            pixel_coords[:, 1],
            color=color,
            s=point_size,
            marker=marker,
        )


def add_size_legend(
    ax,
    sizes,
    vals,
    title="",
    loc="upper right",
):
    """Adds legend about mapping between point size and value."""
    for s, val in zip(sizes, vals):
        # plot them as invisible points
        ax.scatter([], [], s=s, c="gray", alpha=0.6, label=f"{val}")
    ax.legend(
        title=title,
        scatterpoints=1,
        frameon=False,
        labelspacing=1,
        loc=loc,
    )


import pandas as pd


def shaft_mask_from_contacts(df, elec_col, contact_list):
    """
    Return a boolean mask selecting all rows whose electrode shaft contains
    at least one contact from contact_list.

    Parameters
    ----------
    df : pandas.DataFrame
        DataFrame containing electrode labels.
    elec_col : str
        Name of the column with electrode labels (e.g. 'elec').
    contact_list : list-like
        List of contact labels (subset of df[elec_col]).

    Returns
    -------
    pandas.Series (bool)
        Boolean mask aligned with df.index.
    """

    # 1. Regex to extract the shaft label (letters + optional apostrophe)
    shaft_pattern = r"^([A-Za-z]+'?)\d+$"

    # 2. Extract shaft labels for the entire DataFrame
    df_shafts = df[elec_col].str.extract(shaft_pattern)[0]

    # 3. Extract shaft labels from the selected contact list
    selected_shafts = pd.Series(contact_list).str.extract(shaft_pattern)[0].unique()

    # 4. Build and return the mask
    filtered_df = df[df_shafts.isin(selected_shafts)]

    return filtered_df
