classdef FlashingBar < stims.core.Visual
    
    
    methods
        
        function showTrial(self, cond)
            patterns = [0 31 0 31 10 21 10 21 3 28 6 25 12 19 24 7 17 14];
            ncells = ceil(log2(max(patterns)));
            self.screen.setContrast(cond.luminance, cond.contrast)
            self.screen.flip(true, false, true)
            WaitSecs(cond.pre_blank);
            
            self.screen.frameStep = round(self.screen.fps/cond.pattern_frequency);            
            nFrames = floor(cond.trial_duration*self.screen.fps/self.screen.frameStep);
            theta = (cond.orientation-90)/180*pi;   % 0 = north, 90 = east
            
            scale = norm(self.rect(3:4))/2;
            halfWidth = scale*cond.width;
            halfLength = 0.9*scale;
            
            current_pattern = 1;
            for i=1:nFrames
                Screen('FillRect', self.win, cond.bg_color, self.rect)   % background
                if self.screen.escape, break, end
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
                self.screen.flip(false, false, i==1)
            end
        end
    end
end