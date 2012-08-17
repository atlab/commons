%{
mp.Slice (manual) # brain slice for in-vitro patching 
-> common.Animal
slice_id  :  smallint   # brain slice number for this animal
-----
brain_region              : varchar(80)     # e.g. left barrel cortex. free text for now.
thickness = 300           : float           # (um) slice thickness
slice_notes               : varchar(4095)   # any other notes
experimenter              : varchar(80)     # who did the slicing
slice_time = CURRENT_TIMESTAMP : timestamp  # automatic but editable
%}

classdef Slice < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.Slice')
	end

	methods
		function self = Slice(varargin)
			self.restrict(varargin)
		end
	end
end
