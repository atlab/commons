%{
mc.QuantExp (manual) # info about each column quantification experiment

-> mice.Mice                            # Mother ID number
pup_id              : int               # pup ID number
---
tam_dose=null       : int               # dose of tamoxifen administered (mg/kg)
prog_dose=null      : int               # dose of progesterone administered (mg/kg)
prog_supp_dose=null : tinyint           # progesterone supplementation dose (mg)
prog_supp_freq="unknown"      : enum('twice daily','daily','every other day','other','unknown') # progesterone supplementation regimen
tx_time=""             : varchar(4096)     # day of treatment
sac_time=""            : varchar(4096)     # day of sacrifice
qexp_notes=""       : varchar(4096)     # other comments about the experiment
qexp_ts=CURRENT_TIMESTAMP : timestamp   # automatic
%}



classdef QuantExp < dj.Relvar

	properties(Constant)
		table = dj.Table('mc.QuantExp')
	end

	methods
		function self = QuantExp(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
