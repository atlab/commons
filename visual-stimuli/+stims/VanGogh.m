classdef VanGogh < stims.core.Visual
    
    properties
        nBlocks = 1
        
        params = struct(...
            'rng_seed',    1:60,         ... RNG seed 1:150
            'luminance',   10,           ... cd/m^2
            'contrast',    0.95,        ... Michelson's 0-1
            'duration', 30,            ... (seconds)
            'tex_ydim', 150,           ... (pixels) texture dimension
            'tex_xdim', 256,           ... (pixels) texture dimension
            'spatial_freq_half', 0.04, ... (cy/deg) spatial frequency modulated to 50
            'spatial_freq_stop', 0.3,  ... (cy/deg), spatial lowpass cutoff
            'temp_bandwidth', 4,       ... (Hz) temporal bandwidth
            'ori_bandwidth', pi / 20,  ... (rad) bandwidth of orientation filter
            'ori_map_spatial_bandwidth', 0.05,  ... (cy/deg) spatial bandwidth for ori map
            'ori_map_temp_bandwidth', 1,        ... (Hz) temporal bandwidth for ori map
            'contrast_spatial_bandwidth', 0.03, ... (cy/deg) spatial bandwidth of contrast map
            'contrast_temp_bandwidth', 1,       ... (Hz) temporal bandwidth of contrast map
            'contrast_exponent', 1/3            ... exponent of power function for contrast map
            )
    end
     
    methods
        function d = degPerPix(self)
            % assume isometric pixels
            rect = self.rect;
            if isempty(rect)  % hack for precomputing
                rect = [0 0 1024 600];
            end
            d = 180/pi*self.constants.monitor_size*2.54/norm(rect(3:4))/self.constants.monitor_distance;
        end           
    end
    
   
    
    methods(Access=protected)
        
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
            self.frameStep = cond.frame_downsample;
            self.saveAfterEachTrial = true;
            for i=1:size(cond.movie,3)
                if self.escape, break, end
                tex = Screen('MakeTexture', self.win, cond.movie(:,:,i));
                Screen('DrawTexture',self.win, tex, [], self.rect)
                self.flip(false, false, i==1)
                Screen('close',tex)
            end
        end
    end
end