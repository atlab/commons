%{
opt.BarrelMap (imported) # get a map for barrel field, with single whisker stimulation
->common.OpticalMovie
-----
barrel_amp     : longblob        # amplitude map of barrel cortex, difference between on and off time period.
stimulus       : longblob        # raw stimulus signal from the piezo
mov_time       : longblob        # time of each frame of the movie, in sec
mov_ind        : longblob        # indicator of stimulus on off for each frame
%}

classdef BarrelMap < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = common.OpticalMovie & 'purpose="whisker"'
    end
    
	methods(Access=protected)

		function makeTuples(self, key)
		
            disp 'loading movie...'

            filename = fullfile(...
            fetch1(common.OpticalSession(key), 'opt_path'),...
            [fetch1(common.OpticalMovie(key), 'filename') '.h5']);
            [X, framerate, stim, pdFs] = opt.utils.getOpticalData(getLocalPath(filename),'pd');
            
            stim_ind = abs(diff(stim))>0.05;
            stim_time = (1:length(stim_ind))/pdFs;
            
            key.mov_time = (1:size(X,1))/framerate;
            key.mov_ind = logical(interp1(stim_time, double(stim_ind)', key.mov_time, 'nearest','extrap'));
            
            key.barrel_amp = squeeze(mean(X(key.mov_ind,:,:)) - mean(X(~key.mov_ind,:,:)));
            key.stimulus = stim;
			
            self.insert(key)
		end
	end

end