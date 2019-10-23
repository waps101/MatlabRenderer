function [buffer] = MR_compute_buffer_map(fbuffer,wbuffer,map,VM,FM,normalise) %#codegen
%MR_COMPUTE_BUFFER_MAP Summary of this function goes here
%
% Inputs:
%   VM            - nmapcoords by 2 map coordinates
%   FM            - nfaces by 3 triangle of vertex map indices
% compile to mex with:
% codegen MR_compute_buffer_map -args {coder.typeof(0,[inf inf],[1 1]) coder.typeof(0,[inf inf 3],[1 1 0]) coder.typeof(0,[inf inf 3],[1 1 0]) coder.typeof(0,[inf 2],[1 0]) coder.typeof(uint32(0),[inf 3],[1 0]) coder.typeof(true)}

buffer = NaN(size(fbuffer,1),size(fbuffer,2),3);

VM(:,1) = VM(:,1).*(size(map,2)-1)+1;
VM(:,2) = (1-VM(:,2)).*(size(map,1)-1)+1;

for row = 1:size(fbuffer,1)
    for col = 1:size(fbuffer,2)
        if fbuffer(row,col)~=0
            uv = ...
                VM(FM(fbuffer(row,col),1),:).*wbuffer(row,col,1) + ...
                VM(FM(fbuffer(row,col),2),:).*wbuffer(row,col,2) + ...
                VM(FM(fbuffer(row,col),3),:).*wbuffer(row,col,3);
            % Do bilinear interpolation into map, handling edge cases
            xceil = min(size(map,2),ceil(uv(1)));
            xfloor = max(1,floor(uv(1)));
            yceil = min(size(map,1),ceil(uv(2)));
            yfloor = max(1,floor(uv(2)));
            if xceil==xfloor
                % Handle vertex lying exactly on edge of square
                if yceil==yfloor
                    % Vertex lies exactly on two edges of square
                    buffer(row,col,:) = map(yfloor,xfloor,:);
                else
                    % Only interpolate in y
                    buffer(row,col,:) = (yceil-uv(2)).*map(yfloor,xfloor,:) + (uv(2)-yfloor).*map(yceil,xfloor,:);
                end
            elseif yceil==yfloor
                % Handle vertex lying exactly on edge of square
                % Only interpolate in x
                buffer(row,col,:) = (xceil-uv(1)).*map(yfloor,xfloor,:) + (uv(1)-xfloor).*map(yfloor,xceil,:);
            else
                % Standard case, do bilinear interpolation
                % First interpolate along x
                cyfloor = (xceil-uv(1)).*map(yfloor,xfloor,:) + (uv(1)-xfloor).*map(yfloor,xceil,:);
                cyceil = (xceil-uv(1)).*map(yceil,xfloor,:) + (uv(1)-xfloor).*map(yceil,xceil,:);
                % Then interpolate along y
                buffer(row,col,:) = (yceil-uv(2)).*cyfloor + (uv(2)-yfloor).*cyceil;
            end
            if normalise
                buffer(row,col,:) = buffer(row,col,:)./norm(squeeze(buffer(row,col,:)));
            end
        end
    end
end

end

