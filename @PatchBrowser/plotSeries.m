function plotSeries(pb)

series = fetch(mp.Series(pb.key),'*');
nSeries = length(series);
for se = series'
    nChan = length(se.channels);
    for c = 1:nChan
        h=subplot(nChan,nSeries, (c-1)*nSeries+se.series);
        set(h,'parent',pb.seriesPanel);
        T=[];
        
        if se.y_units(c)=='A'
            scl=1E-12;
        elseif se.y_units(c)=='V'
            scl=.001;
        end
        
        if size(se.traces{c},1)>1
            T=mean(se.traces{c})/scl;
        else
            T=se.traces{c}/scl;
        end
        x = 0:1/se.hz:(se.sample_count-1)/se.hz;
        h=plot(x,T,'color',pb.patchCol(se.channels(c),:));
        set(h,'buttondownfcn',@pb.plotTraces)
        if min(T)==max(T)
            T=[0 1];
        end
        
        pos = get(gca,'position');
        set(gca,'position',[pos(1:2),pos(3:4)*1.1])
        
        if se.channels(c) == se.stim_chan
            set(gca,'color','y');
            set(gca,'xlim',[min(x) max(x)],'ylim',[-20 150]);
            text(max(x)/1.5,mean(T),[num2str(size(se.traces{c},1)) 'x'],'color',pb.patchCol(c,:));
        else
            set(gca,'xlim',[min(x) max(x)],'ylim',[-1 3]);
        end
        
        if c==1
            title(['Series ' num2str(se.series)])
        end
        
        if se.series==1
            ylabel(['Chan ' num2str(se.channels(c))]);
        end
        
        k=se;
        k.chan=se.channels(c);
        set(gca,'buttondownfcn',@pb.plotTraces,'userdata',k)
        drawnow
    end
end