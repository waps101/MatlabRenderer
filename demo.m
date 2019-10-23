%% Load the Stanford Bunny mesh

obj = MR_obj_read('data/StanfordBunny.obj');

%% Setup some default camera parameters and render

[cameraparams,renderparams] = MR_default_params(obj.V,400);

render = MR_render_mesh(obj.F,obj.V,cameraparams,renderparams);

figure; imshow(render)

%% More advanced: load a texture map and use per-vertex normals from obj

[cameraparams,renderparams] = MR_default_params(obj.V,400);

renderparams.VT = obj.VT;
renderparams.FT = obj.FT;
renderparams.VN = obj.VN;
renderparams.FN = obj.FN;
renderparams.textureMode = 'useTextureMap';
renderparams.texmap = im2double(imread('data/StanfordBunny.jpg'));

tic;
render = MR_render_mesh(obj.F,obj.V,cameraparams,renderparams);
toc

figure; imshow(render)

%% View the zbuffer and foreground mask

[cameraparams,renderparams] = MR_default_params(obj.V,400);

[~,zbuffer] = MR_render_mesh(obj.F,obj.V,cameraparams,renderparams);

figure; imshow(zbuffer,[]);

foregroundmask = ~isinf(zbuffer);

figure; imshow(foregroundmask);

%% Modify camera parameters to perspective with distortion

[cameraparams,renderparams] = MR_default_params(obj.V,400);

cameraparams.type = 'perspectiveWithDistortion';
cameraparams.k1 = 10;
cameraparams.k2 = 2000;
cameraparams.k3 = 200;
cameraparams.p1 = 0;
cameraparams.p2 = 0;
cameraparams.f = cameraparams.f.*0.6;
render = MR_render_mesh(obj.F,obj.V,cameraparams,renderparams);

figure; imshow(render)

%% Modify some rendering parameters, switch on shadows

[cameraparams,renderparams] = MR_default_params(obj.V,400);

% Set the light source colour to white
renderparams.sourcecolour = [1;1;1];
% Switch to a distant point source coming from slightly right and above
renderparams.lightingModel = 'distantPointSource';
renderparams.sourcedirection = [-1 1 0];
% Make the surface shinier
renderparams.shininess = 100;
renderparams.ka = 0;
renderparams.kd = 0.8;
renderparams.ks = 0.8;
% Use a single colour for the whole mesh
renderparams.textureMode = 'usePerMeshColour';
renderparams.permeshcolour = [1;0.5;0.5];
% Don't light backfaces
renderparams.backfacelighting = 'unlit';
% Switch on shadow mapping
renderparams.shadows = true;

[render,zbuffer,texbuffer,normalbuffer,viewbuffer,sourcebuffer,fbuffer,wbuffer,shadowbuffer,visibility] = MR_render_mesh(obj.F,obj.V,cameraparams,renderparams);

figure; imshow(render)