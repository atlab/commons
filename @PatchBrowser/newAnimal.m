function newAnimal(pb,src,event)

if src == pb.idh.animal
    
    set(pb.idh.slice,'string','');
    set(pb.idh.session,'string','');
    
    a = get(pb.idh.animal,'string');
    w=[];
    if ~isempty(a)
        if isnumeric(str2num(a))
            w = fetch(common.Animal(['animal_id=' a]),'*');
        end
    end
    
    
    if isempty(w)
        set(pb.idh.realID,'string',a);
        set(pb.idh.dob,'string','');
        set(pb.idh.sex,'value',1);
        set(pb.idh.animalNotes,'string','');
        
        set(pb.idh.session,'Enable','off');
        set(pb.idh.slice,'Enable','off');
        set(pb.idh.animalInfo,'Enable','on');
        set(pb.idh.sliceInfo,'Enable','off');
        set(pb.idh.sessionInfo,'Enable','off');
        
        
    else
        set(pb.idh.realID,'string',w.real_id);
        set(pb.idh.dob,'string',w.date_of_birth);
        sexInd = find(strContains({'M','F','unknown'},w.sex));
        set(pb.idh.sex,'value',sexInd);
        set(pb.idh.animalNotes,'string',w.animal_notes);
        
        set(pb.idh.animalInfo,'Enable','off');
        set(pb.idh.slice,'Enable','on');
        set(pb.idh.sessionInfo,'Enable','off');
        uicontrol(pb.idh.slice);
    end
    
else if src == pb.idh.insertAnimal
        
        % copy fields to key
        key=[];
        key.animal_id = str2num(get(pb.idh.animal,'string'));
        key.real_id = get(pb.idh.realID,'string');
        key.date_of_birth = get(pb.idh.dob,'string');
        key.sex = getListSelected(pb.idh.sex);
        key.animal_notes = get(pb.idh.animalNotes,'string');
        
        % error checking
        errmsg='';
        if isempty(key.animal_id) || isempty(key.real_id)
            errmsg='Animal ID and/or Real ID cannot be null';
        end

        if ~isempty(key.date_of_birth)
            try
                d=datenum(key.date_of_birth,29);
                if ~strmatch(datestr(d,29),key.date_of_birth,'exact')
                    errmsg='Date must be in form YYYY-MM-DD';
                end
            catch
                errmsg='Invalid date';
            end
        end
        
        if length(key.real_id) > 20
            errmsg='Real ID field limited to 20 characters';
        end
        
        % try to insert
        if isempty(errmsg)
            try
                m=common.Animal;
                m.insert(key);
                set(pb.idh.animalInfo,'Enable','off');
                set(pb.idh.slice,'Enable','on');
                uicontrol(pb.idh.slice);
                pb.key.animal_id = key.animal_id;
                pb.key.mp_slice = [];
                pb.key.mp_sess = [];
                pb.updateLists;
                pb.updateTabs;
            catch
                errordlg(lasterr);
            end
        else
            errordlg(errmsg);
        end

    end
end
