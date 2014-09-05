function newSession(pb,src,event)

if src == pb.idh.session
    a = get(pb.idh.animal,'string');
    slc = get(pb.idh.slice,'string');
    sess = get(src,'string');
    
    w=[];
    if ~isempty(sess)
        if isnumeric(str2num(sess)) && ~isempty(str2num(sess))
            w = fetch(common.MpSession(['animal_id=' a], ['mp_slice=' slc], ['mp_sess=' sess]),'*');
        end
    end
    
    if isempty(w)
        set(pb.idh.sessionInfo,'Enable','on');
    else
        set(pb.idh.path,'string',w.mp_sess_path);
        set(pb.idh.sessionNotes,'string',w.mp_sess_notes);
        
        set(pb.idh.sessionInfo,'Enable','off');
        set(pb.idh.session,'Enable','on');
    end
    
else if src == pb.idh.insertSession
        % copy fields to key
        key=[];
        key.animal_id = str2num(get(pb.idh.animal,'string'));
        key.mp_slice = str2num(get(pb.idh.slice,'string'));
        key.mp_sess = str2num(get(pb.idh.session,'string'));
        purposes = {'stimulation','firingpattern','spontaneous','other'};
        key.mp_sess_purpose = purposes{get(pb.idh.sessionPurpose,'value')};
        key.mp_sess_path = get(pb.idh.path,'string');
        key.mp_sess_notes = get(pb.idh.sessionNotes,'string');
        
        % error checking
        errmsg='';
        
        % try to insert
        if isempty(errmsg)
            try
                m=common.MpSession;
                m.insert(key);
                set(pb.idh.sessionInfo,'Enable','off');
                pb.key.animal_id = key.animal_id;
                pb.key.mp_slice = key.mp_slice;
                pb.key.mp_sess = key.mp_sess;
                pb.updateLists;
                pb.updateTabs;
                delete(pb.idh.fig);
            catch
                errordlg(lasterr);
            end
        else
            errordlg(errmsg);
        end
    end
end
