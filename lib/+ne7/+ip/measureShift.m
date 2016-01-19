function [x,y] = measureShift(fxcorr)
% Aligns images with subpixel precision
% Example: 
%    [x,y] = measureShift(fft2(img1), conj(fft2(img2)));

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



function demo()
[y,x] = ndgrid(1:32, 1:20);
rng(1)
center = [10 14];
r = sqrt((x-center(1)).^2+(y-center(2)).^2);
template = cos(2*pi*r/4).*exp(-r.^2/200)/2 + randn(size(x))/10;
offset = [-3.5 0.2];
center = center + offset;
r = sqrt((x-center(1)).^2+(y-center(2)).^2);
frame = cos(2*pi*r/4).*exp(-r.^2/200)/2 + randn(size(x))/10;

[xx,yy] = ne7.ip.measureShift(fft2(frame).*conj(fft2(template)));

subplot 141, imagesc(frame,[-1 1]), axis image, title frame
subplot 142, imagesc(template,[-1 1]), axis image, title template
shifted = interp2(frame,x+xx,y+yy,'cubic'); 
%shifted = ne7.ip.correctMotion(frame, [xx;yy]);
subplot 143, imagesc(shifted,[-1 1]), axis image, title 'shifted frame'
subplot 144, imagesc(shifted-template,[-1 1]), axis image, title difference

end