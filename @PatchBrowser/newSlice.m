function newSlice(pb,src,event)

if src == pb.idh.slice
    set(pb.idh.session,'string','');
    a = get(pb.idh.animal,'string');
    s = get(src,'string');
    w=[];
    if ~isempty(s)
        if isnumeric(str2num(s)) && ~isempty(str2num(s))
            w = fetch(common.MpSlice(['animal_id=' a], ['mp_slice=' s]),'*');
        end
    end
    
    if isempty(w)
        set(pb.idh.sliceInfo,'Enable','on');
        
        set(pb.idh.session,'Enable','off');
        set(pb.idh.sessionInfo,'Enable','off');
    else
        set(pb.idh.date,'string',w.slice_date);
        set(pb.idh.region,'string',w.brain_area);
        set(pb.idh.thickness,'string',w.thickness);
        set(pb.idh.sliceNotes,'string',w.slice_notes);
        
        set(pb.idh.sliceInfo,'Enable','off');
        set(pb.idh.session,'Enable','on');
        uicontrol(pb.idh.session);
        
    end
    
else if src == pb.idh.insertSlice
        % copy fields to key
        key=[];
        key.animal_id = str2num(get(pb.idh.animal,'string'));
        key.mp_slice = str2num(get(pb.idh.slice,'string'));
        key.brain_area = get(pb.idh.region,'string');
        key.slice_date = get(pb.idh.date,'string');
        key.thickness = str2num(get(pb.idh.thickness,'string'));
        key.experimenter = get(pb.idh.experimenter,'string');
        key.slice_notes = get(pb.idh.sliceNotes,'string');
        
        % error checking
        errmsg='';
        if isempty(key.mp_slice)
            errmsg='Slice number cannot be null';
        end
        
        if ~isempty(key.slice_date)
            try
                d=datenum(key.slice_date,29);
                if ~strmatch(datestr(d,29),key.slice_date,'exact')
                    errmsg='Date must be in form YYYY-MM-DD';
                end
            catch
                errmsg='Invalid date';
            end
        end
        
        % try to insert
        if isempty(errmsg)
            try
                m=common.MpSlice;
                m.insert(key);
                set(pb.idh.sliceInfo,'Enable','off');
                set(pb.idh.session,'Enable','on');
                uicontrol(pb.idh.session);
                key.animal_id = key.animal_id;
                pb.key.mp_slice = key.mp_slice;
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
