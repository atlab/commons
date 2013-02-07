%{
tp.CellXYZ (computed) # my newest table
-> tp.Trace2
-> tp.Geometry

-----
cell_x  : float    # (microns) cell position in absolute coordinates
cell_y  : float    # (microns) cell position in absolute coordinates
cell_z  : float    # (microns) cell position in absolute coordinates
%}

classdef CellXYZ < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.CellXYZ')
		popRel = tp.Geometry * tp.Extract2
	end

	methods(Access=protected)

		function makeTuples(self, key)
            [pWidth,pHeight,umWidth,umHeight] = fetch1(tp.Align & key, ...
                'px_width', 'px_height', 'um_width', 'um_height');
            [cx,cy,depth,xflip,yflip] = fetch1(tp.Geometry & key, ...
                'center_x', 'center_y', 'depth', 'flipped_x','flipped_y'); 
            [x,y,keys] = fetchn(tp.Trace2 & key, 'centroid_x', 'centroid_y');
            
            for i=1:length(keys)
                tuple = keys(i);    
                tuple.cell_x = cx + (x(i)/pWidth - 0.5)*umWidth*(2-xflip);
                tuple.cell_y = cy + (y(i)/pHeight - 0.5)*umHeight*(2-yflip);
                tuple.cell_z = depth; 
                self.insert(tuple)
            end
		end
	end
end