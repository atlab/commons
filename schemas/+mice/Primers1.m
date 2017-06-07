%{
mice.Primers1 (manual) # info about each primer set

primer_name          : varchar(20)               # primer name
---
direction           : enum('F','R','unknown')   # primer direction
target              : varchar(20)               # allele tested
primer_notes=""    : varchar(4096)             # other comments 
primer_ts=CURRENT_TIMESTAMP : timestamp        # automatic
%}

classdef Primers1 < dj.Relvar
end