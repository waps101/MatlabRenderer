function [normals] = MR_vertex_normals(F,V) %#codegen
%VERTEX_NORMALS Compute vertex normals of mesh
%
% compile to mex with:
% codegen vertex_normals -args {coder.typeof(uint32(0),[inf 3],[1 0]) coder.typeof(0,[inf 3],[1 0])}

% Get the triangle vertices
v1 = F(:, 1);
v2 = F(:, 3);
v3 = F(:, 2);
% Compute the edge vectors
e1s = V(v2, :) - V(v1, :);
e2s = V(v3, :) - V(v1, :);
e3s = V(v2, :) - V(v3, :);

% Normalize the edge vectors
e1s_norm = e1s ./ repmat(sqrt(sum(e1s.^2, 2)), 1, 3);
e2s_norm = e2s ./ repmat(sqrt(sum(e2s.^2, 2)), 1, 3);
e3s_norm = e3s ./ repmat(sqrt(sum(e3s.^2, 2)), 1, 3);

% Compute the angles
angles = zeros([size(e1s_norm,1) 3]);
angles(:, 1) = acos(sum(e1s_norm .* e2s_norm, 2));
angles(:, 2) = acos(sum(e3s_norm .* e1s_norm, 2));
angles(:, 3) = pi - (angles(:, 1) + angles(:, 2));

% Compute the triangle weighted normals
triangle_normals    = cross(e1s, e3s, 2);
w1_triangle_normals = triangle_normals .* repmat(angles(:, 1), 1, 3);
w2_triangle_normals = triangle_normals .* repmat(angles(:, 2), 1, 3);
w3_triangle_normals = triangle_normals .* repmat(angles(:, 3), 1, 3);

% Initialize the vertex normals
normals = zeros(size(V, 1), 3);

% For each triangle
for i = 1: size(F, 1)
    % Update the vertex normals
    normals(v1(i), :) = normals(v1(i), :) + w1_triangle_normals(i, :);
    normals(v2(i), :) = normals(v2(i), :) + w2_triangle_normals(i, :);
    normals(v3(i), :) = normals(v3(i), :) + w3_triangle_normals(i, :);
end

% Normalize the vertex normals
normals = normals ./ repmat(sqrt(sum(normals.^2, 2)), 1, 3);

end

