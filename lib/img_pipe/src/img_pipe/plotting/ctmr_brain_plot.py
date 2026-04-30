# ctmr_brain_plot.py
""" 
This module contains a function (ctmr_brain_plot) that takes as 
 input a 3d coordinate set of triangular mesh vertices (vert) and an ordered
 list of their indices (tri), to produce a 3d surface model of an individual
 brain. Assigning the result of the plot to a variable enables interactive
 changes to be made to the OpenGl mesh object. Default shading is phong point
 shader (shiny surface).

 usage: from ctmr_brain_plot import *
        dat = scipy.io.loadmat('/path/to/lh_pial_trivert.mat'); mesh =
        ctmr_brain_plot(dat['tri'], dat['vert']); mlab.show()

 A second function contained in this module can be used to plot electrodes as
 glyphs (spehres) or 2d circles. The function (el_add) takes as input a list of
 3d coordinates in freesurfer surface RAS space and plots them according to the
 color and size parameters that you provide.

 usage: elecs = scipy.io.loadmat('/path/to/hd_grid.mat')['elecmatrix'];
        points = el_add(elecs, color = (1, 0, 0), msize = 2.5); mlab.show()  

Modified for use in python from MATLAB code originally written by Kai Miller and
Dora Hermes (ctmr_gui, see
https://github.com/dorahermes/Paper_Hermes_2010_JNeuroMeth)

"""

import scipy.io
import numpy as np
import matplotlib as mpl
import mne
import pyvista as pv
import matplotlib.pyplot as plt 

from collections.abc import Sequence
from matplotlib import cm
from matplotlib.colors import ListedColormap
from vtkmodules.vtkFiltersSources import vtkSphereSource

# preprare binary colormap for plotting curvature on inflated brain
dark = np.array([186 / 256, 186 / 256, 186 / 256, 1.0])
light = np.array([107 / 256, 107 / 256, 107 / 256, 1.0])
cmap_curv = ListedColormap(np.vstack([dark, light]))


def ctmr_gauss_plot(
    tri,
    vert,
    color=(0.8, 0.8, 0.8),
    brain_color = None,
    elecmatrix=None,
    weights=None,
    opacity=1.0,
    gsp=10,
    cmap="RdBu_r",
    show_colorbar=True,
    plotter=None,
    vmin=None,
    vmax=None,
    window_size=(1200, 900),
    background_color='white',
    depth_peeling=100,
):
    """
    This function plots the 3D brain surface mesh

    Parameters
    ----------
        color : tuple
            (n,n,n) tuple of floats between 0.0 and 1.0, background color of
            brain
        elecmatrix : array-like
            [nchans x 3] matrix of electrode coordinate values in 3D
        weights : array-like
            [nchans x 1] - if [elecmatrix] is also given, this will color the brain
            vertices according to these weights
        msize : float
            size of the electrode.  default = 2
        opacity : float (0.0 - 1.0)
            opacity of the brain surface (value from 0.0 - 1.0)
        cmap : str or mpl.colors.LinearSegmentedColormap
            colormap to use when plotting gaussian weights with [elecmatrix] and
            [weights]
        gsp : float
            gaussian smoothing parameter, larger makes electrode activity more
            spread out across the surface if specified

    Returns
    -------
    plotter : pyvista plotter instance
    """
    # if color is another iterable, make it a tuple.
    color = tuple(color)

    # open new plotter if needed
    if plotter is None:
        plotter = get_new_plotter(
            window_size=window_size, 
            background_color=background_color, 
            depth_peeling=depth_peeling,
            )

    # prepare brain mesh (if we have electrodes and weights, we need to make
    # a gaussian around each electrode to get the surface color)
    if elecmatrix is not None and weights is not None:
        brain_color = np.zeros(
            vert.shape[0],
        )
        for i in np.arange(elecmatrix.shape[0]):
            b_z = np.abs(vert[:, 2] - elecmatrix[i, 2])
            b_y = np.abs(vert[:, 1] - elecmatrix[i, 1])
            b_x = np.abs(vert[:, 0] - elecmatrix[i, 0])
            gauss_wt = np.nan_to_num(
                weights[i] * np.exp((-(b_x**2 + b_z**2 + b_y**2)) / gsp)
            )
            brain_color = brain_color + gauss_wt
        # scale the colors so that it matches the weights that were passed in
        brain_color = brain_color * (np.abs(weights).max() / np.abs(brain_color).max())
        if vmin == None and vmax == None:
            vmin = -np.abs(brain_color).max()
            vmax = np.abs(brain_color).max()
            
    # now do the actual plotting of the surface
    mesh = plot_mesh(
        plotter,
        vert,
        tri,
        opacity=opacity,
        cmap=cmap,
        scalars=brain_color,
        color=color,
        vmin=vmin,
        vmax=vmax,
    )
    
    # plot colorbar
    if weights is not None and show_colorbar:
        cbar = add_cbar(plotter, weights, cmap=cmap)

    return plotter


