%{
# assigns recording channel to a cell in slice
-> mp.Cohort
channel         : tinyint       # physical channel number
-----
-> mp.Cell
sketch_x        : float         # x position in sketch
sketch_y        : float         # y position in sketch
cell_assignment_ts = CURRENT_TIMESTAMP : timestamp   # don't edit
%}

classdef CellAssignment < dj.Manual
end
