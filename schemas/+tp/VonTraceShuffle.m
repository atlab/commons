%{
tp.VonTraceShuffle (computed) # Von Mises tuning with resampling
-> tp.Sync
-> tp.Trace
-> tp.CaOpt
-----
vt_pref  : float   # (radians) preferred direction
vt_base  : float   # von Mises base value
vt_sharp : float   # sharpness
vt_amp1  : float   # amplitude at preferred direction
vt_amp2  : float   # amplitude at opposite direction
vt_r2    : float   # variance explained
vt_p     : float   # p-value of variance explained (shuffle test)
nshuffles: float   # the number of shuffles used to compute p-value
%}

classdef VonTraceShuffle < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table  = dj.Table('tp.VonTraceShuffle')
        popRel = pro(tp.Sync*tp.CaOpt & tp.Trace, psy.Grating, 'count(distinct direction)->ndirections') & 'ndirections>=8'
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            
            % fetch traces
            times = fetch1(tp.Sync(key), 'frame_times');
            
            [X,keys] = fetchn(tp.Trace & key, 'gtrace');
            X = double([X{:}]);
            fps = fetch1(tp.Align & key, 'fps');
            
            % condition traces
            X = bsxfun(@rdivide, X, mean(X));
            X = ne7.dsp.subtractBaseline(X,fps,0.03);
            
            % fetch stimulus information
            trials = tp.Sync(key)*psy.Trial*psy.Grating & ...
                'trial_idx between first_trial and last_trial';
            trials = fetch(trials, 'direction', 'flip_times');
            opt = fetch(tp.CaOpt(key), '*');
            
            [r2, pref, base, sharp, amp1, amp2] = tp.VonTraceShuffle.regress(times,X,trials,opt);
            pvalue = 0.5;
            nshuffles = 1e4;
            for i=1:nshuffles
                if ~mod(sqrt(i),1)
                    fprintf('shuffles %4d/%4d\n', i, nshuffles);
                end
                pvalue = pvalue + (r2 <= tp.VonTraceShuffle.regress(times,X,trials(randperm(end)),opt));
            end
            pvalue = pvalue/(nshuffles+0.5);
            
            for i=1:length(keys)
                tuple = keys(i);
                tuple.vt_pref = pref(i);
                tuple.vt_base = base(i);
                tuple.vt_sharp = sharp(i);
                tuple.vt_amp1 = amp1(i);
                tuple.vt_amp2 = amp2(i);
                tuple.vt_r2   = r2(i);
                tuple.vt_p = pvalue(i);
                self.insert(tuple);
            end                
        end
    end
    
    methods(Static)
        function [r2,pref, base, sharp, amp1, amp2] = regress(times,X,trials,opt)
            G = tp.OriDesign.makeDesignMatrix(times, trials, opt);
            G = bsxfun(@minus, G, mean(G));
            B = ne7.stats.regress(X, G, 0);
            von = fit(ne7.rf.VonMises2, B);
            F = von.compute(von.phi);
            r2 = 1-sum((X-G*F').^2)./sum(X.^2);
            if nargout>1
                base = von.w(:,1);
                amp1 = von.w(:,2);
                amp2 = von.w(:,3);
                sharp= von.w(:,4);
                pref = von.w(:,5);
            end
        end
    end
end
