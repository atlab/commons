%{
tp.OriMap (imported) # responses to directions of full-field drifting gratings
-> tp.Sync
-> tp.CaOpt
-----
regressor_cov   : longblob   # regressor covariance matrix,  nConds x nConds
regr_coef_maps  : longblob   # regression coefficients, width x height x nConds
r2_map          : longblob   # pixelwise r-squared after gaussinization 
dof_map         : longblob   # degrees of in original signal, width x height
%}

classdef OriMap < dj.Relvar & dj.Automatic
    
    properties(Constant)
        table = dj.Table('tp.OriMap')
        popRel = tp.Sync*tp.CaOpt & psy.Grating
    end
    
    methods
        function self = OriMap(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)           
            disp 'loading movie...'
            times = fetch1(tp.Sync(key), 'frame_times');            
            X = getMovie(tp.Align(key),1);
            sz = size(X);
            fps = fetch1(tp.Align(key), 'fps');
            X = reshape(X,[],sz(3))';
            
            trialRel = tp.Sync(key)*psy.Trial*psy.Grating & 'trial_idx between first_trial and last_trial';
            opt = fetch(tp.CaOpt(key), '*');            
            G = tp.OriMap.makeDesignMatrix(times, trialRel, opt);
            
            % crop only the part that contains the stimulus
            X = bsxfun(@rdivide, X, mean(X))-1;  %use dF/F
            if opt.highpass_cutoff>0
                k = hamming(round(fps/opt.highpass_cutoff)*2+1);
                X = X - neurosci.dsp.convmirr(X,k);
            end
            
            disp 'computing responses'
            [B,R2,~,DoF] = neurosci.stats.regress(X, G, 0);
            
            % insert results            
            tuple = key;
            tuple.regressor_cov = single(G'*G);
            tuple.regr_coef_maps = reshape(single(B'), sz(1), sz(2),[]);
            tuple.r2_map = reshape(R2, sz(1:2));
            tuple.dof_map = reshape(DoF, sz(1:2));
            self.insert(tuple)
        end
    end
    
    
    methods(Static)
        function G = makeDesignMatrix(times, trialRel, opt)
            alpha = @(x,a) (x>0).*x/a/a.*exp(-x/a);  % response shape
            
            % relevant trials
            trials = fetch(trialRel, 'direction', 'flip_times');
            [~,~,condIdx] = unique([trials.direction]);
            
            disp 'constructing design matrix...'
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