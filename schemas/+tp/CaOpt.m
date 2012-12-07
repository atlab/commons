%{
tp.CaOpt (lookup) # options for integrating calcium responses
ca_opt  : tinyint    # calcium option number
-----
transient_shape  : enum('exp','onAlpha')  # calcium transient shape
highpass_cutoff  : float                  # (Hz) low-pass cutoff frequency. 0=no filtration 
latency = 0      : float                  # (s) assumed neural response latency
tau = -1         : float                  # (s) time constant (used by some integration functions), -1=use optimal tau
%}

classdef CaOpt < dj.Relvar

	properties(Constant)
		table = dj.Table('tp.CaOpt')
	end

	methods
		function self = CaOpt(varargin)
			self.restrict(varargin)
        end
        
        function fill(self)
            tuples = cell2struct({
                1   'exp'   0.0    0.0  1.5
                2   'exp'   0.0    0.0  0.3
                3   'exp'   0.0    0.0  0.5
                4   'exp'   0.0    0.0  0.75
                5   'exp'   0.0    0.0  1.0
                6   'exp'   0.0    0.0  1.25
                8   'exp'   0.0    0.0  1.75
                9   'exp'   0.0    0.0  2.00
                10  'exp'   0.0    0.0  2.5
                
                
                11  'onAlpha'  0.0    0.0  1.5
                12  'onAlpha'  0.0    0.0  0.3
            }', {'ca_opt', 'transient_shape', 'highpass_cutoff', 'latency', 'tau'});
            self.insert(tuples,'INSERT IGNORE')
            
        end            
	end
end