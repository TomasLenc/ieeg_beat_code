import numpy as np
import pyvista as pv
import matplotlib.pyplot as plt

def vtk_to_numpy_matrix(vtk_mat):
    """Convert vtkMatrix4x4 to a NumPy 4x4 array."""
    mat = np.zeros((4, 4))
    for i in range(4):
        for j in range(4):
            mat[i, j] = vtk_mat.GetElement(i, j)
    return mat


def get_world_to_view_matrix(camera, aspect, near, far):
    """Return the 4x4 matrix converting world coordinates to normalized view coordinates."""
    vtk_mat = camera.GetCompositeProjectionTransformMatrix(aspect, near, far)
    return vtk_to_numpy_matrix(vtk_mat)  # convert to NumPy array


def get_viewport_matrix(window_size):
    """Convert normalized device coordinates (-1 to 1) to pixel coordinates."""
    width, height = window_size
    return np.array(
        [
            [width / 2.0, 0, 0, width / 2.0],
            [0, -height / 2.0, 0, height / 2.0],
            [0, 0, 1, 0],
            [0, 0, 0, 1],
        ]
    )


def apply_transform(points, matrix):
    """Apply 4x4 transformation to Nx4 homogeneous coordinates."""
    return (matrix @ points.T).T


# -------------------------------
# Example
# -------------------------------
plotter = pv.Plotter()

# Random 3D points
N = 5
X = np.random.randint(-3, 3, N)
Y = np.random.randint(-3, 3, N)
Z = np.random.randint(-3, 3, N)
plotter.add_points(np.column_stack((X, Y, Z)), color="red", point_size=100)

plotter.show(auto_close=False)

# Homogeneous coordinates
points_h = np.column_stack((X, Y, Z, np.ones(N)))

# Get camera params
camera = plotter.camera
aspect = plotter.window_size[0] / plotter.window_size[1]
near, far = camera.clipping_range

# 1. World -> normalized view coordinates
world_to_view = get_world_to_view_matrix(camera, aspect, near, far)
view_coords = apply_transform(points_h, world_to_view)
norm_view_coords = view_coords / view_coords[:, 3][:, None]

# 2. Normalized view -> pixel coordinates
viewport = get_viewport_matrix(plotter.window_size)
pixel_coords = apply_transform(norm_view_coords, viewport)
pixel_coords = pixel_coords[:,:2]
print(pixel_coords)

# --------------------------------------------------------------------------------------
# OMFG I already had this fuction I prepared long time ago.... (face palm....)
from img_pipe.plotting.mlab_3D_to_2D import _project_3d_to_2d
pixel_coords = _project_3d_to_2d(plotter, np.vstack([X, Y, Z]).T)
print(pixel_coords)
# --------------------------------------------------------------------------------------

# 3. Screenshot and plot
img = plotter.screenshot()

plt.imshow(img)

for i in range(N):
    plt.plot(pixel_coords[i, 0], pixel_coords[i, 1], "bo")
    print(f"Point {i}: pixel coords = {pixel_coords[i,0:2]}")

plt.show()

plotter.close()
