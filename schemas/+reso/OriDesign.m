%{
reso.OriDesign (computed) # design matrix
-> reso.Sync
-> reso.CaOpt
-----
ndirections     : tinyint    # number of directions
design_matrix   : longblob   # times x nConds
regressor_cov   : longblob   # regressor covariance matrix,  nConds x nConds
%}

classdef OriDesign < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.OriDesign')
        popRel = (reso.Sync * reso.CaOpt) & (reso.Sync*psy.Grating);
    end
    
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            times = fetch1(reso.Sync & key, 'frame_times');
            opt = fetch(reso.CaOpt & key, '*');
            trialRel = reso.Sync*psy.Trial*psy.Grating & ...
                'trial_idx between first_trial and last_trial';
            disp 'constructing design matrix...'
            G = reso.OriDesign.makeDesignMatrix(times, trialRel, opt);
            
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
