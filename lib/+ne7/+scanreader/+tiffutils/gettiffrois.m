function rois = gettiffrois(tiffFile)
% GETTIFFROIS Reads tiff file metadata, extracts the ROI definition section (as JSON) and 
%   decodes it.
try rois = jsondecode(tiffFile.getTag('Artist')); end
end

