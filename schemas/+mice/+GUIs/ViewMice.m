f = figure;
set(f, 'position',[100 100 1404 1000])

uicontrol('style','text','string','ID Range:','position',[50 871 75 29],'fontsize',14,'HorizontalAlignment','Right');
uicontrol('style','text','string','-','position',[175 871 10 29],'fontsize',14,'HorizontalAlignment','Center');

uicontrol('style','text','string','Parent1','position',[240 900 90 16],'fontsize',14);
uicontrol('style','text','string','Parent2','position',[335 900 90 16],'fontsize',14);
uicontrol('style','text','string','Sex','position',[430 900 106 16],'fontsize',14);
uicontrol('style','text','string','Color','position',[541 900 106 16],'fontsize',14);
uicontrol('style','text','string','Ear Punch','position',[652 900 106 16],'fontsize',14);
uicontrol('style','text','string','Line 1','position',[763 900 166 16],'fontsize',14);
uicontrol('style','text','string','Genotype 1','position',[934 900 135 16],'fontsize',14);
uicontrol('style','text','string','Line 2','position',[763 830 166 16],'fontsize',14);
uicontrol('style','text','string','Genotype 2','position',[934 830 135 16],'fontsize',14);
uicontrol('style','text','string','Line 3','position',[763 760 166 16],'fontsize',14);
uicontrol('style','text','string','Genotype 3','position',[934 760 135 16],'fontsize',14);
uicontrol('style','text','string','Owner','position',[50 830 106 16],'fontsize',14);
uicontrol('style','text','string','Facility','position',[161 830 106 16],'fontsize',14);
uicontrol('style','text','string','Room','position',[272 830 106 16],'fontsize',14);

h.range_start = uicontrol('style','edit','position',[125 871 50 30],'fontsize',14,'tag','rangeStart');
h.range_end = uicontrol('style','edit','position',[185 871 50 30],'fontsize',14,'tag','rangeEnd');
h.find = uicontrol('style','pushbutton','position',[50 470 110 29],'fontsize',14,'string','Find Mice','HorizontalAlignment','Center','Callback',@mice.GUIs.findMice);

h.parent1 = uicontrol('style','edit','position',[240 871 90 30],'fontsize',14,'tag','parent1Field');
h.parent2 = uicontrol('style','edit','position',[335 871 90 30],'fontsize',14,'tag','parent2Field');

s = getEnumValues(mice.Mice.table,'sex');
s = {'' s{:}};
v = find(strcmp('',s));
h.sex = uicontrol('style','popupmenu','string',s,'value',v,'position',[430 861 106 35],'fontsize',14,'tag','sexField');

s = getEnumValues(mice.Mice.table,'color');
s = {'' s{:}};
v = find(strcmp('',s));
h.color = uicontrol('style','popupmenu','string',s,'value',v,'position',[541 861 106 35],'fontsize',14,'tag','colorField');

s = getEnumValues(mice.Mice.table,'ear_punch');
s = {'' s{:}};
v = find(strcmp('',s));
h.ear_punch = uicontrol('style','popupmenu','string',s,'value',v,'position',[652 861 106 35],'fontsize',14,'tag','earpunchField');

s = getEnumValues(mice.Mice.table,'owner');
s = {'' s{:}};
v = find(strcmp('',s));
h.owner = uicontrol('style','popupmenu','string',s,'value',v,'position',[50 790 106 35],'fontsize',14,'tag','ownerField');

s = getEnumValues(mice.Mice.table,'facility');
s = {'' s{:}};
v = find(strcmp('',s));
h.facility = uicontrol('style','popupmenu','string',s,'value',v,'position',[161 790 106 35],'fontsize',14,'tag','facilityField');

s = getEnumValues(mice.Mice.table,'room');
s = {'' s{:}};
v = find(strcmp('',s));
h.room = uicontrol('style','popupmenu','string',s,'value',v,'position',[272 790 106 35],'fontsize',14,'tag','roomField');

s = getEnumValues(mice.Lines.table,'line');
s = {'' s{:}};
v = find(strcmp('',s));
h.line1 = uicontrol('style','popupmenu','string',s,'value',v,'position',[763 860 166 35],'fontsize',14,'tag','line1Field');
h.line2 = uicontrol('style','popupmenu','string',s,'value',v,'position',[763 790 166 35],'fontsize',14,'tag','line2Field');
h.line3 = uicontrol('style','popupmenu','string',s,'value',v,'position',[763 720 166 35],'fontsize',14,'tag','line3Field');

s = getEnumValues(mice.Genotypes.table,'genotype');
s = {'' s{:}};
v = find(strcmp('',s));
h.genotype1 = uicontrol('style','popupmenu','string',s,'value',v,'position',[934 860 135 35],'fontsize',14,'tag','genotype1Field');
h.genotype2 = uicontrol('style','popupmenu','string',s,'value',v,'position',[934 790 135 35],'fontsize',14,'tag','genotype2Field');
h.genotype3 = uicontrol('style','popupmenu','string',s,'value',v,'position',[934 720 135 35],'fontsize',14,'tag','genotype3Field');

h.used = uicontrol('style','checkbox','string','Include Used/Euthanized Mice','position',[140 950 250 35],'fontsize',14,'tag','usedBox');
h.clear = uicontrol('style','pushbutton','string','Clear','position',[50 950 90 35],'fontsize',14,'Callback',@mice.GUIs.clearEntry);

cnames = {'ID','AltID','DOB','DOW','Parent1','Parent2','Parent3','Sex','Color','EarPunch','Line1','Genotype1','Line2','Genotype2','Line3','Genotype3','Owner','Facility','Room','Rack','Row','Notes'};
cformat = {'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char'};
cwidth = {40,40,'auto','auto',50,50,50,40,40,60,'auto','auto','auto','auto','auto','auto','auto',50,40,40,40,'auto'};
h.new_mice = uitable('position',[50 60 1304 650],'RowName',' ','ColumnName',cnames,'ColumnFormat',cformat,'columnwidth',cwidth,'tag','miceTable','CellSelectionCallback',@mice.GUIs.selectRow);

h.find = uicontrol('style','pushbutton','position',[50 710 110 29],'fontsize',14,'string','Find Mice','HorizontalAlignment','Center','Callback',@mice.GUIs.findViewMice);

h.print = uicontrol('style','pushbutton','string','Print List','position',[524 10 256 50],'fontsize',16,'Callback',@mice.GUIs.printList,'tag','printListButton');