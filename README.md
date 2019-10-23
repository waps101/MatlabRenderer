# MatlabRenderer

MatlabRenderer is an offscreen renderer written entirely in pure Matlab with no dependencies. It is based on deferred shading, so provides a rasteriser based on z-buffering. It supports texture/normal mapping, shadowing, visibility and orthographic/perspective/perspective+distortion camera models. It is CPU based and hence not fast (around 0.2s to render the Stanford bunny images below on my MacBook Pro) but provides features and control not available with the 3D visualisation tools in Matlab, most notably texture mapping, total control over camera parameters and shadow mapping. Being entirely written in Matlab, it is very hackable if you wish to add your own features.

## Basic usage

```matlab
obj = MR_obj_read('data/StanfordBunny.obj');
[cameraparams,renderparams] = MR_default_params(obj.V,400);
render = MR_render_mesh(obj.F,obj.V,cameraparams,renderparams);
figure; imshow(render)
```

This will render the Stanford bunny with some default camera and rendering parameters:

![Stanford bunny rendering with default parameters](/example1.jpg?raw=true "Stanford bunny rendering with default parameters")

For UV texture mapping, insert the following before the call to **MR_render_mesh**:

```matlab
renderparams.VT = obj.VT;
renderparams.FT = obj.FT;
renderparams.textureMode = 'useTextureMap';
renderparams.texmap = im2double(imread('data/StanfordBunny.jpg'));
```

![Stanford bunny rendering with texture mapping](/example2.jpg?raw=true "Stanford bunny rendering with texture mapping")

**MR_render_mesh** returns many other useful things including per vertex visibility, screen space depth map, normal map, shadow map and texture map.

## Citation

If you use this renderer in your research, please cite the following paper for which it was developed:

A. Bas and W. A. P. Smith. "What Does 2D Geometric Information Really Tell Us About 3D Face Shape?" International Journal of Computer Vision, 127(10):1455-1473, 2019.

Bibtex:

    @article{bas2019what,
      title={What Does {2D} Geometric Information Really Tell Us About {3D} Face Shape?},
      author={Bas, Anil and Smith, William A. P.},
      journal={International Journal of Computer Vision},
      volume={127},
      number={10},
      pages={1455--1473},
      year={2019}
    }

## Overview

**MR_rasterise_mesh** does the bulk of the work. This function performs z-buffering on the projected mesh and returns a face buffer (triangle index per pixel) and a weight buffer (barycentric weight for three triangle vertices per pixel). From these two buffers, any per-vertex or UV space quantity can be interpolated to produce a screen space value. This is exactly what **MR_compute_buffer_per_vertex** does (for per-vertex quantities) and **MR_compute_buffer_map** does (for UV mapped quantities).

The function **MR_render_mesh** is essentially a wrapper to all of the underlying functions, executing the full rendering pipeline. You may want to edit aspects of this, for example to handle multiple light sources. If you want to introduce alternate reflectance models, you should edit **MR_render_buffers**.

Consistent with Matlab, the MatlabRenderer uses a coordinate system in which the top left pixel centre has coordinates (1,1). Positive X is right, positive Y is down and positive Z is into the screen. This means that if up in your mesh coordinate system coincides with the positive Y axis, it will appear upside down in the image. The **MR_default_params** function has an optional third argument which, if set true (default), applies a 180 degree rotation about the X axis to orient the mesh the right way up. If you use default parameters and find your mesh is upside down, pass false as the third parameter to **MR_default_params**.

## Limitations

Currently only supports point light source (local or distant), Blinn-Phong reflectance and scaled orthographic/perspective/perspective-with-distortion camera models. Since everything is written in pure matlab, it would be easy to modify the code to improve upon any of these.

## Normal map versus per vertex normals

If you don't specify anything about surface normals then the default is to compute per-vertex normals and use these. You can alternatively specify your own per-vertex normals or you can use a UV space normal map. The variable names are the same in either case so be careful to avoid confusion. 

### Per-vertex normals

If you specify **renderparams.normalMode = 'perVertexNormals'** then **renderparams.VN** should have size n x 3 (where n is not necessarily the same as the number of vertices) and contain surface normal vectors. **renderparams.FN** is a triangulation that indexes into **renderparams.VN** and could be the same as the mesh triangulation. 

### Normal mapping

If you specify **renderparams.normalMode = 'normalMap'** then **renderparams.VN** should have size n x 2 (where n is not necessarily the same as the number of vertices) and contain 2D UV coordinates. You must also supply a normal map **renderparams.normalmap** of size h x w x 3 containing the normal map in UV space. **renderparams.FN** is a triangulation that indexes into **renderparams.VN** and could be the same as the mesh triangulation or the texture coordinate triangulation.

## Mex files

Although written entirely in Matlab, it is still possible to compile to mex using Matlab's codegen for modest speed improvement. I have already done this for all key functions on Windows 64, Mac OS X and Linux. So, if you do not wish to edit the matlab source, you can safely use the mex files for faster performance. This option is chosen by setting renderparams.usemex = true (default). If you edit any of the functions with precompiled mex files, remember to recompile with codegen if you want to use renderparams.usemex = true with your edited version.

## Alternatives

There are already a number of off-screen Matlab renderers so you may wonder why I wrote another one. There are two reasons: 1. they don't support all the features I wanted, 2. they have dependencies or require compiling in a way that means it is not always possible to get them to work. MatlabRenderer should work in any recent version of matlab. The alternatives that I know of are:

1. https://uk.mathworks.com/matlabcentral/fileexchange/25071-matlab-offscreen-rendering-toolbox
2. https://talhassner.github.io/home/publication/2014_MVAP
