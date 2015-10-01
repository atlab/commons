function [x,y] = measureShift(ixcorr)
% measure the shift of img relative to refImg from xcorr = fft2(img).*conj(fft2(refImg))
sz = size(ixcorr);
assert(length(sz)==2 && all(sz(1:2)>=128 & mod(sz(1:2),2)==0), ...
    'image must have even height and width, at least 128 in size')

phase = fftshift(angle(ixcorr));
mag   = fftshift(abs(ixcorr));
center = sz/2+1;
phaseSlope = [0 0];
for r=[10 15 20]
    [x,y] = meshgrid(-r:r,-r:r);
    plane  = phaseSlope(1)*x + phaseSlope(2)*y;
    phase_ = mod(pi + phase(center(1)+(-r:r),center(2)+(-r:r)) - plane, 2*pi) - pi + plane;
    mag_ = mag(center(1)+(-r:r),center(2)+(-r:r));
    mdl = LinearModel.fit([x(:) y(:)], phase_(:), 'Weights', mag_(:));
    phaseSlope = mdl.Coefficients.Estimate(2:3)';
end
x = -phaseSlope(1)*sz(2)/(2*pi);
y = -phaseSlope(2)*sz(1)/(2*pi);
end
