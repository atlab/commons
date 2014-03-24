%{
pupil.EpochR2 (computed) # trial-based correlations
-> pupil.EpochVonMisesSet
-----
noise_cov = null : longblob  # trial-based noise covariance matrix
sig_cov   = null : longblob  # trial-based signal covariance matrix
%}

classdef EpochR2 < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = pupil.EpochVonMisesSet & pupil.EpochVonMises
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            minTrials = 16;  % minimum number of trials to be included for noise correlation
            minConds  = 5;   % minimum number of conditions to be include in signal correlation
            
            r = fetchn(pupil.EpochVonMises & key, 'responses', 'ORDER BY trace_id');
            r = cat(1,r{:});
            
            % keep conditions with enough trials
            nTrials = min(sum(~isnan(r),3));  % trials per condition
            if min(nTrials>=minTrials)
                r = r(:,nTrials>=minTrials,:);
                
                m = nanmean(r,3);  % mean response
                n = bsxfun(@minus, r, m);  % resdiual signal
                
                if size(m,2)>=minConds
                    key.sig_cov = cov(m');
                    assert(~any(isnan(key.sig_cov(:))))
                end
                key.noise_cov = nancov(reshape(n,size(n,1),[])');
                assert(~any(isnan(key.noise_cov(:))))
            end
            self.insert(key)
        end
    end
end