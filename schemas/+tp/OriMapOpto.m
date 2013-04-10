%{
tp.OriMapOpto (imported) # pixelwised orientation tuning with optogenetic manipulations
-> tp.CaOpt
-> tp.Sync

-----
ndirections                 : tinyint                       # number of directions
regressor_cov_on            : longblob                      # regressor covariance matrix, for light on trials,  nConds x nConds
regressor_cov_off           : longblob                      # regressor covariance matrix, for light off tirals, nconds x nConds
regr_coef_maps_on           : longblob                      # regression coefficients, for light on trials,  width x height x nConds
regr_coef_maps_off          : longblob                      # regression coefficients, for light off trials, width x height x nConds
r2_map_on                   : longblob                      # pixelwise r-squared after gaussinization, for light on trials
r2_map_off                  : longblob                      # pixelwise r-squared after gaussinization, for light off trials
dof_map_on                  : longblob                      # degrees of in original signal, width x height, with light on
dof_map_off                 : longblob                      # degrees of in original signal, width x height, with light off

%}

classdef OriMapOpto < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.OriMapOpto')
        popRel = (tp.Sync * tp.CaOpt) & psy.Grating & 'tau=1.5'
    end
    
    methods
        function self = OriMapOpto(varargin)
            self.restrict(varargin)
        end
    end

	methods(Access = protected)

		function makeTuples(self, key)
            times = fetch1(tp.Sync(key), 'frame_times');
            % apply mask on the times
            mask = fetch1(tp.FrameMask(key), 'frame_mask');
            mask = logical(mask);
            times = times(mask);
            
            opt = fetch(tp.CaOpt(key), '*');
            trialRel_on = tp.Sync(key)*psy.Trial*psy.Grating & 'second_photodiode=1' & 'trial_idx between first_trial and last_trial';
            trialRel_off = tp.Sync(key)*psy.Trial*psy.Grating & 'second_photodiode=-1' & 'trial_idx between first_trial and last_trial';
            disp 'constructing design matrix'
            G_on = tp.OriMapOpto.makeDesignMatrix(times, trialRel_on, opt);
            G_off = tp.OriMapOpto.makeDesignMatrix(times, trialRel_off, opt);
            
            disp 'loading movie...'
            X = getMovie(tp.Align(key),1);
            X = X(:,:,mask);
            sz = size(X);
            fps = fetch1(tp.Align(key), 'fps');
            X = reshape(X,[],sz(3))';
            
            X = bsxfun(@rdivide, X, mean(X))-1;  %use dF/F
            opt = fetch(tp.CaOpt & key, '*');
            if opt.highpass_cutoff>0
                k = hamming(round(fps/opt.highpass_cutoff)*2+1);
                X = X - ne7.dsp.convmirr(X,k);
            end
            
            disp 'computing responses'
            [B_on,R2_on,~,DoF_on] = ne7.stats.regress(X, G_on, 0);
            [B_off,R2_off,~,DoF_off] = ne7.stats.regress(X, G_off, 0);
            
            % insert results
            tuple = key;
            tuple.ndirections = size(G_on,2);
            tuple.regressor_cov_on = single(G_on'*G_on);
            tuple.regressor_cov_off = single(G_off'*G_off);
            tuple.regr_coef_maps_on = reshape(single(B_on'), sz(1), sz(2),[]);
            tuple.regr_coef_maps_off = reshape(single(B_off'), sz(1), sz(2),[]);
            tuple.r2_map_on = reshape(R2_on, sz(1:2));
            tuple.r2_map_off = reshape(R2_off, sz(1:2));
            tuple.dof_map_on = reshape(DoF_on, sz(1:2));
            tuple.dof_map_off = reshape(DoF_off, sz(1:2));
            self.insert(tuple)
                        
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
