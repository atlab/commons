%{
pupil.EpochOpt (lookup) # epochs in recordings
epoch_opt  :  smallint  auto_increment   #  pupil phase computation option
-----
condition          :  enum('all','running','not running', 'dilating','constricting')   # epoch condition
include_blanks     :  tinyint # if 1, then include half a blank before and after
saccade_thresh = 0 : float  # um/s   0 - do not exclude saccades
%}

classdef EpochOpt < dj.Relvar
    
    methods
        
        function fill(self)
            self.inserti(cell2struct({
                
            1            'all'              0   0
            2            'running'          0   0
            3            'not running'      0   0
            4            'running'          0   50
            5            'not running'      0   50
            6            'dilating'         0   50
            7            'constricting'     0   50
            8            'dilating'         0   0
            9            'constricting'     0   0
 
            11            'all'              0   0
            12            'running'          0   0
            13            'not running'      0   0
            14            'dilating'         0   0
            15            'constricting'     0   0
                        
            },{
            
            'epoch_opt' 'condition' 'include_blanks' 'saccade_thresh'
            
            }, 2))
        
        self.disp
        end
        
        function disp(self)
            disp(struct2table(self.fetch('*')))
        end
        
    end
end