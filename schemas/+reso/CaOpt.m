%{
reso.CaOpt (lookup) # options for integrating calcium responses
ca_opt  : tinyint    # calcium option number
-----
transient_shape  : enum('exp','onAlpha')  # calcium transient shape
highpass_cutoff  : float                  # (Hz) low-pass cutoff frequency. 0=no filtration
latency = 0      : float                  # (s) assumed neural response latency
tau = -1         : float                  # (s) time constant (used by some integration functions), -1=use optimal tau
%}

classdef CaOpt < dj.Relvar
    
    properties(Constant)
        table = dj.Table('reso.CaOpt')
    end
    
    methods
        function self = CaOpt(varargin)
            self.restrict(varargin)
        end
        
        function fill(self)
            tuples = cell2struct({
                1   'exp'   0.0    0.0  1.5                
                11  'onAlpha'  0.0    0.0  1.5
                }', {'ca_opt', 'transient_shape', 'highpass_cutoff', 'latency', 'tau'});
            self.inserti(tuples)            
        end
    end
end