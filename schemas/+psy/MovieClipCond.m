%{
psy.MovieClipCond (manual) #  movie clip conditions
-> psy.Condition
-----
-> psy.MovieInfo
clip_number : int    # index of clips, used in filename
cut_after : float   # (s) cuts off after this duration
%}

classdef MovieClipCond < dj.Relvar
end