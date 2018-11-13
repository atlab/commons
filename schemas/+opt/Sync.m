%{
opt.Sync (imported) # my newest table
-> common.OpticalMovie
-----
-> psy.Session
first_trial : int        # first trial matching scan
last_trial  : int        # last trial matching scan
frame_times : longblob   # array of frametimes (seconds) on stimulus clock
sync_ts = CURRENT_TIMESTAMP : timestamp    # automatic

%}

classdef Sync < dj.Imported

	properties
		popRel = common.OpticalMovie('purpose="stimulus"')
    end
    
	methods(Access=protected)

        function makeTuples(self, key)
            filename = fullfile(...
                fetch1(common.OpticalSession(key), 'opt_path'),...
                [fetch1(common.OpticalMovie(key), 'filename') '.h5']);
            [movie, ~, phd, phdFs] = opt.utils.getOpticalData(getLocalPath(filename),'pd');
            [times, psyId] = ne7.dsp.FlipCode.synch(phd, phdFs, psy.Trial(key));
            
            key.psy_id = psyId;
            [trialIds, flipTimes] = fetchn(psy.Trial(key), 'trial_idx', 'flip_times');
            ix = cellfun(@(x) any(x>=times(1) & x<=times(end)), flipTimes);
            trialIds = trialIds(ix);
            
            key.frame_times = interp1(times,(0:size(movie,1)-1)*(length(times)/size(movie,1))+1)';
            key.first_trial = min(trialIds);
            key.last_trial = max(trialIds);
            self.insert(key)
		end
	end
end
