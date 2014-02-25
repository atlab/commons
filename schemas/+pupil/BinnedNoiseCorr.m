%{
pupil.BinnedNoiseCorr (computed) # my newest table
-> reso.TrialTraceSet
-> pupil.TrialSet
-----
bin_ms    : float     # bin duration in milliseconds
noise_cov : longblob  # noise covariance matrix conditioned on pupil phase
sig_cov   : longblob  # signal covariance matrix conditioned on pupil phase
%}

classdef BinnedNoiseCorr < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = reso.TrialTraceSet*pupil.TrialSet*reso.Sync & psy.Grating
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            binSize = 150; % ms
            
            duration = fetchn(reso.Trial & key, 'offset-onset->duration');
            assert(all(abs(duration-median(duration))<0.01),'stimuli must be of the same duration')
            duration = median(duration);

            disp 'computing mean responses...'
            trialTimes = fetch1(reso.TrialTraceSet & key, 'trial_times');
            dt = mean(diff(trialTimes));
            binSize = ceil(binSize/dt/1000);
            binMs = binSize*dt*1000;
            % include a whole number of bins
            interval = find(trialTimes>-0.5,1,'first');
            interval = interval+(1:floor((duration+1.0)/dt/binSize)*binSize);
            trialTimes = trialTimes(interval);
            
            s = fetch(pupil.Trial*reso.TrialTrace*psy.Trial & key, ...
                'trial_trace', 'cond_idx', 'ORDER BY trace_id, cond_idx');
            s = arrayfun(@(s) setfield(s,'trial_trace',s.trial_trace(interval)), s);  %#ok<SFLD>
            [traces,~,~] = dj.struct.tabulate(s, 'trial_trace', 'trace_id', 'cond_idx');
            nRepeats = sum(~cellfun(@isempty,traces),3);
            assert(all(nRepeats(:)>16), 'at least 16 repeats are required for each condition')
            meanScalars = nan([size(traces,1),1]);
            for iTrace=1:size(traces,1)
                meanScalars(iTrace) = mean(mean(cat(1,traces{iTrace,:,:})));
            end
            stimulusInterval = trialTimes>0 & trialTimes<duration+0.150;
            meanTraces = zeros([length(interval) size(nRepeats)]);
            for iTrace=1:size(traces,1)
                for iCond=1:size(traces,2)
                    m = mean(cat(1,traces{iTrace,iCond,:})) - meanScalars(iTrace);
                    meanTraces(stimulusInterval,iTrace,iCond) = m(stimulusInterval);
                end
            end
                        
            disp 'computing correlations...'
            sz = size(traces);
            gix = find(squeeze(~any(cellfun(@isempty,traces),1)));
            [condIxx,trialIxx] = ind2sub(sz(2:3), gix);
            total = nan(length(trialTimes)*length(gix),sz(1));
            signal = nan(size(total));
            for i=1:length(gix)
                ix = (i-1)*length(trialTimes)+(1:length(trialTimes));
                s = traces(:,condIxx(i),trialIxx(i));
                total(ix,:) = cat(1, s{:})';
                signal(ix,:) = meanTraces(:,:,condIxx(i));
            end
            
            % downsample
            k = ones(binSize,1);
            k = k/sum(k);
            signal = conv2(signal,k,'valid');
            signal = signal(1:binSize:end,:);
            total = conv2(total,k,'valid');
            total = total(1:binSize:end,:);
            
            % compute covariances
            key.noise_cov = cov(total-signal);
            key.sig_cov = cov(signal);
            key.bin_ms = binMs;
            
            self.insert(key)
        end
    end
end