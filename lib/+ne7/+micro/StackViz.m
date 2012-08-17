classdef StackViz < handle
    
    properties(SetAccess = private)
        gstack
        rstack
        pitch % (um/m) pixel pitch
    end
    
    
    methods
        
        function self = StackViz(gstack, rstack, pitch, raster)
            self.gstack = gstack;
            self.rstack = rstack;
            self.pitch = pitch;
            if nargin>=4
                % apply raster correction
                if numel(self.gstack)>1
                    self.gstack = trove.RasterCorrection.apply(self.gstack, raster(end,:,:));
                end
                if numel(self.rstack)>1
                    self.rstack = trove.RasterCorrection.apply(self.rstack, raster(end,:,:));
                end
            end
        end
        
        
        function applyAnscombe(self)
            % Anscombe transform
            self.gstack = max(0,self.gstack+10).^0.5;
            self.rstack = max(0,self.rstack+10).^0.5;
        end
        
        
        
        function removeBackground(self, sigmas)
            % remove the background which corresponds to objects larger
            % than sigmas = [sigma_y sigma_x].
            if numel(sigmas)==1
                sigmas = [sigmas sigmas];
            end            
            sigmas = sigmas./self.pitch(1:2);  % convert to pixels

            if numel(self.gstack)>1
                self.gstack = self.gstack - getBackground(self.gstack,sigmas);
            end
            
            if numel(self.rstack)>1
                self.rstack = self.rstack - getBackground(self.rstack,sigmas);
            end            
            
            function bg = getBackground(bg,sigmas)
                for i=1:6
                    smooth = trove.StackViz.smoothStack2(bg, sigmas);
                    bg = bg - max(0,bg-smooth);
                end
            end
        end
        
        
        
        function lowpass3(self, sigmas)            
            if numel(sigmas)==1
                sigmas = [sigmas sigmas sigmas];
            end
            sub(1)
            sub(2)
            sub(3)
                        
            function sub(dim)
                n = floor(sigmas(dim)/abs(self.pitch(dim)))*2+1;
                k = hanning(n);
                k = k/sum(k);
                k = reshape(k, circshift([length(k) 1 1],[1 dim]));
                if numel(self.gstack>1)
                    self.gstack = imfilter(self.gstack, k);
                end
                if numel(self.rstack>1)
                    self.rstack = imfilter(self.rstack, k);
                end
            end
        end
        
        
        function seedMap = findLocalMaxima(self, minSeparation)
            
            % find local maxima 
            sz = size(self.gstack);
            [y,x,z] = ndgrid(1:sz(1), 1:sz(2), (1:sz(3))-(sz(3)+1)/2);
            idx = true;
            % exclude borders
            idx = idx & y>1 & y<sz(1); 
            idx = idx & x>1 & x<sz(2);
            idx = idx & z>1 & z<sz(3);
            
            y = y*self.pitch(1);
            x = x*self.pitch(2);
            z = z*self.pitch(3);
                        
            % get peaks
            idx = idx & self.gstack > circshift(self.gstack, [+1 0 0]);
            idx = idx & self.gstack > circshift(self.gstack, [-1 0 0]);
            idx = idx & self.gstack > circshift(self.gstack, [0 +1 0]);
            idx = idx & self.gstack > circshift(self.gstack, [0 -1 0]);
            idx = idx & self.gstack > circshift(self.gstack, [0 0 +1]);
            idx = idx & self.gstack > circshift(self.gstack, [0 0 -1]); 
            
            % reject noise: below threshold of 3 sigmas  
            % (assume vast majority of matches are not cells)
            zscore = 3.0;  %  cutoff
            idx = find(idx(:));
            vals = self.gstack(idx);
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
            %vals = vals(include);
            %x = x(include);
            %y = y(include);
            %z = z(include);
            
            seedMap = false(sz);
            seedMap(idx) = true;
        end
       
        
        
        function regions = growRegions(self, bw)
            % grow regions downhill from given points
            w = watershed(-self.gstack,26);
            
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