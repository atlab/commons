%{
bs.VonMises (computed) # von mises tuning based on trials and deconvolved traces, optionally conditioned on brain state
-> bs.VonMisesSet
-> reso.Trace
-----
responses : longblob  # table with 2 columns: directions and responses
von_r2    : float     # r-squared of response
von_pref  : float     # (radians) preferred direciton
von_base  : float     # response in anti-preferred orientation
von_amp1  : float     # response in preferred direction
von_amp2  : float     # response in anti-preferred direction
von_sharp : float     # tuning sharpness
von_p : float     # p-value computed by shuffling
%}

classdef VonMises < dj.Relvar
    
    properties(Constant)
        table = dj.Table('bs.VonMises')
    end
    
    methods
        
        function makeTuples(self, key)
            
            disp 'fetching trials...'
            trialTimes = fetch1(reso.TrialTraceSet & key, 'trial_times');
            s = fetch(reso.TrialTrace*bs.TrialBrainState*psy.Trial*psy.Grating & key, ...
                'direction', 'trial_trace', 'trial_brain_state');
            
            % restricting to specified condition
            [bsMin,bsMax] = fetch1(bs.TuningCondition & key, 'bs_min', 'bs_max');
            brainState = [s.trial_brain_state];
            s = s(brainState>=bsMin & brainState<=bsMax);
            if ~isempty(s)                
                disp 'integrating responses...'
                interval = trialTimes > 0.05 & trialTimes < 0.5; % integrate between 50 and 500 ms
                responses = arrayfun(@(s) mean(s.trial_trace(interval)), s, 'uni', false);
                [s.response] = deal(responses{:});
                
                disp 'tabulating...'
                [responses,traceIds,direction] = dj.struct.tabulate(s, 'response', 'trace_id', 'direction');
                if length(direction)>=8 && all(direction == 0:360/length(direction):359)
                    
                    disp 'computing von Mises tuning ...'
                    % compute von Mises tuning
                    nShuffles = fetch1(bs.VonMisesSet & key, 'nshuffles');
                    [von, r2, p] = ne7.rf.VonMises2.computeSignificance(responses, nShuffles);
                    
                    % report results
                    for i=1:length(traceIds)
                        tuple = key;
                        tuple.trace_id = traceIds(i);
                        tuple.von_r2  = r2(i);
                        tuple.responses = single(responses(i,:,:));
                        tuple.von_base = von.w(i,1);
                        tuple.von_amp1 = von.w(i,2);
                        tuple.von_amp2 = von.w(i,3);
                        tuple.von_sharp = von.w(i,4);
                        tuple.von_pref = von.w(i,5);
                        tuple.von_p = p(i);
                        
                        self.insert(tuple)
                    end
                end
            end
        end
    end
end
