function [cameraparams,renderparams] = MR_default_params(V,width,flip)
%MR_DEFAULT_PARAMS Create some default parameters for basic rendering
%
% Returns camera and rendering parameters to give a basic rendering of a
% mesh. The camera is perspective, with the image centred on the centre of
% mass of the mesh. The camera-object distance is 3x the diagonal length of
% the bounding box.
%
%   Inputs:
%      V     - nverts x 3 matrix containing mesh vertices
%      width - desired width of rendered image
%      flip  - (Default = true) determines whether a 180 degree rotation
%              about the x axis is applied (required if y is up in your
%              model)
%   Outputs:
%      cameraparams,renderparams - structures that can be passed to
%                                  MR_render_mesh
%
% William Smith
% University of York
%
% Part of the Matlab Renderer (https://github.com/waps101/MatlabRenderer)

if nargin==2
    flip=true;
end

% Diagonal size of bounding box
diagsize = norm(min(V,[],1)-max(V,[],1));

if flip
    R = rotz(180)*roty(180);
else
    R = eye(3);
end

T = [eye(3) [0;0;3.*diagsize]; 0 0 0 1]*[R zeros(3,1); 0 0 0 1]*[eye(3) -0.5.*(min(V,[],1)+max(V,[],1))'; 0 0 0 1];

cameraparams.type = 'perspective';
cameraparams.cx = 0;
cameraparams.cy = 0;
cameraparams.f = 1;
cameraparams.T = T;

[Vxy,~] = MR_project(V,cameraparams);

width2d = 2.*max(max(Vxy(:,1)),abs(min(Vxy(:,1))));
height2d = 2.*max(max(Vxy(:,2)),abs(min(Vxy(:,2))));
cameraparams.f = width/width2d;

aspect = height2d/width2d;

cameraparams.w = width;
cameraparams.h = ceil(width*aspect);
cameraparams.cx = cameraparams.w/2;
cameraparams.cy = cameraparams.h/2;

renderparams.lightingModel = 'localPointSource';
renderparams.shininess = 40;
renderparams.backfacelighting = 'unlit';
renderparams.ka = 0;
renderparams.kd = 0.9;
renderparams.ks = 0.3;
renderparams.textureMode = 'usePerMeshColour';
renderparams.permeshcolour = [0;0;1];
renderparams.sourceposition = -T(1:3,1:3)'*T(1:3,4); % Position light at camera
%renderparams.sourceposition = roty(-90)*(T(1:3,1:3)'*T(1:3,4))-(T(1:3,1:3)'*T(1:3,4)); % position light right of camera
renderparams.sourcecolour = [1; 1; 1];
renderparams.shadows = false;

end

