classdef plots
    
    methods(Static)
        function compareTuning
            v0 = pro(bs.VonMises & 'tuning_cond=0' & 'von_p<0.01' & 'von_amp1>0.02','tuning_cond->c0');
            v1 = pro(v0*bs.VonMises & 'tuning_cond=1', 'tuning_cond->c1','von_r2->r1', 'von_amp1->a1', 'von_p->p1');
            v2 = pro(v0*bs.VonMises & 'tuning_cond=2', 'tuning_cond->c2','von_r2->r2', 'von_amp1->a2', 'von_p->p2');
            [a1,a2] = fetchn(v1*v2,'a1','a2');
            scatter(a1,a2)
            set(refline(1,0),'Color','r')
            axis square
            grid on
            xlabel 'tuned response with bs<0.002'
            ylabel 'tuned response with bs>0.002' 
            mean(a1>a2)            
        end
        
        
        function BsRaster(varargin)
            for key = fetch(reso.BrainState & varargin)'
                times = fetch1(reso.Sync*patch.Sync & key, 'vis_time');
                interval = [-2.0  2.5]; % seconds before trial
                keys = fetch(reso.Trial & key);
                bsTrace = fetch1(reso.BrainState & key, 'brain_state_trace');
                cleanVm = fetch1(patch.CleanEphys*reso.Sync & key, 'vm');
                [ballTimes,ballVel] = fetch1(patch.Ball*reso.Sync & key, 'ball_time','ball_vel');
                eTimes = fetch1(patch.Ephys*reso.Sync & key, 'ephys_time');
                ballTimes = interp1(eTimes,times,ballTimes);
                k = hamming(51); k = k/sum(k);
                ballVel = ne7.dsp.convmirr(ballVel,k);
                
                vel = cell(size(keys));
                vm = cell(size(keys));
                bt = cell(size(keys));
                bs = nan(size(keys));
                for i=1:length(keys)
                    [onset,trialBs] = fetch1(reso.Trial*reso.TrialBrainState & keys(i),'onset','trial_brain_state');
                    ix = times > onset + interval(1) & times < onset + interval(2);
                    bt{i} = bsTrace(ix);
                    bs(i) = trialBs;
                    vm{i} = cleanVm(ix);
                    ix = ballTimes > onset + interval(1) & ballTimes < onset + interval(2);
                    vel{i} = ballVel(ix);
                end
                
                vm = cellfun(@(x) x(1:min(cellfun(@length,vm))), vm, 'uni', false);
                vel = cellfun(@(x) x(1:min(cellfun(@length,vel))), vel, 'uni', false);
                vm = [vm{:}];
                vel = [vel{:}];
                [bs,order] = sort(bs);
                vm = vm(:,order);
                vel = vel(:,order);
                subplot 131
                imagesc(vm',[-0.08 -0.035])
                subplot 132
                imagesc(vel')
                colormap jet
                
                
                times = fetch1(reso.Sync & key, 'frame_times');
                traces = fetchn(reso.Trace & key, 'ca_trace');
                traces = [traces{:}];
                traces = bsxfun(@rdivide, traces, mean(traces))-1;
                subplot 133
                for iTrace = 1:size(traces,2)
                    ca = cell(size(keys));
                    for iTrial = 1:length(keys)
                        [onset,trialBs] = fetch1(reso.Trial*reso.TrialBrainState & keys(iTrial),'onset','trial_brain_state');
                        ix = times > onset + interval(1) & times < onset + interval(2);
                        ca{iTrial} = traces(ix,iTrace);
                    end
                    ca = cellfun(@(x) x(1:min(cellfun(@length,ca))), ca, 'uni', false);
                    ca = [ca{:}];
                    ca = ca(:,order);
                    imagesc(ca')
                end
            end
        end
    end
end