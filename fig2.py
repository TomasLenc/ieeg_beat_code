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

from img_pipe.plotting.ctmr_brain_plot import _weight_to_color, plot_cbar_mpl
from img_pipe.SupplementalFiles.colorLUT import get_lut

from utils import get_2d_coords, add_elecs_2d, add_size_legend

subjects_dir = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/raw/derivatives/subjects_dir"

feat_path = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/raw/derivatives/features"

save_path = "/Users/tomaslenc/projects_backed_up/Intracerebral_ClassicRhythms_public/raw/derivatives/figures"

# load template brain
patient = img_pipe.freeCoG(
    subj="cvs_avg35_inMNI152", hem="lh", subj_dir=subjects_dir,
)

# ===================================== parameters =====================================

task = "listen"

rhythm = "wp"

brainstem_model_type = "ic"

if rhythm == "sp":
    vmin_fft = -0.4
    vmax_fft = 0.8
elif rhythm == 'wp': 
    vmin_fft = -0.6
    vmax_fft = 0.6
offset_fft = 0.0

vmin_acf = -1.0
vmax_acf = 1.0
offset_acf = 0.0  

# get values from the cochlear model
tbl_urear = pd.read_csv(
    op.join(feat_path, f"response-{brainstem_model_type}_fftAggrFreq.csv")
)
z_fft_urear = tbl_urear[tbl_urear["rhythm"] == rhythm]["z_meterRel"].squeeze()

tbl_urear = pd.read_csv(
    op.join(feat_path, f"response-{brainstem_model_type}_aggrACFtrial.csv")
)
z_acf_urear = tbl_urear[tbl_urear["rhythm"] == rhythm]["z_meterRel"].squeeze()

# ===================================== LUT =====================================

import re
lut = get_lut()

# regex cleanup rules
str_to_rm = [
    r"^Left-",
    r"^Right-",
    r"^ctx_lh_",
    r"^ctx_rh_",
    r"^ctx-lh-",
    r"^ctx-rh-",
    r"^wm_lh_",
    r"^wm_rh_",
    r"^wm-lh-",
    r"^wm-rh-",
]

def clean_name(name):
    for pat in str_to_rm:
        name = re.sub(pat, "", name)
    return name

lut_clean = {}
seen = set()
for name, rgb in lut.items():
    new_name = clean_name(name)
    if new_name not in seen:  # remove duplicates
        lut_clean[new_name] = [int(v) for v in rgb]  # ensure ints
        seen.add(new_name)

# manual LUTs
lut_custom = {
    "Unknown": [255, 255, 255],
    "unknown": [255, 255, 255],
    "PAC": [107, 107, 107],
    "HG": [16, 176, 77],
    "pmHG": [16, 176, 77],
    "alHG": [61, 190, 195],
    "PT": [44, 58, 152],
    "PP": [160, 56, 148],
    "pSTG": [176, 30, 35],
    "mSTG": [177, 178, 53],
    "IFG": [25, 159, 181],
    "MFG": [101, 78, 163],
    "SMC": [130, 90, 44],
    "SMG": [230, 126, 34],  # [217, 105, 0]  # #d96900 as RGB
    "preSMA": [232, 137, 199],
    "SMA": [230, 106, 145],
}

# merge
lut_all = lut_clean
lut_all.update(lut_custom)


# ====================================================================================
# ====================================================================================
# ====================================================================================
# CHANG (auditory cortex)
# ====================================================================================
# ====================================================================================
# ====================================================================================

tbl = pd.read_csv(
    op.join(feat_path, 
            'selections',
            f"response-LFP_rhythm-{rhythm}_task-{task}_atlas-auditory_fft.csv")
)

tbl_resp = tbl[tbl['responsive']]
tbl_nonresp = tbl[~tbl["responsive"]]

tbl_pac = pd.read_csv(
    op.join(
        feat_path,
        'selections',
        f"response-LFP_rhythm-{rhythm}_task-{task}_atlas-functionalPAC_fft.csv",
    )
)
tbl_pac = tbl_pac[(tbl_pac["rhythm"] == rhythm) & (tbl_pac["task"] == task)]

mask_is_pac = tbl_resp.set_index(["subject", "elec"]).index.isin(
    tbl_pac.set_index(["subject", "elec"]).index
)

# sanity check there's no overlap
common = pd.merge(tbl_resp, tbl_nonresp)
assert common.empty

