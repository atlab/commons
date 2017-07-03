%{
reso.Segment (imported) # 2d cell segmentation
-> reso.Align
-> reso.VolumeSlice
---
mask                        : longblob                      # binary 4-connected mask image segmenting the aligned image
segment_ts=CURRENT_TIMESTAMP: timestamp                     # automatic
%}

classdef Segment < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel  = reso.Align & reso.ManualSegment
    end
    
    methods(Access=protected)        
        function makeTuples(self, key)
            self.insert(fetch(reso.ManualSegment & key, '*'))
            makeTuples(reso.Trace, key)
        end
        
    end
end
