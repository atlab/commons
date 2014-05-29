f = figure;
set(f, 'position',[0 0 1404 750])

uicontrol('style','text','string','Animal ID','position',[50 700 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','DOE','position',[145 700 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Age (PND)','position',[240 700 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Experiment Notes','position',[335 700 470 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Slice ID','position',[50 630 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Slice Notes','position',[145 630 470 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Column ID','position',[50 560 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Column Width','position',[145 560 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Surface 1 X','position',[240 560 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Surface 1 Y','position',[335 560 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Surface 2 X','position',[430 560 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Surface 2 Y','position',[525 560 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Column Notes','position',[620 560 470 16],'fontunits','normalized','fontsize',.8);

h.animal_id = uicontrol('style','edit','position',[50 665 90 35],'fontunits','normalized','fontsize',.4,'tag','animalIDField');
h.doe = uicontrol('style','edit','position',[145 665 90 35],'fontunits','normalized','fontsize',.4,'tag','doeField');
h.age = uicontrol('style','edit','position',[240 665 90 35],'fontunits','normalized','fontsize',.4,'tag','ageField');
h.exp_notes = uicontrol('style','edit','position',[335 665 470 35],'fontunits','normalized','fontsize',.4,'HorizontalAlignment','left','tag','expNotesField');
h.slice_id = uicontrol('style','edit','position',[50 595 90 35],'fontunits','normalized','fontsize',.4,'tag','sliceIDField');
h.slice_notes = uicontrol('style','edit','position',[145 595 470 35],'fontunits','normalized','fontsize',.4,'HorizontalAlignment','left','tag','sliceNotesField');
h.p_column_id = uicontrol('style','edit','position',[50 525 90 35],'fontunits','normalized','fontsize',.4,'tag','columnIDField');
h.p_column_width = uicontrol('style','edit','position',[145 525 90 35],'fontunits','normalized','fontsize',.4,'tag','widthField');
h.surface1_x = uicontrol('style','edit','position',[240 525 90 35],'fontunits','normalized','fontsize',.4,'tag','surface1XField');
h.surface1_y = uicontrol('style','edit','position',[335 525 90 35],'fontunits','normalized','fontsize',.4,'tag','surface1YField');
h.surface2_x = uicontrol('style','edit','position',[430 525 90 35],'fontunits','normalized','fontsize',.4,'tag','surface2XField');
h.surface2_y = uicontrol('style','edit','position',[525 525 90 35],'fontunits','normalized','fontsize',.4,'tag','surface2YField');
h.p_column_notes = uicontrol('style','edit','position',[620 525 470 35],'fontunits','normalized','fontsize',.4,'HorizontalAlignment','left','tag','columnNotesField');

cnames = {'Cell ID','Layer','Label','Type','FP','Morph','X','Y','Z','Notes'};
layers = getEnumValues(mc.PatchCells.table,'layer');
labels = getEnumValues(mc.PatchCells.table,'label');
types = getEnumValues(mc.PatchCells.table,'type');
fps = getEnumValues(mc.PatchCells.table,'fp');
morphs = getEnumValues(mc.PatchCells.table,'morph');
cformat = {'char',layers,labels,types,fps,morphs,'numeric','numeric','numeric','char'};
row = {'','unknown','unknown','unknown','unknown','unknown',[],[],[],''};
for i = 1:20
    data(i,1:10) = row;
end
cwidth = {100,125,125,125,125,125,100,100,100,300};
ceditables = [true true true true true true true true true true];
h.cells = uitable('position',[50 60 1304 450],'RowName',' ','ColumnName',cnames,'ColumnWidth',cwidth,'ColumnFormat',cformat,'tag','cellTable','Data',data,'ColumnEditable',ceditables);

h.submit = uicontrol('style','pushbutton','string','Submit Column Info','position',[524 10 256 50],'fontunits','normalized','fontsize',.35,'Callback',@mc.submitColumn,'tag','submitColumnButton');

