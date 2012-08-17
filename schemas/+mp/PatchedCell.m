%{
mp.PatchedCell (manual) # my newest table
-> mp.Slice
patched_cell_id   : smallint   # the number of the cell patched in this slice
-----
firing_pattern      :  varchar(80)    #  classify firing pattern
patched_cell_notes  : varchar(4095)  # cell health, patch quality
%}

classdef PatchedCell < dj.Relvar
    
    properties(Constant)
        table = dj.Table('mp.PatchedCell')
    end
    
    methods
        function self = PatchedCell(varargin)
            self.restrict(varargin)
        end
    end
end
