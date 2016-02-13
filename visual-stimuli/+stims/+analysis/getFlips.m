function [flipIdx, flipAmps] = getFlips(x, fs, frameRate)
% INPUTS:
%   x - photodiode signal
%   fs - (Hz) sampling frequency
%   frameRate (Hz) monitor frame rate

T = fs/frameRate*2;  % period of oscillation measured in samples
% filter flips
n = floor(T/4);  % should be T/2 or smaller
k = hamming(n);
k = [k;0;-k]/sum(k);
x = fftfilt(k,[double(x);zeros(n,1)]);
x = x(n+1:end);
x([1:n end+(-n+1:0)])=0;  % remove edge artifacts

% select flips
flipIdx = ne7.dsp.spaced_max(abs(x),0.22*T);
thresh = 0.15*quantile( abs(x(flipIdx)),0.99);
flipIdx = flipIdx(abs(x(flipIdx))>thresh)';
flipAmps = x(flipIdx);
end