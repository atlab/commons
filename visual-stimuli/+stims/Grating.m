classdef Grating < stims.core.Visual
    
    properties
        nBlocks = 12       
        logger = stims.core.Logger(psy.Session, psy.Condition, psy.Trial, psy.Grating)
        
        % stimulus settings
        constants = struct(...
            'stimulus', 'grating', ...
            'monitor_distance', nan, ...  (cm)
            'monitor_size', 19, ...       (inches) diagonal
            'monitor_aspect', 1.25, ...
            'resolution_x', 1280, ...     (pixels)
            'resolution_y', 1024 ...      (pixels)
            )
        
        params = struct(...
            'pre_blank', 0.5, ...   (s) blank period preceding trials
            'luminance', 5, ...    cd/m^2 mean
            'contrast', 0.95, ...  Michelson contrast 0-1
            'aperture_radius', 0.63, ...  % in units of half-diagonal, 0=no aperture
            'aperture_x', 0, ... % 0=center, in units of half-diagonal
            'aperture_y', 0, ... % 0=center, in units of half-diagonal
            'grating', 'sqr', ...     enum('sqr','sin'), sinusoidal or square, etc.
            'drift_fraction', 1, ...   the fraction of the trial duration taken by drifting grating
            'spatial_freq', 0.04, ...  cycles/degree
            'init_phase', 0, ...   between 0 and 1
            'trial_duration', 0.5, ... (s)
            'temp_freq', 2, ... (Hz)'
            'direction', 0:22.5:359 ... (degrees) 0=north, 90=east
            )
    end
    
    properties(Access=private)
        % textures
        grating
        mask 
    end
    
    
    methods
        function d = degPerPix(self)
            % assume isometric pixels
            d = 180/pi*self.constants.monitor_size*2.54/norm(self.rect(3:4))/self.constants.monitor_distance; 
        end
    end
    
    
    methods(Access=protected)
        
        function showTrial(self, cond)
            % execute a single trial with a single cond
            % See PsychToolbox DriftDemo4.m for API calls
            assert(~isnan(self.constants.monitor_distance), 'monitor distance is not set')
            
            assert(all(ismember({
                'pre_blank'
                'luminance'
                'contrast'
                'grating'
                'aperture_radius'
                'aperture_x'
                'aperture_y'
                'init_phase'
                'spatial_freq'
                'temp_freq'
                'direction'
                'drift_fraction'
                'trial_duration'
                }, fieldnames(cond))))
            
            % initialized grating
            if isempty(self.grating)
                if ~strcmp(getenv('USER'), 'dimitri')
                    % make sure that the monitor is set to the correct resolution
                    assert(all(self.rect(3:4)==[self.constants.resolution_x self.constants.resolution_y]), ...
                        'incorrect monitor resolution')
                end
                radius = inf;
                if cond.aperture_radius
                    radius = cond.aperture_radius * norm(self.rect(3:4))/2;
                end
                self.grating = CreateProceduralSineGrating(self.win, self.rect(3), self.rect(4), [0.5 0.5 0.5 0.0], radius);
            end
            
            self.screen.setContrast(cond.luminance, cond.contrast, strcmp(cond.grating,'sqr'))
            phase = cond.init_phase;
            freq = cond.spatial_freq * self.degPerPix;  % cycles per pixel
            if cond.pre_blank>0
                self.flip(false, false, true)
                WaitSecs(cond.pre_blank);
            end
            
            % update direction to correspond to 0=north, 90=east, 180=south, 270=west
            direction = cond.direction + 90;
            
            % display static grating
            if cond.drift_fraction<1.0
                Screen('DrawTexture', self.win, self.grating, [], [],...
                    direction, [], [], [], [], kPsychUseTextureMatrixForRotation, [phase*360, freq, 0.495, 0]);
                self.flip(false, false, true)
                WaitSecs((1-cond.drift_fraction)*cond.trial_duration);
            end
            
            % display drifting grating
            driftFrames = floor(cond.drift_fraction * cond.trial_duration * self.screen.fps);
            phaseIncrement = cond.temp_freq/self.screen.fps;
            offset = [cond.aperture_x cond.aperture_y]*norm(self.rect(3:4))/2;
            destRect = self.rect + [offset offset];
            for frame = 1:driftFrames
                if self.escape, break, end
                Screen('DrawTexture', self.win, self.grating, [], destRect, direction, [], [], [], [], ...
                    kPsychUseTextureMatrixForRotation, [phase*360, freq, 0.495, 0]);
                if ~isempty(self.mask)
                    Screen('DrawTexture', self.win, self.mask);
                end
                phase = phase + phaseIncrement;
                self.flip(false, false, frame==1)
            end
        end
    end
end