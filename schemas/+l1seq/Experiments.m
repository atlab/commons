%{
l1seq.Experiments (manual) # info about each L1 interneuron sequencing experiment

doe                 : date                                           # date of experiment
exp_type="unknown"  : enum('in vitro patching','in vivo patching','other','unknown') # type of experiment
---
animal_id=null      : int                                            # animal id number
age=null            : tinyint                                        # age of animal when experiment occurred
exp_notes=""       : varchar(4096)                                  # other comments about the experiment
exp_ts=CURRENT_TIMESTAMP : timestamp                                # automatic
%}



classdef Experiments < dj.Relvar

	properties(Constant)
		table = dj.Table('l1seq.Experiments')
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
