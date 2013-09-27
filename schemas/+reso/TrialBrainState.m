%{
reso.TrialBrainState (computed) # the brain state at trial
-> reso.BrainState
-> reso.Trial
-----
trial_brain_state : float  # brain state measured right before trial
%}

classdef TrialBrainState < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.TrialBrainState')
        popRel  = reso.BrainState*reso.TrialSet
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)            
            brainState = fetch1(reso.BrainState & key, 'brain_state_trace');
            times = fetch1(reso.Sync & key, 'frame_times');
            interval = [-0.5 -0.1]; % seconds before trial
            
            for key = fetch(reso.Trial & key)'
                onset = fetch1(reso.Trial & key,'onset');
                ix = times > onset + interval(1) & times < onset + interval(2);
                key.trial_brain_state = mean(brainState(ix));
                
                self.insert(key)
            end
        end
    end
end
