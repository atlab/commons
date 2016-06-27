%{
virus.ProcaryoticPlasmid (manual) # table of bacterial plasmids
-> virus.Construct
procaryotic_vector: char(20)             # name of the eukaryotic vector
---
point_of_use                : varchar(255)                  # species of cells
%}


classdef ProcaryoticPlasmid < dj.Relvar
end