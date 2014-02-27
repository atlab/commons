%{
pupil.EpochTrialSet (computed) # trial traces for phase conditions
-> reso.TrialSet
-> patch.Epochs
-----
# add additional attributes
%}

classdef EpochTrialSet < dj.Relvar & dj.AutoPopulate

	properties
		popRel = reso.TrialSet * reso.Sync * patch.Epochs
	end

	methods(Access=protected)

		function makeTuples(self, key)
			self.insert(key)
            makeTuples(pupil.EpochTrial, key)
		end
	end

end