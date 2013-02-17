%{
maxent.MVNOpt (lookup) # multivariate gaussian model options
mvn_opt : tinyint # multivariate gaussian model id
-----
deconv="none"    : enum("none")  # deconvolution algorithm
sample_rate      : float         # (Hz)  assumed rate of independent samples (compensation for overdispersion)
allow_ori        : tinyint       # 1=visible units can interact with stim orientation 
allow_hidden=0   : tinyint       # 1=model allows  hidden units
allow_hidden_ori : tinyint       # 1=hidden units can interact with stim orientation
%}

classdef MVNOpt < dj.Relvar
	properties(Constant)
		table = dj.Table('maxent.MVNOpt')
    end 
end
