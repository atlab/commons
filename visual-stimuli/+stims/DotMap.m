classdef DotMap < stims.core.Visual
        
    properties       
        nBlocks = 1
        
        % DataJoint tables for data logging
        logger = stims.core.Logger(psy.Session, psy.Condition, psy.Trial, psy.DotMap)        
        
        % stimulus settings
        constants = struct(...
            'stimulus', 'dot map', ...
            'monitor_distance', nan, ...  (cm)
            'monitor_size', 19, ...       (inches) diagonal
            'monitor_aspect', 1.25, ...
            'resolution_x', 1280, ...     (pixels)
            'resolution_y', 1024 ...      (pixels)
            )
        
        params = struct(...
            'rng_seed',    1:44,        ... RNG seed
            'luminance',   5,           ... cd/m^2
            'contrast',    0.95,        ... Michelson's 0-1
            'bg_color',    96,         ... (0-255) the index of the background color
            'tex_xdim',    15,          ... (pixels) texture dimension
            'tex_ydim',    12,          ... (pixels) texture dimension
            'frame_downsample', 3,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
            'dots_per_frame', 1,        ... number of new dots displayed in each frame
            'linger_frames', 5          ... the number of frames each dot persists
            )
    end
        
    
    
            
    methods(Access=protected)

        function showTrial(self, cond)
            % execute a single trial with a single cond
            % See PsychToolbox DriftDemo4.m for API calls
            assert(~isnan(self.constants.monitor_distance), 'monitor distance is not set')
            
            assert(all(ismember({
                'rng_seed'
                'luminance'
                'contrast'
                'bg_color'
                'tex_ydim'
                'tex_xdim'
                'frame_downsample'
                'dots_per_frame'
                'linger_frames'
                }, fieldnames(cond))))
            
            self.screen.setContrast(cond.luminance, cond.contrast)
            self.frameStep = cond.frame_downsample;
            self.saveAfterEachTrial = true;
            
            
            Screen('FillRect', self.win, cond.bg_color, self.rect)            

            [x, y, color] = stims.DotMap.makeDots(cond);
            nDots = length(x);
            width = self.rect(3)/cond.tex_xdim;
            height = self.rect(4)/cond.tex_ydim;
            x = x*width;
            y = y*height;
            rects = [x' y' x'+width y'+height]; 

            nFrames = length(x)/cond.dots_per_frame+cond.linger_frames+1;
            iDot  = 0;
            iBlot = -cond.linger_frames*cond.dots_per_frame;
            for i=1:nFrames
                if self.escape, break, end
                for j=1:cond.dots_per_frame
                    iDot = iDot+1;
                    iBlot = iBlot+1;
                    if iDot<=nDots
                        Screen('FillOval', self.win, color(iDot), rects(iDot,:))
                    end
                    if iBlot>=1 && iBlot<=nDots
                        Screen('FillOval', self.win, cond.bg_color, rects(iBlot,:))
                    end
                end
                if self.escape, break, end
                self.flip(false, true, i==1)
            end
            if self.escape
                self.flip(true, false, true);
            end
        end
    end
    
    methods(Static)
        function [x, y, c] = makeDots(cond)
            % set random number generator
            r = RandStream.create('mt19937ar', 'Seed', cond.rng_seed);
            
            % generate non-overlapping dots
            success = false;
            while ~success
                queue = r.randperm(cond.tex_ydim*cond.tex_xdim*2)-1;
                pos = bitshift(queue,-1);
                success = true;
                % prevent dots from occupying the same spot around the same time
                for i=1:cond.linger_frames*cond.dots_per_frame-1
                    if any(pos(1:end-i) == pos(1+i:end))
                        success = false;
                        break
                    end
                end
            end
            c = bitand(queue,1)*254;
            x = floor(pos/cond.tex_ydim);
            y = mod(pos, cond.tex_ydim);
        end        
    end
end