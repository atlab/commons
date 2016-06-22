%{
virus.Conditional (manual) # system for conditional expression
-> virus.Virus
---
condition                   : enum('floxed','flipped','tet-on','tet-off') # 
%}


classdef Conditional < dj.Relvar
end