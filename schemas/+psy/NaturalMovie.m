%{
psy.NaturalMovie (manual) # Populated by the stim program$
-> psy.Condition
---
type                        : enum('nat', 'phs')            # natural or phase scrambled
luminance                   : float                         # cd/m^2
contrast                    : float                         # Michelson's 0-1
movie_path                  : varchar(255)                  # file path for the movies
movie_number                : tinyint                       # the movie number
aperture_radius             : float                         # in units of half-diagonal, 0=no aperture
aperture_x=0                : float                         # 0=center, in units of half-diagonal
aperture_y=0                : float                         # 0=center, in units of half-diagonal
frame_downsample            : tinyint                       # 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
duration                    : float                         # (s) trial duration
pre_blank                   : float                         # (s) pre trial blank duration 
%}


classdef NaturalMovie < dj.Relvar
    properties(Constant)
        table = dj.Table('psy.NaturalMovie')
    end
    
    methods
        function self = NaturalMovie(varargin)
            self.restrict(varargin)
        end
    end
end
