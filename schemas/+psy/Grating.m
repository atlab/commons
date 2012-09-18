%{
psy.Grating (manual) # Populated by the stim program

-> psy.Condition
---
pre_blank=0                 : float                         # (s) blank period preceding trials
luminance                   : float                         # cd/m^2 mean
contrast                    : float                         # Michelson contrast 0-1
aperture_radius=0           : float                         # in units of half-diagonal, 0=no aperture
aperture_x=0                : float                         # aperture x coordinate, in units of half-diagonal, 0 = center
aperture_y=0                : float                         # aperture y coordinate, in units of half-diagonal, 0 = center
grating                     : enum('sqr','sin')             # sinusoidal or square, etc.
drift_fraction=0            : float                         # the fraction of the trial duration taken by drifting grating
spatial_freq                : decimal(4,2)                  # cycles/degree
init_phase                  : float                         # 0..1
trial_duration              : float                         # ms
temp_freq                   : decimal(4,1)                  # Hz
direction                   : float                         # 0-360 degrees
%}


classdef Grating < dj.Relvar
    properties(Constant)
        table = dj.Table('psy.Grating')
    end
    
    methods
        function self = Grating(varargin)
            self.restrict(varargin)
        end
    end
end
