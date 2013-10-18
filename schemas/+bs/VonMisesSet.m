%{
bs.VonMisesSet (computed) # von mises tuning of groups of traces from the same slice
-> reso.TrialTraceSet
-> bs.BrainState
-> bs.TuningCondition
-----
ndirs           : tinyint     # number of directions
nshuffles=10000 : int         # numbger of shuffles for p-value computation
%}

classdef VonMisesSet < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('bs.VonMisesSet')
        popRel = pro(bs.TuningCondition*reso.TrialTraceSet*bs.BrainState, psy.Grating, ...
            'count(distinct direction)->ndirs') & 'ndirs>=8';
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            directions = unique(fetchn(psy.Grating & key, 'direction'));
            nDirs = length(directions);
            assert(nDirs>=8 && ~mod(nDirs,2) && all(directions == (0:360/nDirs:359)'),...
                'directions must be sufficient and evenly distributed')
            tuple = key;
            tuple.ndirs = length(directions);
            self.insert(tuple)
            makeTuples(bs.VonMises, key)
        end
    end
end