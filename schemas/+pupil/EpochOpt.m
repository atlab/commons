%{
pupil.EpochOpt (lookup) # epochs in recordings
epoch_opt       : smallint AUTO_INCREMENT # pupil phase computation option
---
condition                   : enum('all','running','not running','dilating','constricting') # epoch condition
saccade_thresh=0            : float                         # um/s   0 - do not exclude saccades
%}

classdef EpochOpt < dj.Relvar
    
    methods
        
        function fill(self)
            self.inserti({
                
            1     'all'              0
            
            2     'running'          0
            3     'not running'      0
            
            4     'running'          50
            5     'not running'      50
            
            6     'dilating'         50
            7     'constricting'     50
            
            8     'dilating'         0
            9     'constricting'     0
            
            10    'dilating'         10
            11    'constricting'     10
            
            12    'dilating'         25
            13    'constricting'     25
            
            })
        
        self.disp
        end
        
        function disp(self)
            disp(struct2table(self.fetch('*')))
        end
        
    end
end
