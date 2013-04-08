%{
tp.CellClassification (computed) # mark the class of the cell for each trace
-> tp.Extract
-> tp.Trace
-----
cell_class_idx : tinyint # cell class number, from 1 to 8

%}

classdef CellClassification < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.CellClassification')
        popRel = tp.Extract;
    end

	methods
        function self = CellClassification(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
		function makeTuples(self, key)
            
            doManual = input('Do you want to do cell classification manually?1/0:');
            
            
            if doManual
                cell_class = input('Type in the cell type number:');
                % load and show images for both channels
                [g,r] = fetch1(tp.FineAlign & key, 'fine_green_img', 'fine_red_img');
                mask = logical(fetch1(tp.SegmentManual & key, 'manual_mask'));
                figure; imshowpair(g,r);
                
                % manually click the red cells
                mask = bwlabel(mask);
                figure; imagesc(mask);
                L = ginput;
                [cell_num a] = size(L);
                for ii = 1:cell_num
                    cell_idx = mask(round(L(ii,2)), round(L(ii,1)));
                    tuple = fetch(tp.Trace & key & ['trace_idx=' num2str(cell_idx)]);
                    tuple.cell_class_idx = cell_class;
                    self.insert(tuple);
                end
                close all
            end
            cell_class = input('Type in the cell type number:');
            keys = fetch(tp.Trace & key);
            for ii = 1:length(keys)
                tuple = dj.struct.join(keys(ii), key);
                tuple.cell_class_idx = cell_class;
                self.insert(tuple, 'INSERT IGNORE');
            end
            
			
		end
	end
end
