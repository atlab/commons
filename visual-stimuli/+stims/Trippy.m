classdef Trippy < stims.core.Visual
    
    methods(Access=protected)
        
        function d = degPerPix(self)
            % assume isometric pixels
            rect = self.rect;
            if isempty(rect)
                rect = [0 0 1024 600];
            end
            d = 180/pi*self.constants.monitor_size*2.54/norm(rect(3:4))/self.constants.monitor_distance;
        end
        
        
        function prepare(self)
            if ~isfield(self.conditions, 'movie')
                disp 'precomuting movies...'
                rect = self.rect;
                if isempty(rect)
                    rect = [0 0 1024 600];
                end
                fps = self.screen.fps;
                if isempty(fps)
                    fps = 60;
                end
                newConditions = [];
                for iCond=1:length(self.conditions)
                    fprintf .
                    cond = self.conditions(iCond);
                    cond.packed_phase_movie = ...
                        psy.Trippy.make_packed_phase_movie(...
                        cond, fps/cond.frame_downsample, self.degPerPix*rect(3:4));
                    cond.version = psy.Trippy.version;
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
            fps = self.screen.fps;
            if isempty(fps)
                fps = 60;
            end
            assert(~isnan(self.constants.monitor_distance), 'monitor distance is not set')
            self.screen.setContrast(cond.luminance, cond.contrast)
            self.screen.frameStep = cond.frame_downsample;
            movie = psy.Trippy.interp_time(cond.packed_phase_movie, cond, fps/cond.frame_downsample);
            for i=1:size(movie,1)
                if self.screen.escape, break, end
                m = psy.Trippy.interp_space(movie(i,:), cond);
                m = (cos(2*pi*m)+1)/2*253+1;
                tex = Screen('MakeTexture', self.win, m);
                Screen('DrawTexture', self.win, tex, [], self.rect)
                self.screen.flip(false, false, i==1)
                Screen('close', tex)  % delete the texture
            end
        end
    end
end