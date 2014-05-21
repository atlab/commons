%{
mc.Connections (manual) # info about each connection tested

-> mc.PatchColumns
cell_pre            : varchar(20)                            # presynaptic cell id 
cell_post           : varchar(20)                            # postsynaptic cell id 
---
conn="unknown"      : enum('connected','not connected','unknown')  # connection present or absent
conn_notes=""      : varchar(4096)                           # other comments
conn_ts=CURRENT_TIMESTAMP : timestamp                        # automatic

%}



classdef Connections < dj.Relvar

	properties(Constant)
		table = dj.Table('mc.Connections')
	end

	methods
		function self = Connections(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