def plot_mesh(
    plotter,
    rr,
    tri,
    opacity=1.0,
    cmap="RdBu_r",
    scalars=None,
    color=(0.8, 0.8, 0.8),
    vmin=None,
    vmax=None,
    ambient=0.4225,
    specular=0.333,
    specular_power=66,
    diffuse=0.6995,
    interpolation="phong",
):
    """
    Plot 3D mesh.
    """
    # prepend 3 to each row of triangles to indicate the polygon consists of 3
    # points (vtk format to create PolyData)
    tri = np.c_[np.full(len(tri), 3), tri]
    # make vtk PolyData instance
    mesh = pv.PolyData(rr, tri)
    # compute normal vector for each vertex position (this is also done in MNE)
    if "Normals" not in mesh.point_data:
        mesh.compute_normals(
            cell_normals=False,
            consistent_normals=False,
            non_manifold_traversal=False,
            inplace=True,
        )
    # plot the mesh using pyvista
    actor = plotter.add_mesh(
        mesh=mesh,
        backface_culling=False,
        cmap=cmap,
        scalars=scalars,
        color=color,
        edge_color=color,
        interpolate_before_map=True,
        line_width=1.0,
        opacity=opacity,
        render=False,
        reset_camera=False,
        rgba=False,
        clim=[vmin, vmax],
        show_scalar_bar=False,
        style="surface",
    )
    # set VTK properties (same values used for mayavi in the original img_pipe)
    prop = actor.GetProperty()
    prop.diffuse = diffuse
    prop.interpolation = interpolation
    prop.specular = specular
    prop.specular_power = specular_power
    prop.ambient = ambient
    return actor


def el_add(
    plotter,
    elecmatrix,
    eleclabels=None,
    weights=None,
    colors=(1.0, 0.0, 0.0),
    opacity=1.0,
    cmap="Reds",
    vmin=None,
    vmax=None,
    label_font_size=10,
    label_color=(0.0, 0.0, 0.0),
    show_colorbar=True,
):
    """
    Either pass a single color, or one color per electrode, or array of
    weights that will be converted to colors based on the colormap.
    """
    # if we have a single electrode, let's make sure it's a 2D array
    if elecmatrix.ndim == 1:
        elecmatrix = elecmatrix[np.newaxis, :]
    if weights is not None:
        # if we have weights, let's convert them to colors
        colors = _weight_to_color(weights=weights, vmin=vmin, vmax=vmax, cmap=cmap)
    else:
        # otherwise, if single color was passed, replicate it
        if isinstance(colors, Sequence) or (
            isinstance(colors, np.ndarray) and colors.size == 3
        ):
            colors = np.tile(colors, [elecmatrix.shape[0], 1])
    # go over electrodes and plot each as a sphere
    for i, elec_pos in enumerate(elecmatrix):
        label = eleclabels[i] if eleclabels is not None else None
        _plot_sphere(
            plotter=plotter,
            center=elec_pos,
            color=colors[i],
            opacity=opacity,
            label=label,
            label_font_size=label_font_size,
            label_color=label_color,
        )
    # plot colorbar
    if weights is not None and show_colorbar:
        cbar = add_cbar(plotter, weights, cmap=cmap)


