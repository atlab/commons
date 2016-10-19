%{
inj.AtlasStereotacticTargets (lookup) # Unadjusted stereotactic coordinates from the mouse brain atlas
->inj.Site
target_id                     : char(20) # ID for this set of coordinates
---
caudal                        : double # coordinate caudal from bregma in mm
lateral                       : double # lateral coordinate in mm
ventral                       : double # coordinate ventral from cortical surface in mm
lambda_bregma_basedist=4.21   : double # base distance between lambda and bregma from the stereotactic atlas in mm
%}


classdef AtlasStereotacticTargets < dj.Relvar
end