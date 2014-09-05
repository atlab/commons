function selectAnimal(pb,src,event)

a = getListSelected(src);

w = fetch(common.MpSlice(['animal_id=' a]));
set(pb.sliceList, 'val',0,'string','');
set(pb.sessList, 'val',0,'string','');
pb.key.animal_id = str2num(a);
pb.key.mp_slice = [];
pb.key.mp_sess = [];

if ~isempty(w)
    set(pb.sliceList, 'val',1,'string',[w.mp_slice]);
    pb.key.mp_slice = w(1).mp_slice;
    
    w = fetch(common.MpSession(w(1)));
    if ~isempty(w)
        set(pb.sessList, 'val',1,'string',[w.mp_sess]);
        pb.key.mp_sess = w(1).mp_sess;
    end
end
pb.updateTabs;



