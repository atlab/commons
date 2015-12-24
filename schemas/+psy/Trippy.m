function trippy
sz = [75 128]; % movie frame size
fps = 60;
nframes = 30*60;
n = [8 12]; % number of nodes in each dimension
f = 12; % upscale factor
max_spatial_freq = 1.2*f;   % TODO: map units to 1/degree
tempKernel = hanning(61);  % regulates rate of pattern change
speed = 4;  % Hz - rate of motion for constant pattern

k = length(tempKernel);
assert(k>=3 && mod(k,2)==1)
assert(all(f*n>=sz))

k2 = ceil(k/4);
tempKernel = k2/sum(tempKernel)*tempKernel;
phase = rand(ceil((nframes+k-1)/k2),prod(n));   % cache this

tic
phase = upsample(phase, k2);
phase=conv2(phase,tempKernel,'valid');  % lowpass in time
phase = phase(1:nframes,:);
phase=bsxfun(@plus, max_spatial_freq*phase, (1:nframes)'/fps*speed);  % add motion
m = zeros(n(1)*f, n(2)*f, size(phase,1));
for i=1:size(phase,1)
    m(:,:,i) = (cos(2*pi*up(reshape(phase(i,:),n),f))+1)/2;
end
toc

v = VideoWriter('~/Desktop/trippy3', 'MPEG-4');
v.FrameRate = fps;
v.Quality = 100;
open(v)
writeVideo(v, permute(m(1:sz(1),1:sz(2),:),[1 2 4 3]));
close(v)
end


function img = up(img, factor)
% fast upscale with radial symmetry of interpolation
for i=1:2
    img = upsample(img', factor, round(factor/2));
    l = size(img,1);
    k = gausswin(l,sqrt(0.5)*l/factor);
    k = ifftshift(factor/sum(k)*k);
    img = real(ifft(bsxfun(@times, fft(img), fft(k))));
end
end

