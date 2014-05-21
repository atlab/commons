%{
mc.Experiments (manual) # info about each microcolumn experiment

-> mice.Mice
---
exp_type="unknown"  : enum('patching','two-photon','other','unknown')# type of experiment
doe=null            : date                                           # date of experiment
age=null            : tinyint                                        # age of animal when experiment occurred
exp_notes=""       : varchar(4096)                                  # other comments about the experiment
exp_ts=CURRENT_TIMESTAMP : timestamp                                # automatic
%}



classdef Experiments < dj.Relvar

	properties(Constant)
		table = dj.Table('mc.Experiments')
	end

	methods
		function self = Experiments(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
