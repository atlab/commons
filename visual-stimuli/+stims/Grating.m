classdef Grating < stims.core.Visual
    
    properties
        nBlocks = 12       
        logger = stims.core.Logger(psy.Session, psy.Condition, psy.Trial, psy.Grating)
        
        % stimulus settings
        constants = struct(...
            'stimulus', 'grating', ...
            'monitor_distance', nan, ...  (cm)
            'monitor_size', 7, ...       (inches) diagonal
            'monitor_aspect', 1.7, ...   (physical aspect ratio W/H)
            'resolution_x', 1024, ...     (pixels)
            'resolution_y',  600 ...      (pixels)
            )
        
        params = struct(...
            'pre_blank', 0.5, ...   (s) blank period preceding trials
            'luminance', 5, ...    cd/m^2 mean
            'contrast', 0.95, ...  Michelson contrast 0-1
            'aperture_radius', 0.63, ...  % in units of half-diagonal, 0=no aperture
            'aperture_x', 0, ... % 0=center, in units of half-diagonal
            'aperture_y', 0, ... % 0=center, in units of half-diagonal
            'grating', 'sqr', ...     enum('sqr','sin'), sinusoidal or square, etc.
            'spatial_freq', 0.04, ...  cycles/degree
            'init_phase', 0, ...   between 0 and 1
            'trial_duration', 0.5, ... (s)
            'temp_freq', 2, ... (Hz)'
            'direction', 0:22.5:359, ... (degrees) 0=north, 90=east
            'phase2_fraction', 0,  ... between 0 and 1
            'phase2_temp_freq', 2, ...
            'second_photodiode', 0 ... 1=paint white photodiode patch, -1=black, 0=none
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
                'trial_duration'
                'phase2_fraction'
                'phase2_temp_freq'
                'second_photodiode'
                }, fieldnames(cond))))
            
            % initialized grating
            if isempty(self.grating)
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
            
          
            % display drifting grating
            driftFrames1 = floor(cond.trial_duration * (1-cond.phase2_fraction) * self.screen.fps);
            driftFrames2 = floor(cond.trial_duration * cond.phase2_fraction * self.screen.fps);
            phaseIncrement1 = cond.temp_freq/self.screen.fps;
            phaseIncrement2 = cond.phase2_temp_freq/self.screen.fps;
            offset = [cond.aperture_x cond.aperture_y]*norm(self.rect(3:4))/2;
            destRect = self.rect + [offset offset];
            % display phase1 grating
            for frame = 1:driftFrames1
                if self.escape, break, end
                Screen('DrawTexture', self.win, self.grating, [], destRect, direction, [], [], [], [], ...
                    kPsychUseTextureMatrixForRotation, [phase*360, freq, 0.495, 0]);                
                if ~isempty(self.mask)
                    Screen('DrawTexture', self.win, self.mask);
                end
                if cond.second_photodiode
                    rectSize = [0.05 0.06].*self.rect(3:4);  
                    rect = [self.rect(3)-rectSize(1), 0, self.rect(3), rectSize(2)];
                    color = (cond.second_photodiode+1)/2*255;
                    Screen('FillRect', self.win, color, rect);
                end
                phase = phase + phaseIncrement1;
                self.flip(false, false, frame==1)
            end
            % display phase2 grating
            for frame = 1:driftFrames2
                if self.escape, break, end
                Screen('DrawTexture', self.win, self.grating, [], destRect, direction, [], [], [], [], ...
                    kPsychUseTextureMatrixForRotation, [phase*360, freq, 0.495, 0]);
                if ~isempty(self.mask)
                    Screen('DrawTexture', self.win, self.mask);
                end
                phase = phase + phaseIncrement2;
                self.flip(false, false, frame==1)
            end
        end
    end
end