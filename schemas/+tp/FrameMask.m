%{
tp.FrameMask (imported) # mark the contaminated frames
-> tp.Sync

-----
frame_mask : longblob  # have the same length as frame_times, 0 means the frame is contaminated, 1 means not

%}

classdef FrameMask < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.FrameMask')
        popRel = tp.Sync
    end

    methods
        function self = FrameMask(varargin)
            self.restrict(varargin)
        end
    end
    
	methods(Access = protected)
		function makeTuples(self, key)
            % delete the first two frames of each trial
            times = fetch(tp.Sync(key), 'frame_times');
            trialRel = tp.Sync(key) * psy.Trial * psy.Grating & 'trial_idx between first_trial and last_trial';
            trials = fetch(trialRel,'flip_times');
            
            time = times.frame_times;
            fm = ones(1,length(time));
            for iTrial = 1:length(trials)
                trial = trials(iTrial);
                onset = trial.flip_times(2);
                offset = trial.flip_times(end);
                idx = find(time>=onset & time<offset);
                idx = idx(1:2);
                fm(idx) = 0;
            end
            
            tuple = key;
            tuple.frame_mask = fm;
			self.insert(tuple);
		end
	end
end
