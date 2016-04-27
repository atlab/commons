%{
psy.MadMax (manual) # madmax movie stimulus
-> psy.Condition
-----
clip_number : int    # index of clips, used in filename
path_template = '~/stimuli/movies/madmax/madmax_%03u' : varchar(255)  #
cut_after : float   # (s) cuts off after this duration
%}

classdef MadMax < dj.Relvar
end