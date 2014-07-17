%{
reso.AxonEffect (computed) # effect of indicator on axon activity
-> reso.IndicatorSet
-> reso.Axons
-> reso.Effect
-----
effect_size         : float     #  effect size
effect_p            : float     #  statistical significance per cell
nshuffles           : smallint  # number of shuffles in the permutation test
%}

classdef AxonEffect < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = reso.IndicatorSet * reso.Axons * reso.Effect
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            effect = fetch(reso.Effect & key, '*');
            trace = fetch1(reso.Axons & key, 'axon_trace');
            
            switch effect.analysis
                case 'active * quiet'
                    ind1 = fetch1(reso.Indicator & key & 'condition_num=3','indicator');
                    ind2 = fetch1(reso.Indicator & key & 'condition_num=4','indicator');
                case 'dilation * constriction & quiet'
                    ind1 = fetch1(reso.Indicator & key & 'condition_num=1','indicator');
                    ind2 = fetch1(reso.Indicator & key & 'condition_num=2','indicator');
                otherwise
                    error('Unknown effect name "%s"', effect.analysis)
            end
            
            a1 = mean(double(trace(ind1)));
            a2 = mean(double(trace(ind2)));
            
            key.effect_size = single(a1-a2);
            
            % shuffle test
            key.nshuffles = 10000;
            key.effect_p = 0.5/key.nshuffles;
            for iShuffle=1:key.nshuffles
                if ~mod(iShuffle,500), fprintf .,  end
                ind1_ = ind1;
                ind2_ = ind2;
                for iSplit=1:4
                    split = randi(floor(length(ind1)/2))+floor(length(ind1)/4);
                    ind1_ = [ind1_(split+1:end); ind1_(1:split)];
                    ind2_ = [ind2_(split+1:end); ind2_(1:split)];
                end
                
                a1 = mean(double(trace(ind1_)));
                a2 = mean(double(trace(ind2_)));
                effectSize = single(a1-a2);
                key.effect_p = key.effect_p + (abs(effectSize)>=abs(key.effect_size))/key.nshuffles;
            end
            fprintf \n
            
            self.insert(key)
        end
    end
    
end