classdef plots
    
    methods(Static)
        
        function intervals
            fig = Figure(1,'size',[80 80]);
            for d = [10 20 50 100 200]
                r = sprintf('abs(diam_delta)<%g',d);
                dil = fetchn(pupil.Phases & r & 'epoch_opt=6','duration');
                con = fetchn(pupil.Phases & r & 'epoch_opt=7','duration');
                
                bins = 0:0.1:3.2;
                
                dil = hist(dil,bins);
                con = hist(con,bins);
                dil = dil/sum(dil);
                con = con/sum(con);
                
                
                h = plot(bins,[dil;con],'LineWidth',1);
                set(h(1),'Color',[0 .5 0])
                set(h(2),'Color',[.5 0 0])
                hold on
                
            end
            hold off
            set(gca,'YColor',[1 1 1]*0.99)
            legend dilation constriction 
            legend boxoff
            xlabel 'phase duration (s)'
            
            fig.cleanup
            fig.save('~/Desktop/pupilPhases-dil.eps')
            
        end
        
        function radius
            k = 'animal_id in (2380,2381,2382,2660,2662,2470)';
            s1 = pro(pupil.EpochTrialSet&pupil.EpochVonMisesSet, pupil.EpochTrial, 'epoch_opt->e1', '2*avg(radius)/1000->d1','count(*)->n1');
            s2 = pro(pupil.EpochTrialSet&pupil.EpochVonMisesSet, pupil.EpochTrial, 'epoch_opt->e2', '2*avg(radius)/1000->d2','count(*)->n2');
            [d1,d2] = fetchn(s1*s2 & k & 'e1=7' & 'e2=6' & 'n1>50' & 'n2>50','d1','d2');
            
            [~,p] = ttest(d1-d2)
            
            fig = Figure(1,'size',[45 45]);
            scatter(d1,d2,'k.')
            m = max(max(d1),max(d2));
            axis([0 1.01 0 1.01]*m)
            ticks = 0:.500:1.500;
            set(gca,'XTick',ticks,'YTick',ticks)
            title 'Average pupil diameter (mm)'
            ylabel 'Dilation trials'
            xlabel 'Constriction trials'
            set(refline(1),'Color',[1 1 1]*.7)
            fig.cleanup
            fig.save('~/Google Drive/Pupil Paper/Figure3/pupil-diameter.eps')
        end
        
        
        
        function astroPupil
            k = hamming(17);
            k = k/sum(k);  % smoothing kernel
            for key = fetch(reso.Sync*patch.Sync*reso.SegmentGlia & patch.EyeFrame)'
                filename = sprintf('~/dev/figures/astro_%04u_%02u.eps',key.animal_id,key.scan_idx);
                fig = Figure(1, 'size', [160 120]);
                caTimes = fetch1(reso.Sync & key, 'frame_times');
                X = fetchn(reso.TraceGlia&key,'ca_trace');
                X = [X{:}];
                ticks = 1:size(X,2);
                X = bsxfun(@plus,bsxfun(@rdivide,X,mean(X)),ticks)-1;
                
                % show running epochs
                [runOn,runDur]=fetchn(patch.Running & key, 'run_on', 'run_dur');
                [faceOn,faceDur]=fetchn(patch.Facing & key, 'face_on', 'face_dur');
                [runOn, runDur] = mergeIntervals([runOn; faceOn], [runDur; faceDur]);
                
                for i=1:length(runOn)
                    patch([runOn(i) runOn(i)+runDur(i) runOn(i)+runDur(i) runOn(i)], ...
                        [-2 -2 length(ticks)*[1 1]+1],[0.7 0.7 1.0], 'LineStyle', 'none')
                end
                
                hold on
                plot(caTimes-caTimes(1), ne7.dsp.convmirr(double(X),k),'k');
                hold off
                set(gca,'YTick',ticks,'YGrid','on')
                
                % time conversion to ephys time
                [eTime,vTime] = fetch1(patch.Ephys*patch.Sync & key, 'ephys_time','vis_time');
                caTimes = interp1(vTime, eTime, caTimes);
                
                
                
                % get pupil radius and speed, convert to microns
                [pupilRadius, pupilX, pupilY, pupilTimes] = fetchn(patch.EyeFrame & key, ...
                    'pupil_r','pupil_x','pupil_y','frame_time','ORDER BY frame_time');
                pupilFPS = 1/median(diff(pupilTimes));
                saccadeSpeed = sqrt(gradient(pupilX).^2 + gradient(pupilY).^2)*pupilFPS;
                pixelPitch = 5;  % um / pixel
                saccadeSpeed = saccadeSpeed * pixelPitch;     % convert to microns
                pupilRadius = pupilRadius * pixelPitch;   % convert to microns
                % interpolate over nans
                notnans = ~isnan(pupilRadius);
                pupilRadius = interp1(pupilTimes(notnans),pupilRadius(notnans), pupilTimes, 'linear', 'extrap');
                saccadeSpeed  = interp1(pupilTimes(notnans),saccadeSpeed(notnans), pupilTimes, 'linear', 'extrap');
                
                hold on
                plot(pupilTimes,2*(pupilRadius-min(pupilRadius))/(max(pupilRadius)-min(pupilRadius))-2,'Color',[0 0.4 0.2],'LineWidth',3)
                xlabel 'time (s)'
                hold off
                
                fig.cleanup
                fig.save(filename)
                
                
                % save the image of the site
                clf
                f = figure;
                set(f,'Visible','off')
                filename = sprintf('~/dev/figures/astro_%04u_%02u-map.png',key.animal_id,key.scan_idx);
                g = fetch1(reso.Align & key, 'green_img');
                g = g - quantile(g(:),0.02);
                g = g / quantile(g(:),0.999);
                imshow(g);
                
                
                bw = fetch1(reso.SegmentGlia & key, 'mask');
                bounds = bwboundaries(bw,4);
                hold on
                
                for i=1:length(bounds)
                    bound = bounds{i};
                    plot(bound(:,2), bound(:,1), 'r');
                    xy = mean(bound);
                    text(xy(2),xy(1),sprintf('   %d',i),'Color','y','FontSize',12);
                end
                hold off
                
                im = getframe(gca);
                imwrite(im.cdata, filename)
                
                close(f)
                
            end
        end
        
        function binnedR2
            helper(6,7,false,.78,'~/Google Drive/Pupil Paper/Figure3/binned_r2-sans-saccades-noblanks.eps')
            
            function helper(epoch1,epoch2,includeBlanks,uplim,filename)
                
                r = pupil.BinnedNoiseCorr & struct('include_blanks',includeBlanks) ...
                    & 'r2 is not null' & 'animal_id in (2380,2381,2382,2660,2662,2470)';
                rr1 = [];  rr2 = [];
                for key = fetch(reso.Sync & (r & struct('epoch_opt',epoch1)) & (r & struct('epoch_opt',epoch2)))'
                    tunedIdx = find(fetchn(pupil.EpochVonMises & key & 'epoch_opt=1','(von_amp1>0.1 && von_p<0.01)->p','ORDER BY trace_id'));
                    disp(key)
                    [r2,epoch] = fetchn(pupil.BinnedNoiseCorr & key & struct('include_blanks',includeBlanks) & struct('epoch_opt',{epoch1,epoch2}),...
                        'r2','epoch_opt','ORDER BY epoch_opt');
                    assert(length(epoch)==2 && all(epoch==[epoch1 epoch2]'))
                    rr1 = [rr1; r2{1}(tunedIdx)]; %#ok<AGROW>
                    rr2 = [rr2; r2{2}(tunedIdx)]; %#ok<AGROW>
                end
                
                fig = Figure(1,'size',[45 45]);
                scatter(rr2,rr1,1,'k','filled')
                set(gca,'XTick', 0:0.2:1, 'YTick', 0:0.2:1)
                ylabel 'Quiet dilating'
                xlabel 'Quiet constricting'
                title Reliability
                axis image
                axis([0 uplim 0 uplim])
                set(refline(1,0),'Color',[1 1 1]*.6)
                fig.cleanup
                fig.save(filename)
            end
        end
        
        function binnedCorr
            helper(8,9,false,.5,.2,'noise_corr','Noise corr','~/Google Drive/Pupil Paper/Figure3/binned_noise_corrs-with-saccades-noblanks.eps')
            helper(6,7,false,.5,.1,'noise_corr','Noise corr','~/Google Drive/Pupil Paper/Figure3/binned_noise_corrs-sans-saccades-noblanks.eps')
            
            helper(8,9,false,.7,.3,'sig_corr','Signal corr','~/Google Drive/Pupil Paper/Figure3/binned_sig_corrs-with-saccades-noblanks.eps')
            helper(6,7,false,.7,.3,'sig_corr','Signal corr','~/Google Drive/Pupil Paper/Figure3/binned_sig_corrs-sans-saccades-noblanks.eps')
            
            
            function helper(epoch1,epoch2,includeBlanks,uplim,tickStep,attr,titl,filename)
                
                r = pupil.BinnedNoiseCorr & struct('include_blanks',includeBlanks) & sprintf('%s is not null',attr) & 'animal_id in (2380,2381,2382,2660,2662,2470)';
                c1 = [];  c2 = [];
                for key = fetch(reso.Sync & (r & struct('epoch_opt',epoch1)) & (r & struct('epoch_opt',epoch2)))'
                    tunedIdx = find(fetchn(pupil.EpochVonMises & key & 'epoch_opt=1','(von_amp1>0.1 && von_p<0.01)->p','ORDER BY trace_id'));
                    disp(key)
                    [c,epoch] = fetchn(pupil.BinnedNoiseCorr & key & struct('include_blanks',includeBlanks) & struct('epoch_opt',{epoch1,epoch2}),...
                        attr,'epoch_opt','ORDER BY epoch_opt');
                    assert(length(epoch)==2 && all(epoch==[epoch1 epoch2]'))
                    c = cellfun(@(c) c(tunedIdx,tunedIdx), c, 'uni', false);
                    p = size(c{1});
                    [i,j] = meshgrid(1:p,1:p);
                    cc = corrcov(c{1}); c1(end+1) = mean(cc(i<j)); %#ok<AGROW>
                    cc = corrcov(c{2}); c2(end+1) = mean(cc(i<j)); %#ok<AGROW>
                end
                
                fig = Figure(1,'size',[45 45]);
                scatter(c2,c1,4,'k','filled')
                set(gca,'XTick', 0:tickStep:1, 'YTick', 0:tickStep:1)
                ylabel 'Quiet dilating'
                xlabel 'Quiet constricting'
                title(titl)
                axis image
                axis([0 uplim 0 uplim])
                set(refline(1,0),'Color',[1 1 1]*.5)
                fig.cleanup
                fig.save(filename)
            end
        end
        
        function traceFigure
            fig = Figure(1,'size',[120 60]);
            key = struct('animal_id',2660,'scan_idx',3);
            caTimes = fetch1(reso.Sync & key, 'frame_times');
            dt = median(diff(caTimes));
            [X,keys] = fetchn(reso.Trace & key & 'trace_id in (27,38,51,66,80,85)', 'ca_trace');
            X = double([X{:}]);
            X = bsxfun(@rdivide, X, mean(X))-1;
            
            %            highPass = 0.1;
            %            k = hamming(ceil(1/dt/highPass)*2/1);
            %            k = k/sum(k);
            %            X = X - ne7.dsp.convmirr(X,k);
            
            lambda = 0.3;
            Y = arrayfun(@(i) fast_oopsi(double(X(:,i))',struct('dt',dt),struct('lam',lambda)), 1:size(X,2), 'uni', false);
            Y = [Y{:}];
            Y(max(Y, max(circshift(Y,[1 0]),circshift(Y,[-1 0])))<1e-3)=nan;
            
            X = bsxfun(@plus, X, 1:size(X,2));
            Y = bsxfun(@plus, Y*3, 1:size(Y,2))-0.40;
            
            plot(caTimes-caTimes(1), X, 'k')
            hold on
            plot(caTimes-caTimes(1), Y, 'Color', [.5 .5 .5])
            
            % add stimulus
            [onsets,offsets,directions] = fetchn(reso.Trial*psy.Trial*psy.Grating & key, ...
                'onset', 'offset', 'direction');
            cmap = hsv(180);
            onsets = onsets - caTimes(1);
            offsets = offsets - caTimes(1);
            for i=1:length(onsets)
                h = rectangle('Position',[onsets(i) -0.5 offsets(i)-onsets(i) 0.25]);
                c = cmap(mod(floor(directions(i)),180)+1,:);
                set(h,'FaceColor', c, 'EdgeColor', c)
            end
            
            % add pupilRadius trace
            [pupilRadius, pupilTimes] = fetchn(patch.EyeFrame*reso.Sync & key, ...
                'pupil_r','frame_time','ORDER BY frame_time');
            vTimes = fetch1(patch.Sync*reso.Sync & key, 'vis_time');
            eTimes = fetch1(patch.Ephys*reso.Sync & key, 'ephys_time');
            pupilTimes = interp1(eTimes,vTimes,pupilTimes);
            plot(pupilTimes-caTimes(1), pupilRadius/20+5, 'Color', [1 0.5 0.4], 'LineWidth',1)
            
            hold off
            xlim([0 60]+90)
            ylim([-1 12])
            axis off
            set(gca,'Position',[0.01 0.01 0.98 0.98])
            
            fig.cleanup
            fig.save('~/Desktop/traces3.eps')
        end
        
        
        
        function OSI
            k = 'animal_id in (2380,2381,2382,2660,2662,2470)';
            atLeastOneMinuteRunning = pro(patch.Recording,patch.Running,'sum(run_dur)->tot') & 'tot > 60';

            helper(k,[3 2],'osi-running-with-saccades',...
                {'Not running','Running'}, atLeastOneMinuteRunning)            
            helper(k,[7 6],'osi-dilating-sans-saccades',...
                {'Quiet constricting','Quiet dilating'})
            
            function helper(k,epochs,filename,labels,restrictor)
                % join the tuned cells from 'all' with the cells in
                % conditions defined by epochs.
                rel = pupil.EpochVonMises;
                g0 = rel & k & 'epoch_opt=1' & 'von_p<0.01' & 'von_amp1>0.1';
                if nargin>=5
                    g0 = g0 & restrictor;
                end
                g0 = g0.pro('responses->r0','epoch_opt->e0','(von_pref*180/3.1416)->pref');
                g = arrayfun(@(i,epoch) ...
                    pro(rel & struct('epoch_opt',epoch), sprintf('responses->r%d',i),sprintf('epoch_opt->e%d',i)), ...
                    1:length(epochs), epochs, 'uni', false);
                rel = g0;
                for i=1:length(g)
                    rel = rel*g{i};
                end
                
                % fetch tuning curves for each condition
                fprintf('%d cells\n',rel.count)
                pref = rel.fetchn('pref');
                r = arrayfun(@(i) rel.fetchn(sprintf('r%d',i)), 1:length(epochs), 'uni',false);
                angles = cellfun(@(r,pref) mod((0:360/size(r,2):359) - pref+180,360), r{1}, num2cell(pref), 'uni', false);
                
                [prefR, orthoR] = cellfun(@(r) makeBars(angles,r), r, 'uni', false);
                osis = cellfun(@(pref,ortho) (pref-ortho)./(pref+ortho)*2, ...
                    prefR, orthoR, 'uni',false);
                
                fig = Figure(1,'size',[45 45]);
                scatter(osis{1},osis{2},1,'filled','k')
                set(gca,'XTick', -1:0.5:1.5, 'YTick', -1:0.5:1.5)
                xlabel(labels{1})
                ylabel(labels{2})
                title 'OSI'
                axis image
                mm = 1.03*min(min(osis{1},osis{2}));
                axis([mm 1.6 mm 1.6])
                set(refline(1,0),'Color',[1 1 1]*.6)
                fig.cleanup
                fig.save(sprintf('~/Google Drive/Pupil Paper/Figure3/%s.eps',filename))
                
                function [prefR, orthoR] = makeBars(angles, responses)
                    % avearge responses
                    responses = cellfun(@(r) nanmedian(squeeze(r),2), responses, 'uni', false);
                    prefR = cellfun(@(angles,r) mean(r(abs(angles-180)<22.5,:)), angles, responses);
                    orthoR = cellfun(@(angles,r) mean(r(abs(abs(angles-180)-90)<22.5,:)), angles, responses);
                end
            end
            
        end
        
        
        function averageTuningCurve
            k = 'animal_id in (2380,2381,2382,2660,2662,2470)';
            atLeastOneMinuteRunning = pro(patch.Recording,patch.Running,'sum(run_dur)->tot') & 'tot > 60';  
            helper(k,[7 6],'br','ori-dilation-sans-saccades')
            helper(k,[3 2],'kg','ori-running-with-saccades',atLeastOneMinuteRunning)
            %            helper(k,[5 4],'kg','ori-running-sans-saccades')
            
            function helper(k,epochs,colors,filename, restrictor)
                assert(length(epochs)==length(colors))
                % join the tuned cells from 'all' with the cells in
                % conditions defined by epochs.
                rel = pupil.EpochVonMises;
                g0 = rel & k & 'epoch_opt=1' & 'von_p<0.01' & 'von_amp1>0.1';
                if nargin>=5
                    g0 = g0 & restrictor;
                end
                g0 = g0.pro('responses->r0','epoch_opt->e0','(von_pref*180/3.1416)->pref');
                g = arrayfun(@(i,epoch) ...
                    pro(rel & struct('epoch_opt',epoch), sprintf('responses->r%d',i),sprintf('epoch_opt->e%d',i)), ...
                    1:length(epochs), epochs, 'uni', false);
                rel = g0;
                for i=1:length(g)
                    rel = rel*g{i};
                end
                
                % fetch tuning curves for each condition
                fprintf('%d cells\n',rel.count)
                pref = rel.fetchn('pref');
                r = arrayfun(@(i) rel.fetchn(sprintf('r%d',i)), 1:length(epochs), 'uni',false);
                angles = cellfun(@(r,pref) mod((0:360/size(r,2):359) - pref+180,360), r{1}, num2cell(pref), 'uni', false);
                
                % make tuning curve figure
                fig = Figure(1,'size',[45 40]);
                for i=1:length(epochs)
                    makePlot(angles, r{i}, colors(i))
                    hold on
                end
                hold off
                fig.cleanup
                fig.save(sprintf('~/Google Drive/Pupil Paper/Figure3/%s.eps',filename))
                
                % make legend
                fig = Figure(1,'size',[20 20]);
                for i=1:length(epochs)
                    boundedline([-1 1], i*[1 1], 0.2, colors(i), 'transparency', 0.3)
                    hold on
                end
                hold off
                fig.cleanup
                fig.save(sprintf('~/Google Drive/Pupil Paper/Figure3/%s-legend.eps',filename))
                
                
                
      
                
                function makePlot(angles, responses, color)
                    % avearge responses
                    responses = cellfun(@(r) nanmedian(squeeze(r),2), responses, 'uni', false);
                    % normalize by mean signal
                    responses = cellfun(@(r) r, responses, 'uni', false);
                    
                    % covert to arrays
                    angles = reshape([angles{:}],1,[]);
                    responses = reshape([responses{:}],1,[]);
                    
                    % accumulate averages
                    step = 2 ; % bin size in degrees
                    xx = step/2:step:360;   % bins
                    binIdx = ceil(angles'/step+eps);
                    support = accumarray(binIdx,1,size(xx'))';
                    accum   = accumarray(binIdx,responses,size(xx'))';
                    accum2  = accumarray(binIdx,responses.^2,size(xx'))';
                    
                    % smoothen average response
                    sigma = 30;  % degrees
                    kk = hamming(ceil(sigma/step)*2+1)';
                    support = circshift(cconv(support,kk,length(support)),[0 -(length(kk)-1)/2]);
                    accum = circshift(cconv(accum,kk,length(accum)), [0 -(length(kk)-1)/2]);
                    accum2= circshift(cconv(accum2,kk,length(accum2)), [0 -(length(kk)-1)/2]);
                    meanResponses = accum./support;
                    stdErrors = sqrt(accum2./support-meanResponses.^2)/sqrt(support);
                    
                    % plot mean
                    boundedline(xx-180, meanResponses, stdErrors, color, 'transparency', 0.3)
                    hold off
                    
                    % make plot nice
                    set(gca,'XTick',-180:180:180)
                    xlim([-1 1]*180)
                    ylim([.15 .42])
                    xlabel 'Degrees from preferred direction    '
                    ylabel 'Activity (a.u.)'
                end
                
                
            end
        end
        
        
        
        function trialCorr
            helper(8,9,'noise_cov','noise corr','/Users/dimitri/Google Drive/Pupil Paper/Figure3/trial_noise_corrs-with-saccades.eps')
            helper(6,7,'noise_cov','noise corr','/Users/dimitri/Google Drive/Pupil Paper/Figure3/trial_noise_corrs-sans-saccades.eps')
            
            helper(8,9,'sig_cov','signal corr','/Users/dimitri/Google Drive/Pupil Paper/Figure3/trial_sig_corrs-with-saccades.eps')
            helper(6,7,'sig_cov','signal corr','/Users/dimitri/Google Drive/Pupil Paper/Figure3/trial_sig_corrs-sans-saccades.eps')
            
            function helper(epoch1,epoch2,attr,titl,filename)
                
                r = pupil.EpochR2 & sprintf('%s is not null',attr) & 'animal_id in (2380,2381,2382,2660,2662,2470)';
                c1 = [];  c2 = [];
                for key = fetch(reso.Sync & (r & struct('epoch_opt',epoch1)) & (r & struct('epoch_opt',epoch2)))'
                    tunedIdx = find(fetchn(pupil.EpochVonMises & key & 'epoch_opt=1','(von_amp1>0.1 && von_p<0.01)->p','ORDER BY trace_id'));
                    disp(key)
                    [c,epoch] = fetchn(pupil.EpochR2 & key & struct('epoch_opt',{epoch1,epoch2}),...
                        attr,'epoch_opt','ORDER BY epoch_opt');
                    assert(length(epoch)==2 && all(epoch==[epoch1 epoch2]'))
                    c = cellfun(@(c) c(tunedIdx,tunedIdx), c, 'uni', false);
                    p = size(c{1});
                    [i,j] = meshgrid(1:p,1:p);
                    cc = corrcov(c{1}); c1(end+1) = mean(cc(i<j)); %#ok<AGROW>
                    cc = corrcov(c{2}); c2(end+1) = mean(cc(i<j)); %#ok<AGROW>
                end
                
                fig = Figure(1,'size',[45 45]);
                scatter(c2,c1,1,'k','filled')
                set(gca,'XTick', 0:0.5:1, 'YTick', 0:0.5:1)
                ylabel 'Quiet dilating'
                xlabel 'Quiet constricting'
                title(titl)
                axis image
                axis([.0 .6 .0 .6])
                set(refline(1,0),'Color',[1 1 1]*.5)
                fig.cleanup
                fig.save(filename)
            end
        end
        
        
        
        function trialR2
            helper(8,9,'/Users/dimitri/Google Drive/Pupil Paper/Figure3/trial-r2-with-saccades.eps')
            helper(6,7,'/Users/dimitri/Google Drive/Pupil Paper/Figure3/trial-r2-sans-saccades.eps')
            
            function helper(epoch1,epoch2,filename)
                r = pupil.EpochR2 & 'sig_cov is not null' & 'animal_id in (2380,2381,2382,2660,2662,2470)';
                ars1 = [];
                ars2 = [];
                for key = fetch(reso.Sync & (r & struct('epoch_opt',epoch1)) & (r & struct('epoch_opt',epoch2)))'
                    tunedIdx = find(fetchn(pupil.EpochVonMises & key & 'epoch_opt=1','(von_amp1>0.1 && von_p<0.01)->p','ORDER BY trace_id'));
                    disp(key)
                    [c,s,epoch] = fetchn(pupil.EpochR2 & key & struct('epoch_opt',{epoch1,epoch2}),...
                        'noise_cov','sig_cov','epoch_opt','ORDER BY epoch_opt');
                    c = cellfun(@(c) c(tunedIdx,tunedIdx), c, 'uni', false);
                    s = cellfun(@(c) c(tunedIdx,tunedIdx), s, 'uni', false);
                    assert(length(epoch)==2 && all(epoch==[epoch1 epoch2]'))
                    
                    rs1 = 1-diag(c{1})./(diag(s{1})+diag(c{1}));
                    rs2 = 1-diag(c{2})./(diag(s{2})+diag(c{2}));
                    ars1 = [ars1; rs1]; %#ok<AGROW>
                    ars2 = [ars2; rs2]; %#ok<AGROW>
                end
                
                fig = Figure(1,'size',[45 45]);
                scatter(ars2,ars1,1,'k','filled')
                set(gca,'XTick', 0:0.5:1, 'YTick', 0:0.5:1)
                ylabel 'Quiet dilating'
                xlabel 'Queit constricting'
                title 'Reliability'
                
                axis image
                axis([.0 .9 .0 .9])
                set(refline(1,0),'Color',[1 1 1]*.5)
                fig.cleanup
                fig.save(filename)
                
                fprintf('Median R^2 increase %2.1f%%, p=%1.1e\n', (median(ars1./ars2)-1)*100, signrank(ars1./ars2-1))
            end
        end
        
        
        %             % compare noise corrs
        %             fig = Figure(1,'size',[45 45]);
        %             n = 0;
        %             ac1 = [];
        %             ac2 = [];
        %             for key = fetch(r)'
        %                 tunedIdx = find(fetchn(pupil.EpochVonMises & key & 'epoch_opt=1','(von_amp1>0.1 && von_p<0.01)->p','ORDER BY trace_id'));
        %                 disp(key)
        %                 [c,s,epoch] = fetchn(pupil.BinnedNoiseCorr & key & 'epoch_opt in (4,5)',...
        %                     'noise_cov','sig_cov','epoch_opt','ORDER BY epoch_opt');
        %                 n = n+length(tunedIdx);
        %                 c = cellfun(@(c) c(tunedIdx,tunedIdx), c, 'uni', false);
        %                 s = cellfun(@(c) c(tunedIdx,tunedIdx), s, 'uni', false);
        %                 assert(length(epoch)==2 && all(epoch==[4 5]'))
        %
        %                 c1 = corrcov(c{1});
        %                 c2 = corrcov(c{2});
        %                 p = size(c1);
        %                 [i,j] = meshgrid(1:p,1:p);
        %                 ac1(end+1) = mean(c1(i<j));
        %                 ac2(end+1) = mean(c2(i<j));
        %             end
        %             fprintf('Cells used for r-squared %d\n', n)
        %             scatter(ac2,ac1,8,'k','filled')
        %             set(gca,'XTick',0:.2:.4, 'YTick', 0:.2:.4)
        %             xlabel constricting
        %             ylabel dilating
        %             title 'mean noise corr'
        %             axis image
        %             axis([.0 .4 .0 .4])
        %             set(refline(1,0),'Color',[1 1 1]*.5)
        %             fig.cleanup
        %             fig.save('~/Desktop/noise-corr.eps')
        %
        %         end
        
        
        
        function subplotOriMap(key)
            if count(pupil.Cos2Map & key)
                g = fetch1(reso.Align & key, 'green_img');
                [amp, r2, ori, p] = fetchn(pupil.Cos2Map & key, ...
                    'cos2_amp', 'cos2_r2', 'pref_ori', 'cos2_fp');
                
                % add a black line at the bottom of each figure
                p = cellfun(@(x) cat(1,x,nan(3,size(x,2))), p, 'uni',false);
                amp = cellfun(@(x) cat(1,x,nan(3,size(x,2))), amp, 'uni',false);
                ori = cellfun(@(x) cat(1,x,nan(3,size(x,2))), ori, 'uni',false);
                r2 = cellfun(@(x) cat(1,x,nan(3,size(x,2))), r2, 'uni',false);
                
                % make composite image
                p = cat(1,p{:});
                amp = cat(1,amp{:});
                r2 = cat(1,r2{:});
                ori = cat(1,ori{:});
                
                h = mod(ori,pi)/pi;   % orientation is represented as hue
                s = p<0.01;   % only significantly tuned pixels are shown in color
                v = ones(size(p));  % brightness is proportional to variance explained, scaled between 0 and 10 %
                img = hsv2rgb(cat(3, h, s, v));
                image(img)
                axis image
                axis off
            end
        end
        
        
    end
end



function overlap = doOverlap(on,dur)
% compute overlap length between intervals defined by onsets on and
% durations dur.
overlap = max(0, min(on+dur)-max(on));
end


function frac = fracOverlap(on, dur, onArray, durArray)
% compute fraction overlap between the interval defined by on and dur with
% intervals defined by onArray and durArray. Intervals in array may not overlap.
assert(isscalar(on) && isscalar(dur) && length(onArray)==length(durArray))
frac = sum(arrayfun(@(on2,dur2) doOverlap([on on2], [dur dur2]), onArray, durArray))/dur;
end



function [on,dur] = mergeIntervals(on, dur)
% some intervals defined by onsets on and durations dur may overlap.  Such
% overlapping intervals are merged.

assert(length(on)==length(dur))

[on,ix] = sort(on);
dur = dur(ix);

% merge overlapping intervals
for i=1:length(on-1)
    for j=i+1:length(on)
        if ~doOverlap(on([i j]),dur([i j]))
            break
        else
            dur(i) = max(dur(i), on(j)+dur(j)-on(i));
            dur(j) = 0;
        end
    end
end
on(~dur)=[];
dur(~dur)=[];
end