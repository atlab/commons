%{
tp.VonMap (computed) # my newest table
-> tp.OriMap
-----
von_r2    : longblob   # fraction of variance explained (after gaussinization)
von_fp    : longblob   # p-value of F-test (after gaussinization)
sharpness : longblob   # tuning sharpness 
pref_dir  : longblob   # (radians) preferred direction 
peak_amp1 : longblob   # dF/F at preferred direction 
peak_amp2 : longblob   # dF/F at opposite direction
von_base  : longblob   # dF/F base
%}

classdef VonMap < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('tp.VonMap')
		popRel = tp.OriMap
	end

	methods
		function self = VonMap(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            
            % check that angles are uniformly sampled
            trialRel = tp.Sync(key)*psy.Trial*psy.Grating & 'trial_idx between first_trial and last_trial';
            phi = unique(fetchn(trialRel, 'direction'));
            assert(length(phi)>=8 && mod(length(phi),2)==0 && all(diff(diff(phi))==0), ...
                'the grating experiment did not provide sufficient angles for von Mises fit')
            
            [B, R2, dof, C] = fetch1(tp.OriMap(key), ...
                'regr_coef_maps', 'r2_map', 'dof_map', 'regressor_cov');
            assert(size(B,3) == length(phi), 'OriMap regression coeff dimension mismatch')
            sz = size(R2);
            B = reshape(B,[],length(phi));
            von = fit(neurosci.rf.VonMises2, B');
            F = von.compute(von.phi);  % fitted tuning curves
            C = C^0.5;
            rv = sum((C*(B-F)').^2)./sum((C*B').^2);  % fraction increase in variance due to fit
            R2 = max(0,1-rv)'.*R2(:);   % update R2 for the fit            
            vonDoF = 5;   % degrees of freedom in the von Mises curve            
            Fp = 1-fcdf(R2.*(dof(:)-vonDoF)/vonDoF, vonDoF, (dof(:)-vonDoF));   % p-value of the F distribution
            
            key.von_r2    = single(reshape(R2,sz));
            key.von_fp    = single(reshape(Fp,sz));
            key.pref_dir  = single(reshape(von.w(:,5),sz));
            key.sharpness = single(reshape(von.w(:,4),sz));
            key.peak_amp1 = single(reshape(von.w(:,2),sz));
            key.peak_amp2 = single(reshape(von.w(:,3),sz));
            key.von_base  = single(reshape(von.w(:,1),sz));
			self.insert(key)
		end
	end
end
