function img = filterDoG(img, sigmas)
% a fast  difference-of-gaussian image filtration with
% low-pass sigma(1) and high-pass sigma(2). sigma(1)<sigma(2)

% -- Dimitri Yatsenko, August 2012

% low-pass filtration
k = gaussWin(sigmas(1));
img = imfilter(imfilter(img, k, 'symmetric'), k', 'symmetric');

% high-pass filtration
k = gaussWin(sigmas(2));
img = img - imfilter(imfilter(img, k, 'symmetric'), k', 'symmetric');

end 


function k = gaussWin(sigma)
n = ceil(2.2*sigma);
n = (-n:n)'/sigma;
k = exp(-n.^2/2);
k = k/sum(k);
end


