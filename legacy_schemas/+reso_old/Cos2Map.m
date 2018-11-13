%{
reso.Cos2Map (computed) # orientation tuning maps 
-> reso.OriMap
-----
cos2_amp   : longblob   # dF/F at preferred direction 
cos2_r2    : longblob   # fraction of variance explained (after gaussinization)
cos2_fp    : longblob   # p-value of F-test (after gaussinization)
pref_ori   : longblob   # (radians) preferred direction 
%}

classdef Cos2Map < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('reso.Cos2Map')
		popRel = reso.OriMap & 'ndirections >= 4'
	end

	methods(Access=protected)

		function makeTuples(self, key)
            % check that angles are uniformly sampled
            trialRel = reso.Sync*psy.Trial*psy.Grating & key & 'trial_idx between first_trial and last_trial';
            phi = unique(fetchn(trialRel, 'direction'));
            assert(mod(length(phi),2)==0 && all(diff(diff(phi))==0), ...
                'An even number of directions must be uniformly distributed')
            
            [B, R2, dof, C] = fetch1(reso.OriMap & key, ...
                'regr_coef_maps', 'r2_map', 'dof_map', 'regressor_cov');
            assert(size(B,3) == length(phi), 'OriMap regression coeff dimension mismatch')
            sz = size(R2);
            B = reshape(B,[],length(phi));
            B = double(B);
            C = double(C);
            
            % compute cosine 2 response
            e = exp(1i*pi*phi/90)/sqrt(length(phi));
            b = B*e;
            F = real(2*b*e');    % cos2 tuning curves
            
            C = C^0.5;
            rv = sum((C*(B-F)').^2)./sum((C*B').^2);  % increase in variance due to fit
            R2 = max(0,1-rv)'.*R2(:);    % updated R-squared
            cos2DoF = 2; 
            Fp = 1-fcdf(R2.*(dof(:)-cos2DoF)/cos2DoF, cos2DoF, (dof(:)-cos2DoF));   % p-value of the F distribution
            
            key.cos2_amp = single(reshape(abs(b),sz));
            key.pref_ori = single(reshape(angle(b)/2,sz));
            key.cos2_r2  = single(reshape(R2,sz));
            key.cos2_fp    = single(reshape(Fp,sz));
			self.insert(key)
		end
	end
end
