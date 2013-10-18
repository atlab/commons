%{
bs.TuningCondition (lookup) # conditions for tuning
tuning_cond : tinyint  # brain condition index
-----
bs_min  : float   # brain state min value
bs_max  : float   # brain state max value
%}

classdef TuningCondition < dj.Relvar
    properties(Constant)
        table = dj.Table('bs.TuningCondition')
    end
    methods
        function fill(self)
            tuples = cell2struct({
                0    0  1e8
                1    0  0.002
                2    0.002 1e8
                }, {'tuning_cond','bs_min','bs_max'}, 2);
            self.inserti(tuples)
        end
    end
end