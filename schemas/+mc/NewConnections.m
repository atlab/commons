f = figure;
set(f, 'position',[0 0 785 1250])

uicontrol('style','text','string','Animal ID','position',[50 1200 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Slice ID','position',[145 1200 90 16],'fontunits','normalized','fontsize',.8);
uicontrol('style','text','string','Column ID','position',[240 1200 90 16],'fontunits','normalized','fontsize',.8);

h.animal_id = uicontrol('style','edit','position',[50 1165 90 35],'fontunits','normalized','fontsize',.4,'tag','animalIDField');
h.doe = uicontrol('style','edit','position',[145 1165 90 35],'fontunits','normalized','fontsize',.4,'tag','sliceIDField');
h.age = uicontrol('style','edit','position',[240 1165 90 35],'fontunits','normalized','fontsize',.4,'tag','columnIDField');

h.findCells = uicontrol('style','pushbutton','string','Find Column','position',[50 1125 90 35],'fontunits','normalized','fontsize',.4,'Callback',@mc.findColumn);

cnames = {'Presynaptic','Postsynaptic','Tested','Connected','Notes'};
cformat = {'char','char','logical','logical','char'};
cwidth = {75,75,75,75,350};
ceditables = [true true true true true];
h.connections = uitable('position',[50 60 685 1050],'RowName',' ','ColumnName',cnames,'ColumnWidth',cwidth,'ColumnFormat',cformat,'tag','connectionsTable','ColumnEditable',ceditables,'fontunits','normalized','fontsize',.02);

h.submit = uicontrol('style','pushbutton','string','Submit Connections','position',[50 10 256 50],'fontunits','normalized','fontsize',.35,'Callback',@mc.submitConnections,'tag','submitConnectionsButton');
