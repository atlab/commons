%{
reso.Segment (imported) # 2d cell segmentation
-> reso.Align
-> reso.VolumeSlice
---
mask                        : longblob                      # binary 4-connected mask image segmenting the aligned image
segment_ts=CURRENT_TIMESTAMP: timestamp                     # automatic
%}

classdef Segment < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.Segment')
        popRel  = reso.Align & reso.ManualSegment
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            self.insert(fetch(reso.ManualSegment & key, '*'))
        end
        
    end
end
