# MatlabRenderer

MatlabRenderer is an offscreen renderer written entirely in pure Matlab with no dependencies. It is based on deferred shading, so provides a rasteriser based on z-buffering. It supports texture/normal mapping, shadowing, visibility and orthographic/perspective/perspective+distortion camera models.

## Basic usage

```matlab
obj = MR_obj_read('data/StanfordBunny.obj');
[cameraparams,renderparams] = MR_default_params(obj.V,400);
render = MR_render_mesh(obj.F,obj.V,cameraparams,renderparams);
figure; imshow(render)
```

This will render the Stanford bunny with some default camera and rendering parameters. For UV texture mapping, insert the following before the call to **MR_render_mesh**:

```matlab
renderparams.VT = obj.VT;
renderparams.FT = obj.FT;
renderparams.textureMode = 'useTextureMap';
renderparams.texmap = im2double(imread('data/StanfordBunny.jpg'));
```

## Overview

**MR_rasterise_mesh** does the bulk of the work. This function performs z-buffering on the projected mesh and returns a face buffer (triangle index per pixel) and a weight buffer (barycentric weight for three triangle vertices per pixel). From these two buffers, any per-vertex or UV space quantity can be interpolated to produce a screen space value. This is exactly what **MR_compute_buffer_per_vertex** does (for per-vertex quantities) and **MR_compute_buffer_map** does (for UV mapped quantities).

The function **MR_render_mesh** is essentially a wrapper to all of the underlying functions, executing the full rendering pipeline. You may want to edit aspects of this, for example to handle multiple light sources. If you want to introduce alternate reflectance models, you should edit **MR_render_buffers**.

## Mex files

Although written entirely in Matlab, it is still possible to compile to mex using Matlab's codegen for modest speed improvement. I have already done this for all key functions on Windows 64, Mac OS X and Linux. So, if you do not wish to edit the matlab source, you can safely use the mex files for faster performance. This option is chosen by setting renderparams.usemex = true. If you edit any of the functions with precompiled mex files, remember to recompile with codegen if you want to use renderparams.usemex = true with your edited version.

## Alternatives

There are already a number of off-screen Matlab renderers so you may wonder why I wrote another one. There are two reasons: 1. they don't support all the features I wanted, 2. they have dependencies or require compiling in a way that means it is not always possible to get them to work. MatlabRenderer should work in any recent version of matlab. The alternatives that I know of are:

1. https://uk.mathworks.com/matlabcentral/fileexchange/25071-matlab-offscreen-rendering-toolbox
2. https://talhassner.github.io/home/publication/2014_MVAP
