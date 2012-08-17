%{
common.TpQuality (manual) # my newest table
-> common.TpScan
-----
staing_quality=-1 : tinyint  # (0-5) or -1 if missng
trace_quality=-1  : tinyint  # (0-5) or -1 if missing 
tuning_quality=-1 : tinyint  # (0-5) or -1 if missing
%}

classdef TpQuality < dj.Relvar

	properties(Constant)
		table = dj.Table('common.TpQuality')
	end

	methods
		function self = TpQuality(varargin)
			self.restrict(varargin)
		end
	end
end

