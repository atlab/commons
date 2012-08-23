% ne7.ip.Stack - processing of 3D images

% -- Dimitri Yatsenko, August 2012

classdef Stack < handle
    properties
        stack
        fftStack   % normalized frames, conjugate 3D fft to compute correlation
    end
    
    methods
        
        function self = Stack(stack)
            self.stack = stack;
        end
        
        
        function [x,y,z, peakcorr] = xcorrpeak3d(self, img)
            % finds the optimal offset between image and stack.
            % If img is a movie, does so for every frame.
            %
            % The stack is cached so that subsequent calls with one
            % argument apply the same stack, which increases computational efficiency.
            % At the end always call xcorrpeak3d([],[]) to clear the cached stack.
            
            newstack = isempty(self.fftStack);
            if newstack
                self.fftStack = self.stack;
            end
            
            % apply DoG filter
            sigma1 = 1;   % low-pass size
            sigma2 = 6;   % high-pass size
            img = filterDoG(img, n1, n2);
            if newstack
                self.fftStack = ne7.ip.filterDoG(self.fftStack, sigma1, sigma2);
            end
            
            % apply mask to discount regions near the boundary
            sz = size(img);
            mask = hamming(sz(1))*hamming(sz(2))';
            img   = bsxfun(@times, img, mask);
            if newstack
                self.fftStack = bsxfun(@times, self.fftStack, mask);
            end
            
            % normalize each frame
            img   = bsxfun(@rdivide, img  , sqrt(sum(sum(img.^2))));
            if newstack
                self.fftStack = bsxfun(@rdivide, self.fftStack, sqrt(sum(sum(img.^2))));
            end
            
            % transfer to frequency domain
            if newstack
                self.fftStack = conj(fftn(self.fftStack));
            end
            img = fft2(img);
            
            % compute optimum offset for each frame in img
            nFrames = size(img,3);
            for iFrame=1:nFrames
                c = fftshift(ifftn(bsxfun(@times, img(:,:,iFrame), self.fftStack)));
                [peakcorr(iFrame),idx(iFrame)] = max(c(:)); %#ok<AGROW>
            end
            [y x z] = ind2sub(size(self.fftStack),idx);
        end
    end
    
end