%{
tp.SegOpt (lookup) # specifications of segmentation methods

seg_opt         : tinyint               # segmentation option id
---
seg_algo                    : enum('convex 2D','convex 3D','DoG 2D','DoG 3D','NNMF')# segmentation algorithm
min_radius                  : float                         # (um) min radius of segmented regions
max_radius                  : float                         # (um) max radius of segmented regions
activated=0                 : tinyint                       # 1=populate, 0=dont
%}

classdef SegOpt < dj.Relvar

	properties(Constant)
		table = dj.Table('tp.SegOpt')
	end

	methods
		function self = SegOpt(varargin)
			self.restrict(varargin)
		end
	end
end
