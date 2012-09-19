%{
mp.Cell (manual)                # list of cells
cell_id         : int           # unique cell id in database
-----
cell_type       : enum          # cell type
cell_label      : enum          # molecular or fluorescent label
cell_note       : varchar(256)  # note
cell_ts = CURRENT_TIMESTAMP : timestamp   # don't edit
%}

classdef Cell < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.Cell')
	end

	methods
		function self = Cell(varargin)
			self.restrict(varargin)
		end
	end
end
