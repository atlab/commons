function newSketch(pb,src,event)

%% set up figure
pb.sketchObj=[];
pb.sketchConnection=cell(8);
if ~isempty(findobj(0,'tag','sketchFig'))
    pb.sketchFig = findobj(0,'tag','sketchFig');
else
    pb.sketchFig = figure;
    set(pb.sketchFig,'keypressfcn',@pb.updateSketch,'tag','sketchFig');
    set(pb.sketchFig,'position',[900 50 950 900]);
end
figure(pb.sketchFig)
clf

hBox = uiextras.HBoxFlex('Parent',pb.sketchFig,'Spacing',3);
vBox = uiextras.VBoxFlex('Parent',hBox,'Spacing',3);
sketchPanel = uiextras.BoxPanel('Parent',vBox,'Title','Sketch');
uicontrol('parent',vBox,'string','Save Sketch','callback',@pb.saveSketch);
set(vBox,'Sizes',[-1,20]);

axes('parent',sketchPanel,'xlim',[-1 1], 'ylim', [.5 7.5],'ydir','reverse','xtick',[],'ytick',[1 2 3 4 5 6],'box','on','ActivePositionProperty', 'OuterPosition','buttondownfcn',@pb.updateSketch)

set(gca,'deletefcn','pb.sketchObj=[];');
for i=1.5:5.5
    line([-10 10],[i i])
end
hold on
pb.sketchObj(1).handle=plot(-1,.5,'marker','^','markerfacecolor',[.4 .4 .4],'color',[.4 .4 .4],'markersize',10);
pb.sketchObj(1).id=0;
pb.sketchObj(1).chan=-1;
pb.sketchObj(1).cell_type='Pyramidal';
pb.sketchObj(1).cell_label='None';
pb.sketchObj(1).textStr = '';
pb.sketchObj(1).x = -1;
pb.sketchObj(1).y = .5;
pb.sketchObj(1).textHandle=[];

pb.sketchObj(2).handle=plot(-.9,.5,'marker','o','markerfacecolor',[.4 .4 .4],'color',[.4 .4 .4],'markersize',10);
pb.sketchObj(2).id=0;
pb.sketchObj(2).chan=-1;
pb.sketchObj(2).cell_type='Not specified';
pb.sketchObj(2).cell_label='None';
pb.sketchObj(2).textStr = '';
pb.sketchObj(2).x = -1;
pb.sketchObj(2).y = .5;
pb.sketchObj(2).textHandle=[];

draggable(pb.sketchObj(1).handle,'endfcn',@pb.updateSketch);
draggable(pb.sketchObj(2).handle,'endfcn',@pb.updateSketch);


