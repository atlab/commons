classdef plots
    
    methods(Static)
        
        function binnedR2
            helper(8,9,false,.78,'~/Google Drive/Pupil Paper/Figure3/binned_r2-with-saccades-noblanks.eps')
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
                set(refline(1,0),'Color',[1 1 1]*.5)
                fig.cleanup
                fig.save(filename)
            end
        end
        
        function binnedCorr
            helper(8,9,false,.7,.3,'sig_corr','Signal corr','~/Google Drive/Pupil Paper/Figure3/binned_sig_corrs-with-saccades-noblanks.eps')
            helper(8,9,false,.5,.2,'noise_corr','Noise corr','~/Google Drive/Pupil Paper/Figure3/binned_noise_corrs-with-saccades-noblanks.eps')
            helper(8,9,true, .2,.1,'noise_corr','Noise corr','~/Google Drive/Pupil Paper/Figure3/binned_noise_corrs-with-saccades.eps')
            helper(6,7,false,.5,.1,'noise_corr','Noise corr','~/Google Drive/Pupil Paper/Figure3/binned_noise_corrs-sans-saccades-noblanks.eps')
            helper(6,7,true, .2,.1,'noise_corr','Noise corr','~/Google Drive/Pupil Paper/Figure3/binned_noise_corrs-sans-saccades.eps')
            
            helper(8,9,true, .7,.3,'sig_corr','Signal corr','~/Google Drive/Pupil Paper/Figure3/binned_sig_corrs-with-saccades.eps')
            helper(6,7,false,.7,.3,'sig_corr','Signal corr','~/Google Drive/Pupil Paper/Figure3/binned_sig_corrs-sans-saccades-noblanks.eps')
            helper(6,7,true, .7,.3,'sig_corr','Signal corr','~/Google Drive/Pupil Paper/Figure3/binned_sig_corrs-sans-saccades.eps')
            
            
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
             helper(k,[7 6],'osi-dilating-sans-saccades',...
                 {'Quiet constricting','Quiet dilating'})
             helper(k,[9 8],'osi-dilating-with-saccades',...
                 {'Quiet constricting','Quiet dilating'})
             
            function helper(k,epochs,filename,labels)
                % join the tuned cells from 'all' with the cells in
                % conditions defined by epochs.
                rel = pupil.EpochVonMises;
                g0 = rel & k & 'epoch_opt=5' & 'von_p<0.01' & 'von_amp1>0.1';
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
                 set(gca,'XTick', 0:0.5:1.5, 'YTick', 0:0.5:1.5)
                 xlabel(labels{1})
                 ylabel(labels{2})
                 title 'OSI'
                 axis image
                 mm = 1.03*min(min(osis{1},osis{2}));
                 axis([mm 1.6 mm 1.6])
                 set(refline(1,0),'Color',[1 1 1]*.5)
                 fig.cleanup
                 fig.save(sprintf('~/Google Drive/Pupil Paper/Figure3/%s.eps',filename))
                
