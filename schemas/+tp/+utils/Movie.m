classdef Movie < ne7.scanimage.Reader
    % a wrapper around ne7.scanimage.Reader with motion and raster
    % correction
    
    properties
        key       % datajoint restrictor to select a tp.Align
        fps       % frames per second
        raster    % raster correction
        motion    % motion correction
        degrees   % polynomial degrees
        dx        % in microns
        dy        % in microns
    end
    
    
    methods
        function self = Movie(key, warp, warpDegree)
            % get the filename and call superclass' constructor
            assert(count(tp.Align & key)==1, 'One Movie at a caTimes please')
            filename = getFilename(common.TpScan(key));
            self = self@ne7.scanimage.Reader(filename{1});
            self.key = key;
            if nargin < 2
                if exists(tp.FineAlign & key)
                    [warp, warpDegree] = ...
                        fetch1(tp.FineAlign & key, 'warp_polynom', 'warp_degree');
                else
                    warp = fetch1(tp.Align & key, 'motion_correction');
                    warpDegree = 0;
                end
            end
            self.motion = warp;
            self.degrees = [warpDegree warpDegree size(self.motion,2)-2*(warpDegree+1)];
            
            [self.raster, self.fps, self.dx, self.dy] = ...
                fetch1(tp.Align & key, 'raster_correction', 'fps', ...
                'um_width/px_width->px', 'um_height/px_height->py');
            assert(max(self.dx,self.dy)/min(self.dx,self.dy)<1.1, ...
                'cannot process non-isometric pixels')
            self.nFrames = size(self.raster,1);
            
            % recenter motion
            self.motion = bsxfun(@minus, double(self.motion), median(double(self.motion)));
        end
        
        
        function frames = getFrames(self, channel, frameIdx)
            % read specified frames and apply corrections
            frames = self.read(channel, frameIdx);
            frames = ne7.micro.RasterCorrection.apply(frames, self.raster(frameIdx,:,:));
            for i=1:length(frameIdx)
                frames(:,:,i) = ne7.ip.YWarp.apply(frames(:,:,i), self.motion(frameIdx(i),:), self.degrees);
            end
        end
        
        
        function meanFrame = getMeanFrame(self, channel, frameIdx)
            if nargin<3
                frameIdx = 1:self.nFrames;
            end
            n = length(frameIdx);
            meanFrame = 0;
            for i = frameIdx(:)'
                meanFrame = meanFrame + double(self.getFrames(channel, i))/n;
            end
        end
        
        
        function write(self, savepath, skipCorrections)
            % save an AVI file
            if nargin<2
                savepath = '.';
            end
            skipCorrections = nargin>=3 && skipCorrections;
            fname = sprintf('%05d_%03d.avi', self.key.animal_id, self.key.scan_idx);
            
            fprintf('making avi %s for\n', fullfile(savepath, fname))
            disp(self.key)
            clf
            targetFps = 3; % Hz
            disp 'reading green channel...'
            if skipCorrections
                g = self.read(1,1:self.nFrames);
            else
                g = self.getFrames(1,1:self.nFrames);
            end
            disp 'compressing green channel...'
            g = compressVideo(g, self.fps, targetFps);
            
             disp 'reading red channel...'
             if skipCorrections
                 r = self.read(2,1:self.nFrames);
             else
                 r = self.getFrames(2,1:self.nFrames);
             end
             disp 'compressing red channel...'
             r = compressVideo(r, self.fps, targetFps);
            
            disp 'saving AVI...'
            g = cat(4,r*0,g,zeros(size(g),'uint8'));
            g = permute(g, [1 2 4 3]);
            
            v = VideoWriter(fullfile(savepath,fname));
            v.FrameRate = 30;
            v.Quality = 100;
            v.open
            v.writeVideo(g)
            v.close
            
            if skipCorrections
                prefix = 'u';
            else
                prefix = 'c';
            end
            disp 'converting avi'
            system(sprintf('ffmpeg -i %s -y -sameq %s.mp4', ...
                fullfile(savepath, fname), fullfile(savepath, [prefix fname(1:end-4)])));
            delete(fullfile(savepath,fname))
            disp done
        end
        
        
        function writeStim(self, savepath)
            if nargin<2
                savepath = '.';
            end
            skipCorrections = false;
            % opt = fetch(tp.CaOpt(self.key), '*');
            trialRel = tp.Sync(self.key)*psy.Trial*psy.Grating & ...
                'trial_idx between first_trial and last_trial';
            
            fname = sprintf('stim%05d_%03d.avi', self.key.animal_id, self.key.scan_idx);
            fprintf('making the ori movie %s\n', fullfile(savepath, fname))
            % frames per second in the movie. The movie is typically played
            % back at 30 fps, so the effective speedup of the playback in
            % 30/targetFps.  E.g. if targetFps = 3, the movie plays at 10x
            % the speed.
            targetFps = 7.5; % Hz
            
            % make the stimulus movie
            h = self.height-1;
            stimMovie = zeros(h,h,self.nFrames)+0.5;
            counts = zeros(1,self.nFrames);
            [y,x] = meshgrid(2*(0:h-1)/(h-1)-1, 2*(0:h-1)/(h-1)-1);
            r = x.^2+y.^2;
            mask = 1./(1+exp(50*(r-1)));
            caTimes = fetch1(tp.Sync(self.key), 'frame_times');
            trials = trialRel.fetch('*');
            
            disp 'making stim movie'
            for i=1:length(trials)
                trial = trials(i);
                for iFlip = 2:length(trial.flip_times)
                    phi = trial.direction/180*pi;
                    yy = sin(phi)*x - cos(phi)*y;
                    yy = yy*2;
                    phase = trial.temp_freq*(trial.flip_times(iFlip)-trial.flip_times(2));
                    c = cos(2*pi*(yy - phase));
                    c = 1./(1+exp(10*c));
                    c = 0.5 + (c-0.5).*mask;
                    iFrame = ceil((trial.flip_times(iFlip) - caTimes(2))*self.fps);
                    counts(iFrame) = counts(iFrame)+1;
                    stimMovie(:,:,iFrame) = stimMovie(:,:,iFrame) + (c-stimMovie(:,:,iFrame))/counts(iFrame);
                end
            end
            
            disp 'compressing stim movie..'
            stimMovie = compressVideo(192*stimMovie,self.fps,targetFps,false);
            
            clf
            disp 'reading green channel...'
            if skipCorrections
                g = self.read(1,1:self.nFrames);
            else
                g = self.getFrames(1,1:self.nFrames);
            end
            disp 'compressing green channel...'
            g = compressVideo(g, self.fps, targetFps);
            
            disp 'reading red channel...'
            if skipCorrections
                r = self.read(2,1:self.nFrames);
            else
                r = self.getFrames(2,1:self.nFrames);
            end
            disp 'compressing red channel...'
            r = compressVideo(r, self.fps, targetFps);
            
            disp 'saving AVI...'
            g = cat(4,...
                cat(2,r,stimMovie),...
                cat(2,g,stimMovie),...
                cat(2,zeros(size(g),'uint8'),stimMovie));
            
            g = permute(g, [1 2 4 3]);
            
            v = VideoWriter(fullfile(savepath,fname));
            v.FrameRate = 15;
            v.Quality = 100;
            v.open
            v.writeVideo(g)
            v.close
            
            if skipCorrections
                prefix = 'u';
            else
                prefix = 'c';
            end
            disp 'converting avi'
            system(sprintf('ffmpeg -i %s -y -sameq %s.mp4', ...
                fullfile(savepath, fname), fullfile(savepath, [prefix fname(1:end-4)])));
            delete(fullfile(savepath,fname))
            disp done
            fprintf('making avi %s for\n', fullfile(savepath, fname))
        end
        
        
        
        function writeOri(self, savepath)
            if nargin<2
                savepath = '.';
            end
            skipCorrections = false;
            opt = fetch(tp.CaOpt(self.key) & 'ca_opt=13', '*');
            trialRel = tp.Sync(self.key)*psy.Trial*psy.Grating & ...
                'trial_idx between first_trial and last_trial';
            
            fname = sprintf('ori%05d_%03d.avi', self.key.animal_id, self.key.scan_idx);
            fprintf('making the ori movie %s\n', fullfile(savepath, fname))
            % frames per second in the movie. The movie is typically played
            % back at 30 fps, so the effective speedup of the playback in
            % 30/targetFps.  E.g. if targetFps = 3, the movie plays at 10x
            % the speed.
            targetFps = 6; % Hz
            
            % make the stimulus movie
            h = self.height-1;
            stimMovie = zeros(h,h,3,self.nFrames)+0.5;
            counts = zeros(1,self.nFrames);
            [y,x] = ndgrid(2*(0:h-1)/(h-1)-1, 2*(0:h-1)/(h-1)-1);
            r = x.^2+y.^2;
            mask = 1./(1+exp(50*(r-1)));
            caTimes = fetch1(tp.Sync(self.key), 'frame_times');
            G = tp.OriDesign.makeDesignMatrix(caTimes, trialRel, opt);
            trials = trialRel.fetch('*');
            
            disp 'making ori movie'
            for i=1:length(trials)
                trial = trials(i);
                fprintf .
                for iFlip = 2:length(trial.flip_times)
                    phi = trial.direction/180*pi;
                    hue = mod(phi/pi,1);
                    yy = sin(phi)*x - cos(phi)*y;
                    yy = yy*2;
                    phase = trial.temp_freq*(trial.flip_times(iFlip)-trial.flip_times(2));
                    
                    c = cos(2*pi*(yy - phase));
                    c = 1./(1+exp(10*c));
                    c = hsv2rgb(hue*ones(size(c)),0.5*ones(size(c)),c);
                    c = bsxfun(@times, 0.5 + (c-0.5), mask);
                    
                    iFrame = ceil((trial.flip_times(iFlip) - caTimes(2))*self.fps);
                    counts(iFrame) = counts(iFrame)+1;
                    stimMovie(:,:,:,iFrame) = stimMovie(:,:,:,iFrame) + (c-stimMovie(:,:,:,iFrame))/counts(iFrame);
                end
            end
            
            % make the calcium movie
            
            disp 'compressing stim movie..'
            stimMovie = cat(4,...
                compressVideo(255*squeeze(stimMovie(:,:,1,:)),self.fps,targetFps,false), ...
                compressVideo(255*squeeze(stimMovie(:,:,2,:)),self.fps,targetFps,false), ...
                compressVideo(255*squeeze(stimMovie(:,:,3,:)),self.fps,targetFps,false));
            
            clf
            disp 'reading green channel...'
            if skipCorrections
                g = self.read(1,1:self.nFrames);
            else
                g = self.getFrames(1,1:self.nFrames);
                X = reshape(g,[],size(g,3))';
                X = bsxfun(@minus, X, mean(X));
                fi = (0:size(G,2)-1)/size(G,2)*2*pi;
                G = G*[sin(2*fi') cos(2*fi')];
                G = G*(G'*G)^(-0.5);  % orthonormalize
                X = bsxfun(@rdivide, X, std(X)*sqrt(size(X,1)));
                X = bsxfun(@times, X, reshape(G,[],1,2));
                nor = cumsum(sum(G.^2,2));
                X = cumsum(X);
                ori = atan2(X(:,:,1),X(:,:,2)); 
                ori = reshape(ori,size(g));
                ori = mod(ori/2/pi,1);
                X = bsxfun(@rdivide, squeeze(sum(X.^2,3)), nor);
                X = reshape(X,size(g));
                X = min(1,X/0.05);
                ori = compressVideo(ori*255, self.fps, targetFps, false);
                X = compressVideo(X*255,self.fps,targetFps, false);
                g = compressVideo(g,self.fps,targetFps,false);
                g = cat(4,ori,X,g);
                clear ori X
                sz = size(g);                
                g = permute(g,[1 2 4 3]);
                for i=1:sz(3)
                    g(:,:,:,i) = hsv2rgb(single(squeeze(g(:,:,:,i)))/255)*255;
                end
            end
                        
            disp 'saving AVI...'
            g = cat(2,cat(4,g,g,g),stimMovie);
            
            g = permute(g, [1 2 4 3]);
            
            v = VideoWriter(fullfile(savepath,fname));
            v.FrameRate = 30;
            v.Quality = 100;
            v.open
            v.writeVideo(g)
            v.close
            
            if skipCorrections
                prefix = 'u';
            else
                prefix = 'c';
            end
            disp 'converting avi'
            system(sprintf('ffmpeg -i %s -y -sameq %s.mp4', ...
                fullfile(savepath, fname), fullfile(savepath, [prefix fname(1:end-4)])));
            delete(fullfile(savepath,fname))
            disp done
            fprintf('making avi %s for\n', fullfile(savepath, fname))
        end
        
        
        
    end
end



function v = compressVideo(m, frameRate, targetFrameRate,doMax)
% reduce the frame rate to targetFrameRate and conver to uint8
if numel(m)==1
    v = uint8(0);
else
    doMax=nargin<4 || doMax;
    if doMax 
        offset = 100;
        m = sqrt(abs(m + offset));  
        mn = mean(m,3);
        q = quantile(mn(:),0.02);
        mn = mn - q;
        m = m - q;
        m = 255* m / max(mn(:));
    end
    
    nFrames = ceil(size(m,3)*targetFrameRate/frameRate)-1;
    v = zeros(size(m,1), size(m,2), nFrames,'uint8');
    
    i = 1;
    for iFrame = 1:nFrames
        if iFrame == nFrames
            j = size(m,3);
        else
            j = round(iFrame*frameRate/targetFrameRate);
        end
        if doMax
            v(:,:,iFrame) = uint8(max(m(:,:,i:j),[],3));
        else
            v(:,:,iFrame) = uint8(mean(m(:,:,i:j),3));
        end
        i = j+1;
    end
end
end