%% set up assignment info
vBox = uiextras.VBoxFlex('Parent',hBox,'Spacing',3);
titlePanel = uicontrol('Style','text','Parent',vBox,'String','Assignments','Backgroundcolor',[0.75 0.9 1.0]);
for i=1:8
    tBox(i)=uicontrol('Style','text','Parent', vBox, 'String',['Channel ' num2str(i)]);
    set(tBox(i),'backgroundcolor',pb.patchCol(i,:),'foregroundcolor','w');
    
    % Initialize possible assignments, types, and labels
    assignments={'New Cell'};
    types=mp.Cell.table.getEnumValues('cell_type');
    labels=mp.Cell.table.getEnumValues('cell_label');
    
    % get all previous cells on this channel for this slice
    key=pb.key;
    key=rmfield(key,'mp_sess'); 
    key.channel=i;
    c = fetch(mp.CellAssignment(key),'*');
    
    % If there's no previous cells on this channel for this slice, set it
    % up for a new cell
    if isempty(c)   
        tVal = find(strcmp('Not Specified',types));
        lVal = find(strcmp('None',labels));
        uicontrol('Style','popup','Parent', vBox, 'String',assignments,'Value',1,'backgroundcolor','w','enable','off','tag',['assignment' num2str(i)]);
        uicontrol('Style','popup','Parent', vBox, 'String',types,'Value',tVal,'backgroundcolor','w','tag',['celltype' num2str(i)],'callback',@pb.updateSketch);
        uicontrol('Style','popup','Parent', vBox, 'String',labels,'Value',lVal,'backgroundcolor','w','tag',['celllabel' num2str(i)],'callback',@pb.updateSketch);
        uicontrol('Style','edit','Parent', vBox, 'String','','backgroundcolor','w','tag',['cellnote' num2str(i)]);
    
    % Otherwise, it may be the same cell as a previous session
    else
        
        % Create a list of previous cell assignments on this channel
        [~,ind] = sort([c.mp_sess],'descend');
        c = c(ind);
        for j=1:length(c)
            assignments{j+1} = ['Cell ' num2str(c(j).cell_id) '  (Session ' num2str(c(j).mp_sess) ')'];
        end
        
        % assume it's the same cell as the most recent session
        c=c(1);
        cType = fetch1(mp.Cell(['cell_id=' num2str(c.cell_id)]),'cell_type');
        tVal = find(strcmp(cType,types));
        cLabel = fetch1(mp.Cell(['cell_id=' num2str(c.cell_id)]),'cell_label');
        lVal = find(strcmp(cLabel,labels));
        uicontrol('Style','popup','Parent', vBox, 'String',assignments,'Value',2,'backgroundcolor','w','tag',['assignment' num2str(i)],'callback',@pb.updateSketch);
        uicontrol('Style','popup','Parent', vBox, 'String',types,'Value',tVal,'backgroundcolor','w','tag',['celltype' num2str(i)],'callback',@pb.updateSketch);
        uicontrol('Style','popup','Parent', vBox, 'String',labels,'Value',lVal,'backgroundcolor','w','tag',['celllabel' num2str(i)],'callback',@pb.updateSketch);
        uicontrol('Style','edit','Parent', vBox, 'String','','backgroundcolor','w','tag',['cellnote' num2str(i)]);
        
        % add a new pb.SketchObj
        w = length(pb.sketchObj) + 1;
        pb.sketchObj(w).chan=c.channel;
        pb.sketchObj(w).id=c.cell_id;
        pb.sketchObj(w).cell_type=cType;
        pb.sketchObj(w).cell_label=cLabel;
        pb.sketchObj(w).textStr = num2str(c.channel);
        pb.sketchObj(w).x = c.sketch_x;
        pb.sketchObj(w).y = c.sketch_y;
        if isPyramidal(pb.sketchObj(w))
            pb.sketchObj(w).handle=plot(c.sketch_x,c.sketch_y,'marker','^','markerfacecolor',pb.patchCol(c.channel,:),'color',pb.patchCol(c.channel,:),'markersize',10);
        else
            pb.sketchObj(w).handle=plot(c.sketch_x,c.sketch_y,'marker','o','markerfacecolor',pb.patchCol(c.channel,:),'color',pb.patchCol(c.channel,:),'markersize',10);
        end
          
        draggable(pb.sketchObj(w).handle,'endfcn',@pb.updateSketch);
        pb.sketchObj(w).textHandle=text(c.sketch_x+.02, c.sketch_y+.02, pb.sketchObj(w).textStr,'fontsize',14);
    end
end

%% draw connections
for i=1:length(pb.sketchObj)
    for j=1:length(pb.sketchObj)
        if i==j
            continue
        end
        
        pair = fetch(pro(mp.CellPair(['cell_id=' num2str(pb.sketchObj(i).id)],'presynaptic=1','connected=1'),'cell_id->cell1')...
            * pro(mp.CellPair(['cell_id=' num2str(pb.sketchObj(j).id)],'presynaptic=0','connected=1'),'cell_id->cell2'),'cell_pair');
        if isempty(pair)
            continue
        else
            
            % Draw each direction with a different width to see overlaps
            if pb.sketchObj(i).chan > pb.sketchObj(j).chan
                hLine=line([pb.sketchObj(i).x pb.sketchObj(j).x],[pb.sketchObj(i).y pb.sketchObj(j).y],'color',pb.patchCol(pb.sketchObj(i).chan,:),'linestyle','--','linewidth',6);
            else
                hLine=line([pb.sketchObj(i).x pb.sketchObj(j).x],[pb.sketchObj(i).y pb.sketchObj(j).y],'color',pb.patchCol(pb.sketchObj(i).chan,:),'linestyle','-','linewidth',3);
            end
            
            % get it out of the way of the clickable cell markers
            sendToBack(hLine);
            
            % I don't think we want to make it clickable - you shouldn't be
            % able to delete a connection identified in another file
            % set(hLine,'buttondownfcn',@pb.updateSketch);
            
            pb.sketchConnection{pb.sketchObj(i).chan,pb.sketchObj(j).chan}=hLine;
        end
    end
end
set(hBox,'Sizes',[-1 500]);
set(vBox,'Sizes',[15 -1*ones(1,40)])