img, pixel_coords_resp = get_2d_coords(tbl_resp, patient, mesh_name='STP', mesh_opacity=1.0)
_, pixel_coords_nonresp = get_2d_coords(tbl_nonresp, patient, mesh_name="STP")


# ================================= empty pial surf ==================================

# plt.close()
# f = plt.figure(figsize=(20, 20), facecolor=None)
# gs = f.add_gridspec(1, 10)
# ax = f.add_subplot(gs[0, 0:8])
# ax_cbar = f.add_subplot(gs[0, -1])
# ax.axis("off")

# ax.imshow(img)

# plt.savefig(
#     op.join(
#         save_path, f"response-LFP_rhythm-{rhythm}_task-{task}_surf-stp_feat-none.png"
#     ),
#     dpi=900,
# )

# plt.show()

# ===================================== anatomy =====================================

plt.close()

f = plt.figure(figsize=(20, 20), facecolor=None)
gs = f.add_gridspec(1, 10)
ax = f.add_subplot(gs[0, 0:8])
ax_cbar = f.add_subplot(gs[0, -1])
ax.axis("off")

ax.imshow(img)

val2s = lambda vals: vals / 80.0 * 400
s = val2s(tbl_resp["sum_magn"].to_numpy())
cmap = lut_all

cols = np.vstack([np.array(cmap[lab])/255. for lab in tbl_resp["custom"].to_list()])

# nonresponsive
ax.scatter(
    pixel_coords_nonresp[:, 0],
    pixel_coords_nonresp[:, 1],
    color=(0, 0, 0),
    s=10,
    marker="o",
)

# responsive not PAC
ax.scatter(
    pixel_coords_resp[~mask_is_pac, 0],
    pixel_coords_resp[~mask_is_pac, 1],
    c=cols[~mask_is_pac, :],
    s=100,
    marker="o",
)

# PAC
ax.scatter(
    pixel_coords_resp[mask_is_pac, 0],
    pixel_coords_resp[mask_is_pac, 1],
    c=cols[mask_is_pac,:],
    s=100,
    marker="o",
    edgecolors="black",
    linewidth=2,
)

vals_for_leg = np.array([10., 30., 50., 70.])
add_size_legend(ax, sizes=val2s(vals_for_leg), vals=vals_for_leg)

plt.savefig(
    op.join(
        save_path, f"response-LFP_rhythm-{rhythm}_task-{task}_surf-stp_feat-anat.png"
    ),
    dpi=1200,
)

plt.show()

# ===================================== FFT =====================================

cmap = "YlOrBr"

plt.close()

f = plt.figure(figsize=(20, 20), facecolor=None)
gs = f.add_gridspec(1, 10)
ax = f.add_subplot(gs[0, 0:8])
ax_cbar = f.add_subplot(gs[0, -1])
ax.axis("off")

ax.imshow(img)

# prepare color of each electrode based on its feature value
vals = tbl_resp["z_meterRel"].to_numpy() - offset_fft
cols = _weight_to_color(vals, vmin=vmin_fft, vmax=vmax_fft, cmap=cmap)

val2s = lambda vals: (vals - (-0.6)) / 1.3 * 300
s = val2s(vals)
vals_for_leg = np.array([-0.6, -0.3, 0, 0.3, 0.6])
add_size_legend(ax, sizes=val2s(vals_for_leg), vals=vals_for_leg)

ax.scatter(
    pixel_coords_nonresp[:, 0],
    pixel_coords_nonresp[:, 1],
    color=(1,1,1),
    s=10,
    marker="o",
)

ax.scatter(
    pixel_coords_resp[:, 0],
    pixel_coords_resp[:, 1],
    c=cols,
    s=s, #100,
    marker="o",
    edgecolors=None,
    linewidth=1,
    alpha=0.8,
)

plot_cbar_mpl(
    vmin=vmin_fft + offset_fft,
    vmax=vmax_fft + offset_fft,
    extra_ticks=[0, z_fft_urear],  # -0.140705355171239,
    ax=ax_cbar,
    label="",
    cmap=cmap,
)

plt.savefig(
    op.join(
        save_path,
        f"response-LFP_rhythm-{rhythm}_task-{task}_surf-stp_feat-zbeatFFT.png",
    ),
    dpi=900,
)

plt.show()


