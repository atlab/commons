function submitConnections(src,~)

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
m.connections = get(h.connections,'data');

errorString = {};
errorCount = 0;

if ~isempty(errorString)
    h.errorMessage = uicontrol('style','text','String',['Cannot find column due to the following errors: '], 'position', [335 1200 500 16],'fontsize',14,'tag','errorMessage');
    h.errorBox = uicontrol('style','listbox','string',errorString,'tag','errorBox','position',[335 1165 500 50]);
else schema = mc.getSchema;
    schema.conn.startTransaction
    for i = 1:size(m.connections,1)
        a = fetch(mc.Connections & ['animal_id=' m.animal_id] & ['slice_id="' m.slice_id '"'] & ['p_column_id=' m.p_column_id] & ['cell_pre="' m.connections{i,1} '"'] & ['cell_post="' m.connections{i,2} '"']);
        if isempty(a) && m.connections{i,3} == true
            tuple.animal_id = str2num(m.animal_id);
            tuple.slice_id = m.slice_id;
            tuple.p_column_id = str2num(m.p_column_id);
            tuple.cell_pre = m.connections{i,1};
            tuple.cell_post = m.connections{i,2};
            tuple.conn = 'not connected';
            tuple.conn_notes = m.connections{i,5};
            tuple
            %makeTuples(mc,Connections,tuple)
        else if ~isempty(a) && ~isempty(m.connections{i,5})
                update(mc.Connections & a, 'conn_notes',m.connections{i,5});
            end
        end
        if m.connections(i,3) == true && m.connections(i,4) == true
            update(mc.Connections & a,'conn','connected');
        end
    end     
end

end
