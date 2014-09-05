function selectSlice(pb,src,event)

a = getListSelected(pb.animalList);
slc = getListSelected(pb.sliceList);

w = fetch(common.MpSession(['animal_id=' a],['mp_slice=' slc]));
set(pb.sessList, 'val',0,'string','');
pb.key.animal_id = str2num(a);
pb.key.mp_slice = str2num(slc);
pb.key.mp_sess = [];

if ~isempty(w)
    set(pb.sessList, 'val',1,'string',[w.mp_sess]);
    pb.key.mp_sess = w(1).mp_sess;
end    
pb.updateTabs;

end


