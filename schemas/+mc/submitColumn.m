function submitColumn(src,~)

figHand = get(src,'parent');

h.errorMessage = findobj(figHand,'tag','errorMessage');
h.errorBox = findobj(figHand,'tag','errorBox');

delete(h.errorMessage);
delete(h.errorBox);

h.animal_id = findobj(figHand,'tag','animalIDField');
h.doe = findobj(figHand,'tag','doeField');
h.age = findobj(figHand,'tag','ageField');
h.exp_notes = findobj(figHand,'tag','expNotesField');
h.slice_id = findobj(figHand,'tag','sliceIDField');
h.slice_notes = findobj(figHand,'tag','sliceNotesField');
h.p_column_id = findobj(figHand,'tag','columnIDField');
h.p_column_width = findobj(figHand,'tag','widthField');
h.surface1_x = findobj(figHand,'tag','surface1XField');
h.surface1_y = findobj(figHand,'tag','surface1YField');
h.surface2_x = findobj(figHand,'tag','surface2XField');
h.surface2_y = findobj(figHand,'tag','surface2YField');
h.p_column_notes = findobj(figHand,'tag','columnNotesField');
h.cells = findobj(figHand,'tag','cellTable');

m.animal_id = get(h.animal_id,'string');
m.doe = get(h.doe,'string');
m.age = get(h.age,'string');
m.exp_notes = get(h.exp_notes,'string');
m.slice_id = get(h.slice_id,'string');
m.slice_notes = get(h.slice_notes,'string');
m.p_column_id = get(h.p_column_id,'string');
m.p_column_width = get(h.p_column_width,'string');
m.surface1_x = get(h.surface1_x,'string');
m.surface1_y = get(h.surface1_y,'string');
m.surface2_x = get(h.surface2_x,'string');
m.surface2_y = get(h.surface2_y,'string');
m.p_column_notes = get(h.p_column_notes,'string');
m.cells = get(h.cells,'Data');

errorString = {};
errorCount = 0;

if isempty(m.animal_id) || isempty(m.slice_id) || isempty(m.p_column_id)
    errorCount = errorCount + 1;
    errorString{errorCount} = 'Animal ID, Slice ID and Column ID are required fields.';
end

if ~isempty(errorString)
    h.errorMessage = uicontrol('style','text','String',['Cannot submit column due to the following errors: '], 'position', [620 630 500 16],'fontsize',14,'tag','errorMessage');
    h.errorBox = uicontrol('style','listbox','string',errorString,'tag','errorBox','position',[620 595 500 50]);
else schema = mc.getSchema;
    schema.conn.startTransaction
    a = fetch(mc.Experiments & ['animal_id=' m.animal_id]);
    if isempty(a)
        tuple.animal_id = str2num(m.animal_id);
        tuple.exp_type = 'patching';
        tuple.doe = m.doe;
        tuple.age = str2num(m.age);
        tuple.exp_notes = m.exp_notes;
        makeTuples(mc.Experiments,tuple);
        clear tuple a
    end
    a = fetch(mc.Slices & ['animal_id=' m.animal_id] & ['slice_id="' m.slice_id '"']);
    if isempty(a)
        tuple.animal_id = str2num(m.animal_id);
        tuple.slice_id = m.slice_id;
        tuple.slice_notes = m.slice_notes;
        makeTuples(mc.Slices,tuple);
        clear tuple a
    end
    a = fetch(mc.PatchColumns & ['animal_id=' m.animal_id] & ['slice_id="' m.slice_id '"'] & ['p_column_id=' m.p_column_id]);
    if isempty(a)
       tuple.animal_id = str2num(m.animal_id);
       tuple.slice_id = m.slice_id;
       tuple.p_column_id = str2num(m.p_column_id);
       tuple.p_column_width = str2num(m.p_column_width);
       tuple.p_column_notes = m.p_column_notes;
       tuple.surface1_x = str2num(m.surface1_x);
       tuple.surface1_y = str2num(m.surface1_y);
       tuple.surface2_x = str2num(m.surface2_x);
       tuple.surface2_y = str2num(m.surface2_y);
       makeTuples(mc.PatchColumns,tuple);
       clear tuple a 
    end
    for i = 1:20
        if ~strcmp(m.cells(i,1),'') && isempty(fetch(mc.PatchCells & ['animal_id=' m.animal_id] & ['slice_id="' m.slice_id '"'] & ['p_column_id=' m.p_column_id] & ['p_cell_id="' m.cells(i,1) '"']))
            tuple.animal_id = str2num(m.animal_id);
            tuple.slice_id = m.slice_id;
            tuple.p_column_id = str2num(m.p_column_id);
            tuple.p_cell_id = m.cells{i,1};
            tuple.layer = m.cells{i,2};
            tuple.label = m.cells{i,3};
            tuple.type = m.cells{i,4};
            tuple.fp = m.cells{i,5};
            tuple.morph = m.cells{i,6};
            tuple.cell_x = m.cells{i,7};
            tuple.cell_y = m.cells{i,8};
            tuple.cell_z = m.cells{i,9};
            tuple.cell_notes = m.cells{i,10};
            makeTuples(mc.PatchCells,tuple)
            clear tuple
        end
    end
    row = {'','unknown','unknown','unknown','unknown','unknown',[],[],[],''};
    for i = 1:20
        data(i,1:10) = row;
    end
    set(h.cells,'Data',data);
    set(h.p_column_id,'string','');
    schema.conn.commitTransaction
end

end