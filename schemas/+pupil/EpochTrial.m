%{
pupil.EpochTrial (computed) # trials included in each trace
-> pupil.EpochTrialSet
-> reso.Trial
-----
%}

classdef EpochTrial < dj.Relvar
    methods
        function makeTuples(self, key)
            
            % assert that patch trials correspond with reso trials
            assert(all(ismember(fetchn(reso.Trial & key, 'trial_idx'),fetchn(reso.Trial & key, 'trial_idx'))))
            
            % fetch pupil phases
            [epochOnsets, epochDurations, isRunning, saccadeVel] = fetch1(patch.Epochs & key, ...
                'epoch_onsets', 'epoch_durations','is_running', 'saccade_vel');
            epochOpt = fetch(patch.EpochOpt & key, '*');

            % for pupil phases, remove saccades and exclude running 
            if ismember(epochOpt.epoch_condition, {'dilating' 'constricting'})
                selection = ~isRunning & saccadeVel < 500;
                epochOnsets = epochOnsets(selection);
                epochDurations = epochDurations(selection);
                clear isRunning saccadeVel
            end

            % convert epoch times to vis stim times
            vTimes = fetch1(patch.Sync & key, 'vis_time');
            eTimes = fetch1(patch.Ephys & key, 'ephys_time');
            epochOnsets = interp1(eTimes, vTimes, double(epochOnsets));

            % select trials whose offsets are contained within the epoch
            [trialOffsets, keys] = fetchn(reso.Trial*reso.Sync & key, ...
                'offset', 'ORDER BY trial_idx');
            keys = dj.struct.join(key,keys);
            for i=1:length(keys)
                if any(trialOffsets(i) > epochOnsets & ...
                        trialOffsets(i) < epochOnsets+epochDurations)
                    self.insert(keys(i))
                end
            end
        end
    end
end