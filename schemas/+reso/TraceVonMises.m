%{
reso.TraceVonMises (computed) # VonMises tuning fits for traces
-> reso.Sync
-> reso.Trace
-> reso.CaOpt

-----
von_r2    : double  # fraction of variance explained (after gaussinization)
von_fp    : double  # p-value of F-test
sharpness : float   # tuning sharpness
pref_dir  : float   # (radians) preferred direction
peak_amp1 : float   # dF/F at preferred direction
peak_amp2 : float   # dF/F at opposite direction
von_base  : float   # dF/F base
nshuffles : int     # number of shuffles used in
shuffle_p : float   # p-value computed by shuffle
%}

classdef TraceVonMises < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.TraceVonMises')
        popRel = reso.Segment*reso.OriDesign & reso.Trace
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            times = fetch1(reso.Sync & key, 'frame_times');
            opt = fetch(reso.CaOpt & key, '*');
            
            % check that angles are uniformly sampled
            trialRel = reso.Sync*psy.Trial*psy.Grating & key ...
                & 'trial_idx between first_trial and last_trial';
            phi = unique(fetchn(trialRel, 'direction'));
            assert(mod(length(phi),2)==0 && all(diff(diff(phi))==0), ...
                'An even number of grating directions must be uniformly distributed.')
            
            % load and condition traces
            fps = fetch1(reso.ScanInfo & key, 'fps');
            [X, traceKeys] = fetchn(reso.Trace & key, 'ca_trace');
            X = double([X{:}]);
            X = bsxfun(@rdivide, X, mean(X));
            X = ne7.dsp.subtractBaseline(X,fps,0.03);
            X = bsxfun(@minus, X, mean(X));
            
            % linear regression & von Mises fit
            trials = fetch(trialRel, 'direction', 'flip_times');
            [von,R2,Fp] = regress(times, X, trials, opt);
            
            % compute significance by shuffling
            nShuffles = 1e4;
            p = 0.5/nShuffles;  % pvalues
            for iShuffle = 1:nShuffles
                if ~mod(iShuffle,200)
                    fprintf .
                end
                trials = arrayfun(@(x,y) struct('flip_times',x.flip_times,'direction',y.direction), trials, trials(randperm(end)));
                [~,R2_] = regress(times, X, trials, opt);
                p = p + (R2_ >= R2)/nShuffles;
            end
            fprintf \n
            
            for i=1:length(traceKeys)
                tuple = dj.struct.join(key,traceKeys(i));
                tuple.von_r2    = R2(i);
                tuple.von_fp    = Fp(i);
                tuple.pref_dir  = von.w(i,5);
                tuple.sharpness = von.w(i,4);
                tuple.peak_amp1 = von.w(i,2);
                tuple.peak_amp2 = von.w(i,3);
                tuple.von_base  = von.w(i,1);
                tuple.nshuffles = nShuffles;
                tuple.shuffle_p = p(i);
                self.insert(tuple)
            end
        end
    end
end


function [von, R2, Fp] = regress(times, X, trials, opt)
G = reso.OriDesign.makeDesignMatrix(times, trials, opt);
C = G'*G;

[B,R2,~,dof] = ne7.stats.regress(X, G, 0);
von = fit(ne7.rf.VonMises2, B);
F = von.compute(von.phi);  % fitted tuning curves
C = C^0.5;
rv = sum((C*(B-F')).^2)./sum((C*B).^2);  % fraction increase in variance due to fit
R2 = max(0,1-rv)'.*R2(:);   % update R2 for the fit
vonDoF = 5;   % degrees of freedom in the von Mises curve
Fp = 1-fcdf(R2.*(dof(:)-vonDoF)/vonDoF, vonDoF, (dof(:)-vonDoF));   % p-value of the F distribution
end