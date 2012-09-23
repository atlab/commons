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
        
        
                
        function writeVideo(self, savepath)
            if nargin<2
                savepath = '.';
            end
            for key = fetch(self)'
                disp 'making movie for'
                disp(key)
                clf
                f = getFilename(common.TpScan(key));
                scim = ne7.scanimage.Reader(f{1});

                fps = fetch1(tp.Align(key),'fps');
                targetFps = 3; % Hz
                disp 'compressing green channel'
                g = compressVideo(m.getMovie(1), fps, targetFps);
                disp 'compressing red channel'
                r = compressVideo(m.getMovie(2), fps, targetFps);
                disp 'saving AVI...'
                g = cat(4,r,g,zeros(size(g),'uint8'));
                g = permute(g, [1 2 4 3]);
                
                fname = sprintf('%05d_%03d.avi', key.animal_id, key.scan_idx);
                v = VideoWriter(fullfile(savepath,fname));
                v.FrameRate = 30;
                v.Quality = 100;
                v.open
                v.writeVideo(g)
                v.close
                
                disp 'converting avi'
                system(sprintf('ffmpeg -i %scim -y -vcodec -sameq %scim', ...
                    fullfile(savepath, fname), fullfile(savepath, ['a' fname])));
                delete(fullfile(savepath,fname))
                
                disp done
            end
        end
        
    end
end
