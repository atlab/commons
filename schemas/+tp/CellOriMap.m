%{
tp.CellOriMap (computed) # compute orientation tuning for each segmented cell, under the condition of both LED light on and off
-> tp.CaOpt
-> tp.Sync
-> tp.Trace

-----

cft_bmat_on   : blob   # regression coeffients, nConds, for LED stimulus on
cft_bmat_off  : blob   # regression coeffients, nConds, for LED stimulus off
cft_r2_on     : float  # single value of r-squared, for LED stimulus on
cft_r2_off    : float  # single value of r-squared, for LED stimulus off
cft_pvalue_on : float  # p value of the regression, for LED stimulus on
cft_pvalue_off: float  # p value of the regression, for LED stimulus off


%}

classdef CellOriMap < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.CellOriMap')
        popRel = tp.Sync * tp.CaOpt * tp.SegOpt & tp.Trace & 'tau=1.5';
	end

	methods
		function self = CellOriMap(varargin)
			self.restrict(varargin)
		end
	end
    
    methods(Access=protected)

		function makeTuples(self, key)
		disp 'loading movie...'
            t = fetch1(tp.Sync(key), 'frame_times');
            trialRel_on = tp.Sync(key)*psy.Trial*psy.Grating & 'second_photodiode=1' & 'trial_idx between first_trial and last_trial';
            trialRel_off = tp.Sync(key)*psy.Trial*psy.Grating & 'second_photodiode=-1' & 'trial_idx between first_trial and last_trial';
            trials_on = fetch(trialRel_on,'flip_times');
            trials_off = fetch(trialRel_off,'flip_times');
            opt = fetch(tp.CaOpt(key), '*');
            [traces, keys] = fetchn(tp.Trace & key, 'gtrace');
            traces = [traces{:}];
            
            % convert to dF/F
            traces = bsxfun(@rdivide, traces, mean(traces))-1;
            
            % apply mask on the traces
            mask = fetch1(tp.FrameMask(key), 'frame_mask');
            mask = logical(mask);
            traces = traces(mask,:);
            t = t(mask);
            % generate design matrix
            G_on = tp.CellOriMap.makeDesignMatrix(t,trialRel_on,opt,false);
            G_off = tp.CellOriMap.makeDesignMatrix(t,trialRel_off,opt,false);
            
            % regression
            disp 'regression...'
            [B_on,R2_on] = ne7.stats.regress(traces, G_on, 0);
            [B_off,R2_off] = ne7.stats.regress(traces, G_off, 0);
            
            % calculating p value by sampling
            disp 'calculating p value...'
            nShuffles = 1000;
            pvalue_on = .5*ones(1,length(keys));
            pvalue_off = .5*ones(1,length(keys));
            tic
            for ii = 1:nShuffles
                G_on = tp.CellOriMap.makeDesignMatrix(t,trialRel_on,opt,true);
                G_off = tp.CellOriMap.makeDesignMatrix(t,trialRel_off,opt,true);
                [~,R2_on_shuffled] = ne7.stats.regress(traces,G_on,0);
                [~,R2_off_shuffled] = ne7.stats.regress(traces,G_off,0);
                pvalue_on = pvalue_on + (R2_on<=R2_on_shuffled);
                pvalue_off = pvalue_off + (R2_off<=R2_off_shuffled);
            end
            pvalue_on = pvalue_on/(nShuffles + .5);
            pvalue_off = pvalue_off/(nShuffles + .5);
            toc
            % insert results
            for i=1:length(keys)
                tuple = dj.struct.join(keys(i),key);
                tuple.cft_bmat_on  = single(B_on(:,i));
                tuple.cft_bmat_off = single(B_off(:,i));
                tuple.cft_r2_on = R2_on(i);
                tuple.cft_r2_off = R2_off(i);
                tuple.cft_pvalue_on = pvalue_on(i);
                tuple.cft_pvalue_off = pvalue_off(i);
                self.insert(tuple);
            end                
		end
    end
    
    
    methods(Static)
        function G = makeDesignMatrix(times, trials, opt, doShuffle)
            % compute the directional tuning design matrix with a separate
            % regressor for each direction.  
            
            alpha = @(x,a) (x>0).*x/a/a.*exp(-x/a);  % response shape
            
            % relevant trials
            if ~isstruct(trials)
                trials = fetch(trials, 'direction', 'flip_times');
            end
            [~,~,condIdx] = unique([trials.direction]);
            
            if doShuffle
                condIdx = condIdx(randperm(end));
            end
            
            
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