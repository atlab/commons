function d = oriDiff(ori1,ori2)
% compute the absolute difference between orientations ori1 and ori2 (in degrees)

ori1 = mod(ori1, 180);
ori2 = mod(ori2, 180);
b1 = min(ori1,ori2);
b2 = max(ori1,ori2);
d = min(b2-b1,b1+180-b2);