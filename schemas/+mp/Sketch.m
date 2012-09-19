%{
mp.Sketch (manual)            # manual sketch
-> common.MpSession  
-----
sketch          : longblob      # matlab fig

%}

classdef Sketch < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.Sketch')
	end

	methods
		function self = Sketch(varargin)
			self.restrict(varargin)
		end
	end
end
