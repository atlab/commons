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