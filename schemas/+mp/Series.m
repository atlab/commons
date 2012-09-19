%{
mp.Series (imported)            # imported sweep data
-> common.MpSession  
series          : smallint      # series #
-----
channels        : tinyblob      # vector of channel numbers
stim_chan       : tinyint       # number (not index) of stim channel
y_units         : varchar(8)    # string of 'A' and 'V' indicating unit of each channel
hz              : float         # sampling frequency
scales          : tinyblob      # vector of scaling factors for each channel
v_hold          : tinyblob      # vector of holding potentials for each channel
sweep_count     : int           # number of sweeps
sample_count    : int           # number of samples per trace
traces          : longblob      # cell array of channels containing sweeps x samples for each channel
validtraces     : blob          # matrix of channels x sweeps indicating whether each trace is valid

%}

classdef Series < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.Series')
	end

	methods
		function self = Series(varargin)
			self.restrict(varargin)
		end
	end
end
