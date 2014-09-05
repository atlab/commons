function insertDialog(pb,src,event)

idh.fig = figure('position',[600 600 550 250]);

hTop = uiextras.HBox('Parent',idh.fig,'Spacing',3);
vLeft = uiextras.VBox('Parent',hTop,'Spacing',3);
vRight = uiextras.VBox('Parent',hTop,'Spacing',3);
set(hTop,'Sizes',[-1 -5]);

% Animal, Slice, and Session number
uicontrol('style','text','parent',vLeft,'string','Animal ID');
idh.animal = uicontrol('style','edit','parent',vLeft,'string','','callback',@pb.newAnimal);
uiextras.Empty('Parent',vLeft);
uicontrol('style','text','parent',vLeft,'string','Slice');
idh.slice = uicontrol('style','edit','parent',vLeft,'string','','enable','off','callback',@pb.newSlice);
uiextras.Empty('Parent',vLeft);
uicontrol('style','text','parent',vLeft,'string','Session');
idh.session = uicontrol('style','edit','parent',vLeft,'string','','enable','off','callback',@pb.newSession);
uiextras.Empty('Parent',vLeft);
set(vLeft,'Sizes',[20 20 -1 20 20 -1 20 20 -1]);

% ************Animal info
v = uiextras.VBox('Parent',vRight);
ht = uiextras.HBox('Parent',v);
he = uiextras.HBox('Parent',v);

uicontrol('style','text','parent',ht,'string','Real ID:');
idh.realID=uicontrol('style','edit','parent',he,'string','');

uicontrol('style','text','parent',ht,'string','Sex:');
idh.sex=uicontrol('style','popupmenu','parent',he,'string',{'M','F','unknown'});

uicontrol('style','text','parent',ht,'string','Strain:');
idh.strain=uicontrol('style','popupmenu','parent',he,'string',{'C57/BLK6','Rat','Other'});

uicontrol('style','text','parent',ht,'string','Date of Birth:');
idh.dob=uicontrol('style','edit','parent',he,'string','');

set(he,'Sizes',[-2 -1 -2 -2])
set(ht,'Sizes',[-2 -1 -2 -2])

h = uiextras.HBox('Parent',v);
uicontrol('style','text','parent',h,'string','Notes:')
idh.animalNotes=uicontrol('style','edit','parent',h,'string','');
set(h,'Sizes',[50,-1]);

h = uiextras.HBox('Parent',v);
uiextras.Empty('Parent',h);
idh.insertAnimal=uicontrol('parent',h,'string','Insert Animal','callback',@pb.newAnimal);
set(h,'Sizes',[-3 -1]);
set(v,'Sizes',[20 20 -1 -1],'Enable','off');
idh.animalInfo=v;

% ***********Slice info
v = uiextras.VBox('Parent',vRight);
ht = uiextras.HBox('Parent',v);
he = uiextras.HBox('Parent',v);

uicontrol('style','text','parent',ht,'string','Slice Date');
idh.date=uicontrol('style','edit','parent',he,'string',datestr(now,29));

uicontrol('style','text','parent',ht,'string','Thickness');
idh.thickness=uicontrol('style','edit','parent',he,'string','350');

uicontrol('style','text','parent',ht,'string','Region');
idh.region=uicontrol('style','edit','parent',he,'string','S1');

uicontrol('style','text','parent',ht,'string','Experimenter:');
idh.experimenter=uicontrol('style','edit','parent',he,'string','Xiaolong');

set(he,'Sizes',[-2 -1 -1 -2])
set(ht,'Sizes',[-2 -1 -1 -2])

h = uiextras.HBox('Parent',v);
uicontrol('style','text','parent',h,'string','Notes:');
idh.sliceNotes=uicontrol('style','edit','parent',h,'string','');
set(h,'Sizes',[50,-1]);

h = uiextras.HBox('Parent',v);
uiextras.Empty('Parent',h);
idh.insertSlice=uicontrol('parent',h,'string','Insert Slice','callback',@pb.newSlice);
set(h,'Sizes',[-3 -1]);
set(v,'Sizes',[20 20 -1 -1],'Enable','off');
idh.sliceInfo=v;

% **************Session info
v = uiextras.VBox('Parent',vRight);

uiextras.Empty('Parent',v);
h = uiextras.HBox('Parent',v);
uicontrol('style','text','parent',h,'string','Path:');
idh.path=uicontrol('style','edit','parent',h,'string','/mnt/stor01/xiaolong data/Files for Jake/');
set(h,'Sizes',[60,-1]);

h = uiextras.HBox('Parent',v);
uicontrol('style','text','parent',h,'string','Notes:');
idh.sessionNotes=uicontrol('style','edit','parent',h,'string','');
set(h,'Sizes',[60,-1]);

h = uiextras.HBox('Parent',v);
uicontrol('style','text','parent',h,'string','Purpose:');
idh.sessionPurpose=uicontrol('style','popup','Parent',h,'string',{'Stimulation','Firing Pattern','Spontaneous','Other'});
uiextras.Empty('Parent',h);
idh.insertSession=uicontrol('parent',h,'string','Insert Session','callback',@pb.newSession);
set(h,'Sizes',[70 -1 -1 -1]);
set(v,'Sizes',[20 20 -1 -1],'Enable','off');

set(vRight,'Sizes',[-1 -1 -1]);
idh.sessionInfo=v;
pb.idh=idh;

% *****************Initialize
set(pb.idh.animal,'backgroundcolor','w')
set(pb.idh.slice,'backgroundcolor','w')
set(pb.idh.session,'backgroundcolor','w')

if ~isempty(pb.key.animal_id)
    set(pb.idh.animal,'string',num2str(pb.key.animal_id));
    pb.newAnimal(pb.idh.animal,'');
    
    if ~isempty(pb.key.mp_slice)
        set(pb.idh.slice,'string',num2str(pb.key.mp_slice));
        pb.newSlice(pb.idh.slice,'');
        if ~isempty(pb.key.mp_sess)
            s=str2num(get(pb.sessList,'string'));
            set(pb.idh.session,'string',num2str(max(s)+1));
        else
            set(pb.idh.session,'string','1');
            uicontrol(pb.idh.session);
        end
        set(pb.idh.sessionInfo,'Enable','on');
    else
        uicontrol(pb.idh.slice);
        set(pb.idh.sliceInfo,'Enable','on');
    end
end


end