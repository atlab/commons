%{
opt.SpotMap (imported) # retinotopic mapping using grating spots

-> opt.Sync
tau_idx         : tinyint               # tau index (internal)
---
spot_amp                    : longblob                      # (percent) response magnitudes for each spot
spot_r2                     : longblob                      # r-squared of total response
spot_fp                     : longblob                      # total response p-value (F-test)
%}

classdef SpotMap < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('opt.SpotMap')
		popRel = opt.Sync & psy.Grating
	end

	methods
		function self = SpotMap(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            
            disp 'loading movie...'
            filename = fullfile(...
                fetch1(common.OpticalSession(key), 'opt_path'),...
                [fetch1(common.OpticalMovie(key), 'filename') '.h5']);
            X = opt.utils.getOpticalData(getLocalPath(filename));
            X = single(X);
            
            % smoothen and downsample
            X = permute(X, [2 3 1]);
            k = hamming(5);
            k = k/sum(k);
            X = imfilter(X,k,'symmetric');
            X = imfilter(X,k','symmetric');
            X = imresize(X,0.5);
            X = permute(X, [3 1 2]);
            sz = size(X);
            X = reshape(X, sz(1), []);
            X = bsxfun(@minus, X, mean(X));
            
            trialRel = opt.Sync*psy.Trial*psy.Grating & key & 'trial_idx between first_trial and last_trial';
            trials = fetch(trialRel, 'aperture_x*1000+aperture_y->position', 'flip_times');
            [~,~,condIdx] = unique([trials.position]);
            times = fetch1(opt.Sync(key), 'frame_times');
            
            % exclude the times 20 s before and after stimulus
            firstTime = min(arrayfun(@(x) x.flip_times(2), trials));
            lastTime = max(arrayfun(@(x) x.flip_times(end), trials));
            ix = times > firstTime - 20 & times < lastTime + 20;
            times = times(ix);
            X = X(ix,:);

            taus = [0.5 1.0 1.5 2.0 3.0 4.0];
            for tauIdx = 1:length(taus)
                disp 'constructing design matrix...'
                tau = taus(tauIdx);  % hemodynamic response time constant

                G = zeros(length(times), length(unique(condIdx)), 'single');
                for iTrial = 1:length(trials)
                    trial = trials(iTrial);
                    onset = trial.flip_times(2);  % the second flip is the start of the drift  
                    offset = trial.flip_times(end);
                    ix = find(times>=onset & times < offset);
                    G(ix, condIdx(iTrial)) = G(ix, condIdx(iTrial)) ...
                        + 1 - exp((onset-times(ix))/tau);
                    ix = find(times>=offset & times < offset+5*tau);
                    G(ix, condIdx(iTrial)) = G(ix, condIdx(iTrial)) ...
                        + (1-exp((onset-offset)/tau))*exp((offset-times(ix))/tau);
                end
                                
                disp 'regressing...'
                [B, R2, Fp] = neurosci.stat.regress(X, G, 0);

                disp 'saving data'
                key.tau_idx = tauIdx;
                key.spot_amp = reshape(single(B)', sz(2), sz(3), []);
                key.spot_r2  = reshape(single(R2), sz(2), sz(3));
                key.spot_fp  = reshape(single(Fp), sz(2), sz(3));
                self.insert(key)
            end
		end
	end
end
