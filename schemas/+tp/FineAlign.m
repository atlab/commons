%{
tp.FineAlign (imported) # subpixel geometrical adjustment of each frame

-> tp.Align
---
warp_degree                 : tinyint                       # polynomial degree
warp_polynom                : longblob                      # warp polynomial coefficients
fine_green_img              : longblob                      # green corrected image
fine_red_img                : longblob                      # red corrected image
xwarp_degree=5              : tinyint                       # polynomial for x as a function of x
fine_ts=CURRENT_TIMESTAMP   : timestamp                     # automatic timestamp
%}

classdef FineAlign < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.FineAlign')
        popRel = tp.Align
    end
    
    methods
        function self = FineAlign(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            [raster, gframe, px, py] = fetch1(tp.Align & key, ...
                'raster_correction', 'green_img', ...
                'um_width/px_width->px', 'um_height/px_height->py');
            assert(max(px/py, py/px)<1.1, 'tp.FineAlign cannot process non-isometric pixels')
            f = getFilename(common.TpScan(key));
            scim = ne7.scanimage.Reader(f{1});
            
            % compute the most typical frame
            disp 'computing subpixel correction...'
            tuple = key;
            tuple.warp_degree = 2;
            tuple.xwarp_degree = 4;
            yWarp = ne7.ip.YWarp(gframe);
            degrees = [tuple.warp_degree*[1 1] tuple.xwarp_degree];
            tuple.warp_polynom = zeros(scim.nFrames, sum(degrees)+2, 'single');
            p = zeros(1, sum(degrees)+2);
            for iFrame = 1:scim.nFrames
                if ~mod(sqrt(iFrame),1)
                    fprintf('[%3d/%d]\n', iFrame, scim.nFrames)
                end
                
                % read green frame
                frame = double(scim.read(1, iFrame));
                frame = ne7.micro.RasterCorrection.apply(frame, raster(iFrame,:,:));
                
                % fit polynomials
                yWarp.fit(frame, degrees, p);
                p = yWarp.coefs;
                tuple.warp_polynom(iFrame, :) = p;
            end
            
            m = tp.utils.Movie(key, tuple.warp_polynom, tuple.xwarp_degree);
            tuple.fine_green_img = m.getMeanFrame(1);
            tuple.fine_red_img = m.getMeanFrame(2);
            
            
            self.insert(tuple)
        end
    end
end
