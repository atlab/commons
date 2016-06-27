function demoMeasureShift
% demonstrates how to use ne7.ip.measureShift

% Dimitri Yatsenko 2016-02-03

% generated the template
[y,x] = ndgrid(1:32, 1:20);
rng(1)
center = [10 14];
r = sqrt((x-center(1)).^2+(y-center(2)).^2);
template = cos(2*pi*r/4).*exp(-r.^2/200)/2 + randn(size(x))/10;

% generate offset image 
offset = [-3.5 0.2];
center = center + offset;
r = sqrt((x-center(1)).^2+(y-center(2)).^2);
frame = cos(2*pi*r/4).*exp(-r.^2/200)/2 + randn(size(x))/10;

% measure shift
tic
[xx,yy] = ne7.ip.measureShift(fft2(frame).*conj(fft2(template)));
t = toc;

% report results
subplot 141, imagesc(frame,[-1 1]), axis image, title frame
subplot 142, imagesc(template,[-1 1]), axis image, title template
shifted = interp2(frame,x+xx,y+yy,'cubic'); 
%shifted = ne7.ip.correctMotion(frame, [xx;yy]);
subplot 143, imagesc(shifted,[-1 1]), axis image, title 'shifted frame'
subplot 144, imagesc(shifted-template,[-1 1]), axis image, title difference
fprintf('Actual shift = (%1.2f, %1.2f).  Measured shift = (%1.2f, %1.2f)  Measure time %1.3f s\n', ...
    offset(1), offset(2), xx, yy, t)
end
