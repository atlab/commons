%{
pop.ModelOpt (lookup) # variants of calcium population models
model_opt  : tinyint # population model number
-----
ori_input    : tinyint   # 1=include orientation tuning in model
hidden_units : tinyint   # 0=no hidden units, 1=allow hidden units, 2=hidden units with stimulus interactions
ca_tau       : float     # (seconds) the time constant of the calcium transient
%}

classdef ModelOpt < dj.Relvar
	properties(Constant)
		table = dj.Table('pop.ModelOpt')
	end
end