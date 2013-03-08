%{
pop.SegOpt (lookup) # specifications of segmentation methods

seg_opt         : tinyint               # segmentation option id
---
source_image="green"        : enum('green','fine orimap')   # the source image shown to user for segmentation
%}

classdef SegOpt < dj.Relvar
    
    properties(Constant)
        table = dj.Table('pop.SegOpt')
    end
    
    methods
        function self = SegOpt(varargin)
            self.restrict(varargin)
        end
    end
end