function updateTabs(pb,src,event)

if nargin==1
    event.SelectedChild=1;
end

if ~isempty(pb.key.animal_id) && ~isempty(pb.key.mp_slice) && ~isempty(pb.key.mp_sess)
    set(pb.tabPanel,'TabEnable',{'on','on','on'});
    
    %infoPanel
    if event.SelectedChild==1
        pb.tabPanel.SelectedChild=1;
        delete(get(pb.infoPanel,'children'));
        fields={'date_of_birth','sex','animal_notes','slice_date','brain_area','thickness','experimenter','slice_notes','mp_sess_purpose','mp_sess_path','mp_sess_notes'};
        uicontrol('style','text','parent',pb.infoPanel,...
            'String',struct2text(fetch(common.Animal(pb.key)*common.MpSlice(pb.key)*common.MpSession(pb.key),fields{:})),...
            'units','normalized','position',[.025 .025 .95 .95],'horizontalalignment','left');
        uicontrol('parent',pb.infoPanel,'String','New Session','units','normalized','position',[.7 .9 .2 .05],'callback',@pb.insertDialog);
    end
    
    %seriesPanel
    if event.SelectedChild==2
        pb.tabPanel.SelectedChild=2;
        delete(get(pb.seriesPanel,'children'));
        series = fetch(mp.Series(pb.key),'*');
        if ~isempty(series) 
            pb.plotSeries;
        elseif isempty(series)
            uicontrol('Parent', pb.seriesPanel, 'String','Import Series','units','normalized','position',[.4 .475 .2 .05],'callback',@pb.importSeries);
        end
    end
    
    %sketchPanel
    if event.SelectedChild==3
        pb.tabPanel.SelectedChild=3;
        delete(get(pb.sketchPanel,'children'));
        sketch = fetch(mp.CellAssignment(pb.key));
        if ~isempty(sketch)
            pb.plotSketch
        else
            uicontrol('Parent', pb.sketchPanel, 'String','New Sketch','units','normalized','position',[.4 .475 .2 .05],'callback',@pb.newSketch);
        end
        
    end
    
else
    set(pb.tabPanel,'TabEnable',{'on','off','off'});
    pb.tabPanel.SelectedChild = 1;
    delete(get(pb.infoPanel,'children'));
    uicontrol('parent',pb.infoPanel,'String','New Session','units','normalized','position',[.4 .475 .2 .05],'callback',@pb.insertDialog);
end

