function img = correctMotion(img, xymotion)
% img size [x y nSlices nFrames].   2D and 3D images also work
% xymotion size [2 nSlices nFrames] - contains [x y] shifts for each slice and frame

sz = [size(img,1) size(img,2) size(img,3) size(img,4)];
for iFrame = 1:sz(4)
    for iSlice = 1:sz(3)
        im = img(:,:,iSlice,iFrame);
        g = griddedInterpolant(im,'cubic','nearest');
        [y,x] = ndgrid((1:sz(1))+xymotion(2,iSlice,iFrame), (1:sz(2))+xymotion(1,iSlice,iFrame));
        img(:,:,iSlice,iFrame) = g(y,x);
    end
end
end