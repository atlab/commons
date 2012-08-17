classdef Segmentation
    
    methods(Static)
        function maskIndices = convex2D(img, pixelPitch, opt)
            assert(all(isfield(opt, {
                'sigma1' 'sigma2' 'min_area' 'max_area' 'max_eccentricity' 'min_rel_intensity'
                })), 'missiong options')
            
            original = img;
            
            % pre-filtering
            img = imfill(img);  % fill in vessells, neucleus, etc
            img = diffGauss(img, opt.sigma1/pixelPitch, opt.sigma2/pixelPitch);
            img = max(0,img);  % thresholding
            
            % segment convex regions
            k = [1 -2 1];
            bw = img > quantile(img(:), 0.1) & ... % discard dark regions
                imfilter(img, k, 'symmetric') < 0 & ...
                imfilter(img, k', 'symmetric') < 0;  % discard concave intensity regions
            bw = imfill(bw,'holes');
            regions = bwlabel(bw,4);
            
            % select regions that meet criteria
            p = regionprops(regions, img,'Area','Eccentricity','MeanIntensity');  %#ok
            subset = true;
            subset = subset & [p.Area] > opt.min_area/pixelPitch^2;    % exclude small segments
            subset = subset & [p.Area] < opt.max_area/pixelPitch^2;    % exclude large segments
            subset = subset & [p.Eccentricity] < opt.max_eccentricity; % exclude elongated segments
            subset = subset & [p.MeanIntensity] > opt.min_rel_intensity*quantile([p(subset).MeanIntensity],0.8);  % exclude dim sigments
            subset = find(subset);
            n = length(subset);
            maskIndices = cell(n, 1);
            
            for i = 1:n
                maskIndices{i} = find(regions==subset(i));
            end
            
            % display results
            clf
            subplot 221, imagesc(original), axis image, title original
            subplot 222, imagesc(img), axis image, title filterd
            bounds = bwboundaries(bw,4);
            subplot 223
            imagesc(img)
            hold on
            axis image
            for i = 1:length(bounds)
                plot(bounds{i}(:,2),bounds{i}(:,1),'g')
            end
            hold off
            title 'all segments'
            
            subplot 224
            imagesc(original)
            axis image
            colormap gray
            hold on
            for i=subset
                plot(bounds{i}(:,2),bounds{i}(:,1),'g')
            end
            hold off
            title 'selected segments'
            drawnow
        end
    end
end



function img = diffGauss(img, n1, n2)
% a fast approximation of difference-of-gaussian image filtration with
% sigmas n1 (smaller) and n2 (larger).
n1 = ceil(n1);
if n1>0
    k1 = hamming(n1*2+1);
    k1 = k1/sum(k1);
    img = imfilter(imfilter(img, k1, 'symmetric'), k1', 'symmetric');
end

n2 = ceil(n2);
if n2>0
    k2 = hamming(n2*2+1);
    k2 = k2/sum(k2);
    img = img - imfilter(imfilter(img, k2, 'symmetric'), k2', 'symmetric');
end
end