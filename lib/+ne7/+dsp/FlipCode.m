classdef FlipCode
    
    properties(Constant)
        frameRate = 60    % Hz
    end
    
    methods(Static)      
        function [times, psyId] = synch(signal, fs, djTrials)
            % given the photodiode signal sampled at fs Hz, returns the times
            % of each time sample in signal in the timeframe of the matching trials
            % in the djTrial table. This is still work in progress and will be
            % significantly improved and documented.
            % DY: 2011-07-02
            
            % all times are in seconds
            
            requiredFlips = 200;
            maxDiscrepancy = 0.0075;  % (s) - this may be heigh because of slow time constants of LCD monitors
            
            times = [];
            psyId = nan;
            
            % identify some flips in the photodiode channel
            [flipIdx, flipNums] = ne7.dsp.FlipCode.whichFlips(double(signal), fs);
            assert( sum(~isnan(flipNums))>=requiredFlips, 'insufficient decoded flips. Uncoded photodiode flips?');
            djTrials = djTrials & ...
                sprintf('last_flip_count>=%d and last_flip_count<=%d', min(flipNums), max(flipNums));
            if djTrials.count
                [psyId, lastFlipCount,trialFlipTimes] = djTrials.fetchn('psy_id', 'last_flip_count', 'flip_times');
                assert(all(psyId == psyId(1)), 'Multiple PsySessions in scan: not allowed. Skipping.');
                [lastFlipCount, order] = sort(lastFlipCount);
                trialFlipTimes = trialFlipTimes(order);
                psyId = psyId(1);
                trialFlipNums = [];
                for i=1:length(lastFlipCount)
                    trialFlipNums = [trialFlipNums  lastFlipCount(i)+(1-length(trialFlipTimes{i}):0)]; %#ok<AGROW>
                end
                trialFlipTimes = [trialFlipTimes{:}];
                assert(length(trialFlipTimes)==length(trialFlipNums));
                
                % the following line needed to be introduced after the stimulus change on Feb. 14, 2013.
                % Stimuli recorded before then should be processed without
                % this line.
                flipNums = flipNums - 1;
                
                % fit times from the trial table to detected flips
                commonFlipNums = intersect(flipNums, trialFlipNums);
                if length(commonFlipNums)<requiredFlips
                    warning 'Insufficient matched flips'
                else
                    % assumes uninterrupted uniform sampling of photodiode!!!
                    matchedFlipIdx = flipIdx(ismember(flipNums,commonFlipNums));
                    matchedFlipTimes = trialFlipTimes(ismember(trialFlipNums,commonFlipNums));
                    mx = mean(matchedFlipIdx);
                    b = robustfit(matchedFlipIdx-mx, matchedFlipTimes);
                    times = ((1:length(signal))-mx)*b(2)+b(1);
                    
                    if quantile(abs(matchedFlipTimes - times(matchedFlipIdx)),0.9) > maxDiscrepancy
                        warning 'incorrectly detected flips'
                        times = [];
                    end
                end
            end
        end
        
        function [flipIdx, flipNums] = whichFlips(x, fs)
            % given a photodiode signal x with flips that encode their own numbers
            % returns:
            % flipIdx: the indices of the detected flips in x and their encoded
            % flipNums: the sequential numbers of the detected indices
            
            [flipIdx, flipAmps] = getFlips(x, fs, ne7.dsp.FlipCode.frameRate);
            flipNums = flipAmpsToNums(flipAmps);
        end

    end 
end








function flipNums = flipAmpsToNums(flipAmps)
% given a sequence of flip amplitudes with encoded numbers,
% assign cardinal numbers to as many flips as possible.

flipNums = nan(size(flipAmps));

% find threshold for positive flips (assumed stable)
ix = find(flipAmps>0);
thresh = (quantile(flipAmps(ix),0.1) + quantile(flipAmps(ix),0.9))/2;

frame = 16; % 16 positive flips
nFrames = 5;  % must be odd. 3 or 5 are most reasonable
iFlip = 1;
quitFlip = length(flipAmps)-frame*nFrames*2-2;
while iFlip < quitFlip
    amps = flipAmps(iFlip+(0:frame*nFrames-1)*2);
    if all(amps>0) % only consider positive flips
        bits = amps < thresh;  % big flips are for zeros
        nums = bin2dec(char(fliplr(reshape(bits, [frame nFrames])')+48));
        if all(diff(nums)==1)  % found sequential numbers
            %fill out the numbers of the flips in the middle frame
            ix = iFlip + floor(nFrames/2)*frame*2 + (0:frame*2-1);
            nums = nums((nFrames+1)/2)*frame*2 + (0:frame*2-1)+2;
            flipNums(ix) = nums;
            iFlip = iFlip + frame*2-1;
        end 
    end
    iFlip = iFlip+1;
end
end



function [flipIdx, flipAmps] = getFlips(x, fs, frameRate)
% INPUTS:
%   x - photodiode signal
%   fs - (Hz) sampling frequency
%   frameRate (Hz) - the max frame rate

T = fs/frameRate*2;  % period of oscillation measured in samples
% filter flips
n = floor(T/2);  % should be T/2 or smaller
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