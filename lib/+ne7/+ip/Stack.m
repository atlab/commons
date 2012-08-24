% ne7.ip.Stack - processing of 3D images

% -- Dimitri Yatsenko, August 2012

classdef Stack < handle
    properties
        stack
        conjFFT   % normalized frames, conjugate 3D fft to compute correlation
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
                c = fftshift(ifftn(bsxfun(@times, img(:,:,iFrame), self.conjFFT)));
                [peakcorr(iFrame),idx(iFrame)] = max(c(:)); %#ok<AGROW>
            end
            [y x z] = ind2sub(size(self.conjFFT),idx);
            
            % recenter offsets
            y = y(:) - ceil((sz(1)+1)/2);
            x = x(:) - ceil((sz(2)+1)/2);
            z = z(:) - ceil((sz(3)+1)/2);
        end
    end
    
end