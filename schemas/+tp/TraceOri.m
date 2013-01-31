%{
tp.TraceOri (computed) # orientation tuning for traces
-> tp.Trace2
-> tp.OriDesign
-----
regr_coef      : blob   # regression coefficients, width x height x nConds
r2             : float  # pixelwise r-squared 
dof            : float  # degrees of in original signal
%}

classdef TraceOri < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.TraceOri')
        popRel = tp.Extract*tp.OriDesign
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            disp 'loading traces...'
            G = fetch1(tp.OriDesign & key, 'design_matrix');
            [X, traceKeys] = fetchn(tp.Trace & key, 'gtrace');
            X = double([X{:}]);
            fps = fetch1(tp.Align & key, 'fps');
            
            % condition signal
            X = bsxfun(@rdivide, X, mean(X));
            X = ne7.dsp.subtractBaseline(X,fps,0.03);
            X = bsxfun(@minus, X, mean(X));   % zero mean 
                                    
            % high-pass filtration
            opt = fetch(tp.CaOpt & key, '*');
            if opt.highpass_cutoff>0
                k = hamming(round(fps/opt.highpass_cutoff)*2+1);
                X = X - ne7.dsp.convmirr(X,k);
            end
            
            disp 'computing responses'
            [B,R2,~,DoF] = ne7.stats.regress(X, G, 0);
            
            % insert results
            for i=1:length(traceKeys)
                tuple = dj.struct.join(key, traceKeys(i));
                tuple.regr_coef = B(:,i);
                tuple.r2 = R2(i);
                tuple.dof = DoF(i);
                self.insert(tuple)
            end
        end
    end
end
