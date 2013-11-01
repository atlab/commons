f = figure;
set(f, 'position',[100 100 1404 1000])

uicontrol('style','text','string','Ear Tag #','position',[50 900 90 16],'fontsize',14);
uicontrol('style','text','string','Alternate ID','position',[145 900 90 16],'fontsize',14);
uicontrol('style','text','string','DOB','position',[240 900 90 16],'fontsize',14);
uicontrol('style','text','string','DOW','position',[335 900 90 16],'fontsize',14);
uicontrol('style','text','string','Father','position',[430 900 90 16],'fontsize',14);
uicontrol('style','text','string','Mother 1','position',[525 900 90 16],'fontsize',14);
uicontrol('style','text','string','Mother 2','position',[620 900 90 16],'fontsize',14);
uicontrol('style','text','string','Sex','position',[715 900 106 16],'fontsize',14);
uicontrol('style','text','string','Color','position',[826 900 106 16],'fontsize',14);
uicontrol('style','text','string','Ear Punch','position',[937 900 106 16],'fontsize',14);
uicontrol('style','text','string','Line 1','position',[1048 900 166 16],'fontsize',14);
uicontrol('style','text','string','Genotype 1','position',[1219 900 135 16],'fontsize',14);
uicontrol('style','text','string','Line 2','position',[1048 830 166 16],'fontsize',14);
uicontrol('style','text','string','Genotype 2','position',[1219 830 135 16],'fontsize',14);
uicontrol('style','text','string','Line 3','position',[1048 760 166 16],'fontsize',14);
uicontrol('style','text','string','Genotype 3','position',[1219 760 135 16],'fontsize',14);
uicontrol('style','text','string','Owner','position',[50 830 106 16],'fontsize',14);
uicontrol('style','text','string','Facility','position',[161 830 106 16],'fontsize',14);
uicontrol('style','text','string','Room','position',[272 830 106 16],'fontsize',14);
uicontrol('style','text','string','Rack','position',[383 830 90 16],'fontsize',14);
uicontrol('style','text','string','Row','position',[478 830 90 16],'fontsize',14);
uicontrol('style','text','string','Notes','position',[573 830 470 16],'fontsize',14);

h.animal_id = uicontrol('style','edit','position',[50 865 90 35],'fontsize',14,'tag','animalIDField');
h.other_id = uicontrol('style','edit','position',[145 865 90 35],'fontsize',14,'tag','otherIDField');
h.dob = uicontrol('style','edit','position',[240 865 90 35],'fontsize',14,'tag','dobField');
h.dow = uicontrol('style','edit','position',[335 865 90 35],'fontsize',14,'tag','dowField');
h.parent1 = uicontrol('style','edit','position',[430 865 90 35],'fontsize',14,'tag','parent1Field');
h.parent2 = uicontrol('style','edit','position',[525 865 90 35],'fontsize',14,'tag','parent2Field');
h.parent3 = uicontrol('style','edit','position',[620 865 90 35],'fontsize',14,'tag','parent3Field');

s = getEnumValues(mice.Mice.table,'sex');
v = find(strcmp('unknown',s));
h.sex = uicontrol('style','popupmenu','string',s,'value',v,'position',[715 860 106 35],'fontsize',14,'tag','sexField');

s = getEnumValues(mice.Mice.table,'color');
v = find(strcmp('unknown',s));
h.color = uicontrol('style','popupmenu','string',s,'value',v,'position',[826 860 106 35],'fontsize',14,'tag','colorField');

s = getEnumValues(mice.Mice.table,'ear_punch');
v = find(strcmp('None',s));
h.ear_punch = uicontrol('style','popupmenu','string',s,'value',v,'position',[937 860 106 35],'fontsize',14,'tag','earpunchField');

s = getEnumValues(mice.Mice.table,'owner');
v = find(strcmp('none',s));
h.owner = uicontrol('style','popupmenu','string',s,'value',v,'position',[50 790 106 35],'fontsize',14,'tag','ownerField');

s = getEnumValues(mice.Mice.table,'facility');
v = find(strcmp('unknown',s));
h.facility = uicontrol('style','popupmenu','string',s,'value',v,'position',[161 790 106 35],'fontsize',14,'tag','facilityField');

s = getEnumValues(mice.Mice.table,'room');
v = find(strcmp('unknown',s));
h.room = uicontrol('style','popupmenu','string',s,'value',v,'position',[272 790 106 35],'fontsize',14,'tag','roomField');

h.rack = uicontrol('style','edit','position',[383 795 90 35],'fontsize',14,'tag','rackField');
h.row = uicontrol('style','edit','position',[478 795 90 35],'fontsize',14,'tag','rowField');
h.mouse_notes = uicontrol('style','edit','position',[573 795 470 35],'fontsize',14,'HorizontalAlignment','left','tag','notesField'); 

s = getEnumValues(mice.Lines.table,'line');
s = {'' s{:}};
v = find(strcmp('',s));
h.line1 = uicontrol('style','popupmenu','string',s,'value',v,'position',[1048 860 166 35],'fontsize',14,'tag','line1Field');
h.line2 = uicontrol('style','popupmenu','string',s,'value',v,'position',[1048 790 166 35],'fontsize',14,'tag','line2Field');
h.line3 = uicontrol('style','popupmenu','string',s,'value',v,'position',[1048 720 166 35],'fontsize',14,'tag','line3Field');

s = getEnumValues(mice.Genotypes.table,'genotype');
v = find(strcmp('unknown',s));
h.genotype1 = uicontrol('style','popupmenu','string',s,'value',v,'position',[1219 860 135 35],'fontsize',14,'tag','genotype1Field');
h.genotype2 = uicontrol('style','popupmenu','string',s,'value',v,'position',[1219 790 135 35],'fontsize',14,'tag','genotype2Field');
h.genotype3 = uicontrol('style','popupmenu','string',s,'value',v,'position',[1219 720 135 35],'fontsize',14,'tag','genotype3Field');

last = fetch(mice.Mice);
number = size(last,1);
set(h.animal_id,'string',(last(number).animal_id + 1))

h.autopopulate = uicontrol('style','checkbox','string','Autopopulate','position',[140 950 150 35],'fontsize',14,'tag','autoBox');
h.clear = uicontrol('style','pushbutton','string','Clear Entry','position',[50 950 90 35],'fontsize',14,'Callback',@mice.GUIs.clearEntry);

cnames = {'ID','Alt ID','DOB','DOW','Father','Mother1','Mother2','Sex','Color','Ear Punch','Line1','Genotype1','Line2','Genotype2','Line3','Genotype3','Owner','Facility','Room','Rack','Row','Notes'};
cformat = {'char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char','char'};
cwidth = {40,40,'auto','auto',40,50,50,40,40,60,'auto','auto','auto','auto','auto','auto','auto',50,40,40,40,'auto'};
h.new_mice = uitable('position',[50 60 1304 650],'RowName',' ','ColumnName',cnames,'ColumnFormat',cformat,'columnwidth',cwidth,'tag','miceTable','CellSelectionCallback',@mice.GUIs.selectRow);

h.add = uicontrol('style','pushbutton','string','+','position',[50 710 25 25],'fontsize',18,'backgroundcolor','g','Callback',@mice.GUIs.plusCallback);
h.delete = uicontrol('style','pushbutton','string','-','position',[75 710 25 25],'fontsize',18,'backgroundcolor','r','Callback',@mice.GUIs.minusCallback);

h.submit = uicontrol('style','pushbutton','string','Submit New Mice to Database','position',[524 10 256 50],'fontsize',16,'Callback',@mice.GUIs.submitMice,'tag','submitMiceButton');


