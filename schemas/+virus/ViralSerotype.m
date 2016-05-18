%{
virus.ViralSerotype (manual) # membership table for viral serotypes
-> virus.Virus
---
-> virus.Serotype
%}


classdef ViralSerotype < dj.Relvar
end