%{
reso.Trial (computed) # trials that played during calcium scan
->reso.TrialSet
->psy.Trial
-----
onset  :  double     # (s) trial onset time on stimulus time
offset :  double     # (s) trial offset time on stimulus time
%}

classdef Trial < dj.Relvar
    
    methods
        function makeTuples(self, key)
            times = fetch1(reso.Sync & key, 'frame_times');
            nFrames = fetch1(reso.Align & key, 'nframes');
            keys = fetch(reso.Sync*psy.Trial & key & ...
                'trial_idx between first_trial and last_trial');
            
            % extra recording time required before and after trial
            secondsBefore = 2.0;
            secondsAfter = 3.0;
            
            for key = keys'
                flipTimes = fetch1(psy.Trial & key, 'flip_times');
                key.onset = flipTimes(2);  % first flip is clear screen
                key.offset = flipTimes(end);
                if key.onset>times(1)+secondsBefore && key.offset < times(nFrames)-secondsAfter
                    self.insert(key)
                end
            end
        end
    end
end