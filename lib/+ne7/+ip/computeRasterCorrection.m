function rasterPhase = computeRasterCorrection(img, fillFraction)
% compute raster correction for resonant scanners

k = hamming(7); k = k/sum(k);
odd   = imfilter(img(1:2:end,:), k,'symmetric');
even  = imfilter(img(2:2:end,:), k,'symmetric');
odd  =  odd(4:end-3,:);
even = even(4:end-3,:);
odd = odd - mean(odd(:));
odd = odd / sqrt(sum(odd(:).^2));
even = even - mean(even(:));
even = even / sqrt(sum(even(:).^2));
sz = size(odd);
ix = (-sz(2)/2+0.5:sz(2)/2-0.5)/(sz(2)/2);
tx = asin(ix*fillFraction);  % convert index to time
odd = odd';
even = even';

rasterPhase = 0;
step = 0.02;
while step>1e-4
    phases = rasterPhase + step*[-0.5 -0.25 -0.1 0.1 0.25 0.5]*fillFraction;
    c= nan(size(phases));
    for iPhase = 1:length(phases);
        odd_  = interp1(ix,  odd, sin(tx'+phases(iPhase))/fillFraction,'linear');
        even_ = interp1(ix, even, sin(tx'-phases(iPhase))/fillFraction,'linear');
        c(iPhase) = sum(sum(odd_(18:end-17,:).*even_(18:end-17,:)));
    end
    p = polyfit(phases,c,2);
    rasterPhase = max(phases(1),min(phases(end),-p(2)/2/p(1)));
    assert(abs(rasterPhase)<0.02, 'weird raster correction')
    step = step/4;
end
end



