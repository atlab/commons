function plotSketch(pb)

pb.sketchObj=[];
pb.sketchConnection=cell(8);

% Set up panel
hBox = uiextras.HBoxFlex('Parent',pb.sketchPanel,'Spacing',3);
vBox = uiextras.VBoxFlex('Parent',hBox,'Spacing',3);
sketchPanel = uiextras.BoxPanel('Parent',vBox,'Title','Sketch');
uicontrol('parent',vBox,'string','Replace Sketch','callback',@pb.replaceSketch);
set(vBox,'Sizes',[-1,20]);

vBox = uiextras.VBoxFlex('Parent',hBox,'Spacing',3);
titlePanel = uicontrol('Style','text','Parent',vBox,'String','Assignments','Backgroundcolor',[0.75 0.9 1.0]);
for i=1:8
    t=uicontrol('Style','text','Parent', vBox, 'String',['Channel ' num2str(i)]);
    set(t,'backgroundcolor',pb.patchCol(i,:),'foregroundcolor','w');
    
    tBox(i)=uicontrol('Style','text','Parent', vBox, 'String','');
end
set(hBox,'Sizes',[-1 100]);
set(vBox,'Sizes',[15 -1 -2 -1 -2 -1 -2 -1 -2 -1 -2 -1 -2 -1 -2 -1 -2])

axes('parent',sketchPanel,'xlim',[-1 1], 'ylim', [.5 6.5],'ydir','reverse','xtick',[],'box','on','ActivePositionProperty', 'OuterPosition')

set(gca,'deletefcn','pb.sketchObj=[];');
for i=1.5:5.5
    line([-10 10],[i i])
end
hold on

% Load cells

c = fetch(mp.CellAssignment(pb.key),'*');

for i=1:length(c)
    pb.sketchObj(i).id = c(i).cell_id;
    pb.sketchObj(i).chan = c(i).channel;
    pb.sketchObj(i).x = c(i).sketch_x;
    pb.sketchObj(i).y = c(i).sketch_y;
    
    pb.sketchObj(i).cell_type = fetch1(mp.Cell(['cell_id=' num2str(c(i).cell_id)]),'cell_type');
    pb.sketchObj(i).cell_label = fetch1(mp.Cell(['cell_id=' num2str(c(i).cell_id)]),'cell_label');
    pb.sketchObj(i).textStr = num2str(pb.sketchObj(i).chan);
    
    if isPyramidal(pb.sketchObj(i))
        marker = '^';
    else
        marker = 'o';
    end
    
    pb.sketchObj(i).handle = plot(pb.sketchObj(i).x,pb.sketchObj(i).y,'marker',marker,'markerfacecolor',pb.patchCol(c(i).channel,:),'color',pb.patchCol(c(i).channel,:),'markersize',10);
    
    set(tBox(pb.sketchObj(i).chan),'String',['ID: ' num2str(pb.sketchObj(i).id)]);
    pb.sketchObj(i).textHandle = text(pb.sketchObj(i).x+.02, pb.sketchObj(i).y+.02,pb.sketchObj(i).textStr,'fontsize',14);
end

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
            
            pb.sketchConnection{pb.sketchObj(i).chan,pb.sketchObj(j).chan}=hLine;
        end
    end
end






