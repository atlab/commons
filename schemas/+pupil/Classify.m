%{
pupil.Classify (computed) # classification of pupil dilation/restriction$
-> reso.Sync
-> patch.PupilPhase
---
membership                  : longblob                      # membership degree for each calcium frame
%}

classdef Classify < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = (reso.Sync*pupil.Phase) & patch.Eye
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            tuple = key;
            key = fetch(reso.Sync*patch.Recording*pupil.Phase & key);
            
            % load pupil trace, convert to stim time
            [pupilRadius,pupilTime] = fetchn(patch.EyeFrame & key, ...
                'pupil_r', 'frame_time');
            ix = ~isnan(pupilTime) & ~isnan(pupilRadius);
            pupilRadius = pupilRadius(ix);
            pupilTime = pupilTime(ix);
            
            % compute running periods
            [runOn,runDur]=fetchn(patch.Running & key & 'run_vel*run_dur>1','run_on','run_dur');
            isRunning=false(size(pupilTime));
            for j=1:length(runOn)
                ix = interp1(pupilTime,1:length(pupilTime),runOn(j),'nearest'):interp1(pupilTime,1:length(pupilTime),runOn(j)+runDur(j), 'nearest');
                isRunning(ix) = true;
            end
            
            % convert to simulus time
            [vtime, etime] = fetch1(patch.Sync*patch.Ephys & key,'vis_time','ephys_time');
            pupilTime = interp1(etime,vtime,pupilTime,'linear');
            ix = ~isnan(pupilTime);
            pupilTime = pupilTime(ix);
            pupilRadius = pupilRadius(ix);
            isRunning = isRunning(ix);
            
            % filter pupil trace and compute hilbert phase and amplitude
            band = [0.1 1.0];  % Hz
            pupilFPS = 1/median(diff(pupilTime));
            k = hamming(2*round(pupilFPS/band(1))+1);
            k = k/sum(k);
            pupilRadius = pupilRadius - ne7.dsp.convmirr(pupilRadius,k);
            k = hamming(2*round(pupilFPS/band(2))+1);
            k = k/sum(k);
            pupilRadius = ne7.dsp.convmirr(pupilRadius,k);
            pupilPhase = phase(hilbert(pupilRadius))/(2*pi); % phase of pupil dilation / contraction
            pupilAmp = abs(hilbert(pupilRadius));  % amplitude of pupil dilation / contraction
            
            % classify pupil phase
            phaseOpt = fetch(pupil.Phase & key, '*');
            phase1 = phaseOpt.central_phase - phaseOpt.phase_window/2;
            phase2 = phaseOpt.central_phase + phaseOpt.phase_window/2;
            assert(phase1 < phase2 && phase1>=0 && phase1<=1 && phase2>=0 && phase2<=1) % take care of the rollover when needed
            membership = mod(pupilPhase,1) > phase1 & mod(pupilPhase,1) <= phase2 & ~isRunning;
            assert(mean(membership)>0.25, 'less than 25% of the data qualified')
            membership = membership.*pupilAmp.^0.5;
            
            % convert to calcium frame times
            caTimes = fetch1(reso.Sync & key, 'frame_times');
            membership = interp1(pupilTime, membership, caTimes);
            assert(~any(isnan(membership)))
            
            tuple.membership = single(membership);
            self.insert(tuple)
        end
    end
end
