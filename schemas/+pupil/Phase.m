%{
pupil.Phase (lookup) # pupil phase to condition on  
phase_id  : smallint   #  pupil phase id
-----
central_phase : float #  phases are scaled from 0 to 1  
phase_window  : float #  window width -- currently rectangular window
phase_label   : varchar(255)  # label for axes, etc
%}

classdef Phase < dj.Relvar
    methods
        function fill(self)
            self.insert(struct('phase_id',1,'central_phase',3/4,'phase_window',.5,'phase_label','dilating'))
            self.insert(struct('phase_id',2,'central_phase',1/4,'phase_window',.5,'phase_label','constricting'))
        end
    end
end