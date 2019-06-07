# MatlabRenderer
Z-buffer based offscreen renderer written in pure Matlab with no dependencies. Supports texture/normal mapping, shadowing, visibility and orthographic/perspective/perspective+distortion camera models.

MR_rasterise_mesh does the bulk of the work. This function performs z-buffering on the projected mesh and returns a face buffer (triangle index per pixel) and a weight buffer (barycentric weight for three triangle vertices per pixel). From these two buffers, any per-vertex quantity can be interpolated to produce a screen space value.
