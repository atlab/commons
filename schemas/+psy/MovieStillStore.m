%{
psy.MovieStillStore (imported) # cached still frames from the movie
-> psy.MovieInfo
-----
%}

classdef MovieStillStore < dj.Relvar & dj.AutoPopulate
    properties
        popRel = psy.MovieInfo
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            self.insert(key);
            makeTuples(psy.MovieStill, key)
        end
    end
end