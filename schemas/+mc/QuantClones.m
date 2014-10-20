%{
mc.QuantClones (manual) # clones from quantitative analysis

-> mc.QuantExp                          
clone_id            : tinyint               # clone ID number for this animal
slice_id            : tinyint               # slice number
---
cell_count=null          : int                   # number of cells
qclone_notes=""       : varchar(4096)     # other comments about the clone
qclone_ts=CURRENT_TIMESTAMP : timestamp   # automatic
%}



classdef QuantClones < dj.Relvar

	properties(Constant)
		table = dj.Table('mc.QuantClones')
	end

	methods
		function self = QuantClones(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
