%{
tp.SpikeCorrMap (imported) # correlation maps to spikes
-> common.TpPatch
-> tp.FineAlign
-> tp.CaOpt
-----
spike_corr_map  : longblob    # pixelwise correlation map

%}

classdef SpikeCorrMap < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.SpikeCorrMap')
        popRel = common.TpPatch*tp.FineAlign*tp.CaOpt
    end
    
     methods
        function self = SpikeCorrMap(varargin)
            self.restrict(varargin{:})
        end
     end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            % read voltage signal
            ne7.sys.waitForMemory(10,60);
            reader = tp.utils.Movie(key);
            disp 'reading voltage signal...'
            voltage =  reader.read(4,[],false);
            samplesPerFrame = size(voltage,1)*size(voltage,2);
            fs = fetch1(tp.Align & key, 'fps')*samplesPerFrame;
            X = permute(voltage, [2 1 3]);
            X = double(X(:));
            
            disp 'extracting spikes...'
            refractoryPeriod = 1.5/1000; %(s)
            thresh = 8; % sigma
            nonzeros = X~=0;
            X = filterSpikes(X, fs, [300 6000]);
            % robust estimate of std dev in non-zero segments
            sigma = 0.7413*iqr(X(nonzeros));
            X = bsxfun(@rdivide,X,sigma);
            spikeIdx = ne7.dsp.spaced_max(X,refractoryPeriod*fs,thresh); % threshold at thresh sigmas
            spikeTimes = spikeIdx / fs;  % spike times from the beginning
            clear X
            
            % construct calcum response
            disp 'computing pixelwise correlations...'
            alpha = @(x,a) (x>0).*x/a/a.*exp(-x/a);  % alpa response shape
            times = fetch1(tp.Sync(key), 'frame_times');
            times = times - times(1);   % calcium frame times starting with first frame
            opt = fetch(tp.CaOpt(key), '*');
            G = zeros(size(times));
            
            for iSpike = 1:length(spikeTimes)
                onset = spikeTimes(iSpike);
                switch opt.transient_shape
                    case 'onAlpha'
                        ix = find(times >= onset & times < onset+6*opt.tau);
                        G(ix) = G(ix) + alpha(times(ix)-onset,opt.tau);
                    case 'exp'
                        ix = find(times >= onset & times < onset+6*opt.tau);
                        G(ix) = G(ix) + exp((onset-times(ix))/opt.tau);
                    otherwise
                        assert(false)
                end
            end
            
            % compute pixelwise correlations
            ne7.sys.waitForMemory(8,60);
            X = reader.getFrames(1,1:reader.nFrames);
            sz = size(X);
            X = reshape(X,[],sz(3));
            C = corr(X',G');
            C = reshape(C, sz(1:2));
            
            figure
            imagesc(C)
            axis image            
            colormap gray
            colorbar 
            
            % compute correlation map
            key.spike_corr_map = C;
            self.insert(key)
            disp 'commited spike corr map'
        end
    end
end



function x = filterSpikes(x,fs,Fstop)
n1=round(fs/Fstop(1)); k1 = hamming(n1*2+1); k1=-k1/sum(k1);
n2=round(fs/Fstop(2)); k2 = hamming(n2*2+1); k2=+k2/sum(k2);
ix = n1-n2+(1:2*n2+1);
k1(ix)=k1(ix)+k2;
x = ne7.dsp.convmirr(x,k1);
end
