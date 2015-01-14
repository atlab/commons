%{
psy.NoiseMap2 (manual) # pink noise stimulus from Niell & Stryker
-> psy.Condition
---
noise_map_version           : smallint                      # algorithm version; increment when code changes
rng_seed                    : double                        # random number generate seed
luminance                   : decimal(5,2)                  # (cd/m^2)
contrast                    : decimal(6,3)                  # michelson contrast
tex_ydim                    : smallint                      # (pixels) texture dimension
tex_xdim                    : smallint                      # (pixels) texture dimension
spatial_freq_half           : decimal(6,4)                  # (cy/deg) spatial frequency modulated to 50%
spatial_freq_stop           : decimal(6,4)                  # (cy/deg), spatial lowpass cutoff
temp_bandwidth              : decimal(6,4)                  # (Hz) temporal bandwidth of the stimulus
contrast_mod_freq           : decimal(6,5)                  # (Hz) raised cosine contrast modulation
frame_downsample            : tinyint                       # 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
duration                    : decimal(6,3)                  # (s) trial duration
contrast_slope              : decimal(6,4)                  # onset slope
modulation_shift            : decimal(4,3)                  # shift of the signamoid argument (cosine value)
%}


classdef NoiseMap2 < dj.Relvar
end