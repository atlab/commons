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
motion_correction           : longblob                      # motion correction offsets
motion_rms                  : float                         # (um) stdev of motion
green_img                   : longblob                      # mean corrected image
red_img                     : longblob                      # mean corrected image
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
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            % read the green movie
            disp 'reading tiff file'
            f = getFilename(common.TpScan(key));
            f = f{1};
            s = ne7.scanimage.Reader(f);
            fov = fetch1(common.TpSession(key),'fov');
            
            [g, discardedFinalLine] = s.read(1);
            gmean = mean(g,3);
            gmean = gmean-min(gmean(:));
            gmean = uint8(255*gmean./max(gmean(:)));
            tuple = key;
            tuple.green_uncorrected = gmean;

            tuple.discarded_final_line = discardedFinalLine;

            tuple.fps = s.hdr.acq.frameRate;
            tuple.dwell_time = s.hdr.acq.pixelTime*1e6;
            
            tuple.nframes = s.hdr.acq.numberOfFrames;
            tuple.px_width = size(g,2);
            tuple.px_height = size(g,1);
            tuple.um_width  = abs(fov/(s.hdr.acq.zoomFactor * s.hdr.acq.baseZoomFactor) ...
                * s.hdr.acq.scanAngleMultiplierFast);
            tuple.um_height = abs(fov/(s.hdr.acq.zoomFactor * s.hdr.acq.baseZoomFactor) ...
                * s.hdr.acq.scanAngleMultiplierSlow);
            
            pitchRatio = (tuple.um_width/tuple.px_width)/(tuple.um_height/tuple.px_height);
            if pitchRatio > 1.02 || pitchRatio < 0.98
                warning 'non-isometric pixels'
            end
            
            disp 'raster correction'
            warp = ne7.micro.RasterCorrection.fit(g, [3 5]);
            tuple.raster_correction = warp;
            g = ne7.micro.RasterCorrection.apply(g, warp);
            
            disp 'motion correction...'
            assert(s.hdr.acq.fastScanningX==1 & s.hdr.acq.fastScanningY==0, 'x must be the fast axis')
            
            offsets = ne7.micro.MotionCorrection.fit(g);
            tuple.motion_correction = int16(offsets);
            tuple.motion_rms = mean(std(offsets).*[tuple.um_height tuple.um_width]./[tuple.px_height tuple.px_width]);
            
            disp 'averaging frames...'
            g = ne7.micro.MotionCorrection.apply(g, offsets);
            tuple.green_img = single(mean(g,3));
            clear g
            try
                block = 256;
                avg = 0;
                for i=1:block:s.nFrames
                    ix = i:min(i+block-1,s.nFrames);
                    r = s.read(2,ix);
                    r = ne7.micro.RasterCorrection.apply(r, warp(ix,:,:));
                    r = ne7.micro.MotionCorrection.apply(r, offsets(ix,:));
                    avg = avg + sum(r,3)/s.nFrames;
                end
                tuple.red_img = single(avg);
            catch   %#ok<CTCH>
                tuple.red_img = 0;
            end
            
            disp done.
            
            self.insert(tuple)
        end
    end        
    
    methods
        
        function movie = getMovie(self, idx)
            key = fetch(self);
            cachePath = '/Volumes/stage/cache/corrected_movies';
            cacheFile = fullfile(cachePath, sprintf('movie_%05d_%d_%03d_%u.mat', ...
                key.animal_id, key.tp_session, key.scan_idx, idx));
            if exist(cacheFile, 'file')
                disp 'loading a cached file (after a 30-second pause to reduce race conditions)'
                pause(30)  
                s = load(cacheFile);
                movie = s.movie;
            else
                assert(length(key)==1, 'one movie at a time please')
                f = getFilename(common.TpScan(key));
                s = ne7.scanimage.Reader(f{1});
                movie = s.read(idx);
                [raster, motion] = self.fetch1('raster_correction', 'motion_correction');
                if ~isempty(raster)
                    disp 'raster correction...'
                    movie = ne7.micro.RasterCorrection.apply(movie, raster);
                end
                if ~isempty(motion)
                    disp 'motion correction...'
                    movie = ne7.micro.MotionCorrection.apply(movie, motion);
                end
                if ~exist(cacheFile, 'file') && exist(cachePath, 'dir')
                    save(cacheFile, 'movie', '-v7.3');
                end
            end
        end
        
        function plot(self)
            keys = fetch(self);
            for key = keys'
                if length(keys)>1
                    figure
                end
                [g,r] = fetch1(tp.Align(key), 'green_img', 'red_img');
                g = g-min(g(:));
                g = g/max(g(:));
                r = r-min(r(:));
                r = r/max(r(:));
                im = cat(3,r,g,zeros(size(g)));
                imshow(im)
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
        
        function writeVideo(self, savepath)
            if nargin<2
                savepath = '.';
            end
            for key = fetch(self)'
                disp 'making movie for'
                disp(key)
                clf
                m = tp.Align(key);
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
                system(sprintf('ffmpeg -i %s -y -vcodec -sameq %s', ...
                    fullfile(savepath, fname), fullfile(savepath, ['a' fname])));
                delete(fullfile(savepath,fname))
                
                disp done
            end
        end
    end
end



function v = compressVideo(m, frameRate, targetFrameRate)
% reduce the frame rate to targetFrameRate and conver to uint8
if numel(m)==1
    v = uint8(0);
else       
    offset = 100;    
    m = sqrt(abs(m + offset));  % anscombe transform
    mn = mean(m,3);
    q = quantile(mn(:),0.02);
    mn = mn - q;
    m = m - q;
    m = 255* m / max(mn(:));
    
    nFrames = ceil(size(m,3)*targetFrameRate/frameRate)-1;
    v = zeros(size(m,1), size(m,2), nFrames,'uint8');
    
    i = 1;
    for iFrame = 1:nFrames        
        if iFrame == nFrames
            j = size(m,3);
        else
            j = round(iFrame*frameRate/targetFrameRate);
        end
        v(:,:,iFrame) = uint8(max(m(:,:,i:j),[],3));
        i = j+1;
        
        if mod(i,250)==1
            fprintf('%03d /%03d\n', iFrame, nFrames)
        end
    end
end
end
