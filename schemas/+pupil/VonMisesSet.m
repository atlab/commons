%{
pupil.VonMisesSet (computed) # von mises tuning conditioned on 
-> reso.TrialTraceSet
-> pupil.TrialSet
-----
ndirs           : tinyint     # number of directions
nshuffles=10000 : int         # numbger of shuffles for p-value computation
%}

classdef VonMisesSet < dj.Relvar & dj.AutoPopulate

	properties
		popRel = reso.TrialTraceSet*pupil.TrialSet
	end

	methods(Access=protected)

		function makeTuples(self, key)
            directions = unique(fetchn(psy.Grating*psy.Trial*pupil.Trial & key, 'direction'));
            nDirs = length(directions);
            assert(nDirs>=8 && ~mod(nDirs,2) && all(directions == (0:360/nDirs:359)'),...
                'directions must be sufficient and evenly distributed')
            tuple = key;
            tuple.ndirs = length(directions);
            self.insert(tuple)
            makeTuples(pupil.VonMises, key)
		end
	end

end