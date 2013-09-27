%{
reso.VonMises (computed) # von mises tuning based on trials and deconvolved traces, optionally conditioned on brain state
-> reso.VonMisesSet
-> reso.Trace
-----
responses : longblob  # table with 2 columns: directions and responses
von_pref  : float     # (radians) preferred direciton
von_base  : float     # response in anti-preferred orientation
von_amp1  : float     # response in preferred direction
von_amp2  : float     # response in anti-preferred direction
von_sharp : float     # tuning sharpness
von_p : float     # p-value computed by shuffling
%}

classdef VonMises < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.VonMises')
        popRel = reso.Segment*reso.TuningCondition & (reso.Trial*psy.Grating);
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            disp 'fetching trials...'
            assert(key.tuning_cond == 0, 'brain state conditioning is not yet implemented')
            trialTimes = fetch1(reso.TrialTraceSet & key, 'trial_times');
            s = fetch(reso.TrialTrace*psy.Trial*psy.Grating & key, 'direction', 'trial_trace');
            
            disp 'integrating responses...'
            interval = trialTimes > 0.05 & trialTimes < 0.5; % integrate between 50 and 500 ms
            responses = arrayfun(@(s) mean(s.trial_trace(interval)), s, 'uni', false);
            [s.response] = deal(responses{:});
            
            disp 'tabulating...'
            [responses,traceIds] = dj.struct.tabulate(s, 'response', 'trace_id', 'direction');
            
            disp 'computing von Mises tuning ...'
            % compute von Mises tuning
            [von,r2] = computeTuning(responses);
            
            % compute significance by shuffling
            nShuffles = fetch1(reso.VonMisesSet & key, 'nshuffles');
            p = 0.5*ones(1,length(traceIds))/nShuffles;
            sz = size(responses);
            responses = reshape(responses, sz(1),[]);
            for i=1:nShuffles
                if ~mod(i-1,250), fprintf('Shuffles [%4d/%4d]\n', i-1, nShuffles), end
                [~, r2_] = computeTuning(reshape(responses(:,randperm(end)),sz));
                p = p + (r2_>=r2)/nShuffles;
            end
            responses = reshape(responses, sz);
            
            % report results
            for i=1:length(traceIds)
                tuple = key;
                tuple.trace_id = traceIds(i);
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

function [von, r2] = computeTuning(x)
von = fit(ne7.rf.VonMises2, nanmean(x,3)');
y = bsxfun(@minus, x, von.compute);
r2 = 1-nanvar(reshape(y,size(x,1),[])')./nanvar(reshape(x,size(x,1),[])');
end
