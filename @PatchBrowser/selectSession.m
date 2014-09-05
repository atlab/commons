function selectSession(pb,src,event)
pb.key.animal_id = str2num(getListSelected(pb.animalList));
pb.key.mp_slice = str2num(getListSelected(pb.sliceList));
pb.key.mp_sess = str2num(getListSelected(pb.sessList));

pb.updateTabs;
    
end


