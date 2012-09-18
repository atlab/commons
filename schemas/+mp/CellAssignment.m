%{
mp.CellAssignment (manual) # my newest table
-> common.MpSession
channel         : tinyint       # physical channel number
-----
-> mp.Cell
sketch_x        : float         # x position in sketch
sketch_y        : float         # y position in sketch
cell_assignment_ts = CURRENT_TIMESTAMP : timestamp   # don't edit
%}

classdef CellAssignment < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.CellAssignment')
	end

	methods
		function self = CellAssignment(varargin)
			self.restrict(varargin)
		end
	end
end
