% Reader for ScanImage 5 scans (including multiROI).
%
% Example 1: Process a scan field by field
%     scan = scanreader.readscan('my_scan_*.tif')
%     for fieldId = scan.nFields
%         field = scan(fieldId, :, :, :, :)
%         % process field
%     end
%
% See README for details.

function scan = readscan(pathnames, classname, joinContiguous)
% READSCAN Reads a ScanImage scan.
%   scan = READSCAN(PATHNAMES) returns a scan read from PATHNAMES. PATHNAMES is a single
%   pathname or pathname pattern (a string extended via dir) or an array of pathnames or
%   pathname patterns.
%
%   scan = READSCAN(PATHNAMES, CLASSNAME) returns a scan of class specified by string
%   CLASSNAME. Default is 'int16'
%
%   scan = READSCAN(PATHNAMES, CLASSNAME, JOINCONTIGUOUS) returns a scan where fields that
%   are contiguous in the scan will be joined if JOINCONTIGUOUS is true. Default is false.
%   For non-multiroi scans this has no effect. See help of ScanMultiROI.joincontiguousfields 
%   for details.

% Fill optional values
switch nargin
    case 1
        classname = 'int16';
        joinContiguous = false;
    case 2
        joinContiguous = false;
end

% Expand wildcards
filenames = expandwildcard(pathnames);
if isempty(filenames)
    if iscellstr(pathnames)
        pathnamesAsString = strcat('{' , strjoin(pathnames, ', '), '}');
    else
        pathnamesAsString = pathnames;
    end
    error('readscan:PathnameError', 'Pathname(s) %s do not match any files in disk.', pathnamesAsString);
end

% Read version from one of the tiff files
tiffFile = Tiff(filenames{1});
tiffInfo = ne7.scanreader.utils.gettiffinfo(tiffFile);
version = getscanimageversion(tiffInfo);

% Select the appropiate scan object
switch version
    case '5.1'
        scan = ne7.scanreader.scans.Scan5Point1();
    case '5.2'
        scan = ne7.scanreader.scans.Scan5Point2();
    case '2016b'
        if isscanmultiROI(tiffInfo)
            scan = ne7.scanreader.scans.ScanMultiROI(joinContiguous);
        else
            scan = ne7.scanreader.scans.Scan2016b();
        end
    otherwise
        error('readscan:ScanImageVersionError', 'Sorry, ScanImage version %s is not supported', version)
end

% Read metadata and data (lazy operation)
scan.readdata(filenames, classname)

% Close tiff file
tiffFile.close()

end

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

function version = getscanimageversion(info)
% GETSCANIMAGEVERSION Looks for the ScanImage version in the tiff file headers.
%
%   version = GETSCANIMAGEVERSION(INFO) returns the scanImage version as a string read
%   from the headers provided in INFO.
pattern = 'SI.?\.VERSION_MAJOR = ''(.*)''';
match = regexp(info, pattern, 'tokens', 'dotexceptnewline');
if isempty(match)
    error('getscanimageversion:ScanImageVersionError', 'Could not find ScanImage version in the tiff header');
else
    version = match{1}{1};
end
end

function isMultiROI = isscanmultiROI(info)
% ISSCANMULTIROI Looks whether the scan is multiROI in the tiff file headers.
%
%   isMultiROI = ISSCANMULTIROI(INFO) returns a boolean indicating whether the scan is
%   multiROI read from the headers provided in INFO.

pattern = 'hRoiManager\.mroiEnable = (.)';
match = regexp(info, pattern, 'tokens', 'dotexceptnewline');
if isempty(match)
    isMultiROI = false;
else
    isMultiROI = strcmp(match{1}{1}, '1');
end
end