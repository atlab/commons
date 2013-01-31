%{
tp.MinistackSegment (computed) # my newest table
-> tp.Ministack
-----
ministack_mask  : longblob   # the binary 3D image identyfying cell bodies

%}

classdef MinistackSegment < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.MinistackSegment')
        popRel = tp.Ministack
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            self.insert(key)
        end
        
    end
end