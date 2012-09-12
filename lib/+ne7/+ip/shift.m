function img = shift(img,yx)
% shift image by yx pixels.  Works similarly to circshift but the boundary
% pixels are replicated instead of wrapping like in circshift.
img = img(...
    max(1,min(end,(1:end)+double(yx(1)))), ...
    max(1,min(end,(1:end)+double(yx(2)))));
end