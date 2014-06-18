%{
mc.PatchColumns (manual) # info about each column patched

-> mc.Slices
p_column_id            : tinyint                            # column number for this slice
---
p_column_width          : tinyint                           # width of column in microns
p_column_notes=""       : varchar(4096)                     # other comments about the column, e.g. health, location
p_column_ts=CURRENT_TIMESTAMP : timestamp                   # automatic
surface1_x=NULL         : float                             # x coordinate of surface point 1
surface1_y=NULL         : float                             # y coordinate of surface point 1
surface2_x=NULL         : float                             # x coordinate of surface point 2
surface2_y=NULL         : float                             # y coordinate of surface point 2
%}



classdef PatchColumns < dj.Relvar

	properties(Constant)
		table = dj.Table('mc.PatchColumns')
	end

	methods
		function self = PatchColumns(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