def plot_2d(
    im, elec_pos, weights=None, color="b", cmap="Purples", s=50, dynamic_size=False
):
    """
    Use matplotlib to plot 2D snapshot overlaid with electrodes as circle
    markers.
    """
    if weights is not None:
        c = _weight_to_color(weights, cmap=cmap)
        if dynamic_size:
            s = (weights / weights.max() * s / 2) + s / 2
    else:
        c = color
    f, ax = plt.subplots(figsize=(5, 5))
    ax.imshow(im)
    ax.set_axis_off()
    ax.scatter(elec_pos[:, 0], elec_pos[:, 1], c=c, s=s)
    return f


def add_cbar(
    plotter,
    weights,
    cmap,
    cbar_title="",
    n_labels=2,
    title_font_size=None,
    label_font_size=None,
    vertical=True,
):
    """
    We need a way to plot colorbar when rendering each individual electrode as a
    signel colored shpere mesh. The reason is that if we were to call
    plotter.add_points() method, the points wouldn't change change size with
    zoom... But with each single electrode as an indivudal shpere, it's pain in
    the ass to construct a colormap - it needs a mapper attached to a dataset.
    The easiest hack is to make a new temporary plotter, plot the points there
    using add_points(), extract the mappper, and apply it to make a colorbar in
    our original plotter.
    """
    # make the font sizes proportional to figugre size if not specified
    if title_font_size is None:
        int(sum(plotter.window_size) / 50)
    if label_font_size is None:
        int(sum(plotter.window_size) / 50)
    # open temporary plotter we're gonna throw away
    tmp_plotter = pv.Plotter()
    # plot the electrodes as points using pyvista add_points()
    rr = np.random.rand(len(weights), 3)
    mesh = tmp_plotter.add_points(rr, scalars=weights, rgb=False, cmap=cmap)
    # now we have access to the mapper, so we can apply it to our original
    # plotter and make the colorbar
    cbar = plotter.add_scalar_bar(
        title=cbar_title,
        mapper=mesh.GetMapper(),
        n_labels=n_labels,
        title_font_size=title_font_size,
        label_font_size=label_font_size,
        vertical=vertical,
    )
    cbar.SetTextPositionToPrecedeScalarBar()
    return cbar


def plot_cbar_mpl(
    cmap="viridis",
    vmin=0.0,
    vmax=1.0,
    extra_ticks=[],
    ax=None,
    orientation="vertical",
    label="",
    label_kwargs=dict(labelpad=-15, rotation="horizontal"),
):
    """This is for matplotlib only. Plot colorbar into the given axes. If no axes are
    passed, it will crate a new figure."""
    from matplotlib.colors import Normalize
    from matplotlib.colorbar import ColorbarBase

    colormap = plt.get_cmap(name=cmap)
    norm = Normalize(vmin=vmin, vmax=vmax)
    if ax is None:
        f, ax = plt.subplots(figsize=(0.2, 1))
    if extra_ticks:
        ticks = np.sort(np.append([vmin, vmax], extra_ticks))
    else:
        ticks = [vmin, vmax]
    print(ticks)
    cbar = ColorbarBase(
        ax, cmap=colormap, norm=norm, ticks=ticks, orientation=orientation
    )
    # remove the colorbar frame except for the line containing the ticks
    cbar.outline.set_visible(False)
    ax.tick_params(length=0)
    ax.set_ylabel(label, **label_kwargs)
    return ax.get_figure(), ax


def _plot_sphere(
    plotter,
    center,
    factor=2.0,
    resolution=16,
    color=(1.0, 0.0, 0.0),
    opacity=1.0,
    label=None,
    label_font_size=20,
    label_color=(0.0, 0.0, 0.0),
):
    """
    Plot 3D sphere. This is a hack to plot electrodes that will change size when
    zooming the camera.
    """
    sphere = vtkSphereSource()
    sphere.SetThetaResolution(resolution)
    sphere.SetPhiResolution(resolution)
    sphere.Update()
    geom = sphere.GetOutput()
    mesh = pv.PolyData(center)
    glyph = mesh.glyph(orient=False, scale=False, factor=factor, geom=geom)
    actor = plotter.add_mesh(
        mesh=glyph,
        color=color,
        opacity=opacity,
        backface_culling=False,
        smooth_shading=True,
        render=False,
        reset_camera=False,
    )
    # add a label
    if label is not None:
        if not isinstance(label, list):
            label = [label]
        plotter.add_point_labels(
            points=center,
            labels=label,
            show_points=False,
            font_size=label_font_size,
            text_color=label_color,
            shape=None,
            always_visible=True,
        )
    return actor


