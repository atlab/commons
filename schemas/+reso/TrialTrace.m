%{
reso.TrialTrace (computed) # calcium signal around stimulus
-> reso.TrialTraceSet
-> reso.Trace
-> reso.Trial
-----
trial_trace :  longblob   # deconvolved, upsampled, resampled to have stimulus onset at zero_idx, include 1.0 sec before and after trial
%}

classdef TrialTrace < dj.Relvar
    
    properties(Constant)
        table = dj.Table('reso.TrialTrace')
    end
    
    methods
        
        function makeTuples(self, key)
            
            % deconvolve trace
            [times,trace] = fetch1(reso.Sync*reso.Trace & key, ...
                'frame_times', 'ca_trace');
            times = times(1:length(trace));
            trace = trace/mean(trace)-1;
            dt = median(diff(times));
            trace = fast_oopsi(double(trace'),struct('dt',dt));
         
            trialTimes = fetch1(reso.TrialTraceSet & key, 'trial_times');
            
            % extract snippets around trials
            for key = fetch(reso.Trace*reso.Trial & key)'
                onset = fetch1(reso.Trial & key, 'onset');
                key.trial_trace = single(pchip(times-onset,trace,trialTimes));
                self.insert(key)
            end
        end
        
    end
end
