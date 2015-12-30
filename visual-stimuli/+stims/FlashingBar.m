classdef FlashingBar < stims.core.Visual
    
    properties
        
        params = struct(...
            'pre_blank', 1.5, ... (s) blank period preceding trials
            'orientation', [0 90],   ... (degrees) 0=horizontal,  90=vertical
            'luminance', 5, ...     (cd/m^2) mid-value luminance
            'contrast', 0.95, ...   (0-1) Michelson contrast
            'bg_color', 127, ...   0-254
            'offset', -0.8:0.05:0.8, ... normalized by half-diagonal
            'width', 0.05,  ... normalized by half-diagonal
            'trial_duration', 1, ... (s) ON time of flashing bar
            'pattern_frequency', 8 ... (Hz) will be rounded to nearest fraction of fps
            )
    end
    
    
    methods(Access=protected)
        
        function showTrial(self, cond)
            % execute a single trial with a single cond
            assert(~isnan(self.constants.monitor_distance), 'monitor distance is not set')
            patterns = [0 31 0 31 10 21 10 21 3 28 6 25 12 19 24 7 17 14];
            ncells = ceil(log2(max(patterns)));
            self.screen.setContrast(cond.luminance, cond.contrast)
            self.flip(true, false, true)
            WaitSecs(cond.pre_blank);
            
            self.frameStep = round(self.screen.fps/cond.pattern_frequency);
            self.saveAfterEachTrial = true;
            
            nFrames = floor(cond.trial_duration*self.screen.fps/self.frameStep);
            theta = (cond.orientation-90)/180*pi;   % 0 = north, 90 = east
            
            scale = norm(self.rect(3:4))/2;
            halfWidth = scale*cond.width;
            halfLength = 0.9*scale;
            
            current_pattern = 1;
            for i=1:nFrames
                Screen('FillRect', self.win, cond.bg_color, self.rect)   % background
                if self.escape, break, end
                if i<nFrames
                    current_pattern = mod(current_pattern, length(patterns)) + 1;
                    x = cond.offset*cos(theta)*scale + self.rect(3)/2;
                    y = cond.offset*sin(theta)*scale + self.rect(4)/2;
                    pattern = dec2bin(patterns(current_pattern), ncells) - 48;
                    pattern = imresize(pattern,[1 length(pattern)*8], 'nearest');
                    tex = Screen('MakeTexture', self.win, pattern'*255);
                    Screen('DrawTexture', self.win, tex, [], ...
                        [x-halfWidth, y-halfLength, x+halfWidth, y+halfLength], cond.orientation-90)
                end
                self.flip(false, false, i==1)
            end
        end
    end
end