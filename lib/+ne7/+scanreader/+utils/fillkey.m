function fullKey = fillkey(key, numDimensions)
% FILLKEY Fill indexing key to numDimensions
%   FILLKEY(KEY, NUMDIMENSIONS) fills KEY with 1s until size is equal to NUMDIMENSIONS.
%   Raises an error if KEY  is larger than NUMDIMENSIONS (and values in high dimensions 
%   are greater than one)

% Check key is not larger than num_dimensions
if length(key) > numDimensions
    isValid = all(cellfun(@(index) index == 1, key(numDimensions + 1: end)));
    if isValid
       key = key{1:numDimensions}; 
    else
        error('fillkey:IndexError', 'too many indices for scan: %d', length(key))
    end
end

% Fill key (if empty output is full array, else fill missing dimensions with 1)
if isempty(key)
     [fullKey{1:numDimensions}] = deal(':'); % {':', ':', ':', ..., ':'}
else
    fullKey = key;
    [fullKey{length(fullKey) + 1: numDimensions}] = deal(1);
end

end