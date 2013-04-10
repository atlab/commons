%{
tp.CellSpeedTuning (computed) # compute the regression of the speed tuning
-> tp.CaOpt
-> tp.Sync
-> tp.Trace

-----
cst_b: blob  # regression coeffients, nConds
cst_r2: float  # single value of r-squared
cst_pvalue: float # p value of the regression

%}

classdef CellSpeedTuning < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.CellSpeedTuning')
        popRel = tp.Sync * tp.CaOpt * tp.SegOpt & tp.Trace & 'tau=1.5';
    end
    
    methods
		function self = CellSpeedTuning(varargin)
			self.restrict(varargin)
		end
	end
    
    methods(Access=protected)

		function makeTuples(self, key)
            disp 'loading movie...'
            t = fetch1(tp.Sync(key), 'frame_times');
            trialRel = tp.Sync(key)*psy.Trial*psy.Grating & 'trial_idx between first_trial and last_trial';
            trials = fetch(trialRel, 'temp_freq/spatial_freq->speed','flip_times');
            opt = fetch(tp.CaOpt(key), '*');
            [traces, keys] = fetchn(tp.Trace & key, 'gtrace');
            traces = [traces{:}];
            
            % convert to dF/F
            traces = bsxfun(@rdivide, traces, mean(traces))-1;
            % generate design matrix
            G = tp.CellSpeedTuning.makeDesignMatrix(t,trials,opt,false);
            
            % regression
            disp 'regression...'
            [B,R2] = ne7.stats.regress(traces, G, 0);
            
            % calculating p value by sampling
            disp 'calculating p value...'
            nShuffles = 10000;
            pvalue = .5*ones(1,length(keys));
            tic
            for ii = 1:nShuffles
                G = tp.CellSpeedTuning.makeDesignMatrix(t,trials,opt,true);
                [~,R2_shuffled] = ne7.stats.regress(traces,G,0);
                pvalue = pvalue + (R2<=R2_shuffled);
            end
            pvalue = pvalue/(nShuffles + .5);
            toc
            % insert results
            disp 'saving data...'
            for i=1:length(keys)
                tuple = dj.struct.join(keys(i),key);
                tuple.cst_b  = single(B(:,i));
                tuple.cst_r2 = R2(i);
                tuple.cst_pvalue = pvalue(i);
                self.insert(tuple);
            end                
		end
    end
    
    
    methods(Static)
    
        function G = makeDesignMatrix(t, trials, opt, doShuffle)
        % t is the time course of the entire movie when the stimulus is shown
        % trialRel, relavant trials
        % opt is the calcium option
        % G: design matrix, t x Conds
        
            % response shape, alpha function
            alpha = @(x,a) (x>0).*x/a/a.*exp(-x/a);
                     
            [~,~,condIdx] = unique([trials.speed]);
            
            if doShuffle
                condIdx = condIdx(randperm(end));
            end
            
            G = zeros(length(t), length(unique(condIdx)), 'single');
            
            for iTrial = 1:length(trials)
                      
                trial = trials(iTrial);
                onset = trial.flip_times(2);  % second flip is the start of the drifting phase
                offset = trial.flip_times(end);
                switch opt.transient_shape
                    case 'onAlpha'
                        idx = find(t >= onset & t < onset+6*opt.tau);
                        G(idx, condIdx(iTrial)) = G(idx, condIdx(iTrial)) ...
                            + alpha(t(idx)-onset,opt.tau)';
                    case 'exp'
                        idx = find(t>=onset & t < offset);
                        G(idx, condIdx(iTrial)) = G(idx, condIdx(iTrial)) ...
                            + 1 - exp((onset-t(idx))/opt.tau)';
                        idx = find(t>=offset & t < offset+5*opt.tau);
                        G(idx, condIdx(iTrial)) = G(idx, condIdx(iTrial)) ...
                            + (1-exp((onset-offset)/opt.tau))*exp((offset-t(idx))/opt.tau)';
                    otherwise
                        assert(false)
                end
            end
            
        
        end
            
    end
end