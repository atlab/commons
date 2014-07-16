%{
reso.Effect (lookup) # effects to test in calcium traces
effect :  smallint  # effect id
-----
analysis :  varchar(255)   # identification of analysis to perform 
%}

classdef Effect < dj.Relvar
    
    methods
        function fill(self)
            self.insert({
                1   'active * quiet'
                2   'dilation * constriction & quiet'
                })
        end
    end
end