%function traces = importTraces( input_args )
fn = '/mnt/lab/users/jake/work/local/@PatchBrowser/x120816b.inf';
fid = fopen(fn,'r');

datPath = fgetl(fid);

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
        tr(k).group = n(end-3);
        tr(k).sweep = n(end-1);
        tr(k).trace = n(end);
        tr(k).series = n(end-2);
        tr(k).sweep = n(end-1);
        tr(k).trace = n(end);
        tr(k).chan = str2num(tr(k).chanStr(end));
        tr(k).stim = str2num(tr(k).stimStr(end));
        
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
        
        tr(k).ts = eval(['Trace' tr(k).suffix '(:,1);']);
        tr(k).dat = eval(['Trace' tr(k).suffix '(:,2);']);
        
        k=k+1;
    end
        
        s = fgetl(fid);
end

fclose(fid);


%% parse series and sweep num


for i=tr
    group(i.group).series(i.series).sweep(i.sweep).trace(i.trace) = i;
end
  
%%
for gr = 1:length(group)
    numSeries = length(group(gr).series);
    numTrace = length(group(gr).series(1).sweep(1).trace);
    figure
    for se = 1:numSeries
        for t = 1:numTrace
            subplot(numTrace,numSeries, (t-1)*numSeries+se);
            T=[];
            hz = group(gr).series(se).sweep(1).trace(1).hz;
            if group(gr).series(se).sweep(1).trace(t).yUnit=='A'
                scl=1E-12;
            elseif group(gr).series(se).sweep(1).trace(t).yUnit=='V'
                scl=.001;
            end
            len = group(gr).series(se).sweep(1).trace(1).sampCount;
            for sw = 1:length(group(gr).series(se).sweep)
                T(sw,:) = group(gr).series(se).sweep(sw).trace(t).dat;
            end
            if sw>1
                mT=mean(T)/scl;
            else
                mT=T/scl;
            end
            plot(0:1/hz:(len-1)/hz,mT,'color',patchCol(t,:));
            set(gca,'xlim',[0 len/hz],'ylim',[min([mT -20]), max([mT 20])]);
            pos = get(gca,'position');
            set(gca,'position',[pos(1:2),pos(3:4)*1.1])
            
            if group(gr).series(se).sweep(1).trace(t).chan == group(gr).series(se).sweep(1).trace(t).stim
                set(gca,'color','y');
                text(len/(hz*1.5),mean([min([mT -20]), max([mT 20])]),[num2str(length(group(gr).series(se).sweep)) 'x'],'color',patchCol(t,:));
            end
            
            if t==1
                title(['Series ' num2str(se)])
            end
            
            if se==1
                ylabel(['Chan ' num2str(t)]);
            end
            
            set(gca,'buttondownfcn',@browseSeries)
            
        end
    end
end
            
            
%%            


T=cell(8);
scl=ones(8);
hz=ones(8);
k=1;
for i=tr
    k=k+1;
    if i.yUnit=='A'
        scl(i.chan,i.stim)=1E-12;
    elseif i.yUnit=='V'
        scl(i.chan,i.stim)=.001;
    end
    hz(i.chan,i.stim)=i.hz;
    try
        T{i.chan,i.stim}=cat(2,T{i.chan,i.stim}, i.dat);
    catch
        %lasterr
        disp('using padCat instead of cat');
        T{i.chan,i.stim}=padCat(2,T{i.chan,i.stim}, i.dat);
    end
end

figure;
k=1;
for i=1:8
    for j=1:8
        subplot(8,8,k)
        %if k>1 
        %    continue
        %end
        %figure
        len = size(T{i,j},1);
        plot(0:1/hz(i,j):(len-1)/hz(i,j),T{i,j}/scl(i,j),'color',[.4 .4 .4]);
        hold on
        plot(0:1/hz(i,j):(len-1)/hz(i,j),mean(T{i,j},2)/scl(i,j),'k','linewidth',2);
        set(gca,'xlim',[0 len/hz(i,j)],'ylim',[min(T{i,j}(:))/scl(i,j) max(T{i,j}(:))/scl(i,j)]);
        pos = get(gca,'position');
        set(gca,'position',[pos(1:2),pos(3:4)*1.1])
        k=k+1;
    end
end

figure;
k=1;
for i=1:8
    for j=1:8
        subplot(8,8,k)
%         figure
%         if k>1 
%             continue
%         end
        if i==j
            len = size(T{i,j},1);
            plot(0:1/hz(i,j):(len-1)/hz(i,j),T{i,j}/scl(i,j),'color',[.4 .4 .4]);
            hold on
            plot(0:1/hz(i,j):(len-1)/hz(i,j),mean(T{i,j},2)/scl(i,j),'b');
            set(gca,'xlim',[0 len/hz(i,j)],'ylim',[min(T{i,j}(:))/scl(i,j) max(T{i,j}(:))/scl(i,j)]);
            pos = get(gca,'position');
        else
            len = size(T{i,j},1);
            x = 0: 1/hz(i,j) : (len-1)/hz(i,j);
            w = ones(10,1);
            w = w/sum(w);
            mT = convmirr(mean(T{i,j},2)/scl(i,j),w);
            plot(x,mT,'b');
            set(gca,'xlim',[0 len/hz(i,j)],'ylim',[min(mT(:)) max(mT(:))]);
        end
        pos = get(gca,'position');
        set(gca,'position',[pos(1:2),pos(3:4)*1.1])
        k=k+1;

    end
end
%end

