% Reader for ScanImage 5 scans (including multiROI).
%
% Example 1: Process a scan field by field
%     scan = scanreader.readscan('my_scan_*.tif')
%     for fieldId = 1:scan.nFields
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
filenames = ne7.scanreader.utils.expandwildcard(pathnames);
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
tiffInfo = ne7.scanreader.tiffutils.gettiffinfo(tiffFile);
version = ne7.scanreader.tiffutils.getscanimageversion(tiffInfo);

% Select the appropiate scan object
switch version
    case '5.1'
        scan = ne7.scanreader.scans.Scan5Point1();
    case '5.2'
        scan = ne7.scanreader.scans.Scan5Point2();
    case {'2016b','2017b'}
        if ne7.scanreader.tiffutils.isscanmultiROI(tiffInfo)
            scan = ne7.scanreader.scans.ScanMultiROI(joinContiguous);
        else
            scan = ne7.scanreader.scans.Scan2016b();
        end
    case '2017a'
        if ne7.scanreader.tiffutils.isscanmultiROI(tiffInfo)
            scan = ne7.scanreader.scans.ScanMultiROI(joinContiguous);
        else
            scan = ne7.scanreader.scans.Scan2017a();
        end
    otherwise
        error('readscan:ScanImageVersionError', 'Sorry, ScanImage version %s is not supported', version)
end

% Read metadata and data (lazy operation)
scan.readdata(filenames, classname)

% Close tiff file
tiffFile.close()

end