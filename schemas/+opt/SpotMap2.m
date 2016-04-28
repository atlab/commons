%{
opt.SpotMap2 (imported) # retinotopic mapping with grating spots. Average
-> opt.Sync
-----
spot_amp : longblob # percent, response amplitude of each spot
%}

classdef SpotMap2 < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('opt.SpotMap2')
        popRel = opt.Sync & psy.Grating
    end
    
    methods
		function self = SpotMap2(varargin)
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
            sz = size(X);
            trialRel = opt.Sync(key)*psy.Trial*psy.Grating & 'trial_idx between first_trial and last_trial';
            trials = fetch(trialRel, 'aperture_x*1000+aperture_y->position', 'flip_times');
            nTrials = length(trials);
            [conds,~,condIdx] = unique([trials.position]);
            nConds = length(conds);
            ntrials = nTrials/nConds;
            times = fetch1(opt.Sync(key), 'frame_times');
            
            X_amp = zeros(sz(2),sz(3),nConds,ntrials);
            cnt = ones(1,nConds); % counter for the trials of each condition
            
            for iTrial = 1:length(trials)
                trial = trials(iTrial);
                onset = trial.flip_times(2);  % the second flip is the start of the drift  
                offset = trial.flip_times(end);
                cond = condIdx(iTrial);
                ix_on = (times>=onset & times < offset);
                ix_off = (times>onset - 2*framerate & times<onset);
                X_temp = (squeeze(mean(X(ix_on,:,:))) - squeeze(mean(X(ix_off,:,:))))./squeeze(mean(X(ix_off,:,:)));
                X_amp(:,:,cond,cnt(cond)) = X_temp;
                cnt(cond) = cnt(cond)+1;
            end
            key.spot_amp = squeeze(mean(X_amp,4));
            
			self.insert(key)
		end
	end
end
