function updateTraces(pb,src,event)

purpose = fetch1(common.MpSession(pb.key),'mp_sess_purpose');
switch purpose
    case 'stimulation'
        switch get(src,'type')
            case 'line'
                set(findobj(gcf,'linewidth',3),'linewidth',1,'color',[.4 .4 .4]);
                set(findobj(gcf,'tag','mean'),'linewidth',2);
                tag = get(src,'tag');
                if strncmp('mean',tag,1)
                    return
                end
                set(findobj(gcf,'tag',tag),'linewidth',3,'color','y');
                bringToFront(findobj(gcf,'tag','mean'));
                bringToFront(findobj(gcf,'tag',tag));
            case 'axes'
                set(findobj(gcf,'linewidth',3),'linewidth',1,'color',[.4 .4 .4]);
                set(findobj(gcf,'tag','mean'),'linewidth',2);
                bringToFront(findobj(gcf,'tag','mean'));
            case 'figure'
                c = event.Character;
                if c == char(127)
                    h = findobj(gcf,'linewidth',3);
                    tag = get(h,'tag');
                    if strncmp('mean',tag,1)
                        return
                    end
                    
                    for i = 1:length(h)
                        p = get(h(i),'parent');
                        
                        mH = findobj(p,'tag','mean');
                        T = get(mH,'userdata');
                        T(str2num(tag{i}),:)=nan;
                        set(mH,'userdata',T);
                        
                        if size(T,1)>1
                            set(mH,'ydata',nanmean(T));
                        else
                            set(mH,'ydata',zeros(size(T)));
                        end
                        
                        delete(h(i));
                    end
                end
        end
        
    case 'firingpattern'
        switch get(src,'type')
            case 'line'
                h=findobj(gcf,'tag','singletrace');
                set(h,'Ydata',get(src,'ydata'));
                set(findobj(gcf,'linewidth',3),'linewidth',1);
                set(src,'linewidth',3);
            case 'figure'
                c = event.Character;
                if c == char(30)
                    ind = str2num(get(findobj(gcf,'linewidth',3),'tag'));
                    h = findobj(gcf,'tag',num2str(ind+1));
                    if ~isempty(h)
                        set(findobj(gcf,'linewidth',3),'linewidth',1);
                        set(h,'linewidth',3);
                        hSingle=findobj(gcf,'tag','singletrace');
                        set(hSingle,'Ydata',get(h,'ydata'));
                    end
                elseif c == char(31)
                    ind = str2num(get(findobj(gcf,'linewidth',3),'tag'));
                    h = findobj(gcf,'tag',num2str(ind-1));
                    if ~isempty(h)
                        set(findobj(gcf,'linewidth',3),'linewidth',1);
                        set(h,'linewidth',3);
                        hSingle=findobj(gcf,'tag','singletrace');
                        set(hSingle,'Ydata',get(h,'ydata'));
                    end
                end
        end
end






