%{
tp.Align (imported) # motion correction

-> common.TpScan
---
nframes                     : smallint                      # total number of frames
px_width                    : smallint                      # pixels per line
px_height                   : smallint                      # lines per frame
um_width                    : float                         # width in microns
um_height                   : float                         # height in microns
fps                         : float                         # (Hz) frames per second
dwell_time                  : float                         # (us) microseconds per pixel per frame
discarded_final_line        : tinyint                       # 1 if the flyback line has been removed
raster_correction=null      : longblob                      # raster artifact correction
motion_correction           : longblob                      # (pixels) y,x motion correction offsets
motion_rms                  : float                         # (um) stdev of motion
green_img                   : longblob                      # mean corrected image
red_img=null                : longblob                      # mean corrected image
aligment_ts=CURRENT_TIMESTAMP: timestamp                    # automatic
green_uncorrected=null      : longblob                      # uint8 image before corrections for verification
%}

classdef Align < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.Align')
        popRel = common.TpScan
    end
    
    methods
        function self = Align(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            % read the green movie
            f = getFilename(common.TpScan & key);
            f = f{1};
            scim = ne7.scanimage.Reader(f);
            fov = fetch1(common.TpSession(key),'fov');
            
            disp 'reading tiff file'
            [g, discardedFinalLine] = scim.read(1);
            gmean = mean(g,3);
            gmean = gmean-min(gmean(:));
            gmean = uint8(255*gmean./max(gmean(:)));
            tuple = key;
            tuple.green_uncorrected = gmean;
            
            tuple.discarded_final_line = discardedFinalLine;
            
            tuple.fps = scim.hdr.acq.frameRate;
            tuple.dwell_time = scim.hdr.acq.pixelTime*1e6;
            
            tuple.nframes = scim.nFrames;
            tuple.px_width = size(g,2);
            tuple.px_height = size(g,1);
            tuple.um_width  = abs(fov/(scim.hdr.acq.zoomFactor * scim.hdr.acq.baseZoomFactor) ...
                * scim.hdr.acq.scanAngleMultiplierFast);
            tuple.um_height = abs(fov/(scim.hdr.acq.zoomFactor * scim.hdr.acq.baseZoomFactor) ...
                * scim.hdr.acq.scanAngleMultiplierSlow);
            
            pitchRatio = (tuple.um_width/tuple.px_width)/(tuple.um_height/tuple.px_height);
            if abs(1-pitchRatio) > 0.02
                warning 'non-isometric pixels'
            end
            
            disp 'raster correction'
            warp = ne7.micro.RasterCorrection.fit(g, [3 5]);
            tuple.raster_correction = warp;
            g = ne7.micro.RasterCorrection.apply(g, warp);
            
            disp 'motion correction...'
            assert(scim.hdr.acq.fastScanningX==1 & scim.hdr.acq.fastScanningY==0, 'x must be the fast axis')
            
            offsets = ne7.micro.MotionCorrection.fit(g);
            offsets = bsxfun(@minus, offsets, median(offsets));
            tuple.motion_correction = int16(offsets);
            tuple.motion_rms = mean(std(offsets).*[tuple.um_height tuple.um_width]./[tuple.px_height tuple.px_width]);
            
            disp 'averaging frames...'
            g = ne7.micro.MotionCorrection.apply(g, offsets);
            tuple.green_img = single(mean(g,3));
            clear g
            if scim.hasChannel(2)
                tuple.red_img = 0;
                block = 256;
                avg = 0;
                for i=1:block:scim.nFrames
                    ix = i:min(i+block-1,scim.nFrames);
                    r = scim.read(2,ix);
                    r = ne7.micro.RasterCorrection.apply(r, warp(ix,:,:));
                    r = ne7.micro.MotionCorrection.apply(r, offsets(ix,:));
                    avg = avg + sum(r,3);
                end
                tuple.red_img = single(avg/scim.nFrames);
            end            
            disp 'finished coarse alignment'
            self.insert(tuple)
        end
    end
    
    methods
        
        function movie = getMovie(self, idx)
            key = fetch(self); 
            assert(length(key)==1, 'one movie at a time please')
            f = getFilename(common.TpScan(key));
            scim = ne7.scanimage.Reader(f{1});
            movie = scim.read(idx);
            [raster, motion] = self.fetch1('raster_correction', 'motion_correction');
            if ~isempty(raster)
                disp 'raster correction...'
                movie = ne7.micro.RasterCorrection.apply(movie, raster);
            end
            if ~isempty(motion)
                disp 'motion correction...'
                movie = ne7.micro.MotionCorrection.apply(movie, motion);
            end
        end
        
        
        function plot(self)
            keys = fetch(self);
            for key = keys'
                if length(keys)>1
                    figure
                end                
                [g,r] = fetch1(tp.Align(key), 'green_img', 'red_img');
                imshowpair(g,r)
            end
        end
                
       
        function savePreview(self)
            for key = fetch(self)'
                [g,r] = fetch1(tp.Align(key), 'green_img', 'red_img');
                g = g-min(g(:));
                g = g/max(g(:));
                if numel(r)==1
                    im = cat(3,g,g,g);
                else
                    r = r-min(r(:));
                    r = r/max(r(:));
                    im = cat(3,r,g,zeros(size(g)));
                end
                f = getFilename(common.TpScan(key));
                f = f{1};
                f = [f(1:end-4) '_view.png'];
                disp(['Saving ' f])
                imwrite(im,f,'png')
            end
        end
    end
end