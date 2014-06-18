%{
mc.PatchCells (manual) # info about each cell patched

-> mc.PatchColumns
p_cell_id            : varchar(20)                            # cell id within this column
---
layer="unknown"         : enum('1','2/3','4','5','6','unknown') # cell body location determined during experiment
label="unknown"         : enum('positive','negative','no marker used','unknown') # positive or negative for fluorescent marker
type="unknown"          : enum('excitatory','inhibitory','unknown') # cell type, general
fp="unknown"            : enum('pyramidal','fs interneuron','non-fs interneuron','unknown') # firing pattern of cell
morph="unknown"         : enum('pyramidal','stellate','martinotti','basket','bipolar','bitufted','double bouquet','single bouquet','chandelier','neurogliaform','unknown') # morphological classification of cell
cell_x=null             : float                                 # cell x position in absolute coordinates
cell_y=null             : float                                 # cell y position in absolute coordinates
cell_z=null             : float                                 # cell z position in absolute coordinates
cell_notes=""           : varchar(4096)                         # other comments or distinguishing features
cell_ts=CURRENT_TIMESTAMP : timestamp                           # automatic

%}



classdef PatchCells < dj.Relvar

	properties(Constant)
		table = dj.Table('mc.PatchCells')
	end

	methods
		function self = PatchCells(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
