function stack = conditionStack(stack)
% bandpass filter stack for computing cross-correlation

% low-pass filter
k = hamming(5);
k = k/sum(k);
stack = imfilter(imfilter(stack,k,'symmetric'),k','symmetric');

% unsharp masking
sigma = 41;  % somewhat arbitrary
k = gausswin(sigma);
k = k/sum(k);
stack = stack - imfilter(imfilter(stack, k, 'symmetric'), k', 'symmetric');

% taper image boundaries
sz = size(stack);
mask = atan(10*hanning(sz(1)))*atan(10*hanning(sz(2)))' /atan(10)^2;
stack = bsxfun(@times, stack, mask);

% normalize
stack = bsxfun(@rdivide, stack, sqrt(sum(sum(stack.^2))));
end
