%{
pupil.OriDesign (computed) # Orientation tuning design matrix parameterized with pupil phase
-> reso.Sync
-> pupil.Phase
-> pupil.CaOpt
---
-> patch.Eye
ndirections                 : tinyint                       # number of directions
modulation                  : longblob                      # stimulus modulation by pupil and behavior
design_matrix               : longblob                      # times x nConds
regressor_cov               : longblob                      # regressor covariance matrix,  nConds x nConds
%}

classdef OriDesign < dj.Relvar & dj.AutoPopulate
    properties
        popRel = (reso.Sync*pupil.Phase*pupil.CaOpt) & patch.Eye & psy.Grating
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            key = fetch(reso.Sync*patch.Recording*pupil.Phase*pupil.CaOpt & key);
            
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
            
            % condition the design matrix on
            phaseOpt = fetch(pupil.Phase & key, '*');
            phase1 = phaseOpt.central_phase - phaseOpt.phase_window/2;
            phase2 = phaseOpt.central_phase + phaseOpt.phase_window/2;
            assert(phase1 < phase2 && phase1>=0 && phase1<=1 && phase2>=0 && phase2<=1) % take care of the rollover when needed
            modulation = mod(pupilPhase,1) > phase1 & mod(pupilPhase,1) <= phase2 & ~isRunning;
            assert(mean(modulation)>0.25, 'less than 25% of the data qualified')
            modulation = modulation.*pupilAmp.^0.5;
            
            % load stimulus information and construct the design matrix
            caTimes = fetch1(reso.Sync & key, 'frame_times');
            opt = fetch(pupil.CaOpt & key, '*');
            trialRel = reso.Sync*psy.Trial*psy.Grating & key & ...
                'trial_idx between first_trial and last_trial';
            disp 'constructing design matrix...'
            G = pupil.OriDesign.makeDesignMatrix(caTimes, trialRel, opt);
            
            % apply modulation
            modulation = interp1(pupilTime, modulation, caTimes);
            assert(~any(isnan(modulation)))
            G = bsxfun(@times, G, modulation');
            G = bsxfun(@minus, G, mean(G));
            
            key.modulation = single(modulation);
            key.ndirections = size(G,2);
            key.design_matrix = single(G);
            key.regressor_cov = single(G'*G);
            self.insert(key)
        end
    end
    
    
    methods(Static)
        function G = makeDesignMatrix(times, trials, opt)
            % compute the directional tuning design matrix with a separate
            % regressor for each direction.
            
            alpha = @(x,a) (x>0).*x/a/a.*exp(-x/a);  % response shape
            
            % relevant trials
            if ~isstruct(trials)
                trials = fetch(trials, 'direction', 'flip_times');
            end
            [~,~,condIdx] = unique([trials.direction]);
            
            G = zeros(length(times), length(unique(condIdx)), 'single');
            for iTrial = 1:length(trials)
                trial = trials(iTrial);
                onset = trial.flip_times(2);  % second flip is the start of the drifting phase
                offset = trial.flip_times(end);
                switch opt.transient_shape
                    case 'onAlpha'
                        ix = find(times >= onset & times < onset+6*opt.tau);
                        G(ix, condIdx(iTrial)) = G(ix, condIdx(iTrial)) ...
                            + alpha(times(ix)-onset,opt.tau)';
                    case 'exp'
                        ix = find(times>=onset & times < offset);
                        G(ix, condIdx(iTrial)) = G(ix, condIdx(iTrial)) ...
                            + 1 - exp((onset-times(ix))/opt.tau)';
                        ix = find(times>=offset & times < offset+5*opt.tau);
                        G(ix, condIdx(iTrial)) = G(ix, condIdx(iTrial)) ...
                            + (1-exp((onset-offset)/opt.tau))*exp((offset-times(ix))/opt.tau)';
                    otherwise
                        assert(false)
                end
            end
        end
    end
end
