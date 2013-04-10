classdef Pause    
    properties
        duration % seconds
    end
    
    methods
        function self = Pause(duration)
            self.duration = duration;
        end
        
        function init(varargin)
            % do nothin'
        end
        
        function run(self)
            WaitSecs(self.duration);
        end
    end
end