classdef VanGogh < stims.core.Visual
    
    methods(Access=protected)
        
        function d = degPerPix(self)
            % assume isometric pixels
            rect = self.rect;
            if isempty(rect)  % hack for precomputing
                rect = [0 0 1024 600];
            end
            d = 180/pi*self.constants.monitor_size*2.54/norm(rect(3:4))/self.constants.monitor_distance;
        end
        
        
        function prepare(self)
            if ~isfield(self.conditions, 'movie')
                % pre-compute movies
                disp 'making movies'
                newConditions = [];
                for iCond=1:length(self.conditions)
                    fprintf .
                    cond = self.conditions(iCond);
                    lookup = psy.VanGoghLookup;
                    rect = self.rect;
                    if isempty(rect)
                        rect = [0 0 1024 600];  % hack!
                    end
                    fps = self.screen.fps;
                    if isempty(fps)
                        fps = 60;   % hack!
                    end
                    [movie, key] = ...
                        lookup.lookup(cond, self.degPerPix*rect(3:4), ...
                        fps/cond.frame_downsample);
                    cond = dj.struct.join(self.conditions(iCond), key);
                    cond.movie = max(1,min(254, movie));  % 0 and 255 are reserved for flips
                    newConditions = [newConditions; cond]; %#ok<AGROW>
                end
                fprintf \n
                self.conditions = newConditions;
            end
        end
    end
    
    
    methods
        function showTrial(self, cond)
            % execute a single trial with a single cond
            % See PsychToolbox DriftDemo4.m for API calls
            assert(~isnan(self.constants.monitor_distance), 'monitor distance is not set')
            
            assert(all(ismember({
                'rng_seed'
                'luminance'
                'contrast'
                'tex_ydim'
                'tex_xdim'
                'spatial_freq_half'
                'spatial_freq_stop'
                'temp_bandwidth'
                'frame_downsample'
                'movie'
                }, fieldnames(cond))))
            
            self.screen.setContrast(cond.luminance, cond.contrast)
            self.screen.frameStep = cond.frame_downsample;
            for i=1:size(cond.movie,3)
                if self.escape, break, end
                tex = Screen('MakeTexture', self.win, cond.movie(:,:,i));
                Screen('DrawTexture',self.win, tex, [], self.rect)
                self.screen.flip(false, false, i==1)
                Screen('close',tex)
            end
        end
    end
end