%{
opt.BarMap (imported) # retinotopic mapping with moving bars. Average
->opt.Sync
-----
bar_phase_map        : longblob  # phase of the response at the stimulus frequency
bar_amp_map          : longblob  # amplitude of the response at the stimulus frequency
freq                 : longblob  # entire frequecy chain
freq_rel             : double    # stimulus frequency of this session
range_factor         : double    # range of frequency included in the map, [freq_rel*(1-range_factor), freq_rel*(1+range_factor)]
direction            : double    # direction of the moving bar
ntrials              : int       # number of trials on this session
%}

classdef BarMap < dj.Relvar & dj.AutoPopulate
	properties
        popRel = opt.Sync & psy.MovingBar
    end
    
    methods
		function self = BarMap(varargin)
			self.restrict(varargin)
		end
    end
    
	methods(Access=protected)

		function makeTuples(self, key)
            disp 'loading movie...'
            tic
            filename = fullfile(...
                fetch1(common.OpticalSession(key), 'opt_path'),...
                [fetch1(common.OpticalMovie(key), 'filename') '.h5']);
            [X, framerate] = opt.utils.getOpticalData(getLocalPath(filename),'mov');
            toc
            
            trialRel = opt.Sync(key)*psy.Trial*psy.MovingBar & 'trial_idx between first_trial and last_trial';
            trials = fetch(trialRel, 'flip_times', 'direction');
            trial_duration = fetch(psy.MovingBar & trialRel, 'trial_duration');
            trial_duration = trial_duration(1).trial_duration;
            freq_rel = 1/trial_duration;
           
            % time of the scans on the stimulus clock
            times = fetch1(opt.Sync(key), 'frame_times');
            
            % take out the movie with stimulus on
            onset = trials(1).flip_times(2);
            offset = trials(end).flip_times(end);
            ix = (times>=onset & times<offset);
            X_rel = X(ix,:,:);
            X_rel = bsxfun(@minus,max(X_rel,[],1), X_rel);
            
            disp 'Fourier transform...'
            tic
            x_dfft = fft(X_rel);
            toc
            duration = size(X_rel,1)/framerate;
            freq = 1/duration*(0:length(X_rel)-1);          
            
            
            % get the Fourier transform at the frequency of stimulus frequency
            disp 'Caculating phase and amplitude...'
            tic
            amp = abs(x_dfft);
            phase = angle(x_dfft);
            range_factor = 0.1;
            amp_rel = squeeze(mean(amp(freq>freq_rel*(1-range_factor) & freq<freq_rel*(1+range_factor), :,:)));
            phase_rel = squeeze(mean(phase(freq>freq_rel*(1-range_factor) & freq<freq_rel*(1+range_factor),:,:)));
            toc
            
            disp 'Insert key...'
            tic
            key.bar_phase_map = phase_rel;
            key.bar_amp_map = amp_rel;
%             key.amp = amp;
%             key.phase = phase;
            key.range_factor = range_factor;
            key.freq_rel = freq_rel;
            key.ntrials  = length(trials);
            key.direction = trials(1).direction;
            key.freq = freq;			
            self.insert(key)
            toc
		end
	end
end
