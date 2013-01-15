%{
tp.Trace2 (imported) # raw calcium trace
-> tp.Extract2

trace_idx      : smallint  # cell index within the segmentation
---
gtrace         : longblob  # fluorescence trace in green channel
centroid_x     : float  # (pixels) centroid x-coordinate
centroid_y     : float  # (pixels) centroid y-coordinate
mask_pixels    : mediumblob                    # indices of segment pixels in the image
mask_weights=null  : mediumblob                # normalized weights of pixels in the mask
g_contrast=null  : float                         # Michelson contrast in the green channel
r_contrast=null  : float                         # Michelson contrast in the red channel

%}

classdef Trace2 < dj.Relvar
    
    properties(Constant)
        table = dj.Table('tp.Trace2')
    end
    
    methods
        function makeTuples(self, key)
            DEBUG = true;
            % compute pixel pitch (um/pixel)
            [fps, px,py] = fetch1(tp.Align & key, ...
                'fps', 'um_width/px_width->px', 'um_height/px_height->py');
            assert(max(px/py, py/px)<1.1, ...
                'the present algorithm cannot accept non-isometric pixels')
            pitch = (px+py)/2;
            
            % get mean frames
            [g,r] = fetch1(tp.FineAlign & key, 'fine_green_img', 'fine_red_img');
            movie = tp.utils.Movie(key);
            
            
            % extract traces
            mask = logical(fetch1(tp.SegmentManual & key, 'manual_mask'));
            opt = fetch(tp.ExtractOpt & key,'*');
            disp 'loading movie...'
            X = movie.getFrames(1,1:movie.nFrames);
            regions = regionprops(mask, 'Centroid');
            sz = size(X);
            X = reshape(X,[],sz(3))';
            [yi,xi] = ndgrid(1:sz(1),1:sz(2));
            [maxRadius, minRadius] = fetch1(tp.SegOpt & key, 'max_radius', 'min_radius');
            maxRadius = maxRadius/pitch;
            minRadius = minRadius/pitch;
            if DEBUG
                showMask = zeros(sz(1:2));  % used for verification
            end
            pixels  = cell(numel(regions),1);
            traces = zeros(sz(3), numel(regions), 'single');
            weights = cell(numel(regions),1);
            include = true(1,numel(regions));
            switch opt.pixel_averaging
                case 'mean'
                    % use centroid and radius rather than actual region
                    for iTrace=1:length(regions)
                        xy = regions(iTrace).Centroid;
                        d2 = (xi-xy(1)).^2 + (yi-xy(2)).^2;
                        cix = find(d2 < minRadius);
                        pixels{iTrace} = cix;
                        traces(:,iTrace) = mean(X(:,cix),2);
                    end
                    
                case 'median' % 75th percentile actually
                    % use centroid and radius rather than actual region
                    for iTrace=1:length(regions)
                        xy = regions(iTrace).Centroid;
                        d2 = (xi-xy(1)).^2 + (yi-xy(2)).^2;
                        cix = find(d2 < minRadius*maxRadius);
                        pixels{iTrace} = cix;
                        traces(:,iTrace) = quantile(X(:,cix),0.75,2);
                    end
                    
                case 'NNMF'
                    disp 'Non-negative matrix factorization...'
                    innerContributionCutoff = 1.7;
                    % create unsharp masking kernel 
                    bandwidth = 0.03;
                    unsharp = hamming(round(fps/bandwidth)*2+1);
                    unsharp = -unsharp/sum(unsharp);  % unsharp masking kern
                    unsharp((end+1)/2) = unsharp((end+1)/2) + 1;
                    for iTrace = 1:length(regions)
                        xy = regions(iTrace).Centroid;
                        d2 = (xi-xy(1)).^2 + (yi-xy(2)).^2;
                        idx = find(d2 <= (1.2*maxRadius)^2);
                        cix = d2(idx) < minRadius*maxRadius;
                        x = X(:,idx);
                        [~,mask] = seminmfnnls(ne7.dsp.convmirr(double(x),unsharp), 1, struct('dis',false));
                        ratio = median(mask(cix))/median(mask(~cix));
                        include(iTrace) = ratio > innerContributionCutoff;
                        select = d2(idx)<=minRadius*maxRadius;
                        x = x(:,select);
                        
                        idx = idx(select);
                        mask = mask(select);
                        mask = mask/sum(mask);
                        if DEBUG
                            fprintf('Inner contribution ratio: %1.3f\n', ratio)
                            if include(iTrace)
                                showMask(idx) = showMask(idx) + mask';
                            end
                        end
                        pixels{iTrace} = idx;
                        weights{iTrace} = mask;
                        traces(:,iTrace) = x*mask';
                    end
                    
                otherwise
                    error 'not done yet'
            end
            
            tuple = key;
            bgRadius = maxRadius*2;
            for iTrace = find(include)
                tuple.trace_idx = iTrace;
                tuple.gtrace = traces(:,iTrace);
                if isempty(weights{iTrace})
                    tuple.centroid_x = mean(xi(pixels{iTrace}));
                    tuple.centroid_y = mean(yi(pixels{iTrace}));
                else
                    tuple.centroid_x = weights{iTrace}*xi(pixels{iTrace});
                    tuple.centroid_y = weights{iTrace}*yi(pixels{iTrace});
                end
                tuple.mask_pixels = pixels{iTrace};
                tuple.mask_weights = weights{iTrace};
                tuple.g_contrast = getContrast(g, pixels{iTrace}, bgRadius);
                tuple.r_contrast = getContrast(r, pixels{iTrace}, bgRadius);
                self.insert(tuple)
            end
        end
    end
end



function contrast = getContrast(img, maskPixels, radius)
% Michelson contrast of pixels at maskPixels compared to others within radius
sz = size(img);
[y,x] = ind2sub(sz,maskPixels);
y = mean(y);
x = mean(x);
[yi,xi] = ndgrid(...
    max(1,round(y-radius)):min(sz(1),round(y+radius)),...
    max(1,round(x-radius)):min(sz(2),round(x+radius)));
hood = (yi-y).^2+(xi-x).^2 < radius^2;
hood = sub2ind(sz, yi(hood), xi(hood));
object     = mean(img(maskPixels));
background = quantile(img(hood),0.4);
contrast = (object-background)/(object+background)*2;
end