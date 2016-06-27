%{
inj.VirusInjection (manual) # Virus Injection

-> mice.Mice
-> virus.Virus
-> inj.Site
---
-> inj.GuidanceMethod
volume=null                   : double      # injection volume in nl
speed=null                    : double      # injection speed [nl/min]
toi=CURRENT_TIMESTAMP         : timestamp   # time of injection
%}


classdef VirusInjection < dj.Relvar
end