function importSeries(pb,src,event)

fn = fetch1(common.MpSession(pb.key),'mp_sess_path');
%fn = '/mnt/lab/users/jake/work/local/@PatchBrowser/x120816b.inf';

if length(fn)<4
    errordlg('No file path specified');
    return
end

if all(fn(end-3:end) == '.mat') || all(fn(end-3:end) == '.inf')
    fn = fn(1:end-4);
end

try
    mat = load([fn '.mat']);
catch
    errordlg('lasterr');
end

fid = fopen([fn '.inf'],'r');
if fid<0
    errordlg(['Cannot open ' fn '.inf']);
    return
end


datPath = fgetl(fid);

childs = get(pb.seriesPanel,'children');
delete(childs);
uicontrol('Parent', pb.seriesPanel, 'String','Importing...','units','normalized','position',[.4 .475 .2 .05]);
drawnow

try
s = fgetl(fid);
k=1;
tr=[];
while ischar(s)
    
    if strmatch('TRACE',s,'exact')
        
        s = fgetl(fid);
        tr(k).baseName = decell(textscan(s, '%s[^_]','delimiter','_'));
        tr(k).suffix = sscanf(s, [tr(k).baseName '%s']);
        
        s = fgetl(fid);
        assert(strchk(s,'Label'));
        tr(k).chanStr = strtrim(sscanf(s, '%s[^;]'));
        
        s = fgetl(fid);
        assert(strchk(s,'Stimulus'));
        tr(k).stimStr = strtrim(sscanf(s, '%[^;]'));
        
        n = sscanf(tr(k).suffix,'_%u_%u_%u_%u');
        tr(k).group = n(1);
        tr(k).series = n(2);
        tr(k).sweep = n(3);
        tr(k).trace = n(4);


        tr(k).chan = decell(textscan(tr(k).chanStr,'%*s%u%*s','delimiter','- '));
        
        %tr(k).stim = decell(textscan(tr(k).stimStr,'%*s%u%*s','delimiter','- '));
        tr(k).stim = str2num(tr(k).stimStr(5));
        
        s = fgetl(fid);
        assert(strchk(s,'Sample Interval'));
        tr(k).hz = 1/sscanf(s, '%f');
        
        s = fgetl(fid);
        assert(strchk(s,'Scaling factor'));
        tr(k).scale = sscanf(s, '%f');
        
        s = fgetl(fid);
        assert(strchk(s,'Y-unit'));
        tr(k).yUnit = sscanf(s, '%c1');
        
        s = fgetl(fid);
        % Trace Time
        
        s = fgetl(fid);
        assert(strchk(s,'Holding Voltage'));
        tr(k).holdVolt = sscanf(s, '%f');
        
        s = fgetl(fid);
        assert(strchk(s,'Total Points'));
        tr(k).sampCount = sscanf(s, '%u');
        
        tr(k).ts = eval(['mat.Trace' tr(k).suffix '(:,1);']);
        tr(k).dat = eval(['mat.Trace' tr(k).suffix '(:,2);']);
        
        k=k+1;
    end
    
    s = fgetl(fid);
end

fclose(fid);


%%
if any(unique([tr.group]) > 1)
    errordlg('Multiple groups not allowed in single .inf file');
    return
end

series = unique([tr.series]);
for i=1:length(series)
    seInd = find([tr.series] == series(i));
    se(i).animal_id = pb.key.animal_id;
    se(i).mp_slice = pb.key.mp_slice;
    se(i).mp_sess = pb.key.mp_sess;
    se(i).series = series(i);
    se(i).channels = unique([tr(seInd).chan]);
    
    se(i).stim_chan = unique([tr(seInd).stim]);
    if length(se(i).stim_chan) > 1
        errordlg(['Multiple stim chans for series ' num2str(i)])
        return
    end
    
    se(i).hz = unique([tr(seInd).hz]);
    if length(se(i).hz) > 1
        errordlg(['Multiple sampling frequencies for series ' num2str(i)])
        return
    end
    
    se(i).sweep_count = length(unique([tr(seInd).sweep]));
    se(i).sample_count = unique([tr(seInd).sampCount]);
    if length(se(i).sample_count) > 1
        errordlg(['Multiple sample counts for series ' num2str(i)])
        return
    end
    
    se(i).y_units=[];
    se(i).scales=[];
    se(i).v_hold=[];
    k=1;
    for j = se(i).channels
        ind = find([tr.series] == i & [tr.chan] == j);
        
        y_unit = unique([tr(ind).yUnit]);
        if length(y_unit) > 1
            errordlg(['Multiple Y units for series ' num2str(i) ', channel ' num2str(j)])
            return
        end
        se(i).y_units = [se(i).y_units y_unit];
        
        scales = unique([tr(ind).scale]);
        if length(scales) > 1
            errordlg(['Multiple scaling factors for series ' num2str(i) ', channel ' num2str(j)])
            return
        end
        se(i).scales = [se(i).scales scales];
        
        v_hold = unique([tr(ind).holdVolt]);
        if length(v_hold) > 1
            errordlg(['Multiple holding voltages for series ' num2str(i) ', channel ' num2str(j)])
            return
        end
        se(i).v_hold = [se(i).v_hold v_hold];
        
        for w = 1:se(i).sweep_count
            ind = find([tr.series] == i & [tr.chan] == j & [tr.sweep] == w);
            se(i).traces{k}(w,:) = tr(ind).dat';
            se(i).validtraces(j,w) = 1;
        end
        k=k+1;
    end
end

m = mp.Series;
try
    m.insert(se);
catch
    errordlg(lasterr);
end
pb.updateTabs;
catch
    childs = get(pb.seriesPanel,'children');
    delete(childs);
    uicontrol('Parent', pb.seriesPanel, 'String','Import Series','units','normalized','position',[.4 .475 .2 .05],'callback',@pb.importSeries);
    error(lasterr);
end

