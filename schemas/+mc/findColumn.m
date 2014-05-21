function findColumn(src,~)

figHand = get(src,'parent');

h.errorMessage = findobj(figHand,'tag','errorMessage');
h.errorBox = findobj(figHand,'tag','errorBox');

delete(h.errorMessage);
delete(h.errorBox);

h.animal_id = findobj(figHand,'tag','animalIDField');
h.slice_id = findobj(figHand,'tag','sliceIDField');
h.p_column_id = findobj(figHand,'tag','columnIDField');
h.connections = findobj(figHand,'tag','connectionsTable');

m.animal_id = get(h.animal_id,'string');
m.slice_id = get(h.slice_id,'string');
m.p_column_id = get(h.p_column_id,'string');

errorString = {};
errorCount = 0;

if isempty(m.animal_id) || isempty(m.slice_id) || isempty(m.p_column_id)
    errorCount = errorCount + 1;
    errorString{errorCount} = 'Animal ID, Slice ID and Column ID are required fields.';
end

a = fetch(mc.Experiments & ['animal_id=' m.animal_id]);
if errorCount == 0 && isempty(a)
    errorCount = errorCount + 1;
    errorString{errorCount} = 'No experiments are entered for this animal ID.';
end

a = fetch(mc.Slices & ['animal_id=' m.animal_id] & ['slice_id="' m.slice_id '"']);
if errorCount == 0 && isempty(a)
    errorCount = errorCount + 1;
    errorString{errorCount} = 'Slice has not been entered.';
end

a = fetch(mc.PatchColumns & ['animal_id=' m.animal_id] & ['slice_id="' m.slice_id '"'] & ['p_column_id=' m.p_column_id]);
if errorCount == 0 && isempty(a)
    errorCount = errorCount + 1;
    errorString{errorCount} = 'Column has not been entered.';
end

a = fetch(mc.PatchCells & ['animal_id=' m.animal_id] & ['slice_id="' m.slice_id '"'] & ['p_column_id=' m.p_column_id]);
if errorCount == 0 && isempty(a)
    errorCount = errorCount + 1;
    errorString{errorCount} = 'No cells are entered for this column.';
end

if ~isempty(errorString)
    h.errorMessage = uicontrol('style','text','String',['Cannot find column due to the following errors: '], 'position', [335 1200 500 16],'fontsize',14,'tag','errorMessage');
    h.errorBox = uicontrol('style','listbox','string',errorString,'tag','errorBox','position',[335 1165 500 50]);
else
    connectionCount = 0;
    for i = 1:size(a,1)
        cell_pre = a(i).p_cell_id;
        for j = 1:size(a,1)
            cell_post = a(j).p_cell_id;
            if ~strcmp(cell_pre,cell_post)
                connectionCount = connectionCount + 1;
                connections{connectionCount,1} = cell_pre;
                connections{connectionCount,2} = cell_post;
                b = fetch(mc.Connections & a & ['cell_pre="' cell_pre '"'] & ['cell_post="' cell_post '"'],'*');
                if ~isempty(b)
                    connections{connectionCount,3} = true;
                    if strcmp(b.conn,'connected')
                        connections{connectionCount,4} = true;
                    else connections{connectionCount,4} = false;
                    end
                    connections{connectionCount,5} = b.conn_notes;
                else connections{connectionCount,3} = false;
                    connections{connectionCount,4} = false;
                    connections{connectionCount,5} = '';
                end
            end
        end
    end
    set(h.connections,'Data',connections)
end

end