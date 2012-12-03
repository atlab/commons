function regions = segmentCells3D(stack, voxelDims, cellRadius, contrast, debug)
% segmentation of spherical bright blobs (cells) in a 3D image stack
%
% INPUTS:
%   stack      - a 3D stack of images
%   voxelDims  - y,x,z voxel dimensions in real-world units
%   cellRadius - the presumed radius of a cell in real-world units
%   contrast   - the depth of clefts separating cells
%   debug      - if true, display intermediate results

debug = nargin>=4 && debug;
sz = size(stack);

disp segmenting..

% smooth a little (not generally necessary)
%sigma = 0.1*cellRadius./voxelDims;
%stack = smoothStack(stack, sigma);

% isolate domes
m = stack - imreconstruct(stack-contrast,stack);

% compute distance to dome boundaries
d = bwdist3d(m<0.1*contrast,voxelDims(3)/voxelDims(1));

% smooth the distance to avoid false ridges
sigma = 0.5*cellRadius./voxelDims;
d = smoothStack(d, sigma);

% watershed to detect objects
w = watershed(-d, 26);

if debug
    figure
    iSlice = 3;
        
    subplot 121
    h = imagesc(stack(:,:,iSlice));
    set(h,'AlphaData',(w(:,:,iSlice)~=0)*.3+.7);
    grid on, colormap gray, axis image
end

disp 'shape analysis...'
regions = regionprops(w, stack, ...
    'PixelValues', 'PixelIdxList','Area', 'Image','MaxIntensity', 'BoundingBox');

% discard regions that are too small
cellVolume = pi*cellRadius^3/prod(voxelDims);
regions = regions([regions.Area]>cellVolume);

if debug
    % sort by intensity
    [~,ix] = sort([regions.MaxIntensity], 'descend');
    regions = regions(ix);
end

% analysis of individual regions
result = zeros(sz,'uint16');

iCount = 0;
for i=1:length(regions)
    reg = regions(i);
    % select brightest pixels corresponding to the volume of the cell
    thresh = quantile(reg.PixelValues, 1-cellVolume/length(reg.PixelValues));
    ix = reg.PixelValues > thresh;
    % compute their spatial compactness
    w = reg.PixelValues(ix);
    w = w/sum(w);
    [y,x,z] = ind2sub(sz, reg.PixelIdxList(ix));
    yxz = bsxfun(@times, [y x z], voxelDims);
    c = w'*yxz;  % centroid
    d = svds(bsxfun(@minus, yxz, c));  % singular values
    if debug
        D(i,:) = [d(1) d(1)/d(3)];
    end
    if d(1)/d(3)<2.5
        iCount = iCount + 1;
        result(reg.PixelIdxList(ix))=iCount;
    end
end

if debug
    subplot 122
    imagesc(stack(:,:,iSlice));
    grid on, colormap gray, axis image
    hold on
    b = bwboundaries(result(:,:,iSlice)~=0);
    for i=1:length(b)
        boundary = b{i};
        plot(boundary(:,2), boundary(:,1), 'r');
    end
    hold off 
end

end


function d = bwdist3d(bw, zstep)
% same as bwdist but the third dimension is assumed to be scaled
% differently than x and y. zstep is expressed as fraction of x-step or
% y-step. The distance is euclidean

d = nan(size(bw));
for i=1:size(bw,3)
    d(:,:,i) = bwdist(bw(:,:,i),'euclidean');
end

for i=1:size(bw,3)
    a = min(d(:,:,max(1,i-1)), d(:,:,min(end,i+1)));
    d(:,:,i) = min(d(:,:,i), sqrt(zstep.^2+a.^2));
end
end



function stack = smoothStack(stack, sigmas)
k = hamming(round(sigmas(1))*2+1);
k = k/sum(k);
stack = imfilter(stack, k, 'symmetric');

k = hamming(round(sigmas(2))*2+1);
k = k/sum(k);
stack = imfilter(stack, k', 'symmetric');

k = hamming(round(sigmas(3))*2+1);
k = k/sum(k);
stack = imfilter(stack, reshape(k,1,1,[]));

end