% trove.RasterCorrection - correct bidirection raster artifact.
%
% Two photon movies with bidirection scans may contain raster artifacts due to
% non-uniform mirror velocities near the edges.
% This class computes and applies the warping of add and even lines that
% minimizes the artifact.
%
% Usage:
% warp = trove.RasterCorrection.fit(movie, [4 4]);    % find the 4x4 (y,x) warp coefficients
% movie = trove.RasterCorrection.apply(movie, warp);  % apply warp coefficients
%
% DY: 2010-06-09, 2010-06-18, 2010-07-10, 2011-12-19, 2012-06-02


classdef RasterCorrection < handle
    
    methods(Static)
        
        function warp = fit(movie, polydegree)
            
            nFrames = size(movie,3);
            
            block = 80;
            step = 50;
            blocks = 1:step:size(movie,3);
            w = nan([length(blocks) polydegree]);
            for i=1:length(blocks)
                if isprime(i)
                    fprintf('\n[%3d /%3d] ', i-1, length(blocks))
                end
                frame = mean(movie(1:end-1,:,blocks(i):min(end,blocks(i)+block-1)),3);
                w(i,:,:) = optimize(frame, polydegree);
            end
            fprintf \n
            if length(blocks)==1
                warp = repmat(w,nFrames,1);
            else
                warp = interp1(blocks+floor(block/2),w,1:nFrames,'*linear', 'extrap');
            end
        end
        
        
        
        function movie = apply(movie, warp)
            nFrames = size(movie,3);
            if size(warp, 1)==1
                warp = repmat(warp, nFrames, 1);
            end
            for iFrame = 1:nFrames
                img = movie(:,:,iFrame);
                
                % apply warping
                odds  = img(1:2:end,:);
                evens = img(2:2:end,:);
                xx = (0:size(img ,2)-1)/(size(img,2)-1)*2-1;
                
                %adjust odds
                yy = (0:size(odds,1)-1)/(size(odds,1)-1)*2-1;
                [yref,xref] = ndgrid( yy, xx );
                px = computeOffsetMap(squeeze(warp(iFrame,:,:)), xref, yref);
                img(1:2:end,:) = interp2(xx, yy, odds, ...
                    max(min(xx),min(max(xx),xref-px/2)),yref,'*linear');
                
                %adjust evens
                yy = (0:size(evens,1)-1)/(size(evens,1)-1)*2-1;
                [yref,xref] = ndgrid( yy, xx );
                px = computeOffsetMap(squeeze(warp(iFrame,:,:)), xref, yref);
                img(2:2:end,:) = interp2(xx, yy, evens, ...
                    max(min(xx),min(max(xx),xref+px/2)),yref,'*linear');
                
                movie(:,:,iFrame) = img;
            end
        end
    end
end


function warp = optimize(img, N, maxIter)
if nargin < 4
    maxIter=25;
end
assert(length(size(img))==2, '2D image required to optimize raster correction')
k = hamming(7)';  % horizontal smoothing kernel
img = imfilter(img, k/sum(k), 'symmetric');

% fit warp coefficients
odds  = conv2(img(1:2:floor(end/2)*2,:), [0.5;0.5], 'valid');     % used as reference
evens = img(2:2:size(odds,1)*2,:);
yy = (0:size(odds,1)-1)/(size(odds,1)-1)*2-1;
xx = (0:size(odds,2)-1)/(size(odds,2)-1)*2-1;
[yref,xref] = ndgrid(yy, xx);

% fit the odd image to the even image
ub = 0.05*ones(1,prod(N));  % maximum deviation ~1/20 of image by each polynomial
tolFun = 1e-9*numel(img); % this should be scaled to square of image amplitude
options = optimset('TolX',1e-7,'TolFun',tolFun,'GradObj','on','MaxIter',maxIter,'Display','off');
f = @(p) imgResidual(p,xref,yref,xx,yy,odds,evens,N);
warp = fmincon(f,zeros(1,prod(N)),[],[],[],[],-ub, ub,[],options);
warp = reshape(warp, N);
end


function [L, gradL] = imgResidual(p,xref,yref,xx,yy,odds,evens,N)   % compute objective function L and its gradient dL/dp
px = computeOffsetMap(reshape(p,N), xref, yref);
temp = interp2( xx, yy, odds, max(xx(1),min(xx(end),xref-px)), yref, '*linear' );
d = evens-temp;
L = sum(sum(d.^2))/2;

if nargout > 1
    % compute gradient dL/dp
    g = d.*imfilter(temp, [-0.25 0 0.25], 'symmetric');
    k=0;
    gradL = zeros(1,prod(N));
    for kx=1:N(2)
        for ky=1:N(1)
            k = k+1;
            gradL(k) = sum(sum(g.*chebyI(xref,kx-1).*chebyI(yref,ky-1)));
        end
    end
end
% p,L,gradL,subplot(211); imagesc(px); colorbar; subplot(212); imagesc(d); colorbar; drawnow;
end


function px = computeOffsetMap(p, xref, yref)
px = 0;
for kx=1:size(p,2)
    for ky=1:size(p,1)
        px = px+p(ky,kx)*chebyI(xref,kx-1).*chebyI(yref,ky-1);
    end
end
end


function y = chebyI(x, n)
% fast chebyshev polynomials of the first kind
switch n
    case 0, y = ones(size(x));
    case 1, y = x;
    case 2, y = 2*x.*x-1;
    case 3, y = (4*x.*x-3).*x;
    case 4, xx=x.*x; y = 8*(xx-1).*xx+1;
    case 5, xx=x.*x; y = ((16*xx-20).*xx+5).*x;
    case 6, xx=x.*x; y = ((32*xx-48).*xx+18).*xx-1;
    otherwise
        error('The %dth-degree ChebyI polynomial is not defined', n)
end
end