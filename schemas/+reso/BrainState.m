%{
reso.BrainState (computed) # brain state from patch
-> reso.Sync
-----
-> patch.CleanEphys
band_low  : decimal(5,2)    # Hz
band_high : decimal(5,2)    # Hz
brain_state_trace   : longblob  # trace classifying brain states
%}

classdef BrainState < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.BrainState')
        popRel = reso.Sync & patch.CleanEphys
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            key = fetch(reso.Sync*patch.CleanEphys & key);
            assert(numel(key)==1)
            [ephysTimes, vm] = fetch1(patch.Ephys & key, 'ephys_time', 'vm');
            cleanVm = fetch1(patch.CleanEphys & key, 'vm');
            fs = 1./mean(diff(ephysTimes));
            
            % compute subtreshold membrane potential filtered to [4-7] Hz
            threshVm = -0.035;
            vm = min(vm,threshVm);
            
            % bandpass filter
            band = [4 7];
            lo = hamming(round(fs/band(1))*2+1); lo = lo/sum(lo);
            hi = hamming(round(fs/band(2))*2+1); hi = hi/sum(hi);
            vm = ne7.dsp.convmirr(vm,hi) - ne7.dsp.convmirr(vm,lo);
            
            % compute oscillation amplitude using hilbert transform
            amp = abs(hilbert(vm));
            amp(isnan(cleanVm)) = nan;
            
            % save results
            key.band_low = band(1);
            key.band_high = band(2);
            key.brain_state_trace = single(amp);
            self.insert(key)
        end
    end
end