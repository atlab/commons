%{
psy.VanGogh (manual) # pink noise with periods of motion and orientation
-> psy.Condition
---
-> psy.VanGoghLookup
rng_seed                    : double                        # random number generator seed
luminance                   : float                         # (cd/m^2)
contrast                    : float                         # michelson contrast
duration                    : float                         # (s) trial duration
tex_ydim                    : smallint                      # (pixels) texture dimension
tex_xdim                    : smallint                      # (pixels) texture dimension
spatial_freq_half           : float                         # (cy/deg) spatial frequency modulated to 50%
spatial_freq_stop           : float                         # (cy/deg), spatial lowpass cutoff
temp_bandwidth              : float                         # (Hz) temporal bandwidth
ori_bandwidth               : float                         # (rad) (rad) bandwidth of orientation filter
ori_map_spatial_bandwidth   : float                         # (cy/deg) spatial bandwidth for ori map
ori_map_temp_bandwidth      : float                         # (Hz) temporal bandwidth for ori map
contrast_spatial_bandwidth  : float                         # (cy/deg) spatial bandwidth of contrast map
contrast_temp_bandwidth     : float                         # (Hz) temporal bandwidth of contrast map
contrast_exponent           : float                         # exponent of power function for contrast map
frame_downsample            : tinyint                       # 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
%}


classdef VanGogh < dj.Relvar
    
    properties(Constant)
        table = dj.Table('psy.VanGogh')
    end
    
end
