%{
reso.PeriStimTrace (computed) # calcium signals around the stimulus
->reso.Sync
->reso.Trace
->psy.Trial
-----
stim_onset  :  double     # trial onset time 
trial_trace  :  longblob   # deconvolved, resampled at 2*fps, zeroed on stimulus onset, 2 seconds before and after trial
%}

classdef PeriStimTrace < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.PeriStimTrace')
        popRel  = reso.Sync*reso.Segment*psy.Session
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            key = fetch(reso.Sync*psy.Session & key);
            times = fetch1(reso.Sync & key, 'frame_times');
            dt = mean(diff(times));
            trials = fetch(reso.Sync*psy.Trial & key & ...
                'trial_idx between first_trial and last_trial','flip_times');
            traceKeys = fetch(reso.Trace & key);

            tuples = [];
           
            for traceKey = traceKeys'
                trace = fetch1(reso.Trace & traceKey, 'ca_trace');
                trace = trace/mean(trace)-1;
                trace = fast_oopsi(double(trace'),struct('dt',dt));
                traceTimes = times(1:length(trace));
                for trial = trials'
                    trialKey = rmfield(trial,'flip_times');
                    stimOnset = trial.flip_times(2);  % first flip is clear screen
                    stimOffset = trial.flip_times(end);
                    trialTimes = stimOnset - 2:dt/2:stimOffset+2;
                    if traceTimes(1)<trialTimes(1) && traceTimes(end)>trialTimes(end)
                        trialTrace = pchip(traceTimes,trace,trialTimes); %upsample
                        tuple = dj.struct.join(traceKey, trialKey);
                        tuple.trial_trace = single(trialTrace);
                        tuple.stim_onset = stimOnset;
                        tuples = [tuples, tuple];
                    end
                end
                fprintf .
            end
            fprintf \n
            self.insert(tuples)
        end
    end
end
