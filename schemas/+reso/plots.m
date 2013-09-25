classdef plots  < handle
    
    properties(Abstract)
        neverInstantiateThisClass
    end
    
    methods(Static)
        function OriMap(varargin)
            for caKey = fetch(reso.CaOpt & (reso.Cos2Map & varargin))'
                for siteKey = fetch(reso.Align & (reso.Cos2Map & varargin))'
                    key = dj.struct.join(caKey, siteKey);
                    g = fetch1(reso.Align & key, 'green_img');
                    [amp, r2, ori, p] = fetchn(reso.Cos2Map & key, ...
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
                    
                    f = sprintf('~/dev/figures/reso/cos2map_%05d_%03d_%02d', ...
                        key.animal_id, key.scan_idx, key.ca_opt);
                    set(gcf, 'PaperSize', [8 8], 'PaperPosition', [0 0 8 8])
                    print('-dpng', f, '-r150')
                end
            end
        end
        
        
        
        function BrainStateTuning(varargin)
            traceKeys = fetch(reso.Trace * reso.TraceVonMises & (reso.TraceVonMises & 'shuffle_p<0.001') & reso.BrainState & varargin,'von_r2');
            prior = 0.4;  % time before the stimulus at which to measure the brain state
            win = 2500; % number of indices to average around prior (+/-)
            B=[];r2=[];peakDiff=[];k=1;
            
            for key = traceKeys'
                [eTime,brainState,vm] = fetch1(reso.BrainState*reso.Sync*patch.Sync*patch.CleanEphys & key,'vis_time','brain_state_trace','vm');
                s = fetch(reso.PeriStimTrace & key, '*');
                if ~isempty(s)
                    bs = nan(length(s),1);
                    for i = 1:length(s)
                        [~,ix] = min(abs(eTime - (s(i).stim_onset - prior)));
                        bs(i) = mean(brainState(ix-win:ix+win));
                        %vMat(i,:) = vm(ix-10000:ix+10000);
                    end
                    [bs,ix] = sort(bs);
                    s = s(ix);
                    %vMat=vMat(ix,:);
                end
                x = ((1:length(s(1).trial_trace))-s(1).onset_idx)*s(1).peristim_dt;
                sMat = cat(1,s.trial_trace);
                N=length(bs);
                
                figure(1)
                subplot(121)
                imagesc(x,1:N,sMat,[0 0.2]);
                set(gca,'ydir','normal')
                colormap(1-gray)
                xlabel 'time since stimulus onset'
                ylabel 'trials sorted by brain state'
                
                subplot(143)
                plot(bs,1:N);
                xlabel 'brain state'
                
                subplot(144)
                trialLen = .5; %seconds
                resp = mean(sMat(:,s(1).onset_idx + [1:round(trialLen/s(1).peristim_dt)]),2);
                resp = resp/mean(resp)-1;
                plot(resp,1:N,'*')
                [b,~,~,~,stats]=regress(resp, [ones(N,1) [1:N]']);
                line(b(1)+[1 N]*b(2),[1 N],'color','r')
                fillAxes
                xlabel 'vis response'
                
                set(gcf, 'PaperSize', [4 3], 'PaperPosition', [0 0 4 3])
                %f = sprintf('/mnt/lab/users/dimitri/dev/figures/reso/brain_states_new/Mouse%d_%03u_%u_%03u.png',key.animal_id,key.scan_idx,key.slice_num,key.trace_id);
                %print('-dpng','-r150',f)
                B(k,:)=[b(2) stats(1) stats(3)];
                r2(k)=key.von_r2;
                k=k+1;
                figure(3)
                subplot(131); hist(B(B(:,3)>=.05,1),20)
                subplot(132); hist(B(B(:,3)<.05,1),20)
                subplot(133); scatter(B(:,1),r2,'b.'); hold on; scatter(B(B(:,3)<.05,1),r2(B(:,3)<.05),'r*')
            end
            keyboard
        end
        
    end
    
    
end