classdef MovingNoise < stims.core.Visual
    
    properties
        nBlocks = 1
        
        params = struct(...
            'rng_seed',    1:150,         ... RNG seed
            'luminance',   10,           ... cd/m^2
            'contrast',    0.95,        ... Michelson's 0-1
            'tex_ydim',    150,          ... (pixels) texture dimension
            'tex_xdim',    256,          ... (pixels) texture dimension
            'spatial_freq_half', 0.05,  ... (cy/deg) spatial frequency modulated to 50
            'spatial_freq_stop',0.2,    ... (cy/deg), spatial lowpass cutoff
            'temp_bandwidth', 4,        ... (Hz) temporal bandwidth
            'contrast_mod_freq', 1/6, ... (Hz) raised cosine contrast modulation
            'contrast_slope', 5,        ... onset slope
            'modulation_shift', 0.2,      ... shift of the signamoid argument (cosine value)
            'frame_downsample', 1,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
            'duration', 6              ... (s) trial duration
            )
    end
    
    
    methods
        function d = degPerPix(self)
            % assume isometric pixels
            d = 180/pi*self.constants.monitor_size*2.54/norm(self.rect(3:4))/self.constants.monitor_distance;
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
                    lookup = psy.NoiseMapLookup;
                    [movie, key] = ...
                        lookup.lookup(cond, self.degPerPix*self.rect(3:4), ...
                        self.screen.fps/cond.frame_downsample);
                    cond = dj.struct.join(self.conditions(iCond), key);
                    cond.movie = movie;
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
                'contrast_mod_freq'
                'duration'
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