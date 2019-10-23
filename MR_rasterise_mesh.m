function [zbuffer,fbuffer,wbuffer,Vz] = MR_rasterise_mesh(F, Vcam, Vxy, width, height) %#codegen
%RASTERISE_MESH Run z-buffer algorithm on mesh, return buffers
%
% This is a pure matlab implementation of a z-buffer rasteriser. It takes a
% mesh and camera intrinsics/extrinsics as input and returns the contents
% of the depth, face and weight buffers along with per-vertex visibility.
%
% Inputs:
%   F             - nfaces by 3 triangle vertex indices
%   Vcam          - nverts by 3 vertex positions IN CAMERA COORDINATES
%   Vxy           - nverts by 2 projected 2D vertex coordinates in pixels
%   width, height - scalar width and height of output image
%
% Outputs:
%   zbuffer       - height by width matrix containing depth values or -inf
%   fbuffer       - height by width matrix containing face indices of
%                   closest face or 0
%   wbuffer       - height by width by 3 interpolation weights for three
%                   vertices in closest face or 0
%   Vz            - nverts by 1 vector containing vertex depths
%   E.g. if pixel (r,c) is covered by a triangle, then fbuffer(r,c) is the
%   index of the triangle and wbuffer(r,c,:) are the three weights for
%   vertices F(fbuffer(r,c),:) that can be used for interpolation shading
%
%   Written by Arnaud Dessein and William Smith
%   University of York.
%
% Part of the Matlab Renderer (https://github.com/waps101/MatlabRenderer)

% compile to mex with:
% codegen MR_rasterise_mesh -args {coder.typeof(uint32(0),[inf 3],[1 0]) coder.typeof(0,[inf 3],[1 0]) coder.typeof(0,[inf 2],[1 0]) coder.typeof(0) coder.typeof(0)}

% Get the triangle vertices
v1 = F(:, 1);
v2 = F(:, 2);
v3 = F(:, 3);

% Store the vertex depths for z-buffering
Vz = Vcam(:, 3);

% Construct the pixel grid
[rows, cols] = meshgrid(0: width + 1, 0: height + 1); % pad to avoid boundary problems when interpolating

% Compute bounding boxes for the projected triangles
x       = [Vxy(v1, 1) Vxy(v2, 1) Vxy(v3, 1)];
y       = [Vxy(v1, 2) Vxy(v2, 2) Vxy(v3, 2)];
minx    = max(0,            ceil (min(x, [], 2)));
maxx    = min(width + 1,    floor(max(x, [], 2)));
miny    = max(0,            ceil (min(y, [], 2)));
maxy    = min(height + 1,   floor(max(y, [], 2)));

% Initialize the depth-, face- and weight-buffers
zbuffer = inf(height + 2, width + 2); % pad to avoid boundary problems when interpolating
fbuffer = zeros(height + 2, width + 2);
wbuffer = zeros(height + 2, width + 2, 3);

for i = 1: size(F, 1)
    % If some pixels lie in the bounding box
    if minx(i) <= maxx(i) && miny(i) <= maxy(i)
    
        % Get the pixels lying in the bounding box
        px = rows(miny(i) + 1: maxy(i) + 1, minx(i) + 1: maxx(i) + 1);
        py = cols(miny(i) + 1: maxy(i) + 1, minx(i) + 1: maxx(i) + 1);
        px = px(:);
        py = py(:);
        
        % Compute the edge vectors
        e0 = Vxy(v1(i), :);
        e1 = Vxy(v2(i), :) - e0;
        e2 = Vxy(v3(i), :) - e0;
        
        % Compute the barycentric coordinates (can speed up by first computing and testing a solely)
        det     = e1(1) * e2(2) - e1(2) * e2(1);
        tmpx    = px - e0(1);
        tmpy    = py - e0(2);
        a       = (tmpx * e2(2) - tmpy * e2(1)) / det;
        b       = (tmpy * e1(1) - tmpx * e1(2)) / det;
        
        % Test whether the pixels lie in the triangle
        test = a >= 0 & b >= 0 & a + b <= 1;
        
        % If some pixels lie in the triangle
        if any(test)
        
            % Get the pixels lying in the triangle
            px = px(test);
            py = py(test);
            
            % Interpolate the triangle depth for each pixel
            w2 = a(test);
            w3 = b(test);
            w1 = 1 - w2 - w3;
            pz = Vz(v1(i)) * w1 + Vz(v2(i)) * w2 + Vz(v3(i)) * w3;
                        
            % Update the depth-, face- and weight-buffers
            for j = 1: length(pz)
                if pz(j) < zbuffer(py(j) + 1, px(j) + 1)
                    zbuffer(py(j) + 1, px(j) + 1)       = pz(j);
                    fbuffer(py(j) + 1, px(j) + 1)       = i;
                    wbuffer(py(j) + 1, px(j) + 1 , 1)   = w1(j);
                    wbuffer(py(j) + 1, px(j) + 1 , 2)   = w2(j);
                    wbuffer(py(j) + 1, px(j) + 1 , 3)   = w3(j);
                end
            end
        
        end
    
    end
    
end

% Remove boundary padding
fbuffer = fbuffer(2: height + 1, 2: width + 1);
wbuffer = wbuffer(2: height + 1, 2: width + 1, :);
zbuffer = zbuffer(2: height + 1, 2: width + 1);