%{
pupil.EpochTrialSet (computed) # trial traces for phase conditions
-> reso.TrialSet
-> patch.Eye
-> patch.Ball
-> pupil.EpochOpt
-----
%}

classdef EpochTrialSet < dj.Relvar & dj.AutoPopulate

	properties
		popRel = reso.TrialSet * reso.Sync * patch.Eye * pupil.EpochOpt & patch.Running & patch.EyeFrame
	end

	methods(Access=protected)
		function makeTuples(self, key)
			self.insert(key)
            makeTuples(pupil.EpochTrial, key)
		end
	end

end