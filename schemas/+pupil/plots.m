classdef plots
    
    methods(Static)
        
        function durations(varargin)
            for key = fetch(reso.Sync & (pupil.Classify & varargin))'
                caTimes = fetch1(reso.Sync & key, 'frame_times');
                mem1 = fetch1(pupil.Classify & key & 'phase_id = 1', 'membership');
                mem2 = fetch1(pupil.Classify & key & 'phase_id = 2', 'membership');
                
                plot(caTimes-caTimes(1), mem1, 'go')
                hold on
                plot(caTimes-caTimes(1), mem2, 'r*')
                hold off
            end
        end
        
        
        function pooledNoiseCorrs
            clf
            k = 'animal_id in (2380,2381,2382)';
            k = 'animal_id in (2660)';
            r = pupil.BinnedNoiseCorr;
            r = r.pro('noise_cov->n1','sig_cov->s1','phase_id->p1')* ...
                r.pro('noise_cov->n2','sig_cov->s2','phase_id->p2') & k & 'p1=1' & 'p2=2';
            [n1,n2,s1,s2,keys] = r.fetchn('n1','n2','s1','s2');
            
            tunedIdx = arrayfun(@(key) logical(...
                fetchn(pupil.VonMises & key & 'phase_id=1', 'von_amp1>0.1 && von_p<0.05 -> is_tuned', 'ORDER BY trace_id')), ...
                keys, 'uni',false);
            numTuned = cellfun(@sum, tunedIdx);
            
            sel = numTuned>10;           
            n1 = n1(sel);
            n2 = n2(sel);
            s1 = s1(sel);
            s2 = s2(sel);
            keys = keys(sel);
            tunedIdx = tunedIdx(sel);
            
            
            c1 = cellfun(@avgCorr, n1, tunedIdx);
            c2 = cellfun(@avgCorr, n2, tunedIdx);
            scatter(c2,c1,'filled')
            box on
            axis equal
            xlim([.05 0.45])
            ylim([.05 0.45])
            grid on
            xlim([.0 0.12])
            ylim([.0 0.12])
            set(refline(1,0),'Color','k')
            set(gca,'XTick', 0:.05:.1, 'YTick', 0:.05:.1)
            set(gcf,'PaperSize',[2.5 2.5],'PaperPosition',[0 0 2.5 2.5])
            ylabel dilation
            xlabel constriction
            title 'average noise correlation'
            print -dpdf ~/noiseCorrs
            
            x = -.03:.01:.03;
            hist(c1-c2,x)
            set(gca,'XTick',(-1:1)*.02,'YTick',0:4)
            grid on
            ylabel '# sites'
            xlabel '\Delta avg noise corr'
            box off
            hold on
            plot([0 0],ylim,'r','LineWidth',3)
            hold off
            colormap(gray/2+.5)
            set(gcf,'PaperSize',[2.5 1.5],'PaperPosition',[0 0 2.5 1.5])
            print -dpdf ~/noiseCorrDiffs
            
            cs1 = cellfun(@avgCorr, s1, tunedIdx);
            cs2 = cellfun(@avgCorr, s2, tunedIdx);
            
            scatter(cs2,cs1,'filled')
            box on
            axis equal
            xlim([0 .4])
            ylim([0 .4])
            set(refline(1),'Color','k')
            grid on
            xlim([0 .4])
            ylim([0 .4])
            set(gca,'XTick', 0:.2:.4, 'YTick', 0:.2:.4)
            set(gcf,'PaperSize',[2.5 2.5],'PaperPosition',[0 0 2.5 2.5])
            ylabel dilation
            xlabel constriction
            title 'average signal corrs'
            print -dpdf ~/sigCorrs.pdf
            
            
            x = -.1:.01:.1;
            hist(cs1-cs2,x)
            set(gca,'XTick',(-1:1)*.1,'YTick',0:4)
            xlim([-1 1]*0.11)
            grid on
            ylabel '# sites'
            xlabel '\Delta avg signal corr'
            box off
            hold on
            plot([0 0],ylim,'r','LineWidth',3)
            hold off
            colormap(gray/2+0.5)
            set(gcf,'PaperSize',[2.5 1.5],'PaperPosition',[0 0 2.5 1.5])
            print -dpdf ~/sigCorrDiffs
            
            rr1 = cellfun(@avgR2,s1,n1,tunedIdx);
            rr2 = cellfun(@avgR2,s2,n2,tunedIdx);
            scatter(rr2,rr1,'filled')
            xlim([.0 0.25])
            ylim([.0 0.25])
            axis equal
            xlim([.0 0.2])
            ylim([.0 0.2])
            set(refline(1),'Color','k')
            grid on
            set(gca,'XTick',0:0.05:1,'YTick',0:0.05:1)
            xlabel constriction
            ylabel dilation
            title R^2
            set(gcf,'PaperSize',[2.5 2.5],'PaperPosition',[0 0 2.5 2.5])
            box on
            print -dpdf ~/r-squared
            
            disp done


            
            function c = avgCorr(n,id)
                n = corrcov(n(id,id));
                p = size(n,1);
                [i,j] = meshgrid(1:p,1:p);
                c = mean(n(i<j));                
            end
            
            function r2 = avgR2(s,n,id)
                r2 = mean(diag(s(id,id))./(diag(s(id,id))+diag(n(id,id))));
            end
        end
        
        function averageTuningCurve
            k = 'animal_id in (2380,2381,2382)';
            k = 'animal_id in (2660)';
            r = pupil.VonMises & k;
            g1 = r & 'phase_id=1' & 'von_p < 0.05' & 'von_amp1 > 0.1';
            g2 = r & 'phase_id=2';
            
            % the cells must be tuned under both conditions
            g1 = g1 & g2.pro('phase_id->p2');
            g2 = g2 & g1.pro('phase_id->p1');
            
            [r1, pref1] = g1.fetchn('responses','(von_pref*180/3.1416)->pref');
            [r2, pref2]= g2.fetchn('responses','(von_pref*180/3.1416)->pref');
            
            angles1 = getAngles(r1,pref1);
            angles2 = getAngles(r2,pref2);
            
            clf
            makePlot(angles1, r1, 'r')
            hold on
            makePlot(angles2, r2, 'k')
            set(gcf,'PaperSize',[3 2],'PaperPosition',[0 0 3 2])
            print -dpdf ~/tuningCurve3

            
            function makePlot(angles, responses, color)
                % avearge responses
                responses = cellfun(@(r) nanmean(squeeze(r),2), responses, 'uni', false);
                % normalize by mean signal
                responses = cellfun(@(r) r/mean(r), responses, 'uni', false);
                
                % covert to arrays
                angles = reshape([angles{:}],1,[]);
                responses = reshape([responses{:}],1,[]);
                
                % accumulate averages
                step = 1 ; % bin size in degrees
                xx = step/2:1:360;   % bins
                binIdx = ceil(angles'/step);
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
                boundedline(xx-180, meanResponses, stdErrors, color, 'transparency', 0.4)
                hold off
                
                % make plot nice
                set(gca,'YColor',[1 1 1]*.99)
                set(gca,'XTick',-180:180:180)
                xlim([-1 1]*180)
                ylim([.7 1.9])
            end
            
            
            
            function angles = getAngles(r,pref)
                angles = cellfun(@(r,pref) mod((0:360/size(r,2):359) - pref+180,360), r, num2cell(pref), 'uni', false);
            end
            
        end
        
        
        
        function OriMap(varargin)
            for key = fetch(pupil.Cos2Map & varargin)'
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
                
                title(sprintf('Mouse %d scan %d caOpt=%u', key.animal_id, key.scan_idx, key.ca_opt))
                
                f = sprintf('~/dev/figures/reso/pupil_cos2map_%05d_%03d_%02d-phase%02d', ...
                    key.animal_id, key.scan_idx, key.ca_opt, key.phase_id);
                set(gcf, 'PaperSize', [8 8], 'PaperPosition', [0 0 8 8])
                print('-dpng', f, '-r150')
            end
        end
        
        
        function modulation(varargin)
            for key = fetch(pupil.OriDesign & varargin)'
                [modulation,frameTimes] = fetch1(pupil.OriDesign*reso.Sync & key, 'modulation', 'frame_times');
                plot(frameTimes-frameTimes(1), modulation)
                [pupilTime, radius] = fetchn(patch.EyeFrame*reso.Sync & key, 'frame_time', 'pupil_r');
                [vtime, etime] = fetch1(reso.Sync*patch.Sync*patch.Ephys & key,'vis_time','ephys_time');
                pupilTime = interp1(etime,vtime,pupilTime,'linear');
                
                hold on
                plot(pupilTime-frameTimes(1), radius/150, 'r')
                hold off
                disp ahh
            end
        end
        
        
        function compareTuning
            r = reso.Sync & (pupil.VonMisesSet & 'phase_id=1') & (pupil.VonMisesSet & 'phase_id=2');
            for key = fetch(r)'
                cla
                n = fetchn(pupil.VonMisesSet & key, pupil.VonMises, 'count(*)->n');
                assert(length(n)==2 && all(n==n(1)))
                
                for key = fetch(pupil.VonMisesSet & key, 'ORDER BY phase_id')'
                    amp = fetchn(pupil.VonMises & key,'von_amp1','ORDER BY trace_id');
                    plot(cumsum(amp))
                    hold all
                end
                hold off
                legend dilating constricting
            end
        end
        
        
        function compareDiversity
            r = reso.Sync & (pupil.VonMisesSet & 'phase_id=1') & (pupil.VonMisesSet & 'phase_id=2');
            v = nan(0,2);
            for key = fetch(r)'
                cla
                n = fetchn(pupil.VonMisesSet & key, pupil.VonMises, 'count(*)->n');
                assert(length(n)==2 && all(n==n(1)))
                
                i = 0;
                for key = fetch(pupil.VonMisesSet & key, 'ORDER BY phase_id')'
                    i=i+1;
                    pref{i} = fetchn(pupil.VonMises & key & 'von_p<0.01','von_pref');
                    vv(i) = mean(exp(2i*pi*pref{i}));
                end
                v(end+1,:) = vv;
                bins = 15:30:360;
                c = cellfun(@(pref) hist(pref/pi*180,bins), pref, 'uni', false);
                bar(bins,cat(1,c{:})')
                set(gca,'XTick',bins)
                legend dilating constricting
            end
        end
        
        
        
        function compareCorrs
            r = reso.Sync & (pupil.BinnedNoiseCorr & 'phase_id=1') & (pupil.BinnedNoiseCorr & 'phase_id=2');
            for key = fetch(r)'
                tunedIdx = ...
                    fetchn(pupil.VonMises & key & 'phase_id=1','(von_amp1>0.1 && von_p<0.1)->p','ORDER BY trace_id') & ...
                    fetchn(pupil.VonMises & key & 'phase_id=2','(von_amp1>0.1 && von_p<0.1)->p','ORDER BY trace_id');
                if sum(tunedIdx)<10
                    continue
                end
                disp(key)
                clf
                fig = Figure(1,'size',[200 160]);
                
                [c,s,phase_id] = fetchn(pupil.BinnedNoiseCorr & key,'noise_cov','sig_cov','phase_id','ORDER BY phase_id');
                c = cellfun(@(c) c(tunedIdx,tunedIdx), c, 'uni', false);
                s = cellfun(@(c) c(tunedIdx,tunedIdx), s, 'uni', false);
                assert(length(phase_id)==2 && all(phase_id==[1 2]'))
                %                 subplot 121, imagesc(corrcov(c{1}),[-1 1]), axis image
                %                 subplot 122, imagesc(corrcov(c{2}),[-1 1]), axis image
                subplot 231
                p = size(c{1},1);
                [i,j] = meshgrid(1:p,1:p);
                c1 = corrcov(c{1});
                c2 = corrcov(c{2});
                scatter(c2(i(:)<j(:)),c2(i(:)<j(:)))
                xlabel dilating
                ylabel constricting
                title 'noise correlations'
                axis image
                axis([-.0 .4 -.0 .4])
                refline
                refline(1,0)
                grid on
                
                subplot 232
                bins = -0.1:0.01:0.1;
                ix = i(:)<j(:);
                hist(c1(ix)-c2(ix),bins)
                hold on
                plot([1 1]*median(c1(ix)-c2(ix)),ylim,'r')
                hold off
                xlim(bins([1 end]))
                grid on
                xlabel 'noise corr difference'
                
                subplot 234
                r1 = diag(s{1})./(diag(c{1})+diag(s{1}));
                r2 = diag(s{2})./(diag(c{2})+diag(s{2}));
                scatter(r1,r2)
                xlabel dilating
                ylabel constricting
                title 'R^2'
                axis image
                refline
                refline(1,0)
                grid on
                
                subplot 235
                p = size(c{1},1);
                [i,j] = meshgrid(1:p,1:p);
                
                c1 = corrcov(c{1});
                c2 = corrcov(c{2});
                s1 = corrcov(s{1});
                s2 = corrcov(s{2});
                ss = cat(1, s1(i(:)<j(:)), s2(i(:)<j(:)));
                cc = cat(1, c1(i(:)<j(:)), c2(i(:)<j(:)));
                colr = cat(1,ones(sum(i(:)<j(:)),1), zeros(sum(i(:)<j(:)),1));
                ix = randperm(length(colr));
                scatter(ss(ix),cc(ix),4,colr(ix));
                colormap(winter)
                h = colorbar;
                set(h,'YTick',[0 1],'YTickLabel',{'constricting','dilating'})
                
                xlabel 'signal corrs'
                ylabel 'noise corrs'
                axis image
                axis([-.3 1 -.3 1])
                refline
                refline(1,0)
                set(gca,'XTick',-.5:.5:1,'YTick',-.5:.5:1,'XTickLabel',-.5:.5:1,'YTickLabel',-.5:.5:1)
                grid on
                
                subplot 233
                pupil.plots.subplotOriMap(dj.struct.join(key,struct('phase_id',1,'ca_opt',11)))
                title dilating
                subplot 236
                pupil.plots.subplotOriMap(dj.struct.join(key,struct('phase_id',2,'ca_opt',11)))
                title constricting
                
                fig.cleanup
                set(gcf,'PaperSize',[12 10], 'PaperPosition', [0 0 12 10])
                f = sprintf('~/figures/pupil-%05d-%02d.pdf',key.animal_id, key.scan_idx);
                fig.save(f)
                
            end
            
        end
        
        
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
        
        
        function compareR2
            r = pupil.Cos2Map & 'ca_opt=11';
            r1 = r.pro('phase_id->p1','cos2_amp->r1');
            r2 = r.pro('phase_id->p2','cos2_amp->r2');
            
            [R1,R2] = fetchn(r1*r2 & 'p1=1 and p2=2','r1','r2');
            
            for i=1:length(R1)
                imagesc(R1{i}-R2{i},[-1 1]*0.10)
                colorbar
                axis image
                colormap(covest.doppler)
            end
        end
    end
end