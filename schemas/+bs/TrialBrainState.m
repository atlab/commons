%{
bs.TrialBrainState (computed) # the brain state at trial
-> bs.BrainState
-> reso.Trial
---
trial_brain_state=null      : float                         # brain state measured right before trial
%}

classdef TrialBrainState < dj.Relvar
    
    properties(Constant)
        table = dj.Table('bs.TrialBrainState')
    end
    
    methods
        
        function makeTuples(self, key)            
            brainState = fetch1(bs.BrainState & key, 'brain_state_trace');
            times = fetch1(reso.Sync*patch.Sync & key, 'vis_time');
            interval = [-0.5 -0.1]; % seconds before trial            
            for key = fetch(reso.Trial & key)'
                onset = fetch1(reso.Trial & key,'onset');
                ix = times > onset + interval(1) & times < onset + interval(2);
                key.trial_brain_state =nanmean(brainState(ix));
                self.insert(key)
            end
        end
    end
end
