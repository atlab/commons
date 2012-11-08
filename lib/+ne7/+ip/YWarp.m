classdef YWarp < handle
    % this class applies subpixel nonrigid motion correction to images sequences
    % that are already approximately aligned (within the convex
    % neighborhood of the cross-correlation).
    %
    % Three polynomials are fitted for each frame:
    %    1)   dy = f(y)
    %    2)   dx = f(y)
    %    3)   dx = f(x)
    %
    % The first two polynomials correct for y and x drift and fast
    % movements such as cardiac and respiratory.  They only depend on y
    % (the slow-scanning axis).
    %
    % The third polynomial corrects for the slow changes in the x-raster
    % trajectory that happen due to the heating of mirror galvos at fast
    % scanning rates.  These mostly depend only on the x (repeatable
    % acroass lines)
    %
    % Usage:
    %     ywarp = YWarp(refImg);
    %     yWarp = fit(img, degree);
    %     warp = ywarp.coefs;
    %     img = YWarp.apply(img, wap);
    
    properties(Constant, Access=private)
        opt = optimset(...
            'TolX',1e-3, ...
            'TolFun',1e-4, ...
            'MaxIter',25, ... 
            'Display','off', ...
            'LargeScale','off'...
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
        xvec
        degrees  % 3x1 vector for y(yi), x(yi), x(xi)
    end
    
    methods
        function self = YWarp(refImg)
            % subtract mean
            refImg = double(refImg)-double(mean(refImg(:)));
            
            % mask out boundary
            self.shape = size(refImg);
            self.yvec = 2*(0:self.shape(1)-1)'/(self.shape(1)-1)-1;
            self.xvec = 2*(0:self.shape(2)-1)/(self.shape(2)-1)-1;
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
        
        
        function self = fit(self, img, degrees, p)
            self.degrees = degrees; 
            
            % normalize image
            img = self.mask.*(img - mean(img(:)));
            img = img/norm(img(:));
            
            % zero out fast-changing parameters
            p(1+(1:degrees(1)))=0;
            p(degrees(1)+1+(1:degrees(2)))=0;
            
            % fit image
            f = @(p) self.residual(img, p);
            self.coefs = fminunc(f, p, self.opt);
        end
    end
    
    
    methods(Static)
        function img = apply(img, warp,degrees)
            % interpolate image
            sz = size(img);
            yv = 2*(0:sz(1)-1)'/(sz(1)-1)-1;
            xv = 2*(0:sz(2)-1)/(sz(2)-1)-1;
            [yy,xx] = ndgrid(1:size(img,1), 1:size(img,2));
            for i=0:degrees(1)
                yy = bsxfun(@plus, yy, warp(i+1)*ne7.num.chebyI(yv,i));
            end
            for i=0:degrees(2)
                xx = bsxfun(@plus, xx, warp(i+2+degrees(1))*ne7.num.chebyI(yv,i));
            end
            for i=1:degrees(3)   % zeroth degree omitted
                xx = bsxfun(@plus, xx, warp(i+2+sum(degrees(1:2)))*ne7.num.chebyI(xv,i));
            end
            yy = max(1, min(sz(1), yy));
            xx = max(1, min(sz(2), xx));
            img = griddedInterpolant(img);
            img = img(yy,xx);
        end
    end
    
    
    
    methods(Access=private)
        function L = residual(self, img, p)
            % interpolate reference image
            xx = self.ix;
            yy = self.iy;
            for i=0:self.degrees(1)
                yy = bsxfun(@minus, yy, p(i+1)*ne7.num.chebyI(self.yvec,i));
            end
            for i=0:self.degrees(2)
                xx = bsxfun(@minus, xx, p(i+2+self.degrees(1))*ne7.num.chebyI(self.yvec,i));
            end
            for i=1:self.degrees(3)   % zeroth degree omitted
                xx = bsxfun(@minus, xx, p(i+2+sum(self.degrees(1:2)))*ne7.num.chebyI(self.xvec,i));
            end
            yy = max(1, min(self.shape(1), yy));
            xx = max(1, min(self.shape(2), xx));
            
            % compute residual
            L = sum(sum((img - self.refImg(yy,xx)).^2));
        end
    end
end