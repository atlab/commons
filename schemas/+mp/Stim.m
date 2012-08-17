%{
mp.Stim (manual) # my newest table
-> mp.Session  
stim_id    :  stimulu sid
-----
-> mp.PatchedCell
stimulated cell
%}

classdef Stim < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.Stim')
	end

	methods
		function self = Stim(varargin)
			self.restrict(varargin)
		end
	end
end
