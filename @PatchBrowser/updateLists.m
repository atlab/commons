function updateLists(pb)

w=fetch(common.Animal,'*');

for i=1:length(w)
    if w(i).animal_id == str2num(w(i).real_id)
        s{i}=num2str(w(i).animal_id);
    else
        s{i}=[num2str(w(i).animal_id) ' (' w(i).real_id ')'];
    end
end

set(pb.animalList,'string',s);
a = num2str(pb.key.animal_id);
val = find(strncmp(a,s,length(a)));
set(pb.animalList,'value',val);

w = fetch(common.MpSlice(['animal_id=' a]));
s = [w.mp_slice];
set(pb.sliceList, 'string',num2str(s'));
slc = pb.key.mp_slice;
val = find(slc==s);
if ~isempty(val)
    set(pb.sliceList,'value',val);
end

if ~isempty(slc)
    w = fetch(common.MpSession(['animal_id=' a],['mp_slice=' num2str(slc)]));
    s = [w.mp_sess];
else
    s=[];
end
    
set(pb.sessList, 'string',num2str(s'));
sess = pb.key.mp_sess;
val = find(sess==s);
if ~isempty(val)
    set(pb.sessList,'value',val);
end
%pb.sliceList = uicontrol('parent',slicePanel,'style','listbox','string','','callback',@pb.selectSlice);
%pb.sessList = uicontrol('parent',sessPanel,'style','listbox','string','','callback',@pb.selectSession);