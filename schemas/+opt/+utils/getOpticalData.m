function [Data Fs pdData pdFs] = getOpticalData(fn)

% function [Data Fs pdData pdFs] = getOpticalData(fn)
%
% Gets the data from the Intrinsic Imager program.
% fn   : filename
% Data : camera data in: [time x y]
% Fs   : Sampling rate
% pdData : photodiode data 
% pdFs   : photodiode Sampling rate
%
% MF 2012-06

data = single(opt.utils.loadHWS(fn,'imaging','movie')); % get the imaging data
try
    imsizeX = opt.utils.loadHWS(fn,'imaging','x'); 
    imsizeY = opt.utils.loadHWS(fn,'imaging','y');
catch  %#ok<CTCH>
    display('Could not find image size, selecting 512')
    imsizeX = 512;
    imsizeY = 512;
end

Data = permute(reshape(data,imsizeX,[],imsizeY),[2 3 1]); % reshape into [time x y]

if nargout>1
    Fs = opt.utils.loadHWS(fn,'imaging','hz'); % get framerate
end

if nargout>2
    pdData = opt.utils.loadHWS(fn,'ephys','photodiode'); % get photodiode data
end

if nargout>3
    pdFs = opt.utils.loadHWS(fn,'ephys','hz'); % get framerate
end