# ===================================== ACF =====================================

tbl = pd.read_csv(
    op.join(
        feat_path,
        "selections",
        f"response-LFP_rhythm-{rhythm}_task-{task}_atlas-auditory_acfTrial.csv",
    )
)
tbl_resp = tbl[tbl["responsive"]]
tbl_nonresp = tbl[~tbl["responsive"]]

# sanity check there's no overlap
common = pd.merge(tbl_resp, tbl_nonresp)
assert common.empty

img, pixel_coords_resp = get_2d_coords(
    tbl_resp, patient, mesh_name="STP", mesh_opacity=1.0
)
_, pixel_coords_nonresp = get_2d_coords(tbl_nonresp, patient, mesh_name="STP")


cmap = "RdPu"

plt.close()

f = plt.figure(figsize=(20, 20), facecolor=None)
gs = f.add_gridspec(1, 10)
ax = f.add_subplot(gs[0, 0:8])
ax_cbar = f.add_subplot(gs[0, -1])
ax.axis("off")

ax.imshow(img)

# prepare color of each electrode based on its feature value
vals = tbl_resp["z_meterRel"].to_numpy() - offset_acf
cols = _weight_to_color(vals, vmin=vmin_acf, vmax=vmax_acf, cmap=cmap)

# prepare marker sizes
val2s = lambda vals: (vals - (-1)) / 2.0 * 300
s = val2s(vals)
vals_for_leg = np.array([-1.0, -0.5, 0, 0.5, 1.0])
add_size_legend(ax, sizes=val2s(vals_for_leg), vals=vals_for_leg)

ax.scatter(
    pixel_coords_nonresp[:, 0],
    pixel_coords_nonresp[:, 1],
    color=(1,1,1),
    s=10,
    marker="o",
)

ax.scatter(
    pixel_coords_resp[:, 0],
    pixel_coords_resp[:, 1],
    c=cols,
    s=s, #100,
    marker="o",
    edgecolors=None,
    linewidth=1,
    alpha=0.8,
)

plot_cbar_mpl(
    vmin=vmin_acf + offset_acf,
    vmax=vmax_acf + offset_acf,
    extra_ticks=[0, z_acf_urear],  # -0.389040147802482,
    ax=ax_cbar,
    label="",
    cmap=cmap,
)

plt.savefig(
    op.join(
        save_path,
        f"response-LFP_rhythm-{rhythm}_task-{task}_surf-stp_feat-zbeatACFtrial.png",
    ),
    dpi=900,
)

plt.show()


# ====================================================================================
# ====================================================================================
# ====================================================================================
# whole brain (Desikan Killinany)
# ====================================================================================
# ====================================================================================
# ====================================================================================

tbl = pd.read_csv(
    op.join(
        feat_path,
        "selections",
        f"response-LFP_rhythm-{rhythm}_task-{task}_atlas-assoc_fft.csv",
    )
)

# remove HG
tbl = tbl[tbl['custom'] != 'HG']

tbl_resp = tbl[tbl["responsive"]]
tbl_nonresp = tbl[~tbl["responsive"]]

# sanity check there's no overlap
common = pd.merge(tbl_resp, tbl_nonresp)
assert common.empty
assert tbl_resp.shape[0] + tbl_nonresp.shape[0] == tbl.shape[0]
assert not np.any(tbl.custom == "SFG")

camera_pos = [
    (-332.0277343542532, 48.603911408498575, -50.59195842557436),
    (-1.087700479978634, -16.20437870514722, 2.6991319347732636),
    (-0.15889100690013935, 0.0004734889523023048, 0.9872960162658775),
]
img, pixel_coords_resp = get_2d_coords(
    tbl_resp,
    patient,
    mesh_name="pial",
    mesh_opacity=1,
    camera_pos=camera_pos,
)
_, pixel_coords_nonresp = get_2d_coords(
    tbl_nonresp,
    patient,
    mesh_name="pial",
    camera_pos=camera_pos,
)

# ================================= empty pial surf ==================================

# plt.close()
# f = plt.figure(figsize=(20, 20), facecolor=None)
# gs = f.add_gridspec(1, 10)
# ax = f.add_subplot(gs[0, 0:8])
# ax_cbar = f.add_subplot(gs[0, -1])
# ax.axis("off")

# ax.imshow(img)

