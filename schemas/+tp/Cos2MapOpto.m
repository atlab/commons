%{
tp.Cos2MapOpto (computed) # my newest table
-> tp.OriMapOpto

-----
cos2_amp_on   : longblob   # dF/F at preferred direction, with light on 
cos2_amp_off  : longblob   # dF/F at preferred direction, with light off
cos2_r2_on    : longblob   # fraction of variance explained (after gaussinization)
cos2_r2_off   : longblob   # fraction of variance explained (after gaussinization)
cos2_fp_on    : longblob   # p-value of F-test (after gaussinization)
cos2_fp_off   : longblob   # p-value of F-test (after gaussinization)
pref_ori_on   : longblob   # (radians) preferred direction 
pref_ori_off  : longblob   # (radians) preferred direction

%}

classdef Cos2MapOpto < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.Cos2MapOpto')
        popRel = tp.OriMapOpto & 'ndirections >= 4'
    end
    
    methods
        function self = Cos2MapOpto(varargin)
            self.restrict(varargin)
        end
    end

	methods(Access = protected)

		function makeTuples(self, key)
            % check that angles are uniformly sampled
            trialRel = tp.Sync(key)*psy.Trial*psy.Grating & 'trial_idx between first_trial and last_trial';
            phi = unique(fetchn(trialRel, 'direction'));
            assert(mod(length(phi),2)==0 && all(diff(diff(phi))==0), ...
                'An even number of directions must be uniformly distributed')
            
            [B_on, R2_on, dof_on, C_on] = fetch1(tp.OriMapOpto(key), ...
                'regr_coef_maps_on', 'r2_map_on', 'dof_map_on', 'regressor_cov_on');
            [B_off, R2_off, dof_off, C_off] = fetch1(tp.OriMapOpto(key), ...
                'regr_coef_maps_off', 'r2_map_off', 'dof_map_off', 'regressor_cov_off');
            assert(size(B_on,3) == length(phi), 'OriMap regression coeff dimension mismatch')
            sz = size(R2_on);
            B_on = reshape(B_on,[],length(phi));
            B_off = reshape(B_off,[],length(phi));
            B_on = double(B_on);
            B_off = double(B_off);
            C_on = double(C_on);
            C_off = double(C_off);
            
            % compute cosine 2 response
            e = exp(1i*pi*phi/90)/sqrt(length(phi));
            b_on = B_on*e;
            b_off = B_off*e;
            F_on = real(2*b_on*e');
            F_off = real(2*b_off*e');    % cos2 tuning curves
            
            C_on = C_on^0.5;
            C_off = C_off^0.5;
            rv_on = sum((C_on*(B_on-F_on)').^2)./sum((C_on*B_on').^2);  % increase in variance due to fit
            R2_on = max(0,1-rv_on)'.*R2_on(:);    % updated R-squared
            rv_off = sum((C_off*(B_off-F_off)').^2)./sum((C_off*B_off').^2);  % increase in variance due to fit
            R2_off = max(0,1-rv_off)'.*R2_off(:);    % updated R-squared
            cos2DoF = 2; 
            Fp_on = 1-fcdf(R2_on.*(dof_on(:)-cos2DoF)/cos2DoF, cos2DoF, (dof_on(:)-cos2DoF));   % p-value of the F distribution
            Fp_off = 1-fcdf(R2_off.*(dof_off(:)-cos2DoF)/cos2DoF, cos2DoF, (dof_off(:)-cos2DoF));
            
            
            key.cos2_amp_on = single(reshape(abs(b_on),sz));
            key.cos2_amp_off = single(reshape(abs(b_off),sz));
            key.pref_ori_on = single(reshape(angle(b_on)/2,sz));
            key.pref_ori_off = single(reshape(angle(b_off)/2,sz));
            key.cos2_r2_on  = single(reshape(R2_on,sz));
            key.cos2_r2_off  = single(reshape(R2_off,sz));
            key.cos2_fp_on    = single(reshape(Fp_on,sz));
            key.cos2_fp_off    = single(reshape(Fp_off,sz));
			self.insert(key)
		end
	end
end
