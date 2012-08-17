%{
mp.HistoCell (manual) # my newest table
-> mp.HistoImage
-> mp.PatchedCell
-----
mask :  longblob   # pixels corresponding to the cell in the HitoImage
location : varchar(30)  # location in microns -- separate into x,y,z?
celltype : varchar(30)  # morphology, firing pattern
marker   : varchar(30)  # how was labeled
%}

classdef HistoCell < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.HistoCell')
	end

	methods
		function self = HistoCell(varargin)
			self.restrict(varargin)
		end
	end
end
