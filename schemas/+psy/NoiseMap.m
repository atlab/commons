%{
psy.NoiseMap (manual) # pink noise stimulus from Niell & Stryker
-> psy.Condition
-----
rng_seed=0              : double       # random number generate seed

luminance               : float        # (cd/m^2)
contrast                : float        # michelson contrast 

tex_ydim = 64           : smallint     # (pixels) texture dimension
tex_xdim = 80           : smallint     # (pixels) texture dimension

spatial_freq_half=0.05  : float        # (cy/deg) spatial frequency modulated to 50%
spatial_freq_stop=0.20  : float        # (cy/deg), spatial lowpass cutoff

temp_bandwidth=4        : float        # (Hz) temporal bandwidth of the stimulus
contrast_mod_freq=0.1   : float        # (Hz) raised cosine contrast modulation
frame_downsample = 1    : tinyint      # 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc

duration                : float        # (s) trial duration
%}

classdef NoiseMap < dj.Relvar
    
    properties(Constant)
        table = dj.Table('psy.NoiseMap')
    end
    
    methods
        function self = NoiseMap(varargin)
            self.restrict(varargin)
        end
    end
end