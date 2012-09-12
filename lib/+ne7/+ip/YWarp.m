classdef YWarp < handle
    % this class applies subpixel correction to images that are already
    % approximately aligned.
    % The warping function is a polynomial of the y-coordinate, which is
    % optimal for motion correction in movies acquired by raster scanning
    % with Y as the slow scan dimension.
    %
    % Usage:
    %     ywarp = YWarp(refImg);
    %     yWarp = fit(img, degree);
    %     img = yWarp.apply(image);
    
    properties(Constant, Access=private)
        opt = optimset(...
            'TolX',1e-3, ...
            'TolFun',1e-4, ...
            'MaxIter',12, ...
            'LargeScale','off',...
            'Display','off', ...
            'UseParallel','always'...
            )
    end
    
    properties
        coefs
    end
    
    properties(Access=private)
        refImg
        shape
        ix
        iy
        mask
        yvec
    end
    
    methods
        function self = YWarp(refImg)
            % subtract mean
            refImg = double(refImg)-double(mean(refImg(:)));
            
            % mask out boundary
            self.shape = size(refImg);
            self.yvec = 2*(0:self.shape(1)-1)'/(self.shape(1)-1)-1;
            [self.iy, self.ix] = ndgrid(1:self.shape(1), 1:self.shape(2));
            self.mask = min(...
                min(self.iy-1, self.shape(1)-self.iy), ...
                min(self.ix-1, self.shape(2)-self.ix));
            self.mask = min(1,self.mask/min(self.shape)*8);
            self.mask = self.mask.^2.*(3-2*self.mask);
            refImg = refImg.*self.mask;
            
            % normalize referenced image
            refImg = refImg / norm(refImg(:));
            self.refImg = griddedInterpolant(refImg);
        end
        
        
        function self = fit(self, img, degree, motion)
            if nargin<4
                motion = [0 0];
            end
            
            % normalize image
            img = self.mask.*(img - mean(img(:)));
            img = img/norm(img(:));
            
            % fit image
            p = [motion(1) zeros(1,degree) motion(2) zeros(1,degree)];
            f = @(p) self.residual(img, p);
            self.coefs = fminunc(f, p, self.opt);
        end
        
        
        function img = apply(self, img)
            % interpolate image
            p = self.coefs;
            xx = self.ix;
            yy = self.iy;
            np = length(p)/2;
            for i=1:np;
                yy = bsxfun(@plus, yy, p(i)*ne7.num.chebyI(self.yvec,i-1));
                xx = bsxfun(@plus, xx, p(np+i)*ne7.num.chebyI(self.yvec,i-1));
            end
            yy = max(1, min(self.shape(1), yy));
            xx = max(1, min(self.shape(2), xx));
            img = griddedInterpolant(img);
            img = img(yy,xx);
        end
    end
    
    
    
    methods(Access=private)
        function L = residual(self, img, p)
            % interpolate reference image
            xx = self.ix;
            yy = self.iy;
            np = length(p)/2;
            for i=1:np;
                yy = bsxfun(@minus, yy, p(i)*ne7.num.chebyI(self.yvec,i-1));
                xx = bsxfun(@minus, xx, p(np+i)*ne7.num.chebyI(self.yvec,i-1));
            end
            yy = max(1, min(self.shape(1), yy));
            xx = max(1, min(self.shape(2), xx));
            
            % compute residual
            L = sum(sum((img - self.refImg(yy,xx)).^2));
        end
    end
end