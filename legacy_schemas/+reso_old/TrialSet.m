%{
reso.TrialSet (computed) # set of trials that played during calcium scan
->reso.Sync
-----
%}

classdef TrialSet < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.TrialSet')
        popRel = reso.Sync & psy.Trial;
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            self.insert(key)
            makeTuples(reso.Trial, key)
        end
    end
end