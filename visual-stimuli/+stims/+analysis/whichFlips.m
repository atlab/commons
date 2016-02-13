function [flipIdx, flipNums] = whichFlips(x, fs, fps)
% given a photodiode signal x with sampling rate fs, decode photodiode
% flips numbers.  The monitor frame rate is fps.
%
% returns:
% flipIdx: the indices of the detected flips in x and their encoded
% flipNums: the sequential numbers of the detected indices

[flipIdx, flipAmps] = stims.analysis.getFlips(x, fs, fps);
flipNums = stims.analysis.flipAmpsToNums(flipAmps);
end
