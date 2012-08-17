%{
mp.CellPair (manual) # my newest table
-> mp.Session
cell_pair   : smallint   # cell pair number
-> mp.PatchedCell
-----
order_in_pair :  tinyint  # 1 or 2
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
