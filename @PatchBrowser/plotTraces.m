function plotTraces(pb,src,event)

purpose = fetch1(common.MpSession(pb.key),'mp_sess_purpose');
switch purpose
    case 'stimulation'
        
        if ~isempty(findobj(0,'tag','sweepFig'))
            pb.sweepFig = findobj(0,'tag','sweepFig');
        else
            pb.sweepFig = figure;
            set(pb.sweepFig,'keypressfcn',@pb.updateSketch,'tag','sweepFig');
        end
        figure(pb.sweepFig)
        clf
        
        if get(src,'type')=='line'
            src=get(src,'parent');
        end
        se = get(src,'userdata');
        set(gcf,'userdata',se,'keypressfcn',@pb.updateTraces);
        
        a1 = subplot(2,1,1);
        a1=gca;
        chanInd = find([se.channels]==se.chan);
        if se.y_units(chanInd)=='A'
            scl=1E-12;
        elseif se.y_units(chanInd)=='V'
            scl=.001;
        end
        
        T=se.traces{chanInd};
        if size(T,1)>1
            mT=mean(T)/scl;
        else
            mT=T/scl;
        end
        x = 0:1/se.hz:(se.sample_count-1)/se.hz;
        
        for i=1:size(T,1)
            h=plot(x,T(i,:)/scl,'color',[.4 .4 .4]);
            set(h,'tag',num2str(i),'buttondownfcn',@pb.updateTraces);
            hold on
        end
        
        h=plot(x,mT,'color',pb.patchCol(se.chan,:),'linewidth',2);
        set(h,'tag','mean','buttondownfcn',@pb.updateTraces,'userdata',T/scl);
        if min(mT)==max(mT)
            T=[0 1];
        end
        set(gca,'xlim',[min(x) max(x)],'ylim',[min(T(:)/scl) max(T(:)/scl)]*1.2);
        set(gca,'buttondownfcn',@pb.updateTraces);
        
        title(['Series ' num2str(se.series) ' Channel ' num2str(se.chan)])
        
        if se.y_units(chanInd)=='A'
            ylabel('pA');
        elseif se.y_units(chanInd)=='V'
            ylabel('mV');
        end
        
        
        %%
        a2 = subplot(2,1,2);
        
        chanInd = find([se.channels]==se.stim_chan);
        if se.y_units(chanInd)=='A'
            scl=1E-12;
        elseif se.y_units(chanInd)=='V'
            scl=.001;
        end
        
        T=se.traces{chanInd};
        if size(T,1)>1
            mT=mean(T)/scl;
        else
            mT=T/scl;
        end
        x = 0:1/se.hz:(se.sample_count-1)/se.hz;
        for i=1:size(T,1)
            h=plot(x,T(i,:)/scl,'color',[.4 .4 .4]);
            set(h,'tag',num2str(i),'buttondownfcn',@pb.updateTraces);
            hold on
        end
        h=plot(x,mT,'color',pb.patchCol(se.stim_chan,:),'linewidth',2);
        set(h,'tag','mean','buttondownfcn',@pb.updateTraces,'userdata',T/scl);
        if min(mT)==max(mT)
            T=[0 1];
        end
        set(gca,'xlim',[min(x) max(x)],'ylim',[min(T(:)/scl) max(T(:)/scl)]*1.2);
        set(gca,'buttondownfcn',@pb.updateTraces);
        
        title(['Series ' num2str(se.series) ' Channel ' num2str(se.stim_chan)])
        
        if se.y_units(chanInd)=='A'
            ylabel('pA');
        elseif se.y_units(chanInd)=='V'
            ylabel('mV');
        end
        
        xlabel('sec')
        
        yL=get(a1,'ylim');
        
        if se.chan ~= se.stim_chan
            mT=mT-min(mT);
            mT=mT/max(mT);
            mT = mT*diff(yL)+yL(1);
            plot(a1,x,mT,'color',pb.patchCol(se.stim_chan,:),'linewidth',2);
        end
        
        set(a2,'position',[.05 .05 .9 .17]);
        set(a1,'position',[.05 .3 .9 .65]);
        
    case 'firingpattern'
        if isempty(pb.sweepFig)
            pb.sweepFig = figure;
        else
            figure(pb.sweepFig);
            clf
        end
        set(gcf,'keypressfcn',@pb.updateTraces);
        if get(src,'type')=='line'
            src=get(src,'parent');
        end
        se = get(src,'userdata');
        
        subplot 211
        
        chanInd = find([se.channels]==se.chan);
        scl=.001;
        T=se.traces{chanInd};
        x = 0:1/se.hz:(se.sample_count-1)/se.hz;
        h=plot(x,T(1,:)/scl,'color',pb.patchCol(se.chan,:));
        set(h,'tag','singletrace');
        set(gca,'xlim',[min(x) max(x)],'ylim',[min(T(:)/scl) max(T(:)/scl)]*1.2);
        pos = get(gca,'position');
        set(gca,'position',[pos(1) pos(2)/2 pos(3) pos(4)*2])
        title(['Series ' num2str(se.series) ' Channel ' num2str(se.chan)])
        ylabel('mV');
        xlabel('sec')
        
        %%
        subplot 414
        
        for i=1:size(T,1)
            h=plot(x,T(i,:)/scl,'color',pb.patchCol(se.chan,:));
            if i==1
                set(h,'linewidth',3);
            end
            set(h,'tag',num2str(i),'buttondownfcn',@pb.updateTraces);
            hold on
        end
        
        set(gca,'xlim',[min(x) max(x)],'ylim',[min(T(:)/scl) max(T(:)/scl)]*1.2);
        ylabel('mV');
        xlabel('sec')
        
end



