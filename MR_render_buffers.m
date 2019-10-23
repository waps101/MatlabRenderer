function render = MR_render_buffers(texbuffer,normalbuffer,viewbuffer,sourcebuffer,shadowbuffer,shininess,backfacelighting,ka,kd,ks,sourcecolour) %#codegen
%MR_RENDER_BUFFERS Perform deferred shading
%
% Uses screen space buffers (texture, normal, view, source) and performs
% deferred shading rendering. Only supports Blinn-Phong reflectance and
% point source illumination.
%
% William Smith
% University of York
%
% Part of the Matlab Renderer (https://github.com/waps101/MatlabRenderer)
%
% compile to mex with:
% codegen MR_render_buffers -args {coder.typeof(0,[inf inf 3],[1 1 0]) coder.typeof(0,[inf inf 3],[1 1 0]) coder.typeof(0,[inf inf 3],[1 1 0]) coder.typeof(0,[inf inf 3],[1 1 0]) coder.typeof(0,[inf inf],[1 1]) coder.typeof(0) coder.typeof('A',[1 inf],[0 1]) coder.typeof(0) coder.typeof(0) coder.typeof(0) coder.typeof(0,[3 1])}


render = NaN(size(texbuffer));

for row=1:size(texbuffer,1)
    for col=1:size(texbuffer,2)
        if ~isnan(texbuffer(row,col,1))
            n = squeeze(normalbuffer(row,col,:));
            v = squeeze(viewbuffer(row,col,:));
            s = squeeze(sourcebuffer(row,col,:));
            h = v+s;
            h = h./norm(h);
            diffuseshading = dot(n,s);
            specularshading = dot(n,h);
            switch backfacelighting
                case 'lit'
                    diffuseshading = abs(diffuseshading);
                    specularshading = abs(specularshading);
                case 'unlit'
                    diffuseshading = max(0,diffuseshading);
                    specularshading = max(0,specularshading);
            end
            render(row,col,:) = shadowbuffer(row,col) .* sourcecolour .* (ka.*squeeze(texbuffer(row,col,:)) + kd.*squeeze(texbuffer(row,col,:)).*diffuseshading + ks.*specularshading.^shininess);
        end
    end
end

end

