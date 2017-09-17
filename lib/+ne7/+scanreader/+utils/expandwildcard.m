function filenames = expandwildcard(wildcard)
% EXPANDWILDCARD Expands a list of pathname patterns to form a sorted array of absolute
% filenames
%
%   filenames = EXPANDWILDCARD(WILDCARD) returns an array of absolute filenames found when
%   expanding WILDCARD.
if ischar(wildcard)
    wildcardList = {wildcard};
elseif iscellstr(wildcard)
    wildcardList = wildcard;
else
    error('expandwildcard:TypeError', 'Expected string or cell array of strings, received %s', class(wildcard))
end

% Expand wildcards
directories = cellfun(@dir, wildcardList, 'UniformOutput', false);
directories = vertcat(directories{:}); % flatten list

% Make absolute filenames
makeabsolute = @(dir) fullfile(dir.folder, dir.name);
filenames = arrayfun(makeabsolute, directories, 'uniformOutput', false);

% Sort them
[~, newOrder] = sort({directories.name});
filenames = filenames(newOrder);

end