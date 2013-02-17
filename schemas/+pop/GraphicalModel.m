%{
pop.GraphicalModel (computed) # graphical model of orientation tuning
-> pop.Segment
-> tp.Sync
-> pop.ModelOpt
-----
nneurons             : smallint  # number of neurons
nhidden              : smallint  # number of hidden units
nparams              : smallint  # total number of parameters
drives               : longblob  # cell drives
ori_drives           : longblob  # stimulus interactions (including hidden units)
cell_cell            : longblob  # pairwise interactions between cells
cell_hidden          : longblob  # pairwise interactions between cells and hidden units
mean_log_likelihood  : float     # resulting mean likelihood
delta_log_likelihood : float     # difference from complete gaussian fit
%}

classdef GraphicalModel < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('pop.GraphicalModel')
        popRel = pop.Segment * pop.ModelOpt * tp.Sync & psy.Grating & pop.Trace & 'model_opt=4'
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            % load calcium traces
            times = fetch1(tp.Sync & key, 'frame_times');
            X = fetchn(pop.Trace & key, 'gtrace');
            X = double([X{:}]);
            fps = fetch1(tp.Align & key, 'fps');
            overdispersion = max(1,fps/4);  % assume about 4 idependent samples per second
            
            % compute dF/F
            X = bsxfun(@rdivide, X, mean(X,1));
            X = ne7.dsp.subtractBaseline(X,fps,0.03);
            
            % construct stimulus design matrix
            trials = tp.Sync(key)*psy.Trial*psy.Grating & ...
                'trial_idx between first_trial and last_trial';
            trials = fetch(trials, 'direction', 'flip_times');
            opt = fetch(pop.ModelOpt & key, '*');
            caOpt = struct('transient_shape','onAlpha','highpass_cutoff',0,'latency',0,'tau',opt.ca_tau);
            S = tp.OriDesign.makeDesignMatrix(times, trials, caOpt);
            S = double(S);
            phi = (0:size(S,2)-1)/size(S,2)*2*pi;   % directions in S
            S = S*[cos(2*phi') sin(2*phi')];        % orientation responses
            S = bsxfun(@minus, S, mean(S));         % make zero-mean
            S = bsxfun(@rdivide, S, sqrt(mean(S.*S)));   % normalize
            
            % set up the population
            allowOri = opt.ori_input;
            allowHidden = opt.hidden_units>=1;
            allowHiddenOri = opt.hidden_units>=2;
            
            models = init(camo.GaussGraph(1024), ...
                X, S, overdispersion, ...
                allowOri, allowHidden, allowHiddenOri);
            
            models = models.evolve(200);
            
            self.insert(key)
        end
    end
end
