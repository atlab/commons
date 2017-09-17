function info = gettiffinfo(tiffFile)
% GETTIFFINFO Gets info from tags in the Tiff file.
%
%   GETTIFFINFO(TIFFFILE) returns a char array with the joined output of the Filename,
%   ImageLength, ImageWidth, ImageDescription, Software and Artist tags (if available).
%
% Note: Only a subset of all available TIFF tags and properties are read.

% Get some basic info
info = sprintf('TIFF File: %s', tiffFile.FileName);
info = sprintf('%s\nImage Length: %d', info, tiffFile.getTag('ImageLength'));
info = sprintf('%s\nImage Width: %d\n', info, tiffFile.getTag('ImageWidth'));

% Get image description tag
try 
    info = sprintf('%s\nIMAGE DESCRIPTION\n%s', info, tiffFile.getTag('ImageDescription'));
end
    
% Get software tag
try info = sprintf('%s\nSOFTWARE\n%s', info, tiffFile.getTag('Software')); end

% % Get artist tag
try info = sprintf('%s\nARTIST\n%s', info, tiffFile.getTag('Artist')); end

end