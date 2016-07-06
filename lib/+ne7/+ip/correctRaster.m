function img = correctRaster(img, rasterPhase, fillFraction)
% raster correction for resonant scanners.
% rasterPhase is the phase different between left-right and right-left scan
% lines.
%
% img size [x y nSlices nFrames].   2D, 3D, 4D images also work

assert(ndims(img)<=5)
sz = size(img);
ix = (-sz(2)/2+0.5:sz(2)/2-0.5)/(sz(2)/2);
tx = asin(ix*fillFraction);  % convert index to time
for iChannel = 1:sz(3)
    for iSlice = 1:sz(4)
        for iFrame = 1:sz(5)
            im = img(:,:,iChannel, iSlice, iFrame);
            extrapVal = mean(im(:));
            img(1:2:end, :, iChannel, iSlice, iFrame) = interp1(ix, im(1:2:end,:)', ...
                sin(tx'+rasterPhase)/fillFraction,'linear',extrapVal)';
            img(2:2:end, :, iChannel, iSlice, iFrame) = interp1(ix, im(2:2:end,:)', ...
                sin(tx'-rasterPhase)/fillFraction,'linear',extrapVal)';
        end
    end
end
end
