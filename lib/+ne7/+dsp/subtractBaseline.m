function y = subtractBaseline(x, fs, bandwidth)
% removes the baseline from the dF/F signal x. 
% The baseline is esimated robustly by discounting positive outliers.
%
% INPUTS:
%  x   -  a columnwise array of signals 
%  fs  -  (Hz) the sampling rate of x
%  bandwidth - (Hz)  the bandwidth of the baseline


k = hamming(round(fs/bandwidth)*2+1);
k = k/sum(k);
zthresh = 1.0;
y = double(x);
for iter = 1:15
    s = ne7.dsp.convmirr(y,k);
    d = y - s;
    negSigma = sqrt(sum(min(0,d.^2))/sum(d<0));    % stddev of negative outliers
    zscore = bsxfun(@rdivide, d, negSigma);
    d = (d + d.*(zscore<zthresh))/2;  % cut positive outliers in half
    y = s + d;
end
s = ne7.dsp.convmirr(y,k);
y = x - s;
