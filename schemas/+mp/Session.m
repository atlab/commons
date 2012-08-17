%{
mp.Session (manual) # multipatch session info
-> mp.Slice
mp_session_id : smallint  # mutipatch recording session number for this slice
-----
mp_session_notes ="" : varchar(4095)  # 
experimenter = ""    : varchar(20)    # who did the patching
mp_session_ts = CURRENT_TIMESTAMP : timestamp  # automatic but editible  
%}

classdef Session < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.Session')
	end

	methods
		function self = Session(varargin)
			self.restrict(varargin)
		end
	end
end
