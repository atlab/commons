classdef Looming < stims.core.Visual
        
    properties
        
        nBlocks = 20
        
        % DataJoint tables for data logging
        logger = stims.core.Logger(psy.Session, psy.Condition, psy.Trial, psy.Looming)

        tables = struct(...
            'session',    psy.Session, ...
            'condition',  psy.Condition, ...
            'parameters', psy.Looming, ...
            'trial',      psy.Trial)
        
        % stimulus settings
        constants = struct(...
            'stimulus', 'looming disk', ...
            'monitor_distance', nan, ...  (cm)
            'monitor_size', 19, ...       (inches) diagonal
            'monitor_aspect', 1.25, ...
            'resolution_x', 1280, ...     (pixels)
            'resolution_y', 1024 ...      (pixels)
            )
        
        params = struct(...
            'luminance',  5, ...       :  cd/m^2
            'contrast', 0.95, ...      :  float    # 0 .. 1 
            'bg_color', 0.5, ...   # 0 .. 1 
            'color',    0, ...         :  float    # 0 .. 1
            'pre_blank', 6, ...     :  float    # seconds - blank screen duration
            'looming_rate', [0.5 1 2], ... :  float    # 1/sec  --   speed / object size
            'loom_duration', 2, ... :  float    # seconds
            'final_radius', 30 ...  :  float    # degrees
            )
    end
        
       
    
    methods(Access=protected)
        
        function showTrial(self, cond)
            % execute a single trial with a single cond
            % See PsychToolbox DriftDemo4.m for API calls
            assert(~isnan(self.constants.monitor_distance), 'monitor distance is not set')
            
            assert(all(ismember({
                'luminance'
                'contrast'
                'bg_color'
                'color'
                'pre_blank'
                'looming_rate'
                'loom_duration'
                'final_radius'
                }, fieldnames(cond))))
            
            self.screen.setContrast(cond.luminance, cond.contrast)
            self.flip(true, false, true)
            WaitSecs(cond.pre_blank);
            
            nFrames = floor(cond.loom_duration*self.screen.fps);
            
            center = self.rect(3:4)/2;
            monitorHeight = self.constants.monitor_size/sqrt(self.constants.monitor_aspect.^2+1)*2.54; % cm
            pixDistance  = self.rect(4)/monitorHeight*self.constants.monitor_distance;  % distance to monitor in pixels
            pixFinalRadius = pixDistance*tan(cond.final_radius*pi/180);
            for i=1:nFrames
                if self.escape, break, end              
                Screen('FillRect', self.win, round(cond.bg_color*255), self.rect)
                remainingTime = cond.loom_duration-(i-1)/self.screen.fps;
                radius = pixFinalRadius/(1 + cond.looming_rate*remainingTime*pixFinalRadius/pixDistance);
                rect = [center center] + [-radius -radius radius radius]; 
                Screen('FillOval', self.win, round(cond.color*255), rect);
                self.flip(false, false, i==1)
            end
        end
    end
end