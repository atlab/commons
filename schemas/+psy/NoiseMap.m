%{
psy.NoiseMap (manual) # pink noise stimulus from Niell & Stryker
-> psy.Condition
---
-> psy.NoiseMapLookup
rng_seed                    : double                        # random number generate seed
luminance                   : float                         # (cd/m^2)
contrast                    : float                         # michelson contrast
tex_ydim                    : smallint                      # (pixels) texture dimension
tex_xdim                    : smallint                      # (pixels) texture dimension
spatial_freq_half           : float                         # (cy/deg) spatial frequency modulated to 50%
spatial_freq_stop           : float                         # (cy/deg), spatial lowpass cutoff
temp_bandwidth              : float                         # (Hz) temporal bandwidth of the stimulus
contrast_mod_freq           : float                         # (Hz) raised cosine contrast modulation
frame_downsample            : tinyint                       # 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
duration                    : float                         # (s) trial duration
contrast_slope              : float                         # onset slope
modulation_shift            : float                         # shift of the signamoid argument (cosine value)
%}


classdef NoiseMap < dj.Relvar
    
    properties(Constant)
        table = dj.Table('psy.NoiseMap')
    end
    
end