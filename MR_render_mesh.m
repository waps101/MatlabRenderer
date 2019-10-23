function [render,zbuffer,texbuffer,normalbuffer,viewbuffer,sourcebuffer,fbuffer,wbuffer,shadowbuffer,visibility] = MR_render_mesh(F,V,cameraparams,renderparams)
%MR_RENDER_MESH Deferred shading mesh renderer pipeline
%
% Note: if rendering multiple images from same viewpoint, the returned
% buffers can be passed directly to MR_render_buffers to avoid recomputing
% rasterisation etc
%
% Inputs:
%    F - nfaces by 3 matrix of vertex indices
%    V - nverts by 3 matrix of vertex coordinates
%    cameraparams - structure containing camera parameters (see
%                   MR_project.m for details)
%    renderparams - structure containing rendering parameters (see demo.m
%                   for details)
%
% Outputs:
%    render - rendered image
%    zbuffer - depth buffer
%    texbuffer,normalbuffer,viewbuffer,sourcebuffer - buffers used
%    for deferred shading
%    fbuffer,wbuffer - face and weight buffers used for barycentric
%    interpolation
%
% William Smith
% University of York
%
% Part of the Matlab Renderer (https://github.com/waps101/MatlabRenderer)

if ~isfield(renderparams,'verbose')
    renderparams.verbose = true;
end

if ~isfield(renderparams,'useMex')
    renderparams.useMex = true;
end

if ~isfield(renderparams,'textureMode')
    if renderparams.verbose
        disp('No texture mode set. Defaulting to per mesh, white colour.');
    end
    renderparams.textureMode = 'usePerMeshColour';
    renderparams.permeshcolour = [1 1 1];
end

if ~isfield(renderparams,'normalMode')
    if renderparams.verbose
        disp('No normal mapping mode set. Defaulting to per vertex normals.');
    end
    renderparams.normalMode = 'perVertexNormals';
end

if ~isfield(renderparams,'sourcecolour')
    if renderparams.verbose
        disp('No source colour set. Defaulting to white light.');
    end
    renderparams.sourcecolour = [1;1;1];
end

if ~isfield(renderparams,'shadows')
    if renderparams.verbose
        disp('No shadow mode set. Defaulting to no shadows.');
    end
    renderparams.shadows = false;
end

if renderparams.useMex
    F = uint32(F);
    if isfield(renderparams,'FT')
        renderparams.FT = uint32(renderparams.FT);
    end
    if isfield(renderparams,'FN')
        renderparams.FN = uint32(renderparams.FN);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform 3D to 2D projection
if renderparams.verbose
    disp('Projecting to 2D...');
end
[Vxy,Vcam] = MR_project(V,cameraparams);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rasterise mesh
if renderparams.verbose
    disp('Rasterising...');
end
if renderparams.useMex
    [zbuffer,fbuffer,wbuffer,Vz] = MR_rasterise_mesh_mex(F, Vcam, Vxy, cameraparams.w, cameraparams.h);
else
    [zbuffer,fbuffer,wbuffer,Vz] = MR_rasterise_mesh(F, Vcam, Vxy, cameraparams.w, cameraparams.h);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute shadow buffer
if renderparams.shadows
    if renderparams.verbose
        disp('Computing shadow buffer...');
    end
    switch renderparams.lightingModel
        case 'localPointSource'
            % Rasterise from light source position
            lightparams.type = 'perspective';
            lightparams.f = 1; lightparams.cx = 0; lightparams.cy = 0;
            axis = cross(renderparams.sourceposition,[0;0;-1]);
            axis = axis./norm(axis);
            angle = acos(dot(renderparams.sourceposition,[0;0;-1]));
            R = axang2rotm(axis.*angle);
            t = -R*renderparams.sourceposition;
            lightparams.T = [R t];
            
        case 'distantPointSource'
            lightparams.type = 'scaledorthographic';
            lightparams.scale = 1;
            axis = cross(renderparams.sourcedirection,[0;0;-1]);
            axis = axis./norm(axis);
            angle = acos(dot(renderparams.sourcedirection,[0;0;-1]));
            R = axang2rotm(axis.*angle);
            t = [0;0;0];
            lightparams.T = [R t];

        otherwise
            warning('Cannot compute shadows for selected lighting model.')
    end
    [Vxy_light,Vlight] = MR_project(V,lightparams);
    scale = cameraparams.w / max( max(Vxy_light(:,1))-min(Vxy_light(:,1)), max(Vxy_light(:,2))-min(Vxy_light(:,2)) );
    Vxy_light = Vxy_light.*scale;
    Vxy_light(:,1) = Vxy_light(:,1) - min(Vxy_light(:,1));
    Vxy_light(:,2) = Vxy_light(:,2) - min(Vxy_light(:,2));
    if renderparams.useMex
        [zbuffer_light,fbuffer_light,~,Vz_light] = MR_rasterise_mesh_mex(F, Vlight, Vxy_light, cameraparams.w, cameraparams.h);
    else
        [zbuffer_light,fbuffer_light,~,Vz_light] = MR_rasterise_mesh(F, Vlight, Vxy_light, cameraparams.w, cameraparams.h);
    end
    shadowPerVertex = MR_vertex_visibility(Vxy_light,Vz_light,zbuffer_light,fbuffer_light,F);
    if renderparams.useMex
        shadowbuffer = MR_compute_buffer_per_vertex_mex(fbuffer,wbuffer,F,double(shadowPerVertex),false);
    else
        shadowbuffer = MR_compute_buffer_per_vertex(fbuffer,wbuffer,F,double(shadowPerVertex),false);
    end
else
    shadowbuffer = ones(size(fbuffer));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute view vector buffer
if renderparams.verbose
    disp('Computing view vector buffer...');
end
switch cameraparams.type
    case 'scaledorthographic'
        v = cameraparams.T(1:3,1:3)'*[0;0;1];
        viewbuffer = zeros(size(wbuffer));
        viewbuffer(:,:,1) = v(1);
        viewbuffer(:,:,2) = v(2);
        viewbuffer(:,:,3) = v(3);
    case 'perspective'
        % Compute camera centre
        c = -cameraparams.T(1:3,1:3)'*cameraparams.T(1:3,4);
        % Compute per-vertex view vectors
        Views(:,1) = c(1)-V(:,1);
        Views(:,2) = c(2)-V(:,2);
        Views(:,3) = c(3)-V(:,3);
        % Rasterise
        if renderparams.useMex
            viewbuffer = MR_compute_buffer_per_vertex_mex(fbuffer,wbuffer,F,Views,true);
        else
            viewbuffer = MR_compute_buffer_per_vertex(fbuffer,wbuffer,F,Views,true);
        end
    case 'perspectiveWithDistortion'
        % Compute camera centre
        c = -cameraparams.T(1:3,1:3)'*cameraparams.T(1:3,4);
        % Compute per-vertex view vectors
        Views(:,1) = c(1)-V(:,1);
        Views(:,2) = c(2)-V(:,2);
        Views(:,3) = c(3)-V(:,3);
        % Rasterise
        if renderparams.useMex
            viewbuffer = MR_compute_buffer_per_vertex_mex(fbuffer,wbuffer,F,Views,true);
        else
            viewbuffer = MR_compute_buffer_per_vertex(fbuffer,wbuffer,F,Views,true);
        end
    otherwise
        warning('Unexpected camera type.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute texture buffer
if renderparams.verbose
    disp('Computing texture buffer...');
end
switch renderparams.textureMode
    case 'useTextureMap'
        % Compute texture buffer from texture map
        if renderparams.useMex
            texbuffer = MR_compute_buffer_map_mex(fbuffer,wbuffer,renderparams.texmap,renderparams.VT,renderparams.FT,false);
        else
            texbuffer = MR_compute_buffer_map(fbuffer,wbuffer,renderparams.texmap,renderparams.VT,renderparams.FT,false);
        end
    case 'usePerVertexColours'
        % Compute texture buffer from per-vertex colours
        if renderparams.useMex
            texbuffer = MR_compute_buffer_per_vertex_mex(fbuffer,wbuffer,F,renderparams.pervertexcolour,false);
        else
            texbuffer = MR_compute_buffer_per_vertex(fbuffer,wbuffer,F,renderparams.pervertexcolour,false);
        end
    case 'usePerMeshColour'
        % Assign a constant colour for the whole texture buffer
        texbuffer = zeros(size(wbuffer));
        mask = repmat(isinf(zbuffer),[1 1 3]);
        for c=1:3
            texbuffer(:,:,c) = renderparams.permeshcolour(c);
        end
        texbuffer(mask) = NaN;
    otherwise
        error('Unsupported texturing mode');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute normal map buffer
if renderparams.verbose
    disp('Computing normal map buffer...');
end
switch renderparams.normalMode
    case 'normalMap'
        if renderparams.useMex
            normalbuffer = MR_compute_buffer_map_mex(fbuffer,wbuffer,renderparams.normalmap,renderparams.VN,renderparams.FN,true);
        else
            normalbuffer = MR_compute_buffer_map(fbuffer,wbuffer,renderparams.normalmap,renderparams.VN,renderparams.FN,true);
        end
    case 'perVertexNormals'
        % Note: vertex normals are in world coordinates
        if ~isfield(renderparams,'VN')
            if renderparams.verbose
                disp('Computing per vertex normals (none supplied)...');
            end
            renderparams.VN = MR_vertex_normals(F,V);
        end
        % Option to use a different triangulation of the per vertex normals
        % than the mesh triangulation. If not specified, default to using
        % same triangulation as mesh.
        if ~isfield(renderparams,'FN')
            renderparams.FN = F;
        else
            renderparams.FN = uint32(renderparams.FN);
        end
        if renderparams.useMex
            normalbuffer = MR_compute_buffer_per_vertex_mex(fbuffer,wbuffer,renderparams.FN,renderparams.VN,true);
        else
            normalbuffer = MR_compute_buffer_per_vertex(fbuffer,wbuffer,renderparams.FN,renderparams.VN,true);
        end
    otherwise
        error('Unsupported normal mapping mode');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute source buffer
if renderparams.verbose
    disp('Computing light source buffer...');
end
switch renderparams.lightingModel
    case 'localPointSource'
        S(:,1) = renderparams.sourceposition(1)-V(:,1);
        S(:,2) = renderparams.sourceposition(2)-V(:,2);
        S(:,3) = renderparams.sourceposition(3)-V(:,3);
        if renderparams.useMex
            sourcebuffer = MR_compute_buffer_per_vertex_mex(fbuffer,wbuffer,F,S,true);
        else
            sourcebuffer = MR_compute_buffer_per_vertex(fbuffer,wbuffer,F,S,true);
        end
    case 'distantPointSource'
        sourcebuffer = zeros(size(wbuffer));
        renderparams.sourcedirection = renderparams.sourcedirection./norm(renderparams.sourcedirection);
        for c=1:3
            sourcebuffer(:,:,c) = renderparams.sourcedirection(c);
        end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Render buffers
if renderparams.verbose
    disp('Rendering buffers...');
end
if renderparams.useMex
    render = MR_render_buffers_mex(texbuffer,normalbuffer,viewbuffer,sourcebuffer,shadowbuffer,renderparams.shininess,renderparams.backfacelighting,renderparams.ka,renderparams.kd,renderparams.ks,renderparams.sourcecolour);
else
    render = MR_render_buffers(texbuffer,normalbuffer,viewbuffer,sourcebuffer,shadowbuffer,renderparams.shininess,renderparams.backfacelighting,renderparams.ka,renderparams.kd,renderparams.ks,renderparams.sourcecolour);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Render buffers
if renderparams.verbose
    disp('Computing per-vertex visibility...');
end
visibility = MR_vertex_visibility(Vxy,Vz,zbuffer,fbuffer,F);

end