# plt.savefig(
#     op.join(
#         save_path, f"response-LFP_rhythm-{rhythm}_task-{task}_surf-pial_feat-none.png"
#     ),
#     dpi=900,
# )

# plt.show()

# ===================================== anatomy ======================================

plt.close()
f = plt.figure(figsize=(20, 20), facecolor=None)
gs = f.add_gridspec(1, 10)
ax = f.add_subplot(gs[0, 0:8])
ax_cbar = f.add_subplot(gs[0, -1])
ax.axis("off")

ax.imshow(img)

cols = np.vstack(
    [np.array(lut_all[lab]) / 255.0 for lab in tbl_resp["custom"].to_list()]
)

ax.scatter(
    pixel_coords_nonresp[:, 0],
    pixel_coords_nonresp[:, 1],
    color=(0, 0, 0),
    s=10,
    marker="o",
)

ax.scatter(
    pixel_coords_resp[:, 0],
    pixel_coords_resp[:, 1],
    c=cols,
    s=100,
    marker="o",
)

plt.savefig(
    op.join(
        save_path, f"response-LFP_rhythm-{rhythm}_task-{task}_surf-pial_feat-anat.png"
    ),
    dpi=900,
)

plt.show()


# ===================================== FFT ======================================

cmap = "YlOrBr"

plt.close()

f = plt.figure(figsize=(20, 20), facecolor=None)
gs = f.add_gridspec(1, 10)
ax = f.add_subplot(gs[0, 0:8])
ax_cbar = f.add_subplot(gs[0, -1])
ax.axis("off")

ax.imshow(img)

# prepare color of each electrode based on its feature value
vals = tbl_resp["z_meterRel"].to_numpy() - offset_fft
cols = _weight_to_color(vals, vmin=vmin_fft, vmax=vmax_fft, cmap=cmap)

# prepare marker sizes
val2s = lambda vals: (vals - (-0.6)) / 1.3 * 300
s = val2s(vals)
vals_for_leg = np.array([-0.6, -0.3, 0, 0.3, 0.6])
add_size_legend(ax, sizes=val2s(vals_for_leg), vals=vals_for_leg)

ax.scatter(
    pixel_coords_nonresp[:, 0],
    pixel_coords_nonresp[:, 1],
    color=(1,1,1),
    s=10,
    marker="o",
)

ax.scatter(
    pixel_coords_resp[:, 0],
    pixel_coords_resp[:, 1],
    c=cols,
    s=s, #100, # s=s,
    marker="o",
    edgecolors=None,
    linewidth=1,
    alpha=0.8,
)

plot_cbar_mpl(
    vmin=vmin_fft + offset_fft,
    vmax=vmax_fft + offset_fft,
    extra_ticks=[0, z_fft_urear],
    ax=ax_cbar,
    label="",
    cmap=cmap,
)

plt.savefig(
    op.join(
        save_path,
        f"response-LFP_rhythm-{rhythm}_task-{task}_surf-pial_feat-zbeatFFT.png",
    ),
    dpi=900,
)

plt.show()


# ===================================== ACF =====================================

tbl = pd.read_csv(
    op.join(
        feat_path,
        "selections",
        f"response-LFP_rhythm-{rhythm}_task-{task}_atlas-assoc_acfTrial.csv",
    )
)

# remove HG
tbl = tbl[tbl["custom"] != "HG"]

tbl_resp = tbl[tbl["responsive"]]
tbl_nonresp = tbl[~tbl["responsive"]]

# sanity check there's no overlap
common = pd.merge(tbl_resp, tbl_nonresp)
assert common.empty
assert tbl_resp.shape[0] + tbl_nonresp.shape[0] == tbl.shape[0]
assert not np.any(tbl.custom == "superiorfrontal")

camera_pos = [
    (-332.0277343542532, 48.603911408498575, -50.59195842557436),
    (-1.087700479978634, -16.20437870514722, 2.6991319347732636),
    (-0.15889100690013935, 0.0004734889523023048, 0.9872960162658775),
]
img, pixel_coords_resp = get_2d_coords(
    tbl_resp,
    patient,
    mesh_name="pial",
    mesh_opacity=1,
    camera_pos=camera_pos,
)
_, pixel_coords_nonresp = get_2d_coords(
    tbl_nonresp,
    patient,
    mesh_name="pial",
    camera_pos=camera_pos,
)


cmap = "RdPu"

plt.close()

