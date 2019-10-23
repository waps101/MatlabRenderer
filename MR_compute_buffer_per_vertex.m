function [buffer] = MR_compute_buffer_per_vertex(fbuffer,wbuffer,F,vals,normalise) %#codegen
%MR_COMPUTE_BUFFER_PER_VERTEX Transform per-vertex quantity into a buffer
%
%
%   Written by William Smith
%   University of York.
%
% compile to mex with:
% codegen MR_compute_buffer_per_vertex -args {coder.typeof(0,[inf inf],[1 1]) coder.typeof(0,[inf inf 3],[1 1 0]) coder.typeof(uint32(0),[inf 3],[1 0]) coder.typeof(0,[inf inf],[1 1]) coder.typeof(true)}

buffer = NaN(size(fbuffer,1),size(fbuffer,2),size(vals,2));
for row = 1:size(fbuffer,1)
    for col = 1:size(fbuffer,2)
        if fbuffer(row,col)~=0
            buffer(row,col,:) = ...
                vals(F(fbuffer(row,col),1),:).*wbuffer(row,col,1) + ...
                vals(F(fbuffer(row,col),2),:).*wbuffer(row,col,2) + ...
                vals(F(fbuffer(row,col),3),:).*wbuffer(row,col,3);
            if normalise
                buffer(row,col,:) = buffer(row,col,:)./norm(squeeze(buffer(row,col,:)));
            end
        end
    end
end

end

