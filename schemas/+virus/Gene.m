%{
virus.Gene (manual) # lookup table of virus genes
gene_name       : char(30)               # identifier of the gne
---
function=null               : varchar(1024)                 # anticipated function of that gene
dna_source=null             : varchar(255)                  # source of the DNA
risk="no known risk"        : varchar(512)                  # risk for humans
%}


classdef Gene < dj.Relvar
end