f = plt.figure(figsize=(20, 20), facecolor=None)
gs = f.add_gridspec(1, 10)
ax = f.add_subplot(gs[0, 0:8])
ax_cbar = f.add_subplot(gs[0, -1])
ax.axis("off")

ax.imshow(img)

# prepare color of each electrode based on its feature value
vals = tbl_resp["z_meterRel"].to_numpy() - offset_acf
cols = _weight_to_color(vals, vmin=vmin_acf, vmax=vmax_acf, cmap=cmap)

# prepare marker sizes
val2s = lambda vals: (vals - (-1)) / 2.0 * 300
s = val2s(vals)
vals_for_leg = np.array([-1.0, -0.5, 0, 0.5, 1.0])
add_size_legend(ax, sizes=val2s(vals_for_leg), vals=vals_for_leg)

ax.scatter(
    pixel_coords_nonresp[:, 0],
    pixel_coords_nonresp[:, 1],
    color=(1,1,1),
    s=10,
    marker="o",
)

ax.scatter(
    pixel_coords_resp[:, 0],
    pixel_coords_resp[:, 1],
    c=cols,
    s=s, #100,
    marker="o",
    edgecolors=None,
    linewidth=1,
    alpha=0.8,
)

plot_cbar_mpl(
    vmin=vmin_acf + offset_acf,
    vmax=vmax_acf + offset_acf,
    extra_ticks=[0, z_acf_urear], 
    ax=ax_cbar,
    label="",
    cmap=cmap,
)

plt.savefig(
    op.join(
        save_path,
        f"response-LFP_rhythm-{rhythm}_task-{task}_surf-pial_feat-zbeatACFtrial.png",
    ),
    dpi=900,
)

plt.show()


# ====================================================================================
# ====================================================================================
# ====================================================================================
# SMA
# ====================================================================================
# ====================================================================================
# ====================================================================================

tbl = pd.read_csv(
    op.join(
        feat_path,
        "selections",
        f"response-LFP_rhythm-{rhythm}_task-{task}_atlas-sma_fft.csv",
    )
)

tbl_resp = tbl[tbl["responsive"]]
tbl_nonresp = tbl[~tbl["responsive"]]

# sanity check there's no overlap
common = pd.merge(tbl_resp, tbl_nonresp)
assert common.empty
assert tbl_resp.shape[0] + tbl_nonresp.shape[0] == tbl.shape[0]

camera_pos = [
    (255.81883447149457, -35.62977341674241, 1.2927489623545965),
    (-27.197583901745404, -3.75060449249896, -3.0364244855488263),
    (-0.014794561451464289, 0.0044403028113276476, 0.9998806952143854),
]
img, pixel_coords_resp = get_2d_coords(
    tbl_resp,
    patient,
    mesh_name="pial",
    mesh_opacity=1,
    camera_pos=camera_pos,
)
_, pixel_coords_nonresp = get_2d_coords(
    tbl_nonresp,
    patient,
    mesh_name="pial",
    camera_pos=camera_pos,
)

# ==================================== anatomy ====================================

plt.close()
f = plt.figure(figsize=(20, 20), facecolor=None)
gs = f.add_gridspec(1, 10)
ax = f.add_subplot(gs[0, 0:8])
ax_cbar = f.add_subplot(gs[0, -1])
ax.axis("off")

ax.imshow(img)

val2s = lambda vals: vals / 80.0 * 400
s = val2s(tbl_resp["sum_magn"].to_numpy())

cols = np.vstack(
    [np.array(lut_all[lab]) / 255.0 for lab in tbl_resp["custom"].to_list()]
)

ax.scatter(
    pixel_coords_nonresp[:, 0],
    pixel_coords_nonresp[:, 1],
    color=(0, 0, 0),
    s=10,
    marker="o",
)

ax.scatter(
    pixel_coords_resp[:, 0],
    pixel_coords_resp[:, 1],
    c=cols,
    s=100,
    marker="o",
)

vals_for_leg = np.array([10.0, 30.0, 50.0, 70.0])
add_size_legend(ax, sizes=val2s(vals_for_leg), vals=vals_for_leg)

plt.savefig(
    op.join(
        save_path, f"response-LFP_rhythm-{rhythm}_task-{task}_surf-pial_roi-sma_feat-anat.png"
    ),
    dpi=900,
)

plt.show()
