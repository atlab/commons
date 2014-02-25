%{
pupil.TrialSet (computed) # trial traces for phase conditions
-> pupil.Classify
-> reso.TrialSet
-----
# add additional attributes
%}

classdef TrialSet < dj.Relvar & dj.AutoPopulate

	properties
		popRel = reso.TrialSet*pupil.Classify
	end

	methods(Access=protected)

		function makeTuples(self, key)
			self.insert(key)
            makeTuples(pupil.Trial, key)
		end
	end

end