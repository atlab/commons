function img = correctMotion(img, xymotion)
% img size [y x] 
% xy motion: motion correct in x and y with subpixel precision

assert(ismatrix(img) && numel(xymotion)==2, 'cannot correct stacks. Only 2D images please')
g = griddedInterpolant(img,'cubic','nearest');   % handles boundaries
[y,x] = ndgrid((1:sz(1))+xymotion(2), (1:sz(2))+xymotion(1)); 
img = g(y,x);