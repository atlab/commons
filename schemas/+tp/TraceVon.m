%{
tp.TraceVon (computed) # VonMises tuning fits for traces
-> tp.TraceOri

-----
von_r2    : double  # fraction of variance explained (after gaussinization)
von_fp    : double  # p-value of F-test (after gaussinization)
sharpness : float   # tuning sharpness 
pref_dir  : float   # (radians) preferred direction 
peak_amp1 : float   # dF/F at preferred direction 
peak_amp2 : float   # dF/F at opposite direction
von_base  : float   # dF/F base

%}

classdef TraceVon < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.TraceVon')
		popRel = tp.Extract*tp.OriDesign & tp.TraceOri 
	end

	methods(Access=protected)

		function makeTuples(self, key)
            % check that angles are uniformly sampled
            trialRel = tp.Sync(key)*psy.Trial*psy.Grating ...
                & 'trial_idx between first_trial and last_trial';
            phi = unique(fetchn(trialRel, 'direction'));
            assert(mod(length(phi),2)==0 && all(diff(diff(phi))==0), ...
                'An even number of grating directions must be uniformly distributed.')
            
            C = fetch1(tp.OriDesign & key, 'regressor_cov');
            [B, R2, dof, traceKeys] = fetchn(tp.TraceOri & key, 'regr_coef', 'r2', 'dof');
            B = [B{:}];
            B = B';
            assert(size(B,2) == length(phi), 'OriMap regression coeff dimension mismatch')
            von = fit(ne7.rf.VonMises2, B');
            F = von.compute(von.phi);  % fitted tuning curves
            C = C^0.5;
            rv = sum((C*(B-F)').^2)./sum((C*B').^2);  % fraction increase in variance due to fit
            R2 = max(0,1-rv)'.*R2(:);   % update R2 for the fit            
            vonDoF = 5;   % degrees of freedom in the von Mises curve            
            Fp = 1-fcdf(R2.*(dof(:)-vonDoF)/vonDoF, vonDoF, (dof(:)-vonDoF));   % p-value of the F distribution
            
            
            for i=1:length(traceKeys)
                tuple = dj.struct.join(traceKeys(i), key);
                tuple.von_r2    = R2(i);
                tuple.von_fp    = Fp(i);
                tuple.pref_dir  = von.w(i,5);
                tuple.sharpness = von.w(i,4);
                tuple.peak_amp1 = von.w(i,2);
                tuple.peak_amp2 = von.w(i,3);
                tuple.von_base  = von.w(i,1);
                self.insert(tuple)
            end
		end
	end
end
