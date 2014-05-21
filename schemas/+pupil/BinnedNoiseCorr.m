%{
pupil.BinnedNoiseCorr (computed) # my newest table
-> reso.TrialTraceSet
-> pupil.EpochTrialSet
include_blanks : tinyint  # 1=yes, 0=no.
-----
bin_ms   : float     # bin duration in milliseconds
noise_corr = null : longblob  # noise covariance matrix conditioned on pupil phase
sig_corr  = null : longblob  # signal covariance matrix conditioned on pupil phase
r2 = null      : longblob # r-squared of response
%}

classdef BinnedNoiseCorr < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = reso.TrialTraceSet*pupil.EpochTrialSet*reso.Sync & psy.Grating
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            binSize = 150; % ms
            for includeBlanks = [false true]
                tuple = key;
                duration = fetchn(reso.Trial & key & pupil.EpochTrial, 'offset-onset->duration');
                assert(all(abs(duration-median(duration))<0.01),'stimuli must be of the same duration')
                duration = median(duration);
                
                disp 'computing mean responses...'
                trialTimes = fetch1(reso.TrialTraceSet & key, 'trial_times');
                dt = mean(diff(trialTimes));
                binSize = ceil(binSize/dt/1000);
                binMs = binSize*dt*1000;
                
                % include a whole number of bins
                interval = find(trialTimes>0,1,'first');
                blank = includeBlanks*0.850;
                interval = interval+(1:ceil((duration+blank)/dt/binSize)*binSize)-1;
                clear trialTimes
                
                s = fetch(pupil.EpochTrial*reso.TrialTrace*psy.Trial & key, ...
                    'trial_trace', 'cond_idx', 'ORDER BY trace_id, cond_idx');
                s = arrayfun(@(s) setfield(s,'trial_trace',s.trial_trace(interval)), s);  %#ok<SFLD>
                [traces,~,~] = dj.struct.tabulate(s, 'trial_trace', 'trace_id', 'cond_idx');
                
                
                % select conditions with sufficient trials
                minRepeats = 15;
                nRepeats = sum(~cellfun(@isempty,traces),3);
                ix = min(nRepeats,[],1)>=minRepeats;
                if ~sum(ix)
                    warning 'insufficient trials'
                else
                    traces = traces(:,ix,:);
                    nRepeats = nRepeats(:,ix);
                    
                    % bin traces
                    k = ones(binSize,1);
                    k = k/sum(k);
                    traces = cellfun(@(t) conv_(t,k), traces, 'uni', false);
                    traces = cellfun(@(t) t(1:binSize:end), traces, 'uni', false);
                    nBins = length(traces{1});
                    traces(cellfun(@isempty,traces)) = {single(nan(1,nBins))};
                    
                    % convert to matrix
                    [nTraces,nConds] = size(nRepeats);
                    traces = double(cell2mat(reshape(traces, nTraces, 1, nConds, [])));
                    
                    % mean stimulus response
                    signal = nanmean(traces,4);
                    
                    % subtract mean response
                    residual = bsxfun(@minus, traces, signal);
                    
                    % convert to z-score
                    zscore = bsxfun(@rdivide, residual, max(eps,nanstd(residual,[],4)));
                    
                    % compute covariances
                    tuple.noise_corr = corrcov(nancov(reshape(zscore,nTraces,[])'));
                    tuple.sig_corr = corrcov(nancov(reshape(signal,nTraces,[])'));
                    tuple.r2 = 1-nanvar(reshape(residual,nTraces,[]),[],2)./nanvar(reshape(traces,nTraces,[]),[],2);
                    assert(...
                        ~any(isnan(tuple.noise_corr(:))) && ...
                        ~any(isnan(tuple.sig_corr(:))) && ...
                        ~any(isnan(tuple.r2(:))));
                end
                tuple.include_blanks = includeBlanks;
                tuple.bin_ms = binMs;
                self.insert(tuple)
            end
        end
    end
end

function ret = conv_(a,b)
if isempty(a)
    ret = [];
else
    ret = conv(a,b,'valid');
end
end