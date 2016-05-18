classdef MovieStill < stims.core.Visual
    
    methods
        
        function showTrial(self, cond)
            img = fetch1(psy.MovieStill & cond, 'still_frame');
            
            % blank the screen if there is a blanking period
            if cond.pre_blank_period>0
                if cond.second_photodiode
                    rectSize = [0.05 0.06].*self.rect(3:4);
                    rect = [self.rect(3)-rectSize(1), 0, self.rect(3), rectSize(2)];
                    Screen('FillRect', self.win, 0, rect);
                end
                % display black photodiode rectangle during the pre-blank
                self.screen.flip(false, false, true)
                WaitSecs(cond.pre_blank_period);
            end
            
            tex = Screen('MakeTexture', self.win, img);
            Screen('DrawTexture', self.win, tex, [], self.rect)
            self.screen.flip(false, false, true)
            Screen('close',tex)
            WaitSecs(cond.duration);
        end
    end
end