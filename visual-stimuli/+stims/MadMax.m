classdef MadMax < stims.core.Visual  
    methods
        function showTrial(self, cond)       
            moviename = sprintf(cond.path_template, cond.clip_number);
            movie = Screen('OpenMovie', self.win, moviename);
            Screen('PlayMovie', movie,1);            
            for i=1:ceil(cond.cut_after*self.screen.fps)
                if self.screen.escape, break, end
                tex = Screen('GetMovieImage', self.win, movie);
                if tex<=0
                    break
                end
                Screen('DrawTexture', self.win, tex, [], self.rect)
                self.screen.flip(false, false, i==1)
                Screen('close',tex)
            end
            Screen('CloseMovie',movie)
        end
    end
end