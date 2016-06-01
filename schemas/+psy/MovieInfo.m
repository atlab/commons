%{
psy.MovieInfo (manual) # movies used for generating clips and stills
movie_name  : char(8)   #  short movie title
-----
movie_class : enum('madmax','object3d','mousecam') # movie type
path : varchar(255) # path for movies
original_file : varchar(255) # original long movie clip
file_template : varchar(255)  # filename template with full path
file_duration : float # (s) duration of each file (must be equal)
codec : varchar(255) # codec parameters for ffmpeg compression
movie_description  : varchar(255) 
%}

classdef MovieInfo < dj.Relvar
    methods
        function fill(self)
            self.inserti({
                'MadMax' 'madmax' '~/stimuli/movies' ...
                'madmax.avi' 'madmax_%03u.mov' 60 ...
                '-c:v libx264 -preset slow -crf 5' ...
                'Mad Max: Fury Road (2015)'
                })
        end
    end
end