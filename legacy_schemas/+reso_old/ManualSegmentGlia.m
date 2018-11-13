%{
reso.ManualSegmentGlia (imported) # manual 2d cell segmentation$
-> common.TpScan
-> reso.VolumeSlice
---
mask                        : longblob                      # binary 4-connected mask image segmenting the aligned image
segment_ts=CURRENT_TIMESTAMP: timestamp                     # automatic
%}



classdef ManualSegmentGlia < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel  = reso.Align
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            g = fetch1(reso.Align & key, 'green_img');
            sz = size(g);
            
            bw = false(sz(1:2));
            for iSlice = 1:size(g,3)
                key.slice_num = iSlice;
                bw = reso.ManualSegment.outlineCells(g(:,:,iSlice),bw);
                assert(~isempty(bw), 'user aborted segmentation')
                key.mask = bw;
                self.insert(key)
            end
        end
    end
    
    
    methods(Access=protected, Static)
        function bw = outlineCells(img,bw)
            f = figure;
            imshow(img)
            set(gca, 'Position', [0.05 0.05 0.9 0.9]);
            pos = get(f, 'Position');
            if strcmp(computer,'GLNXA64')
                set(f,'Position',[160 160 1400 1000])
            else
                set(f, 'Position', [pos(1:2)/4 pos(3:4)*4])
            end
            bw = ne7.ui.drawCells(bw);
            close(f)
        end
    end
end
