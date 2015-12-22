%{
psy.Trippy (manual) # phase-encoded white noise
-> psy.Condition
---
-> psy.TrippyLookup
rng_seed                :double                        # random number generate seed
luminance               :float                         # (cd/m^2)
contrast                :float                         # michelson contrast
tex_ydim                :smallint                      # (pixels) texture dimension
tex_xdim                :smallint                      # (pixels) texture dimension
duration                :float                         # (s) trial duration
max_spatial_freq        :float                         # (cy/deg), spatial lowpass cutoff
control_points          :tinyint                       # number of control points in each dimension
temp_bandwidth          :float                         # (Hz) temporal bandwidth
frame_downsample        :tinyint                       # 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
%}

classdef Trippy < dj.Relvar
    properties(Constant)
        table = dj.Table('psy.Trippy')
    end
end