% function spikeTimes = detectMuaSpikes(X, Fs)
% extract spikes from a single electrode or multielectrode recordings
%
% INPUTS:
%    X: columnwise signal (single or multiple channels)
%    Fs: (Hz) sampling rate of X
%
% OUTPUTS:
%    spikeTimes: (s) times from the first sample
%    spikeIdx: indices of spikes in X
%    X is the filtered version of the input signal
%
% 2010-09-05  Dimitri Yatsenko

function [spikeTimes,spikeIdx,X] = detectMuaSpikes(X, Fs)
refractoryPeriod = 1.5/1000; %(s)
thresh = 8; % sigma

X = filterSpikes(X, Fs);
Z = bsxfun(@rdivide,X,0.7413*iqr(X));  % normalize by robust standard deviation
Z = sqrt(sum(Z.^2,2)/size(Z,2));       % collapse channels into one signal
spikeIdx = ne7.dsp.spaced_max(Z,refractoryPeriod*Fs,thresh); % threshold at thresh sigmas

spikeTimes = (spikeIdx-1)/Fs;     % convert to ms
end 



function x = filterSpikes(x,Fs,Fstop)
if nargin<3
    Fstop = [300 6000];  % Hz
end
n1=round(Fs/Fstop(1)); k1 = hamming(n1*2+1); k1=-k1/sum(k1);
n2=round(Fs/Fstop(2)); k2 = hamming(n2*2+1); k2=+k2/sum(k2);
k1(n1-n2+(1:2*n2+1))=k1(n1-n2+(1:2*n2+1))+k2;
x = ne7.dsp.convmirr(x,k1);
end