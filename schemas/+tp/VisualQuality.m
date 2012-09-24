%{
tp.VisualQuality (manual) # visually assessed image quality before looking at tuning

-> common.TpSession
---
staining=0.0                : decimal(2,1)                  # 1-5. 0 = not rated
resolution=0.0              : decimal(2,1)                  # 1-5, 0 = not rated
motion=0.0                  : decimal(2,1)                  # 1-5, 0 = not rated
activity=0.0                : decimal(2,1)                  # 1-5, 0 = not rated
noise=0.0                   : decimal(2,1)                  # 1-5, 0 = not rated.
quality_notes=""            : varchar(4095)                 # notes on quality
quality_ts=CURRENT_TIMESTAMP: timestamp                     # automatic timestamp
%}

classdef VisualQuality < dj.Relvar

	properties(Constant)
		table = dj.Table('tp.VisualQuality')
	end
end
