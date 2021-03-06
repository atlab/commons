%{
tp.FreqMap (imported) # responses to directions of full-field drifting gratings
-> tp.Sync
-> tp.CaOpt
-----
fm_cov  : longblob   # regressor covariance matrix,  nConds x nConds
fm_bmap  : longblob   # regression coefficients, width x height x nConds
fm_r2map          : longblob   # pixelwise r-squared after gaussinization 
fm_dofmap         : longblob   # degrees of in original signal, width x height
%}

classdef FreqMap < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.FreqMap')
        popRel = (pro(tp.Sync, psy.Grating, 'count(distinct temp_freq)+count(distinct spatial_freq)->n') & 'n>2')*tp.CaOpt
    end
    
    methods
        function self = FreqMap(varargin)
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
            G = tp.FreqMap.makeDesignMatrix(times, trialRel, opt);
            
            % crop only the part that contains the stimulus
            X = bsxfun(@rdivide, X, mean(X))-1;  %use dF/F
            if opt.highpass_cutoff>0
                k = hamming(round(fps/opt.highpass_cutoff)*2+1);
                X = X - ne7.dsp.convmirr(X,k);
            end
            
            disp 'computing responses'
            [B,R2,~,DoF] = ne7.stats.regress(X, G, 0);
            
            % insert results            
            tuple = key;
            tuple.fm_cov= single(G'*G);
            tuple.fm_bmap = reshape(single(B'), sz(1), sz(2),[]);
            tuple.fm_r2map = reshape(R2, sz(1:2));
            tuple.fm_dofmap = reshape(DoF, sz(1:2));
            self.insert(tuple)
        end
    end
    
    
    methods(Static)
        function G = makeDesignMatrix(times, trialRel, opt)
            alpha = @(x,a) (x>0).*x/a/a.*exp(-x/a);  % response shape
            
            % relevant trials
            trials = fetch(trialRel, 'spatial_freq+temp_freq->combo','flip_times');

            [~,~,condIdx] = unique([trials.combo]);
            
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