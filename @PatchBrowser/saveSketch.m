function saveSketch(pb,src,event)

for i=1:length(pb.sketchObj)
    
    if pb.sketchObj(i).chan <=0
        continue
    end
    
    % Is this a new cell? If so, add it 
    if pb.sketchObj(i).id == 0
        
        
        ids = fetchn(mp.Cell,'cell_id');
        if isempty(ids)
            newID=1;
        else
            newID = max(ids)+1;
        end
        pb.sketchObj(i).id = newID;
        
        key=[];
        key.cell_id = pb.sketchObj(i).id;
        key.cell_type = pb.sketchObj(i).cell_type;
        key.cell_label = pb.sketchObj(i).cell_label;
        key.cell_note = '';
        
        m = mp.Cell;
        m.insert(key);
    end
        
    
    % assign it to channel and session in mp.CellAssignment with sketch_x and sketch_y
    key = pb.key;
    key.channel = pb.sketchObj(i).chan;
    key.cell_id = pb.sketchObj(i).id;
    key.sketch_x = pb.sketchObj(i).x;
    key.sketch_y = pb.sketchObj(i).y;
    m = mp.CellAssignment;
    m.insert(key);
    
end

for i=1:8
    for j=1:8
        if i==j
            continue
        end
        
        % add connections to mp.CellPair
        pairs = fetchn(mp.CellPair,'cell_pair');
        if isempty(pairs)
            newPair = 1;
        else
            newPair = max(pairs)+1;
        end
        
        % Presynaptic cell ID
        key=pb.key;
        key.channel = i;
        preID = fetchn(mp.CellAssignment(key),'cell_id');
        
        % Postsynaptic cell ID
        key=pb.key;
        key.channel = j;
        postID = fetchn(mp.CellAssignment(key),'cell_id');
        
        if ~isempty(preID) && ~isempty(postID)
            
            % insert presynaptic cell into pair
            key=[];
            key.cell_pair = newPair;
            key.cell_id = preID;
            key.presynaptic = 1;
            if isempty(pb.sketchConnection{i,j})
                key.connected = 0;
            else
                key.connected = 1;
            end
            m = mp.CellPair;
            try
                m.insert(key);
            catch
                lasterr
            end
                
            
            
            % insert postsynaptic cell into pair
            key=[];
            key.cell_pair = newPair;
            key.cell_id = postID;
            key.presynaptic = 0;
            if isempty(pb.sketchConnection{i,j})
                key.connected = 0;
            else
                key.connected = 1;
            end
            
            try
                m = mp.CellPair;
                m.insert(key);
            catch
                lasterr
            end
        end
    end
end






