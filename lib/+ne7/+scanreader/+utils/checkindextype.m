function checkindextype(axis, index)
% CHECKINDEXTYPE Checks that index is an array of positive integers or ':'.
isIntegerArray = isnumeric(index) && isvector(index) && all(mod(index, 1) == 0) && all(index > 0);
if ~isIntegerArray && ~strcmp(index, ':')
    error('checkindextype:TypeError', 'index in axis %d is not an array of positive integers or '':''', axis)
end
end