%{
psy.DotMap (manual) # ternary dot map stimulus
-> psy.Condition
-----
rng_seed=0              : double             # random number generate seed

luminance               : float              # (cd/m^2)
contrast                : float              # michelson contrast 
bg_color                : tinyint unsigned   # (0-255) the index of the background color

tex_ydim = 20           : smallint           # (pixels) texture dimension
tex_xdim = 25           : smallint           # (pixels) texture dimension

frame_downsample = 2    : tinyint            # 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
dots_per_frame = 1      : smallint           # number of new dots displayed in each frame
linger_frames = 6       : smallint           # the number of frames each dot persists. 
%}


classdef DotMap < dj.Relvar

	properties(Constant)
		table = dj.Table('psy.DotMap')
	end

	methods
		function self = DotMap(varargin)
			self.restrict(varargin)
		end
	end
end
