%{
mp.CellPair (manual)        # pairs of cells
cell_pair       : int       # cell pair id
-> mp.Cell 
-----
presynaptic     : tinyint   # 1=presynpatic, 0=postsynaptic
connected       : tinyint   # 1=connected, 0=not connected, -1=tested but still unknown 
cellpair_ts = CURRENT_TIMESTAMP : timestamp   # don't edit
%}

classdef CellPair < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.CellPair')
	end

	methods
		function self = CellPair(varargin)
			self.restrict(varargin)
		end
	end
end
