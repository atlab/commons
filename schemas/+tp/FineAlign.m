%{
tp.FineAlign (imported) # subpixel geometrical adjustment of each frame

-> tp.Align
---
warp_degree                 : tinyint                       # polynomial degree
warp_polynom                : longblob                      # warp polynomial coefficients
fine_green_img              : longblob                      # green corrected image
fine_red_img                : longblob                      # red corrected image
%}

classdef FineAlign < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.FineAlign')
        popRel = tp.Align
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)            
            [raster, motion, gframe, px, py] = fetch1(tp.Align & key, ...
                'raster_correction', 'motion_correction',...
                'green_img', ...
                'um_width/px_width->px', 'um_height/px_height->py');
            assert(max(px/py, py/px)<1.1, 'tp.FineAlign cannot process non-isometric pixels')
            f = getFilename(common.TpScan(key));
            scim = ne7.scanimage.Reader(f{1});
            
            % compute the most typical frame
            disp 'computing subpixel correction...'
            key.warp_degree = 2;
            ggframe = 0;
            rrframe = 0;
            key.warp_polynom = nan(scim.nFrames, 2*key.warp_degree+2, 'single');
            rcount = 0;
            yWarp = ne7.ip.YWarp(gframe);
            motion = double(motion);
            motion = bsxfun(@minus, motion, median(motion));
            try 
                scim.read(2,1);
                hasRedChannel = true;
            catch %#ok<CTCH>
                hasRedChannel = false;
            end
            for iFrame = 1:scim.nFrames
                if ~mod(sqrt(iFrame),1), fprintf('[%3d/%d]\n', iFrame, scim.nFrames); end
                frame = double(scim.read(1, iFrame));
                frame = ne7.micro.RasterCorrection.apply(frame, raster(iFrame,:,:));                
                
                % subpixel fit
                yWarp.fit(frame, key.warp_degree, motion(iFrame,:));
                key.warp_polynom(iFrame, :) = yWarp.coefs;                
                frame = ne7.ip.YWarp.apply(frame, key.warp_polynom(iFrame,:));
                ggframe = ggframe + frame;
                
                if hasRedChannel && ~mod(iFrame-10,20)
                    rcount = rcount + 1;
                    frame = double(scim.read(2, iFrame));
                    frame = ne7.micro.RasterCorrection.apply(frame, raster(iFrame,:,:));
                    frame = ne7.ip.YWarp.apply(frame, key.warp_polynom(iFrame,:));
                    rrframe = rrframe + frame;
                end
            end
            
            key.fine_green_img = single(ggframe/scim.nFrames);
            key.fine_red_img   = single(rrframe/rcount);
            
            self.insert(key)
        end
    end
end
