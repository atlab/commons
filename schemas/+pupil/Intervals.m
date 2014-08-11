%{
pupil.Intervals (computed) # pupil phase intervals
-> patch.Eye
-> patch.Ball
-> pupil.EpochOpt
interval  : int   # interval id
-----
is_active   : tinyint   # has running or facing
is_spont    : tinyint   # 1=spontaneous activity, 0=all activity
diam_delta  : float     # change in pupil diameter
on_idx      : smallint  # onset index in pupil frames
off_idx     : smallint  # offset index in pupil frames
onset       : double    # (s) onset time
duration    : float     # (s) duration
%}

classdef Intervals < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = patch.Eye*patch.Ball*pupil.EpochOpt ...
            & '`condition` in ("dilating","constricting")' ...
            & patch.EyeFrame & patch.Running & patch.Facing
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            opt = fetch(pupil.EpochOpt & key, '*');
            assert(ismember(opt.condition, {'dilating','constricting'}), ...
                'only dilating and restricting epochs are allowed')
            
            % get pupil radius and speed, convert to microns
            [pupilRadius, pupilX, pupilY, pupilTimes] = fetchn(patch.EyeFrame & key, ...
                'pupil_r','pupil_x','pupil_y','frame_time','ORDER BY frame_time');
            pupilFPS = 1/median(diff(pupilTimes));
            saccadeSpeed = sqrt(gradient(pupilX).^2 + gradient(pupilY).^2)*pupilFPS;
            pixelPitch = 5;  % um / pixel
            saccadeSpeed = saccadeSpeed * pixelPitch; % convert to microns
            pupilRadius = pupilRadius * pixelPitch;   % convert to microns
            
            % flip the sign if constricting
            if strcmp(opt.condition,'constricting')
                pupilRadius = -pupilRadius;
            end
            
            % a interval is considered dilating if the pupil radius increases
            % by more than a threshold
            diamThresh = 5; %um
            [onIdx,offIdx] = risingIntervals(pupilRadius*2, diamThresh, pupilFPS);
            
            % remove intervals whose start is unobservable
            ix = onIdx > 1 & ~isnan(pupilRadius(max(1,onIdx-1)))';
            onIdx = onIdx(ix);
            offIdx = offIdx(ix);
            
            if opt.saccade_thresh
                % exclude saccades
                ix = arrayfun(@(on,off) max(saccadeSpeed(on:off)), onIdx, offIdx) < opt.saccade_thresh;
                onIdx = onIdx(ix);
                offIdx = offIdx(ix);
            end
            diamDelta = 2*(pupilRadius(offIdx)-pupilRadius(onIdx));
            
            % mark active periods (running, "facing")
            [runOn,runDur]=fetchn(patch.Running & key, 'run_on', 'run_dur');
            [faceOn,faceDur]=fetchn(patch.Facing & key, 'face_on', 'face_dur');
            isActive = arrayfun(@(on,off) ...
                any(overlaps(pupilTimes(on),pupilTimes(off),runOn, runOn+runDur)) | ...
                any(overlaps(pupilTimes(on),pupilTimes(off),faceOn, faceOn+faceDur)), ...
                onIdx, offIdx);
            
            % mark spontaneous periods
            [eTime,vTime] = fetch1(patch.Ephys*patch.Sync & key, 'ephys_time','vis_time');
            [trialOnsets, trialOffsets] = fetchn(reso.Trial & key, 'onset', 'offset');
            trialOnsets = interp1(vTime,eTime,trialOnsets,'linear','extrap');
            trialOffsets = interp1(vTime,eTime,trialOffsets,'linear','extrap');
            isSpont = ~arrayfun(@(on,off) ...
                any(overlaps(on,off,trialOnsets-2,trialOffsets+2)), ...
                onIdx, offIdx);
            
            for i=1:length(onIdx)
                tuple = key;
                tuple.interval = i;
                tuple.is_active = isActive(i);
                tuple.is_spont = isSpont(i);
                tuple.diam_delta = diamDelta(i);
                tuple.on_idx = onIdx(i);
                tuple.off_idx = offIdx(i);
                tuple.onset = pupilTimes(onIdx(i));
                tuple.duration = diff(pupilTimes([onIdx(i) offIdx(i)]));
                self.insert(tuple)
            end
        end
    end
end



function yes = overlaps(on,off,onArray,offArray)
% true if the intreval between on and off overlaps intervals defined by
% onAarray/offArray
yes = (onArray-on).*(offArray-on)<=0 ...
    | (onArray-off).*(offArray-off)<=0 ...
    | (onArray-on).*(onArray-off)<=0 ...
    | (offArray-on).*(offArray-off)<=0;
end




function [onsets, offsets] = risingIntervals(x, thresh, fs)
% finds intervals of increasing signal in x

lookahead = 0.25;  % seconds
lookahead = floor(lookahead*fs);
onsets = [];
offsets = [];
start = nan;
for i=1:length(x)
    if isnan(x(i))
        start = nan;
    elseif isnan(start) || x(i)<=x(start)
        start = i;
    elseif x(i)-x(start)>thresh && max(x(i:min(end,i+lookahead)))<=x(i)
        onsets(end+1) = start; %#ok<AGROW>
        offsets(end+1) = i; %#ok<AGROW>
        start = nan;
    end
end
end
