%{
tp.OriMap (imported) # responses to directions of full-field drifting gratings

-> tp.OriDesign
---
ndirections                 : tinyint                       # number of directions
regressor_cov               : longblob                      # regressor covariance matrix,  nConds x nConds
regr_coef_maps              : longblob                      # regression coefficients, width x height x nConds
r2_map                      : longblob                      # pixelwise r-squared after gaussinization
dof_map                     : longblob                      # degrees of in original signal, width x height
%}

classdef OriMap < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.OriMap')
        popRel = tp.OriDesign
    end
    
    methods
        function self = OriMap(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            disp 'loading movie...'
            X = getMovie(tp.Align(key),1);
            sz = size(X);
            fps = fetch1(tp.Align(key), 'fps');
            X = reshape(X,[],sz(3))';
            
            G = fetch1(tp.OriDesign & key, 'design_matrix');
            
            X = bsxfun(@rdivide, X, mean(X))-1;  %use dF/F
            if opt.highpass_cutoff>0
                k = hamming(round(fps/opt.highpass_cutoff)*2+1);
                X = X - ne7.dsp.convmirr(X,k);
            end
            
            disp 'computing responses'
            [B,R2,~,DoF] = ne7.stats.regress(X, G, 0);
            
            % insert results
            tuple = key;
            tuple.ndirections = size(G,2);
            tuple.regressor_cov = single(G'*G);
            tuple.regr_coef_maps = reshape(single(B'), sz(1), sz(2),[]);
            tuple.r2_map = reshape(R2, sz(1:2));
            tuple.dof_map = reshape(DoF, sz(1:2));
            self.insert(tuple)
        end
    end
    
    
    methods(Static)
        function G = makeDesignMatrix(times, trialRel, opt)
            error 'replace tp.OriMap.makeDesignMatrix with tp.OriDesign.makeDesignMatrix'
        end
    end    
end
