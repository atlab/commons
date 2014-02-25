%{
pupil.TrialNoiseCorr (computed) # covariance of response variability
-> reso.TrialTraceSet
-> pupil.TrialSet
-----
cov_matrix : longblob  # noise covariance matrix conditioned on pupil phase
%}

classdef TrialNoiseCorr < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel  = reso.TrialTraceSet*pupil.TrialSet
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            disp 'fetching trials...'
            trialTimes = fetch1(reso.TrialTraceSet & key, 'trial_times');
            s = fetch(pupil.Trial*reso.TrialTrace*psy.Trial*psy.Grating & key, ...
                'direction', 'trial_trace', 'ORDER BY trace_id');
            
            disp 'integrating responses...'
            interval = trialTimes > 0 & trialTimes < trialTimes(end)-0.8;
            s = arrayfun(@(s) setfield(s, 'response', sum(s.trial_trace(interval))), s); %#ok<SFLD>
            [responses, ~, trialIds] = dj.struct.tabulate(s, ...
                'response','trace_id','trial_idx');
            
            % subtract avearge responses
            [m, ~, condIdx] = dj.struct.tabulate(s, ...
                'response','trace_id','cond_idx');
            m = nanmean(m, 3);  % mean responses for each condition
            [condLookup, trialLookup] = dj.struct.tabulate(s, 'cond_idx', 'trial_idx');
            meanIdx = arrayfun(@(x) find(condIdx==median(condLookup(trialLookup==x,:))), trialIds);
            responses = responses - m(:,meanIdx);
            
            % subtract the first principal component
            responses = bsxfun(@minus, responses, mean(responses));
            [U,D,V] = svds(responses,1);
            responses = responses - U*D*V';
                        
            key.cov_matrix = single(cov(responses'));
            self.insert(key)
        end
    end
    
end