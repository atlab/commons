%{
tp.Extract2 (imported) # refines segmentation and extract traces
-> tp.Segment
-> tp.ExtractOpt
-----

%}

classdef Extract2 < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.Extract2')
<<<<<<< HEAD
        popRel = tp.SegmentManual * tp.ExtractOpt & (tp.ExtractOpt & 'pixel_averaging in ("NNMF","median","mean")')
=======
        popRel = tp.SegmentManual * tp.ExtractOpt & 'pixel_averaging in ("NNMF","median","mean")'
>>>>>>> ea874b355df4d921937cd2ce249fcc1457d641ca
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            self.insert(key)
            makeTuples(tp.Trace2, key)
        end
    end
end