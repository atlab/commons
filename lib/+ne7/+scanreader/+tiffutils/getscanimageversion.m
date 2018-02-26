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
