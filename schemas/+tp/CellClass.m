%{
tp.CellClass (lookup) # lookup table of cell type
cell_class_id  : tinyint # cell class number

-----
cell_class  : enum('V1', 'AL', 'PM', 'LM', 'unlabeled V1', 'AL projecting V1', 'PM projecting V1', 'LM projecting V1') # name of the cell classes

%}

classdef CellClass < dj.Relvar

	properties(Constant)
		table = dj.Table('tp.CellClass')
    end
    
    methods
		function self = CellClass(varargin)
			self.restrict(varargin)
        end
        
        function fill(self)
            tuples = cell2struct({
                1   'V1'
                2   'AL'
                3   'PM'
                4   'LM'
                5   'unlabeled V1'
                6   'AL projecting V1'
                7   'PM projecting V1'
                8   'LM projecting V1'
            }', {'cell_class_id', 'cell_class'});
            self.insert(tuples, 'INSERT IGNORE')
            
        end            
	end
end
