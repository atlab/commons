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
            nums = nums((nFrames+1)/2)*frame*2 + (1:frame*2);
            flipNums(ix) = nums;
            iFlip = iFlip + frame*2-1;
        end 
    end
    iFlip = iFlip+1;
end
end