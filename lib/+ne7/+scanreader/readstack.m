% Reader for ScanImage 5 stacks (including multiROI).
%
% Example 1: Process a stack field by field
%     stack = scanreader.readstack('my_stack_*.tif')
%     for fieldId = 1:stack.nFields
%         field = stack(fieldId, :, :, :, :)
%         % process field
%     end
%
% See README for details.

function stack = readstack(pathnames, classname, joinContiguous)
% READSCAN Reads a ScanImage stack.
%
%   Stacks are similar to scans except that we record all frames for a single scanning
%   depth before moving to the next.
%
%   scan = READSTACK(PATHNAMES) returns a stack read from PATHNAMES. PATHNAMES is a single
%   pathname or pathname pattern (a string extended via dir) or an array of pathnames or
%   pathname patterns.
%
%   scan = READSTACK(PATHNAMES, CLASSNAME) returns a stack of class specified by string
%   CLASSNAME. Default is 'int16'
%
%   scan = READSTACK(PATHNAMES, CLASSNAME, JOINCONTIGUOUS) returns a stack where fields 
%   that are contiguous in the scan will be joined if JOINCONTIGUOUS is true. Default is 
%   false. For non-multiroi scans this has no effect. 
%   See help of ScanMultiROI.joincontiguousfields for details.

% Fill optional values
switch nargin
    case 1
        classname = 'int16';
        joinContiguous = false;
    case 2
        joinContiguous = false;
end

% Expand wildcards
filenames = ne7.scanreader.utils.expandwildcard(pathnames);
if isempty(filenames)
    if iscellstr(pathnames)
        pathnamesAsString = strcat('{' , strjoin(pathnames, ', '), '}');
    else
        pathnamesAsString = pathnames;
    end
    error('readstack:PathnameError', 'Pathname(s) %s do not match any files in disk.', pathnamesAsString);
end

% Read version from one of the tiff files
tiffFile = Tiff(filenames{1});
tiffInfo = ne7.scanreader.tiffutils.gettiffinfo(tiffFile);
version = ne7.scanreader.tiffutils.getscanimageversion(tiffInfo);

% Select the appropiate scan object
switch version
    case '5.1'
        stack = ne7.scanreader.stacks.Stack5Point1();
    case '5.2'
        stack = ne7.scanreader.stacks.Stack5Point2();
    case '2016b'
        if ne7.scanreader.tiffutils.isscanmultiROI(tiffInfo)
            stack = ne7.scanreader.stacks.StackMultiROI(joinContiguous);
        else
            stack = ne7.scanreader.stacks.Stack2016b();
        end
    otherwise
        error('readstack:ScanImageVersionError', 'Sorry, ScanImage version %s is not supported', version)
end

% Read metadata and data (lazy operation)
stack.readdata(filenames, classname)

% Close tiff file
tiffFile.close()

end