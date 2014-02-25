%{
pupil.Trial (computed) # trials included in each trace
-> pupil.TrialSet
-> reso.Trial
-----
%}

classdef Trial < dj.Relvar
    methods
        function makeTuples(self, key)
            caTimes = fetch1(reso.Sync & key, 'frame_times');
            membership = fetch1(pupil.Classify & key, 'membership');
            
            [onsets, offsets, keys] = fetchn(reso.Trial*reso.Sync & key, 'onset', 'offset');
            
            for i=1:length(keys)
                trialIndices = find(caTimes >= onsets(i) & caTimes <= offsets(i));
                if all(membership(trialIndices(max(1,floor(end/2)):end)))
                    self.insert(dj.struct.join(key,keys(i)))
                end
            end
        end
    end
end