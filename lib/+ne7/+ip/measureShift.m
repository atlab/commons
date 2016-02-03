function [x,y] = measureShift(fxcorr)
% Aligns images with subpixel precision
% Example: 
%    [x,y] = measureShift(fft2(img1), conj(fft2(img2)));

% Dimitri Yatsenko,  2016-01-07

sz = size(fxcorr);
assert(all(sz(3:end)==1), 'only 2D images are accepted')
assert(all(sz(1:2)>0 & mod(sz(1:2),2)==0), 'image must have even dimensions.')  % TODO: support odd 

% Step 1:  Shift by a whole number of pixels
xcorr = ifft2(fxcorr);
assert(all(isreal(xcorr(:))));
[~,i] = max(xcorr(:));
[y, x] = ind2sub(sz,i);
n = sz(1)/2;  y = mod(y+n, sz(1))-n-1; 
n = sz(2)/2;  x = mod(x+n, sz(2))-n-1; 

fy = (-sz(1)/2:sz(1)/2-1)/sz(1);
fx = (-sz(2)/2:sz(2)/2-1)/sz(2);

% apply whole-pixel shift
fxcorr = fxcorr.*fftshift(exp(2i*pi*fy'*y)*exp(2i*pi*fx*x));

% Step 2: measure the phase slope of all frequencies up to half Nyquist
phase = fftshift(angle(fxcorr));
mag   = fftshift(abs(fxcorr));
ix = abs(fx)<=0.25;
iy = abs(fy)<=0.25;
phase = phase(iy,ix);
mag = mag(iy,ix);
[fy, fx] = ndgrid(fy(iy), fx(ix));
phase_gain = [fy(:).*mag(:) fx(:).*mag(:)]\(phase(:).*mag(:));
y = y-phase_gain(1)/(2*pi);
x = x-phase_gain(2)/(2*pi);
end
