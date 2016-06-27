%{
psy.MovieStillCond (manual) # a still frame condition
-> psy.Condition
-----
-> psy.MovieStill
pre_blank_period :  float   # (s) 
duration : float # (s)
%}

classdef MovieStillCond < dj.Relvar
end