function key=drawOptMask(key)
set(gcf,'WindowButtonDownFcn',@wbdcb,'CloseRequestFcn',@wcf,'UserData',key)
hold on
title('Outline valid area with mouse')
waitfor(gcf);
end

function wcf(src,evnt)
selection = questdlg('Save mask?',...
    'Close Request Function',...
    'Yes','No','Yes');
switch selection
    case 'Yes'
        key=get(src,'userdata');
        
        imh=findobj(gca,'type','image');
        m=max(get(imh,'xdata'));
        n=max(get(imh,'ydata'));
        key=get(src,'userdata');
        key.structure_mask=zeros(n,m,'uint8');
        h = findobj(gca,'tag','mask');
        
        x=get(h,'Xdata');
        y=get(h,'Ydata');
        c = poly2mask(x, y, n,m);
        key.structure_mask(c)=1;
        set(src,'userdata',key);
    case 'No'
        h = findobj(gca,'tag','mask');
        if ~isempty(h)
            delete(h);
        end
        return
end
assignin('caller','key',key);
delete(gcf)
drawnow
end



function wbdcb(src,evnt)
if strcmp(get(src,'SelectionType'),'normal')
    set(src,'pointer','circle')
    cp = get(gca,'CurrentPoint');
    xinit = cp(1,1);yinit = cp(1,2);
    set(src,'WindowButtonMotionFcn',@wbmcb)
    set(src,'WindowButtonUpFcn',@wbucb)
end
end

function wbmcb(src,evnt)
h = findobj(gca,'tag','selectPoly');

cp = get(gca,'currentpoint');
cp = [cp(1,1) cp(1,2)];

if isempty(h)
    h = plot(cp(1),cp(2));
    set(h,'tag','selectPoly');
else
    x=[get(h,'Xdata') cp(1)];
    y=[get(h,'Ydata') cp(2)];
    set(h,'Xdata',x,'ydata',y)
end
end

function wbucb(src,evnt)
if strcmp(get(src,'SelectionType'),'extend')
    set(src,'Pointer','arrow')
    set(src,'WindowButtonMotionFcn','')
    set(src,'WindowButtonUpFcn','')
    h = findobj(gca,'tag','selectPoly');
    delete(h);
else
    set(src,'Pointer','arrow')
    set(src,'WindowButtonMotionFcn','')
    set(src,'WindowButtonUpFcn','')
    
    h = findobj(gca,'tag','selectPoly');
    x=[get(h,'Xdata')]; x=[x x(1)];
    y=[get(h,'Ydata')]; y=[y y(1)];
    set(h,'Xdata',x,'ydata',y)
    
    set(h,'tag','mask');
end
end




