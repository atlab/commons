%{
tp.SegmentManual (imported) # manually outlined cells
-> tp.Segment
-----
manual_mask  :  longblob   # binary mask on the finely aligned image

%}

classdef SegmentManual < dj.Relvar
    
    properties(Constant)
        table = dj.Table('tp.SegmentManual')
    end
    
    methods
        
        function makeTuples(self, key)
            bw = tp.SegmentManual.outlineCells(key,[]);
            assert(~isempty(bw), 'user aborted segmentation')
            key.manual_mask = bw;
            self.insert(key)
        end
        
        
        function redo(self)
            % edit existing segmentations
            for key = fetch(self)
                bw = fetch1(tp.SegmentManual & key, 'manual_mask');
                bw = tp.SegmentManual.outlineCells(key, bw);
                if ~isempty(bw)
                    del(tp.Segment & key)
                    insert(tp.Segment, key)
                    key.manual_mask = bw;
                    insert(tp.SegmentManual, key)
                    disp 'updated mask'
                end
            end
        end
    end
    
    
    methods(Static,Access=private)
        function bw = outlineCells(key,bw)
            [g,r] = fetch1(tp.FineAlign & key, 'fine_green_img', 'fine_red_img');
            g = sqrt(g);
            r = sqrt(r);
            g = max(0,g-quantile(g(:),0.01));
            r = max(0,r-quantile(r(:),0.01));
            f = figure;
            %imshowpair(g,r)
            imshow(g/max(g(:)))
            bw = ne7.ui.drawCells(bw);
            close(f)
        end
    end
end
