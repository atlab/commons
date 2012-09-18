function pixMask
set(gcf,'WindowButtonDownFcn',@wbdcb)
hold on
title('Outline valid area with mouse')
%waitfor(gcf);
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
try
    delete(findobj(gca,'tag','oldPoly'))
catch
end
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
    set(h,'tag','oldPoly');
    imh=findobj(gca,'type','image');
    m=max(get(imh,'xdata'));
    n=max(get(imh,'ydata'));

    mask=zeros(n,m,'uint8');
    c = poly2mask(x, y, n,m);
    mask(c)=1;
    pixInd=find(mask(:));
    
    assignin('caller','mask',mask)
    assignin('caller','pixInd',pixInd)
end
end




