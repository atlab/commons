%{
mc.Slices (manual) # info about each slice used for patching

-> mc.Experiments
slice_id            : varchar(20)                            # unique slice id
---
slice_notes=""       : varchar(4096)                     # other comments about the slice, e.g. health
slice_ts=CURRENT_TIMESTAMP : timestamp                   # automatic
%}



classdef Slices < dj.Relvar

	properties(Constant)
		table = dj.Table('mc.Slices')
	end

	methods
		function self = Slices(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
