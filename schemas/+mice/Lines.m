%{
mice.Lines (manual) # Basic mouse line info$
line            : varchar(100)           # Mouse Line Abbreviation
---
line_full                   : varchar(100)                  # full line name
rec_strain                  : varchar(20)                   # recipient strain
donor_strain                : varchar(20)                   # donor strain
n=null                      : tinyint                       # minimumm number of backcrosses to recipient strain
seq                         : varchar(5000)                 # sequence of transgene, if available
line_notes                  : varchar(4096)                 # other comments
line_ts=CURRENT_TIMESTAMP   : timestamp                     # automatic
%}



classdef Lines < dj.Relvar
	properties(Constant)
		table = dj.Table('mice.Lines')
	end
    
	methods
		function self = Lines(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
