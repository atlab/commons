%{
reso.Conditions (lookup)            # conditions to use for reso.Indicator ** MUST UPDATE popRel in reso.Indicator for new conditions **
condition_num  : tinyint            # condition number
-----
condition_name          : varchar(64)   # name of condition
condition_params=NULL   : mediumblob    # parameters for reso.Indicator

%}

classdef Conditions < dj.Relvar
    
    properties(Constant)
        table = dj.Table('reso.Conditions')
    end
    
    methods
        function self = Conditions(varargin)
            self.restrict(varargin)
        end
        
        function fill(self)
            tuples(1).condition_num=1;
            tuples(1).condition_name = 'quiet dilating';
            tuples(1).condition_params = [];

            tuples(2).condition_num=2;
            tuples(2).condition_name = 'quiet constricting';
            tuples(2).condition_params = [];
            
            tuples(3).condition_num=3;
            tuples(3).condition_name = 'quiet';
            tuples(3).condition_params = [];

            tuples(4).condition_num=4;
            tuples(4).condition_name = 'active';
            tuples(4).condition_params = [];

            self.inserti(tuples)            
        end
    end
end