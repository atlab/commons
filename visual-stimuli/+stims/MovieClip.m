classdef MovieClip < stims.core.Visual
    
    methods(Access = protected)
        
        function prepare(self)
            % precompute the filenames for all conditions
            filenames = cell(size(self.conditions));
          
            for i=1:length(self.conditions)
                    
                filenames{i} = export(psy.MovieClipStore & self.conditions(i));
                    
                if ~exist(filenames{i}, 'file')
                    stims.core.Visual.screen.close()
                    error('Could not find file %s', filenames{i})
                end
            end
            [self.conditions.filename] = deal(filenames{:}); 
        end        
    end
    
    methods
        
        function showTrial(self, cond)
            movie = Screen('OpenMovie', self.win, cond.filename);
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