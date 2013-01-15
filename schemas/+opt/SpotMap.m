%{
opt.SpotMap (imported) # retinotopic mapping using grating spots
-> opt.Sync
tau       :  tinyint  # tau 
-----
spot_amp  : longblob  # (percent) response magnitudes for each spot
spot_r2   : longblob  # r-squared of total response
spot_fp   : longblob  # total response p-value (F-test)
%}

%spot_psth : longblob  # average stimulus-locked response
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
            [X, framerate] = opt.utils.getOpticalData(getLocalPath(filename),'mov');
            
%             % smoothen and downsample
%             X = permute(X, [2 3 1]);
%             k = hamming(5);
%             k = k/sum(k);
%             X = imfilter(X,k,'symmetric');
%             X = imfilter(X,k','symmetric');
%             X = imresize(X,0.5);
%             X = permute(X, [3 1 2]);
            
            % reshape
            sz = size(X);
            X = reshape(X, sz(1), []);
            
%           % baseline correction via low-pass
%             tic
%             disp 'filtering...'
%             framerate=4;
%             n = size(X,1);
%             k = hamming(round(framerate/.01)*2+1);
%             k = k/sum(k);
%             X=(X./convmirr(X,k)-1);  %  dF/F where F is low pass
%             toc
            
%           % baseline correction subtract mean            
%            X = bsxfun(@minus, X, mean(X));


            % baseline correction via interpolation
            tic
            X=X./interp1q(floor(1:framerate*60:sz(1))',X(floor(1:framerate*60:sz(1)),:),[1:sz(1)]')-1;
            X(isnan(X))=0;
            toc

            trialRel = opt.Sync(key)*psy.Trial*psy.Grating & 'trial_idx between first_trial and last_trial';
            trials = fetch(trialRel, 'aperture_x*1000+aperture_y->position', 'flip_times');
            [~,~,condIdx] = unique([trials.position]);
            times = fetch1(opt.Sync(key), 'frame_times');
            
            % exclude the times 20 s before and after stimulus
            firstTime = min(arrayfun(@(x) x.flip_times(2), trials));
            lastTime = max(arrayfun(@(x) x.flip_times(end), trials));
            ix = times > firstTime - 20 & times < lastTime + 20;
            times = times(ix);
            X = X(ix,:);

            %taus = [0.5 1.0 1.5 2.0 3.0 4.0];
            taus=2;
            for tauIdx = 1:length(taus)
                disp 'constructing design matrix...'
                tau = taus(tauIdx);  % hemodynamic response time constant
                
                nCond = length(unique(condIdx));
                nTrials = length(trials);
                G = zeros(length(times), nCond, 'single');
                for iTrial = 1:nTrials
                    trial = trials(iTrial);
                    onset = trial.flip_times(2);  % the second flip is the start of the drift  
                    offset = trial.flip_times(end);
                    cond = condIdx(iTrial);
                    
                    ix = find(times>=onset & times < offset);
                    G(ix, cond) = G(ix, cond) ...
                        + 1 - exp((onset-times(ix))/tau);
                    
                    ix = find(times>=offset & times < offset+5*tau);
                    G(ix, cond) = G(ix, cond) ...
                        + (1-exp((onset-offset)/tau))*exp((offset-times(ix))/tau);
                    
%                     ix = find(times>=onset & times < offset+5*tau);
%                     len = length(ix);
%                     if ~exist('P')
%                         P = zeros(nCond,len+1,size(X,2),'single');
%                     end
%                     P(cond,1:len,:)=squeeze(P(cond,1:len,:))+X(ix,:);
                end
                
%                 P=P./(nTrials/nCond);
                G = bsxfun(@minus, G, mean(G));
                
                tic                
                disp 'regressing...'
                [B, R2, Fp] = ne7.stats.regress(X, G, 0);
                toc

                disp 'saving data'
                key.tau = tau;
                key.spot_amp = reshape(single(B)', sz(2), sz(3), []);
                key.spot_r2  = reshape(single(R2), sz(2), sz(3));
                key.spot_fp  = reshape(single(Fp), sz(2), sz(3));
%                 key.spot_psth = reshape(P,nCond,size(P,2),sz(2),sz(3));
                self.insert(key)
            end
		end
	end
end
