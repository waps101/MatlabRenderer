function [visibility] = MR_vertex_visibility(Vxy,Vz,zbuffer,fbuffer,F)
%MR_VERTEX_VISIBILITY Compute per vertex visibility
%
% Inputs:
%    Vxy     - nverts x 2 matrix of 2D vertex projections
%    Vz      - nverts x 1 vector of vertex depths (i.e. z values in camera 
%              coordinate system)
%    zbuffer - h x w matrix of depths
%    fbuffer - h x w matrix of triangle indices from zbuffering
%    F       - nfaces x 3 matrix of vertex indices, i.e. mesh triangulation
%
% Outputs:
%    visibility - nverts x 1 vector of booleans indicating vertex
%                 visibility
%
% William Smith
% University of York
%
% Part of the Matlab Renderer (https://github.com/waps101/MatlabRenderer)

Vz_buffer = interp2(zbuffer,Vxy(:,1),Vxy(:,2));

visibility  = false(size(Vxy,1),1);

% Visibility testing by finding all vertices of triangles that are in the
% face buffer after rasterisation
test = fbuffer ~= 0;
f = unique(fbuffer(test));
% These are definitely visible. 
visibility(unique([F(f,1); F(f,2); F(f,3)])) = true;

% Use them to automatically compute threshold for z buffer testing
diffs = abs(Vz(visibility)-Vz_buffer(visibility));
% Taking max is not robust enough
%t = max(diffs(~isinf(diffs)));
diffs = diffs(~isinf(diffs));
diffs = sort(diffs);
% Take 50th percentile as robust estimate of threshold (using max can
% sometimes give unreliable results)
t = diffs(round(0.5.*length(diffs)));

% Add vertices that are within threshold of interpolated z buffer value
visibility(abs(Vz-Vz_buffer)<t)=true;

end

