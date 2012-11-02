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
            assert(count(tp.Align & key)==1, 'One Movie at a time please')
            filename = getFilename(common.TpScan(key));
            self = self@ne7.scanimage.Reader(filename{1});
            self.key = key;
            if nargin < 2
                if exists(tp.FineAlign & key)
                    [warp, warpDegree] = ...
                        fetch1(tp.FineAlign & key, 'warp_polynom', 'warp_degree');
                else
                    warp = fech1(tp.Align & key, 'motion_correction');
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
            self.degrees = [0 0 -1];
            
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
        
        
        function write(self, savepath)
            % save an AVI file
            if nargin<2
                savepath = '.';
            end
            fname = sprintf('%05d_%03d.avi', self.key.animal_id, self.key.scan_idx);

            fprintf('making avi %s for\n', fullfile(savepath, fname))
            disp(self.key)
            clf
            targetFps = 3; % Hz
            disp 'reading green channel...'
            g = self.getFrames(1,1:self.nFrames);
            disp 'compressing green channel...'           
            g = compressVideo(g, self.fps, targetFps);
            
            disp 'reading red channel...'
            r = self.getFrames(2,1:self.nFrames);
            disp 'compressing red channel...'
            r = compressVideo(r, self.fps, targetFps);
            
            disp 'saving AVI...'
            g = cat(4,r,g,zeros(size(g),'uint8'));
            g = permute(g, [1 2 4 3]);
            
            v = VideoWriter(fullfile(savepath,fname));   
            v.FrameRate = 30;
            v.Quality = 100;
            v.open
            v.writeVideo(g)
            v.close
            
            disp 'converting avi'
            system(sprintf('ffmpeg -i %s -y -sameq %s', ...
                fullfile(savepath, fname), fullfile(savepath, ['c' fname])));
            delete(fullfile(savepath,fname))
            
            disp done
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
    end
end
end
