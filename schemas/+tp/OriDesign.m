%{
tp.OriDesign (computed) # design matrix
-> tp.Sync
-> tp.CaOpt
-----
ndirections     : tinyint    # number of directions
design_matrix   : longblob   # times x nConds
regressor_cov   : longblob   # regressor covariance matrix,  nConds x nConds
%}

classdef OriDesign < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.OriDesign')
        popRel = (tp.Sync * tp.CaOpt) & psy.Grating
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            times = fetch1(tp.Sync(key), 'frame_times');            
            trialRel = tp.Sync(key)*psy.Trial*psy.Grating & ...
                'trial_idx between first_trial and last_trial';
            opt = fetch(tp.CaOpt(key), '*');
            G = tp.OriMap.makeDesignMatrix(times, trialRel, opt);
            
            key.ndirections = size(G,2);
            key.design_matrix = single(G);
            key.regressor_cov = single(G'*G);
            self.insert(key)
        end
    end
end
