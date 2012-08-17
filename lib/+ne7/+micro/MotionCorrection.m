classdef MotionCorrection

    methods(Static)
        
        function [offsets, peakCorr]  = fit(movie, templateFrames)
            if nargin<2
                templateFrames = 60;
            end
            sigmas = [3 15];  % these work for a broad range of magnifications
            
            % construct template
            template = mean(movie(:,:,1:min(templateFrames,end)),3);
            [offsets, peakCorr] = ne7.micro.MotionCorrection.xcorrpeak(movie, template, sigmas);
        end
        
        
        
        function movie = apply(movie, offsets)
            % offset image img by yxOffset integer pixels, preserving image size.
            % Boundary pixels are duplicated.
            
            for i = 1:size(offsets,1)
                movie(:,:,i) = movie(...
                    min(end,max(1,(1:end)+double(offsets(i,1)))),...
                    min(end,max(1,(1:end)+double(offsets(i,2)))),i);
            end
        end
        
        
        
        
        function img = filterDoG(img, n1, n2)
            % a fast approximation of difference-of-gaussian image filtration with
            % sigmas n1 (smaller) and n2 (larger).
            n1 = ceil(n1);
            n2 = ceil(n2);
            k1 = hamming(n1*2+1);
            k1 = k1/sum(k1);
            k2 = hamming(n2*2+1);
            k2 = k2/sum(k2);
            img = imfilter(imfilter(img, k1, 'symmetric'), k1', 'symmetric');
            img = img - imfilter(imfilter(img, k2, 'symmetric'), k2', 'symmetric');
        end
        
        
        
        function [yxOffsets,peakcorr] = xcorrpeak(img, template, sigmas)
            % compute yxOffsets of image img relative to a template image by finding
            % the peak in the cross-correlation.
            %
            % If img is a 3D, then offsets will be computed for each frame and
            % yxOffsets' shape will be [2 x depth]
            
            if nargin>=3
                % if sigmas are provided, prefilter the template
                template = ne7.micro.MotionCorrection.filterDoG(template, sigmas(1), sigmas(2));
            end
            
            sz = size(template);
            assert(sz(1)==size(img,1) && sz(2)==size(img,2));
            nFrames = size(img,3);
            yxOffsets = zeros(nFrames,2);
            % zero out template boundaries to prevent interference with wraparound
            template([1:round(sz(1)/10), end-round(sz(1)/10)+1:end],:) = 0;
            template(:,[1:round(sz(2)/10), end-round(sz(2)/10)+1:end]) = 0;
            peakcorr = zeros(nFrames,1);
            for i = 1:nFrames
                % cross-correlation of the images
                c=fftshift(ifftn(fftn(img(:,:,i)).*conj(fftn(template))));
                % find the optimum offset yx
                [m,idx]=max(c(:));
                if nargout>1
                    peakcorr(i) = m/sqrt(sum(sum(img(:,:,i).^2)))/sqrt(sum(sum(template).^2));
                end
                [y,x]=ind2sub(sz,idx);
                yxOffsets(i,:) = [y x] - ceil((sz+1)/2);
            end
        end
    end
end
