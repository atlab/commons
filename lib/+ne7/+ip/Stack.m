% ne7.ip.Stack - processing of 3D images

% -- Dimitri Yatsenko, August 2012

classdef Stack < handle
    properties
        stack
        step      % (um/pixel) pixel step
        conjFFT   % normalized frames, conjugate 3D fft to compute correlation
    end
    
    methods
        
        function self = Stack(stack, step)
            self.stack = stack;
            if nargin>1
                self.step = step;
            end
        end
        
        
        function c = corr(self, stack2)
            % compute correlation with another stack of the same size
            assert(all(size(self.stack)==size(stack2)))
            
            % if first time, compute conjFFT
            firstTime = isempty(self.conjFFT);
            if firstTime
                tempStack = self.stack;
            end
            
            % apply Difference-of-Gaussians filter
            sigmas = [1 5];
            stack2 = ne7.ip.filterDoG(stack2, sigmas);
            if firstTime
                tempStack = ne7.ip.filterDoG(tempStack, sigmas);
            end
            
            % mask out features near bounadries
            sz = size(self.stack);
            mask = atan(10*hanning(sz(1)))*atan(10*hanning(sz(2)))' /atan(10)^2;
            stack2 = bsxfun(@times, stack2, mask);
            if firstTime
                tempStack = bsxfun(@times, tempStack, mask);
            end
            
            % normalize each frame
            stack2   = bsxfun(@rdivide, stack2, sqrt(sum(sum(stack2.^2))));
            if firstTime
                tempStack = bsxfun(@rdivide, tempStack, sqrt(sum(sum(tempStack.^2))));
            end
            
            % transfer to frequency domain
            stack2 = fft2(stack2);
            if firstTime
                self.conjFFT = conj(fftn(tempStack));
                clear tempStack
            end
            
            % compute the shift of the peak correlation
            nFrames = size(stack2,3);
            for iFrame=1:nFrames
                c = ifftn(bsxfun(@times, img(:,:,iFrame), self.conjFFT));
                c = fftshift(fftshift(real(c),1),2);
                [peakcorr(iFrame),idx(iFrame)] = max(c(:)); %#ok<AGROW>
            end
            [y, x, z] = ind2sub(size(self.conjFFT),idx);
            
            % recenter offsets
            y = y(:) - ceil((sz(1)+1)/2);
            x = x(:) - ceil((sz(2)+1)/2);
            z = z(:) - ceil((sz(3)+1)/2);

            
        end
        
        
        
        
        
        
        function [x,y,z, peakcorr] = xcorrpeak3d(self, img)
            % finds the optimal offset between image and stack.
            % If img is a movie, does so for every frame.
            %
            % The stack is cached so that subsequent calls with one
            % argument apply the same stack, which increases computational efficiency.
            % At the end always call xcorrpeak3d([],[]) to clear the cached stack.
            
            % if first time, compute conjFFT
            firstTime = isempty(self.conjFFT);
            if firstTime
                tempStack = self.stack;
            end
            
            % apply Difference-of-Gaussians filter
            sigmas = [1 5];
            img = ne7.ip.filterDoG(img, sigmas);
            if firstTime
                tempStack = ne7.ip.filterDoG(tempStack, sigmas);
            end
            
            % mask out features near bounadries
            sz = size(self.stack);
            mask = atan(10*hanning(sz(1)))*atan(10*hanning(sz(2)))' /atan(10)^2;
            img = bsxfun(@times, img, mask);
            if firstTime
                tempStack = bsxfun(@times, tempStack, mask);
            end
            
            % normalize each frame
            img   = bsxfun(@rdivide, img  , sqrt(sum(sum(img.^2))));
            if firstTime
                tempStack = bsxfun(@rdivide, tempStack, sqrt(sum(sum(tempStack.^2))));
            end
            
            % transfer to frequency domain
            img = fft2(img);
            if firstTime
                self.conjFFT = conj(fftn(tempStack));
                clear tempStack
            end
            
            % compute the shift of the peak correlation
            nFrames = size(img,3);
            for iFrame=1:nFrames
                c = ifftn(bsxfun(@times, img(:,:,iFrame), self.conjFFT));
                c = fftshift(fftshift(real(c),1),2);
                [peakcorr(iFrame),idx(iFrame)] = max(c(:)); %#ok<AGROW>
            end
            [y, x, z] = ind2sub(size(self.conjFFT),idx);
            
            % recenter offsets
            y = y(:) - ceil((sz(1)+1)/2);
            x = x(:) - ceil((sz(2)+1)/2);
            z = z(:) - ceil((sz(3)+1)/2);
        end
        
        
        function applyRasterCorrection(self, raster)
            % apply raster correction
            self.stack = ne7.micro.RasterCorrection.apply(self.stack, raster(end,:,:));
        end
        
        
        function applyAnscombe(self, offset)
            % apply Anscombe transform  (variance normalization)
            self.stack = max(0,self.stack+offset).^0.5;
        end
        
        
        function removeBackground(self, sigmas)
            % remove the background which corresponds to objects larger
            % than sigmas = [sigma_y sigma_x].
            if numel(sigmas)==1
                sigmas = [sigmas sigmas];
            end
            sigmas = sigmas./self.step(1:2);  % convert to pixels
            
            self.stack = self.stack - getBackground(self.stack,sigmas);
            
            
            function bg = getBackground(bg,sigmas)
                for i=1:6
                    smooth = ne7.ip.Stack.smoothStack2(bg, sigmas);
                    bg = bg - max(0,bg-smooth);
                end
            end
        end
        
        
        function lowpass3(self, sigmas)
            assert(numel(sigmas)==3, ...
                'ip.Stack.lowpass requires three sigmas for smoothing -- one for each dimension')
            
            subroutine(1)   % filter along y
            subroutine(2)   % filter along x
            subroutine(3)   % filter along z
            
            function subroutine(dim)
                n = floor(sigmas(dim)/abs(self.step(dim)))*2+1;
                k = hanning(n);
                k = k/sum(k);
                k = reshape(k, circshift([length(k) 1 1],[1 dim]));
                self.stack = imfilter(self.stack, k);
            end
        end
        
        
        function seedMap = findLocalMaxima(self, minSeparation, zrange)
            % Given the stack self, find local intensity peaks separated by
            % at lease minSeparation microns whose z positions fall within
            % zrange.
            
            % find local maxima
            sz = size(self.stack);
            [y,x,z] = ndgrid(1:sz(1), 1:sz(2), (1:sz(3))-(sz(3)+1)/2);
            
            y = y*self.step(1);
            x = x*self.step(2);
            z = z*self.step(3);
            
            % mark peaks
            idx = true;
            idx = idx & self.stack > self.stack([1 1:end-1],:,:);
            idx = idx & self.stack > self.stack([2:end end],:,:);
            idx = idx & self.stack > self.stack(:,[1 1:end-1],:);
            idx = idx & self.stack > self.stack(:,[2:end end],:);
            idx = idx & self.stack > self.stack(:,:,[1 1:end-1]);
            idx = idx & self.stack > self.stack(:,:,[2:end end]);
            
            % reject noise: below threshold of 3 sigmas
            % (assume vast majority of matches are not cells)
            zscore = 3.0;  %  cutoff
            idx = find(idx(:));
            vals = self.stack(idx);
            [c,b] = hist(vals,floor(sqrt(length(vals))));
            gauss = @(a, x) a(3)*exp(-((x-a(1))/a(2)).^2/2);
            opt = statset('RobustWgtFun', @(r) max(1,r/quantile(r,0.9)), 'Tune', 1);    % "anti-robust" to fit first peak
            a = nlinfit(b,c,gauss,[0 2 max(c)], opt);
            thresh = a(1)+zscore*abs(a(2));
            sub = vals>thresh;
            idx = idx(sub);
            vals = vals(sub);
            
            % sort local maxima and blot out their smaller neighbors
            [vals,order] = sort(vals,'descend');
            idx = idx(order);
            
            y = y(idx);
            x = x(idx);
            z = z(idx);
            
            include = true(size(vals));
            for i=1:length(vals)
                if include(i)
                    j = i+1:length(idx);
                    r2 = (y(j)-y(i)).^2 + (x(j)-x(i)).^2 + (z(j)-z(i)).^2;
                    include(j) = include(j) & r2 > minSeparation^2;
                end
            end
            idx = idx(include);
            vals = vals(include);
            x = x(include);
            y = y(include);
            z = z(include);
            
            % only include z that are within z range
            include = z>zrange(1) & z<zrange(2);
            
            seedMap = false(sz);
            seedMap(idx(include)) = true;
        end        
        
        
        function [maskPixels, centerZ] = segmentConvex(self, zrange, minRadius)
            % segment regions that are convex
            
            % convert z-range to voxel indices
            sz = size(self.stack);
            zrange = zrange/self.step(3)+(sz(3)+1)/2;
            centerZ = round(mean(zrange));
            assert(centerZ>=2 && centerZ<=sz(3)-1, 'imaged plane is too close to stack boundary')
            
            % segment convex regions
            k = [.5 -1 .5];
            convex = self.stack > 0 ...
                & convn(self.stack, k, 'same') < 0 ...
                & convn(self.stack, k', 'same') < 0;
            w = watershed(-self.stack.*convex,6);
            w = single(w).*single(convex);
            regions = regionprops(w,self.stack, 'Centroid','PixelList','MeanIntensity');
            ix = num2cell(1:length(regions));
            [regions.region] = deal(ix{:});   % remember regions index
            
            % select regions whose centroids are within z-range
            include = arrayfun(@(x) x.Centroid(3) > min(zrange) && x.Centroid(3) < max(zrange), regions);
            regions = regions(include);
            
            % find regions that have enough voxels within image plane
            minPixels = pi*(minRadius/mean(self.step(1:2))).^2;
            include = cellfun(@(x) sum(x(:,3)==centerZ)>minPixels, {regions.PixelList});
            regions = regions(include);
            
            % remove dim regions
            regions = regions([regions.MeanIntensity]>quantile([regions.MeanIntensity], 0.9)*0.25);
            
            % select pixels that belong to the region in imaged plane and in both adjacent planes
            maskPixels = cell(size(regions));
            for i = 1:length(regions)
                maskPixels{i} = find(prod(single(w(:,:,centerZ+(-1:1))==regions(i).region), 3));
            end
            
            % again select regions that have enough pixels
            maskPixels = maskPixels(cellfun(@length, maskPixels)>minPixels);
        end
    end
    
    
    methods(Static)
        function stack = smoothStack2(stack, sigmas)
            n = ceil(sigmas(1)*2)*2+1;
            g = gausswin(n,n/sigmas(1));
            g = g/sum(g);
            stack = imfilter(stack, g, 'symmetric');
            n = ceil(sigmas(2)*2)*2+1;
            g = gausswin(n,n/sigmas(2));
            g = g/sum(g);
            stack = imfilter(stack, g', 'symmetric');
        end
    end
end