%{
virus.Virus (manual) # table of viruses
virus_id        : int                    # unique id for each produced or purchased virus
---
-> virus.Construct
-> virus.Type
-> virus.Source
virus_lot=null              : varchar(64)                   # virus lot
virus_titer=null            : float                         # virus titer
virus_notes                 : varchar(4095)                 # free-text notes
virus_ts=CURRENT_TIMESTAMP  : timestamp                     # automatic
%}


classdef Virus < dj.Relvar
end