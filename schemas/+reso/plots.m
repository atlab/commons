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
            traceKeys = fetch(reso.Trace & (reso.TraceVonMises & 'shuffle_p<0.001') & reso.BrainState & varargin);
            prior = 0.5;  % time before the stimulus at which to measure the brain state
            for key = traceKeys'
                [eTime,brainState] = fetch1(reso.BrainState*reso.Sync*patch.Sync & key,'vis_time','brain_state_trace');
                s = fetch(reso.PeriStimTrace & key, '*');
                if ~isempty(s)
                    bs = nan(length(s),1);
                    for i = 1:length(s)
                        [~,ix] = min(abs(eTime - (s(i).stim_onset - prior)));
                        bs(i) = brainState(ix);
                    end
                    [bs,ix] = sort(bs);
                    s = s(ix);
                end
                x = ((1:length(s(1).trial_trace))-s(1).onset_idx)*s(1).peristim_dt;
                imagesc(x,bs,cat(1,s.trial_trace),[0 0.2])
                colormap(1-gray)
                xlabel 'time since stimulus onset'
                ylabel 'sorted by brain state'
                set(gcf, 'PaperSize', [4 3], 'PaperPosition', [0 0 4 3])
                f = sprintf('~/dev/figures/reso/brain_states/Mouse%d_%03u_%u_%03u.png',key.animal_id,key.scan_idx,key.slice_num,key.trace_id);
                print('-dpng','-r150',f)
            end
        end
        
    end
    
    
end