function img = correctRaster(img, rasterPhase, fillFraction)
% raster correction for resonant scanners.
% rasterPhase is the phase different between left-right and right-left scan
% lines.
%
% img size [x y nChannel nSlices nFrames].   2D, 3D, 4D, 5D images also work

assert(ndims(img)<=5)
ix = (-size(img, 2)/2+0.5:size(img, 2)/2-0.5)/(size(img, 2)/2);
tx = asin(ix*fillFraction);  % convert index to time
for iChannel = 1:size(img, 3)
    for iSlice = 1:size(img, 4)
        for iFrame = 1:size(img, 5)
            im = img(:,:, iChannel, iSlice, iFrame);
            extrapVal = mean(im(:));
            img(1:2:end, :, iChannel, iSlice, iFrame) = interp1(ix, im(1:2:end,:)', ...
                sin(tx'+rasterPhase)/fillFraction,'linear',extrapVal)';
            img(2:2:end, :, iChannel, iSlice, iFrame) = interp1(ix, im(2:2:end,:)', ...
                sin(tx'-rasterPhase)/fillFraction,'linear',extrapVal)';
        end
    end
end
end
