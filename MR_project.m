function [Vxy,Vcam] = MR_project(V,cameraparams)
%MR_PROJECT Compute 3D to 2D projection via a camera model
%
% Inputs:
%    V            - nverts by 3 vertex positions in world coordinates
%    cameraparams - structure containing camera parameters as follows
%
% Require for all camera types:
%    cameraparams.T - 3x4 or 4x4 transformation from world to camera 
%                     coordinates
%
% If cameraparams.type = 'scaledorthographic'
%    cameraparams.scale - uniform scale factor
%
% If cameraparams.type = 'perspective'
%    cameraparams.f - focal length
%    cameraparams.cx, cameraparams.cy - centre of projection
%    
% If cameraparams.type = 'perspectiveWithDistortion'
%    As for perspective plus:
%    cameraparams.k1,k2,k3,p1,p2 - nonlinear distortion parameters
%
% Outputs:
%    Vxy  - nverts by 2 projected 2D vertex coordinates in pixels
%    Vcam - nverts by 3 vertex positions IN CAMERA COORDINATES
%
% William Smith
% University of York
%
% Part of the Matlab Renderer (https://github.com/waps101/MatlabRenderer)

% Compute the transformed vertices
V = [V ones([size(V,1) 1])];
Vcam = V * cameraparams.T(1:3,:).';	% the vertices are transposed

switch cameraparams.type
    case 'scaledorthographic'
        Vxy = Vcam(:,1:2).*cameraparams.scale;
    case 'perspective'
        % Intrinsic parameter matrix
        K = [cameraparams.f 0              cameraparams.cx; ...
             0              cameraparams.f cameraparams.cy; ...
             0              0              1];
        % Compute the projected vertices in the image plane
        V2 = Vcam * K.';            	% the vertices are transposed
        Vxy = zeros([size(V2,1) 2]);
        Vxy(:, 1)    = V2(:, 1) ./ V2(:, 3);	% perspective projection for x
        Vxy(:, 2)    = V2(:, 2) ./ V2(:, 3);	% perspective projection for y
    case 'perspectiveWithDistortion'
        x = Vcam(:, 1) ./ Vcam(:, 3);
        y = Vcam(:, 2) ./ Vcam(:, 3);
        r = sqrt(x.^2 + y.^2);
        xp = x.*(1 + cameraparams.k1.*r.^2 + cameraparams.k2.*r.^4 + cameraparams.k3.*r.^6) + (cameraparams.p1.*(r.^2+2.*x.^2) + 2.*cameraparams.p2.*x.*y);
        yp = y.*(1 + cameraparams.k1.*r.^2 + cameraparams.k2.*r.^4 + cameraparams.k3.*r.^6) + (cameraparams.p2.*(r.^2+2.*y.^2) + 2.*cameraparams.p1.*x.*y);
        Vxy = zeros([size(V,1) 2]);
        Vxy(:,1) = cameraparams.cx + xp.*cameraparams.f;
        Vxy(:,2) = cameraparams.cy + yp.*cameraparams.f;
    otherwise
        warning('Unexpected camera type.')

end

