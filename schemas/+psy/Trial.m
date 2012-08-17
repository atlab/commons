%{
psy.Trial (manual) # my newest table
-> psy.Session
trial_idx       : int     # trial index within sessions
---
-> psy.Condition
flip_times        : mediumblob     # (s) row array of flip times
last_flip_count   : int unsigned   # the last flip number in this trial
trial_ts = CURRENT_TIMESTAMP : timestamp  # automatic
%}

classdef Trial < dj.Relvar

	properties(Constant)
		table = dj.Table('psy.Trial')
	end

	methods
		function self = Trial(varargin)
			self.restrict(varargin)
		end
	end
end
