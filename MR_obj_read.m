function obj = MR_obj_read(filename)
%MR_OBJ_READ Read an obj file and return all elements as a structure
%
% Explanation of output structure:
%
% Always present:
%    obj.V - nverts x 3 matrix containing vertex positions
%    obj.F - nfaces x 3 matrix containing vertex IDs to form triangles
% Optional:
%    obj.VT - n x 2 matrix of texture coordinates
%    obj.VN - nverts x 2 matrix of per-vertex normals
%    
%
% Heavily based on code by BoffinBlogger:
% https://boffinblogger.blogspot.com/2015/05/faster-obj-file-reading-in-matlab.html

fid = fopen(filename);
if fid<0
    error(['Cannot open ' filename '.']);
end
[str, count] = fread(fid, [1,inf], 'uint8=>char'); 
fprintf('Read %d characters from %s\n', count, filename);
fclose(fid);

vertex_lines = regexp(str,'v [^\n]*\n', 'match');
vertex = zeros(length(vertex_lines), 3);
for i = 1: length(vertex_lines)
    v = sscanf(vertex_lines{i}, 'v %f %f %f');
    vertex(i, :) = v';
end
obj.V = vertex;

tex_lines = regexp(str,'vt [^\n]*\n', 'match');
tex = zeros(length(tex_lines), 2);
for i = 1:length(tex_lines)
    vt = sscanf(tex_lines{i}, 'vt %f %f');
    tex(i, :) = vt';
end
obj.VT = tex;

norm_lines = regexp(str,'vn [^\n]*\n', 'match');
norms = zeros(length(norm_lines), 3);
for i = 1:length(norm_lines)
    vn = sscanf(norm_lines{i}, 'vn %f %f %f');
    norms(i, :) = vn';
end
obj.VN = norms;

face_lines = regexp(str,'f [^\n]*\n', 'match');
faces = zeros(length(face_lines), 3);
normfaces = zeros(length(face_lines), 3);
texfaces = zeros(length(face_lines), 3);
normflag=false;
texflag=true;
for i = 1: length(face_lines)
    f = sscanf(face_lines{i}, 'f %d//%d %d//%d %d//%d');
    if (length(f) == 6) % face
        faces(i, :) = [f(1) f(3) f(5)];
        normflag=true;
        normfaces(i,:) = [f(2) f(4) f(6)];
        continue
    end
    f = sscanf(face_lines{i}, 'f %d %d %d');
    if (length(f) == 3) % face
        faces(i, :) = f';
        continue
    end
    f = sscanf(face_lines{i}, 'f %d/%d %d/%d %d/%d');
    if (length(f) == 6) % face
        faces(i, :) = [f(1) f(3) f(5)];
        texflag=true;
        texfaces(i,:) = [f(2) f(4) f(6)];
        continue
    end
    f = sscanf(face_lines{i}, 'f %d/%d/%d %d/%d/%d %d/%d/%d');
    if (length(f) == 9) % face
        faces(i, :) = [f(1) f(4) f(7)];
        texflag=true;
        texfaces(i,:) = [f(2) f(5) f(8)];
        normflag=true;
        normfaces(i,:) = [f(3) f(6) f(9)];
        continue
    end
end
obj.F = faces(:,1:3);
if normflag
    obj.FN = normfaces;
end
if texflag
    obj.FT = texfaces;
end