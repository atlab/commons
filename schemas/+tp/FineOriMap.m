%{
tp.FineOriMap (imported) # my newest table
-> tp.OriDesign
-> tp.FineAlign
---
regr_coef_maps              : longblob                      # regression coefficients, width x height x nConds
r2_map                      : longblob                      # pixelwise r-squared after gaussinization
dof_map                     : longblob                      # degrees of in original signal, width x height
%}

classdef FineOriMap < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.FineOriMap')
        popRel = tp.FineAlign*tp.OriDesign
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            disp 'loading movie...'
            m = tp.utils.Movie(key);
            X = m.getFrames(1,1:m.nFrames);
            fps = fetch1(tp.Align(key), 'fps');
            sz = size(X);
            X = reshape(X,[],sz(3))';
            
            opt = fetch(tp.CaOpt & key, '*');
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
            tuple.regr_coef_maps = reshape(single(B'), sz(1), sz(2),[]);
            tuple.r2_map = reshape(R2, sz(1:2));
            tuple.dof_map = reshape(DoF, sz(1:2));
            self.insert(tuple)
        end
    end
end
