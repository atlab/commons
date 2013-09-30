%{
common.Animal (manual) # Basic subject info

animal_id       : int                   # id (internal to database)
---
real_id                     : varchar(20)                   # real-world unique identification
date_of_birth=null          : date                          # animal's date of birth
sex="unknown"               : enum('M','F','unknown')       # 
owner="Unknown"             : enum('Jake','Shan','Dimitri','Cathryn','Manolis','Unknown') # 
line="Unknown"              : enum('Unknown','SST-Cre','PV-Cre','Wfs1-Ai9','Viaat-Ai9','PV-Ai9','SST-Ai9','PV-ChR2-tdTomato','SST-ChR2-tdTomato','C57/BK6 (WT)') # 
animal_notes=""             : varchar(4096)                 # strain, genetic manipulations
animal_ts=CURRENT_TIMESTAMP : timestamp                     # automatic
%}



classdef Animal < dj.Relvar

	properties(Constant)
		table = dj.Table('common.Animal')
	end

	methods
		function self = Animal(varargin)
			self.restrict(varargin)
		end
	end
end
