%{
pupil.EpochTrial (computed) # trials included in each trace
-> pupil.EpochTrialSet
-> reso.Trial
-----
%}

classdef EpochTrial < dj.Relvar
    methods
        function makeTuples(self, key)
            
            opt = fetch(pupil.EpochOpt & key, '*');
            
            % assert that reso trials correspond to patch trials
            assert(all(ismember(fetchn(reso.Trial & key, 'trial_idx'),fetchn(patch.Trial & key, 'trial_idx'))))
            
            % get trials
            [trialOnsets, trialOffsets, trialKeys] = fetchn(reso.Trial & key, 'onset', 'offset');
            %             if opt.include_blanks
            %                 trialOffsets = trialOffsets + .5; % and 500 ms after
            %             end
            [eTime,vTime] = fetch1(patch.Ephys*patch.Sync & key, 'ephys_time','vis_time');
            % convert to ephys time
            trialOnsets = interp1(vTime,eTime,trialOnsets,'linear','extrap');
            trialOffsets = interp1(vTime,eTime,trialOffsets,'linear','extrap');
            
            % get pupil radius and speed, convert to microns
            [pupilRadius, pupilX, pupilY, pupilTimes] = fetchn(patch.EyeFrame & key, ...
                'pupil_r','pupil_x','pupil_y','frame_time','ORDER BY frame_time');
            pupilFPS = 1/median(diff(pupilTimes));
            saccadeSpeed = sqrt(gradient(pupilX).^2 + gradient(pupilY).^2)*pupilFPS;
            pixelPitch = 5;  % um / pixel
            saccadeSpeed = saccadeSpeed * pixelPitch;     % convert to microns
            pupilRadius = pupilRadius * pixelPitch;   % convert to microns
            % interpolate over nans
            notnans = ~isnan(pupilRadius);
            pupilRadius = interp1(pupilTimes(notnans),pupilRadius(notnans), pupilTimes, 'linear', 'extrap');
            saccadeSpeed  = interp1(pupilTimes(notnans),saccadeSpeed(notnans), pupilTimes, 'linear', 'extrap');
            
            % establish running epochs
            [runOn,runDur]=fetchn(patch.Running & key, 'run_on', 'run_dur');
            [faceOn,faceDur]=fetchn(patch.Facing & key, 'face_on', 'face_dur');
            [runOn, runDur] = mergeIntervals([runOn; faceOn], [runDur; faceDur]);
            
            % select trials that meet condition
            switch opt.condition
                case 'all'
                    select = true(size(trialKeys));
                    
                case {'running','not running'}
                    runFrac = arrayfun(@(on,dur) fracOverlap(on, dur, runOn, runDur),...
                        trialOnsets, trialOffsets-trialOnsets);
                    
                    if strcmp(opt.condition, 'running')
                        select = runFrac ==1;
                    else
                        select = runFrac ==0;
                    end
                    
                case {'dilating', 'constricting'}
                    % a trial is considered dilating if the pupil is bigger
                    % at the end than at the beginning
                    onRad = interp1(pupilTimes, pupilRadius, trialOnsets, 'nearest', 'extrap');
                    offRad = interp1(pupilTimes, pupilRadius, trialOffsets, 'nearest', 'extrap');
                    select = offRad > onRad;
                    select = xor(select, strcmp(opt.condition,'constricting'));
                    
                    % exclude running periods
                    runFrac = arrayfun(@(on,dur) fracOverlap(on, dur, runOn, runDur),...
                        trialOnsets, trialOffsets-trialOnsets);
                    select = select & runFrac == 0;
                    
                otherwise
                    error 'invalid epoch condition'
            end
            if opt.saccade_thresh
                % exclude saccades
                trialOnIx = interp1(pupilTimes, 1:length(pupilTimes), trialOnsets, 'nearest');
                trialOffIx = interp1(pupilTimes, 1:length(pupilTimes), trialOffsets, 'nearest');
                maxSaccadeSpeed = arrayfun(@(onIx,offIx) max(saccadeSpeed(onIx:offIx)), trialOnIx, trialOffIx);
                select = select & maxSaccadeSpeed < opt.saccade_thresh;
            end
            
            tuples = dj.struct.join(key, trialKeys(select));
            self.insert(tuples)
        end
    end
end


function overlap = doOverlap(on,dur)
% compute overlap length between intervals defined by onsets on and
% durations dur.
overlap = max(0, min(on+dur)-max(on));
end


function frac = fracOverlap(on, dur, onArray, durArray)
% compute fraction overlap between the interval defined by on and dur with
% intervals defined by onArray and durArray. Intervals in array may not overlap.
assert(isscalar(on) && isscalar(dur) && length(onArray)==length(durArray))
frac = sum(arrayfun(@(on2,dur2) doOverlap([on on2], [dur dur2]), onArray, durArray))/dur;
end



function [on,dur] = mergeIntervals(on, dur)
% some intervals defined by onsets on and durations dur may overlap.  Such
% overlapping intervals are merged.

assert(length(on)==length(dur))

[on,ix] = sort(on);
dur = dur(ix);

% merge overlapping intervals
for i=1:length(on-1)
    for j=i+1:length(on)
        if ~doOverlap(on([i j]),dur([i j]))
            break
        else
            dur(i) = max(dur(i), on(j)+dur(j)-on(i));
            dur(j) = 0;
        end
    end
end
on(~dur)=[];
dur(~dur)=[];
end