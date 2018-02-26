function checkindexisinbounds(axis, index, dimSize)
%CHECKINDEXISINBOUNDS Check that an index is in bounds for the given dimension size.

% Check if it is valid
if strcmp(index, ':')
    isValid = true; % : never go out of bounds
else
    isValid = max(index) <= dimSize;
end

% Print error if not valid
if ~isValid
    indexAsStr = sprintf('%d ', index);
    indexAsStr(end) = []; % drop last space
    error('checkindexisinbounds:IndexError', 'index %s is out of bounds for axis %d with size %d', indexAsStr, axis, dimSize)
end

end