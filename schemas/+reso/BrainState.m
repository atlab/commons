%{
reso.BrainState (computed) # brain state from patch
-> reso.Sync
-----
-> patch.CleanEphys
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
            vm = subVm(vm,fs,[4 7]);
            
            % compute oscillation amplitude using hilbert transform
            amp = abs(hilbert(vm));
            
            % filter below 0.5 Hz
            cutoff = 0.5;  % Hz
            k = hamming(round(fs/cutoff)*2+1); k = k/sum(k);
            amp = ne7.dsp.convmirr(amp,k);
            amp(isnan(cleanVm)) = nan;            
            key.brain_state_trace = amp;
            
            self.insert(key)
        end
    end
end



function vm = subVm(vm, fs, band)
% subtreshold membrane potential with spikes removed

% remove spikes
spikeIx = ne7.dsp.spaced_max(vm, 0.010*fs, -0.025);
r = ceil(0.005*fs);
for i=spikeIx
    vm(max(1, min(end, i+(-r:r)))) = mean(vm(max(1, min(end, i+[-r r]))));
end

% bandpass filter
lo = hamming(round(fs/band(1))*2+1); lo = lo/sum(lo);
hi = hamming(round(fs/band(2))*2+1); hi = hi/sum(hi);
vm = ne7.dsp.convmirr(vm,hi) - ne7.dsp.convmirr(vm,lo);
end