%                 fig = Figure(1,'size',[50 40]);
%                 avgOSI = cellfun(@median, osis);
%                 bar(avgOSI)
%                 hold on
%                 [ci1,ci2] = cellfun(@(x) confInterval(x,0.95), osis);
%                 errorbar(1:4,avgOSI,ci1-avgOSI,ci2-avgOSI, 'k', 'LineStyle', 'none')
%                 hold off
%                 colormap(gray/2+.5)
%                 set(gca,'XTickLabel',labels)
%                 rotateticklabel(gca,-30);
%                 set(gca,'Position', [.25 .28 .70 .7], 'YTick', 0:.2:.6)
%                 ylabel 'OSI'
%                 ylim([0 .45])
                
                fig.cleanup
                fig.save(sprintf('~/Google Drive/Pupil Paper/Figure3/%s.eps',filename))
                
                
                function [ci1,ci2] = confInterval(x,thresh)
                    m = arrayfun(@(i) median(x(randi(length(x),size(x)))), 1:10000);
                    ci1 = quantile(m,(1-thresh)/2);
                    ci2 = quantile(m,1-(1-thresh)/2);
                end

                
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
            
            helper(k,[7 6 2 5],'brgk','ori-all-sans-saccades')
            helper(k,[9 8 2 3],'brgk','ori-all-with-saccades')
            helper(k,[7 6],'br','ori-dilation-sans-saccades')
            helper(k,[9 8],'br','ori-dilation-with-saccades')
            helper(k,[3 2],'kg','ori-running-with-saccades')
            helper(k,[7 6],'kg','ori-running-sans-saccades')
            
            function helper(k,epochs,colors,filename)
                assert(length(epochs)==length(colors))
                % join the tuned cells from 'all' with the cells in
                % conditions defined by epochs.
                rel = pupil.EpochVonMises;
                g0 = rel & k & 'epoch_opt=1' & 'von_p<0.01' & 'von_amp1>0.1';
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
                


                %                 scatter(osi2,osi1,3,'filled','k')
                %                 xlabel constriction
                %                 ylabel dilation
                %                 axis equal
                %                 xlim([0 1.65])
                %                 ylim([0 1.65])
                %                 set(gca,'XTick',0:.5:1.5,'YTick',0:.5:1.5);
                %                 set(refline(1),'Color',[.5 .5 .5])
                %                 title OSI
                %                 fig.cleanup
                %                 fig.save('~/Google Drive/Pupil Paper/Figure3/pupilOSI.eps')
                %                 p = signrank(osi2,osi1);
                %                 fprintf('OSI increase due to dilation: %2.1f, p-value: %e\n', ...
                %                     (median(osi1)/median(osi2)-1)*100,p)
                
                %             fig = Figure(1,'size',[50 40]);
                %             hist((osi3-osi4)-(osi1-osi2),40)
                %             xlabel 'difference in effects (running-dilation)'
                %             fig.cleanup
                %             fig.save('~/Google Drive/Pupil Paper/Figure3/OSI-effects.eps')
                %
                %             fig = Figure(1,'size',[50 40]);
                %             scatter(osi4,osi3,3,'filled','k')
                %             xlabel quiet
                %             ylabel active
                %             axis equal
                %             xlim([0 1.65])
                %             ylim([0 1.65])
                %             set(gca,'XTick',0:.5:1.5,'YTick',0:.5:1.5);
                %             set(refline(1),'Color',[.5 .5 .5])
                %             title OSI
                %             fig.cleanup
                %             fig.save('~/Google Drive/Pupil Paper/Figure3/runningOSI.eps')
                %             p = signrank(osi4,osi3);
                %             fprintf('OSI increase due to running: %2.1f, p-value: %e\n', ...
                %                 (median(osi3)/median(osi4)-1)*100, p)
                %
                %
                %
                %             fig = Figure(1,'size',[50 40]);
                %             osis = {osi1 osi2 osi3 osi4};
                %             avgOSI = cellfun(@median, osis);
                %             bar(avgOSI)
                %             hold on
                %             [ci1,ci2] = cellfun(@(x) confInterval(x,0.95), osis);
                %             errorbar(1:4,avgOSI,ci1-avgOSI,ci2-avgOSI, 'k', 'LineStyle', 'none')
                %             hold off
                %             colormap(gray/2+.5)
                %             set(gca,'XTickLabel',{'  dilation','  constriction','  active','  quiet'})
                %             rotateticklabel(gca,-30);
                %             set(gca,'Position', [.25 .28 .70 .7], 'YTick', 0:.2:.6)
                %             ylabel 'OSI'
                %             ylim([0 .75])
                %
                %             fig.cleanup
                %             fig.save('~/Google Drive/Pupil Paper/Figure3/meanOSI.eps')
                %
                
%                 function [ci1,ci2] = confInterval(x,thresh)
%                     m = arrayfun(@(i) median(x(randi(length(x),size(x)))), 1:10000);
%                     ci1 = quantile(m,(1-thresh)/2);
%                     ci2 = quantile(m,1-(1-thresh)/2);
%                 end
                
                
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
                    ylabel 'Calcium signal'
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


function th=rotateticklabel(h,rot,demo)
%ROTATETICKLABEL rotates tick labels
%   TH=ROTATETICKLABEL(H,ROT) is the calling form where H is a handle to
%   the axis that contains the XTickLabels that are to be rotated. ROT is
%   an optional parameter that specifies the angle of rotation. The default
%   angle is 90. TH is a handle to the text objects created. For long
%   strings such as those produced by datetick, you may have to adjust the
%   position of the axes so the labels don't get cut off.
%
%   Of course, GCA can be substituted for H if desired.
%
%   TH=ROTATETICKLABEL([],[],'demo') shows a demo figure.
%
%   Known deficiencies: if tick labels are raised to a power, the power
%   will be lost after rotation.
%
%   See also datetick.

%   Written Oct 14, 2005 by Andy Bliss
%   Copyright 2005 by Andy Bliss

%DEMO:
if nargin==3
    x=[now-.7 now-.3 now];
    y=[20 35 15];
    figure
    plot(x,y,'.-')
    datetick('x',0,'keepticks')
    h=gca;
    set(h,'position',[0.13 0.35 0.775 0.55])
    rot=90;
end

%set the default rotation if user doesn't specify
if nargin==1
    rot=90;
end
%make sure the rotation is in the range 0:360 (brute force method)
while rot>360
    rot=rot-360;
end
while rot<0
    rot=rot+360;
end
%get current tick labels
a=get(h,'XTickLabel');
%erase current tick labels from figure
set(h,'XTickLabel',[]);
%get tick label positions
b=get(h,'XTick');
c=get(h,'YTick');
%make new tick labels
if rot<180
    th=text(b,repmat(c(1)-.1*(c(2)-c(1)),length(b),1),a,'HorizontalAlignment','right','rotation',rot);
else
    th=text(b,repmat(c(1)-.1*(c(2)-c(1)),length(b),1),a,'HorizontalAlignment','left','rotation',rot);
end
end