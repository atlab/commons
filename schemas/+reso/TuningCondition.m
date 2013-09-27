%{
reso.TuningCondition (lookup) # conditions for tuning
tuning_cond : tinyint  # brain condition index
-----
brain_state_thresh : float   # threshold of the brain state index
%}

classdef TuningCondition < dj.Relvar
    properties(Constant)
        table = dj.Table('reso.TuningCondition')
    end
end