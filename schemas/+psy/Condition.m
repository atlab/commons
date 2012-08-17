%{
psy.Condition (manual) # my newest table
-> psy.Session
cond_idx        : smallint unsigned     # condition index
-----
%}

classdef Condition < dj.Relvar

	properties(Constant)
		table = dj.Table('psy.Condition')
	end

	methods
		function self = Condition(varargin)
			self.restrict(varargin)
		end
	end
end
