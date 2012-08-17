% function [idx,bpm] = detectHeartbeat(ekg,Fs);
% 
% Given the mouse ekg signal samples at Fs Hz, return the indices of the
% heart beats idx and (optionally) the heart rate in beats per minute at
% those indices.
%
% Dimitri Yatsenko: 2010-09-05

function [idx,bpm] = detectHeartbeat(ekg, Fs)
% low-pass filter to reduce fine noise
Fstop = 1000; % Hz
n = round(Fs/Fstop);
k = hamming(2*n+1);
x = neu.convmirr(ekg,k/sum(k));
x = x(n+1:end);
x([1:n end+(-n+1:0)]) = 0;

% highlight the R peak by subtracting from S of the QRS complex
interpeak = round(Fs*0.002); % interval between R and S peaks of the QRS complex
x=x-[x(interpeak+1:end);zeros(interpeak,1)];

% isolate peaks
maxHeartRate=25; % beats per second
idx = neu.spaced_max(x,Fs/maxHeartRate);

% threshold peaks at 70% of local maxima
thresh=0.7; q=8; n=25;
k = hamming(n); 
localMax = neu.convmirr(x(idx).^q,k/sum(k)).^(1/q);
idx = idx(x(idx)>thresh*localMax);

% if required, compute the heart rate for each index
if nargout>=2
    win=17;  % moving window to compute the median
    bpm = 60./medfilt1(gradient(idx/Fs),win);
end