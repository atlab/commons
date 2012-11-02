%{
tp.Segment (imported) # various cell segmentations in the finely aligned movie

-> tp.SegOpt
-> tp.Motion3D
-> tp.FineAlign
---
%}

classdef Segment < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.Segment')
        popRel = tp.FineAlign * tp.SegOpt & 'activated=1'
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            self.insert(key)
            opt = fetch(tp.SegOpt & key, '*');
            switch opt.seg_algo
                case 'manual'
                    makeTuples(tp.SegmentManual, key)
                otherwise
                    error 'not yet implemented'
            end
        end
    end
end
