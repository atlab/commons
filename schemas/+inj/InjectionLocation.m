%{
inj.InjectionLocation (manual) # Adjusted stereotactic coordinates for injection

->inj.VirusInjection
->inj.AtlasStereotacticTargets
---
lambda_bregma                 : double    # distance between lambda and bregma in mm as measured
caudal                        : double    # coordinate caudal from bregma in mm
lateral                       : double    # lateral coordinate in mm
ventral                       : double    # coordinate ventral from cortical surface in mm
adjustment                    : double    # adjustement factor to convert atlas coordinates to this injection
%}


classdef InjectionLocation < dj.Relvar
end