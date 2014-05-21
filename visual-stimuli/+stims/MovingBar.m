classdef MovingBar < stims.core.Visual
        
    properties
        
       
        % stimulus settings
        
        params = struct(...
            'pre_blank', 0, ...   (s) blank period preceding trials
            'luminance', 5, ...    cd/m^2 mid-value luminance"
            'contrast', 0.95, ...  Michelson contrast
            'bg_color', 127, ...   0-254
            'bar_color', 254, ... 0-254
            'direction', 0:45:359, ... (degrees) 0=north, 90=east
            'bar_length', 1, ... in units of half-diagonal
            'bar_width', 0.04, ... in units of half-diagonal
            'bar_offset', 0, ... offset to the right (when facing in direction of motion) in units of half-diagonal
            'start_pos', -1, ... the starting position of the bar moviement. 1 is the distance from the center to corner"
            'end_pos', 1, ... (-1 1) the ending position of the bar movement
            'trial_duration', 6 ... (s) movement duration
            )
    end
    
    properties(Access=private)
        grating
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
                'bg_color'
                'bar_color'
                'direction'
                'bar_length'
                'bar_width'
                'bar_offset'
                'start_pos'
                'end_pos'
                'trial_duration'
                }, fieldnames(cond))))
            
            self.screen.setContrast(cond.luminance, cond.contrast)
            self.flip(true, false, true)
            WaitSecs(cond.pre_blank);
            
            nFrames = floor(cond.trial_duration*self.screen.fps);
            theta = (cond.direction-90)/180*pi;   % 0 = north, 90 = east
            
            scale = norm(self.rect(3:4))/2;
            tex = Screen('MakeTexture', self.win, cond.bar_color);
            halfWidth = scale*cond.bar_width;
            halfLength = scale*cond.bar_length;
            
            for i=1:nFrames
                if self.escape, break, end
                
                Screen('FillRect', self.win, cond.bg_color, self.rect)
                y0= cond.bar_offset;
                x0= cond.start_pos + (cond.end_pos-cond.start_pos)*(i-1)/(nFrames-1);
                
                x = x0*cos(theta) - y0*sin(theta);
                y = x0*sin(theta) + y0*cos(theta);
                x = x*scale + self.rect(3)/2;
                y = y*scale + self.rect(4)/2;
                
                Screen('DrawTexture', self.win, tex, [], [x-halfWidth, y-halfLength, x+halfWidth, y+halfLength], cond.direction-90)
                self.flip(false, false, i==1)
            end
        end
    end
end