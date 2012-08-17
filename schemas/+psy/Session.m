%{
psy.Session (manual) # Populated by the stim program

-> common.Animal
psy_id          : smallint unsigned     # unique psy session number
---
stimulus="grating"          : varchar(255)                  # experiment type
monitor_distance         : float                         # (cm) eye-to-monitor distance
monitor_size=19             : float                         # (inches) size diagonal dimension
monitor_aspect=1.25         : float                         # physical aspect ratio of monitor
resolution_x=1280                : smallint                      # display resolution along x
resolution_y=1024                : smallint                      # display resolution along y
psy_ts=CURRENT_TIMESTAMP    : timestamp                     # automatic
%}

classdef Session < dj.Relvar
    properties(Constant)
        table = dj.Table('psy.Session')
    end
    methods
        function self = Session(varargin)
            self.restrict(varargin)
        end
    end
end
