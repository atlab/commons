%{
reso.SegmentGlia (imported) # 2d cell segmentation
-> reso.Align
-> reso.VolumeSlice
---
mask                        : longblob                      # binary 4-connected mask image segmenting the aligned image
segment_ts=CURRENT_TIMESTAMP: timestamp                     # automatic
%}

classdef SegmentGlia < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel  = reso.Align & reso.ManualSegmentGlia
    end
    
    methods(Access=protected)        
        function makeTuples(self, key)
            self.insert(fetch(reso.ManualSegmentGlia & key, '*'))
            makeTuples(reso.TraceGlia, key)
        end
        
    end
end