def _weight_to_color(weights, vmin=None, vmax=None, cmap="viridis"):
    """
    Convert scalars (weights) to colors based on a colormap.
    """
    if not isinstance(cmap, ListedColormap):
        cmap = mpl.colormaps[cmap]
    if vmin is None:
        vmin = weights.min()
    if vmax is None:
        vmax = weights.max()
    normalizer = mpl.colors.Normalize(vmin=vmin, vmax=vmax)
    mapper = cm.ScalarMappable(norm=normalizer, cmap=cmap)
    colors = mapper.to_rgba(weights)
    return colors


def get_new_plotter(window_size=(1200, 900), background_color='white', 
                     depth_peeling=100):
    plotter = pv.Plotter(window_size=window_size)
    plotter.background_color = background_color
    if depth_peeling is not None:
        plotter.enable_depth_peeling(depth_peeling)
    return plotter


def plot_plane(plotter, x, y, z, color=(0.0, 0.0, 0.0), opacity=1.0):
    mesh = pv.StructuredGrid(x, y, z)
    actor = plotter.add_mesh(
        mesh=mesh,
        color=color,
        opacity=opacity,
        backface_culling=False,
        smooth_shading=True,
        render=False,
        reset_camera=False,
    )


def set_camera_position(plotter, hem='lh', view_type='lateral'):
    """
    Sets camera position on a plotter depending on the view of the brain we want. 
    
    Parameters
    ----------
        plotter : pyvista plotter instance
        hem : str
            Hemisphere, either 'lh', 'rh', or 'stereo'. 
        view_type : str
            Type of view, can be 'lateral', 'medial', or 'stp' (superior temporal plane). 

    Returns
    -------
    camera_position : tuple
        Output of plotter.camera_position. 
    """
    azimuth = None
    camera_position = None
    
    # lateral view
    if view_type == 'lateral':
        if hem == 'lh':
            camera_position = 'yz'
            azimuth = 180.
        elif hem == 'rh':
            camera_position = 'yz'
            azimuth = 0.
            
    # medial view
    elif view_type == 'medial':
        if hem == 'lh':
            camera_position = 'yz'
            azimuth = 0.
        elif hem == 'rh':
            camera_position = 'yz'
            azimuth = 180.
            
    # superior temporal plane view
    elif view_type == 'stp':
        if hem == 'lh':
            camera_position = [(-130.5289033404, 97.2456495339791, 109.53497900069242),
                (-48.27929878234863, 3.0705623626708984, -21.109783232212067),
                (0.8148560617834777, -0.08398520311067165, 0.5735469328949291)]
        elif hem == 'rh':
            camera_position = [(142.57826363386408, 109.55778718133912, 101.9019514894746),
                (44.078086853027344, 13.467074394226074, -23.159048795700073),
                (-0.8418080142002298, 0.22338545083482794, 0.49138397163886643)]
        elif hem == 'stereo':
            camera_position = 'xy'
            azimuth = 0.
            
    # update camera position 
    if camera_position is not None:
        plotter.camera_position = camera_position
    if azimuth is not None:
        plotter.camera.azimuth = azimuth
        
    return plotter.camera_position


def screenshot(plotter, scale=1):        
    plotter.show()
    arr = plotter.screenshot(transparent_background=False, filename=None, scale=scale)
    return arr


def trim_white_space(img, white_threshold=255):
    """
    Trim white borders from an RGB image.

    Parameters:
        img (np.ndarray): Image array of shape (H, W, 3)
        white_threshold (int): Pixel values >= this are considered white

    Returns:
        np.ndarray: Cropped image
    """

    # Create mask of non-white pixels
    non_white_mask = np.any(img < white_threshold, axis=2)

    # Get bounding box of non-white region
    rows = np.where(non_white_mask.any(axis=1))[0]
    cols = np.where(non_white_mask.any(axis=0))[0]

    if rows.size == 0 or cols.size == 0:
        # Image is fully white
        return img

    top, bottom = rows[0], rows[-1] + 1
    left, right = cols[0], cols[-1] + 1

    return img[top:bottom, left:right]