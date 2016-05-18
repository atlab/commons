%{
psy.MovieInfo (manual) # movies used for generating clips and stills
movie_name  : char(8)   #  short movie title
-----
movie_title  : varchar(255)   # full movie title
path_template : varchar(255)  # filename template with full path
file_duration : float # (s) duration of each file (must be equal)
frame_rate : float  # frames per second
frame_width : int  # (pixels)
frame_height : int  # (pixels) 
%}


classdef MovieInfo < dj.Relvar
    methods
        function fill(self)
            self.inserti({
                'MadMax' 'Mad Max: Fury Road (2015)' '~/stimuli/movies/madmax/madmax_%03u.avi' 60 30 255 144
                })
        end
    end
end