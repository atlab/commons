%{
tp.SegOpt (lookup) # specifications of segmentation methods

seg_opt         : tinyint               # segmentation option id
---
seg_algo                    : enum('manual','manual+NNMF','morpho3D')# segmentation algorithm
min_radius                  : float                         # (um) min radius of segmented regions
max_radius                  : float                         # (um) max radius of segmented regions
activated=0                 : tinyint                       # 1=populate, 0=dont
min_contrast=0.1            : float                         # min acceptable contrast on green channel
in3d                        : tinyint                       # 1=3D segmentation, 0=2D
source_image="green"        : enum('green','fine orimap')   # the source image shown to user for segmentation
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
