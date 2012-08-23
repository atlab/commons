function [x, y, peakcorr] = xcorrpeak(img, template, sigmas)
% compute x,y offsets of image img relative to a template image by finding
% the peak in the cross-correlation.
%
% If img is a 3D, then x,y will be computed for each frame.

% -- Dimitri Yatsenko, August 2012

assert(size(template,3)==1, 'template must be a 2D image')
sz = size(template);
assert(sz(1)==size(img,1) && sz(2)==size(img,2), 'image and template must match in size')
nFrames = size(img,3);

% if DoG sigmas are provided, prefilter
if nargin>=3
    template = ne7.ip.filterDoG(template, sigmas);
    img = ne7.ip.filterDoG(img, sigmas);
end

% mask out features near bounadries 
mask = atan(10*hanning(sz(1)))*atan(10*hanning(sz(2)))' /atan(10)^2;
template = mask.*template;
img = bsxfun(@times, img, mask);

% normalize the images and the template
template = template/sqrt(sum(sum(template.^2)));
img = bsxfun(@mrdivide, img, sqrt(sum(sum(img.^2))));

fTemplate = conj(fftn(template))/norm(template(:));

for i = 1:nFrames
    % compute cross-correlation
    c=fftshift(ifftn(fftn(img(:,:,i)).*fTemplate));
    % find peak correlation and its offsets
    [peakcorr(i), idx(i)]=max(c(:)); %#ok<AGROW>
end
[y x]=ind2sub(sz,idx);

% compute offsets (coordinate of peak correlation relative to the center of the image)
y = y(:) - ceil((sz(1)+1)/2);
x = x(:) - ceil((sz(2)+1)/2);
end

