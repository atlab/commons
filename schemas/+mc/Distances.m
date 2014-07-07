%{
mc.Distances (computed) # compute distances betwee cell pairs
-> mc.Connections

-----

vert_dist       : float         # vertical distance between cell 1 and cell 2
tang_dist       : float         # tangential distance between cell 1 and cell 2
euc_dist        : float         # Euclidian distance between cell 1 and cell 2 

%}

classdef Distances < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('mc.Distances')
        popRel = mc.Connections;
	end

	methods
		function self = Distances(varargin)
			self.restrict(varargin)
		end
	end
    
    methods(Access=protected)

		function makeTuples(self, key)
            connections = fetch(mc.Connections & key);
            [cell1_x,cell1_y,cell1_z] = fetchn(mc.PatchCells & ['animal_id=' num2str(connections.animal_id)] & ['slice_id="' connections.slice_id '"'] & ['p_column_id=' num2str(connections.p_column_id)] & ['p_cell_id="' connections.cell_pre '"'],...
                'cell_x','cell_y','cell_z');
            [cell2_x,cell2_y,cell2_z] = fetchn(mc.PatchCells & ['animal_id=' num2str(connections.animal_id)] & ['slice_id="' connections.slice_id '"'] & ['p_column_id=' num2str(connections.p_column_id)] & ['p_cell_id="' connections.cell_post '"'],...
                'cell_x','cell_y','cell_z');
            [surface1_x,surface1_y,surface2_x, surface2_y] = fetchn(mc.PatchColumns & ['animal_id=' num2str(connections.animal_id)] & ['slice_id="' connections.slice_id '"'] & ['p_column_id=' num2str(connections.p_column_id)],...
                'surface1_x','surface1_y','surface2_x','surface2_y');
            par_m = (surface2_y-surface1_y)/(surface2_x-surface1_x);
            perp_m = -1/par_m;
            par_b = cell2_y-par_m*cell2_x;
            perp_b = cell1_y-perp_m*cell1_x;
            y_dist =(abs(cell2_x*(par_b-cell1_y)+cell1_x*(cell2_y-par_b)))/(sqrt(cell2_x.^2 + (cell2_y-par_b).^2));
            x_dist =(abs((0-cell1_x)*(cell1_y-cell2_y)-(cell1_x-cell2_x)*(perp_b-cell1_y)))/(sqrt((0-cell1_x).^2 + (perp_b-cell1_y).^2));
            tang_dist = sqrt(x_dist.^2 + (cell1_z - cell2_z).^2);
            tuple = key;
            tuple.vert_dist = y_dist;
            tuple.tang_dist = tang_dist;
            tuple.euc_dist = sqrt((tang_dist).^2 + y_dist.^2);
            self.insert(tuple)
        end
    end
end
