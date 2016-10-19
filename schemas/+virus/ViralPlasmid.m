%{
virus.ViralPlasmid (manual) # table of viral plasmids
-> virus.Construct
viral_vector    : char(30)               # name of the eukaryotic vector
---
point_of_use                : varchar(255)                  # species of cells
%}


classdef ViralPlasmid < dj.Relvar
end