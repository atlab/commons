function [Data Fs pdData pdFs] = getOpticalData(varargin)

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

fn = varargin{1};
getPd=1;
getMov=1;
if nargin > 1
    switch varargin{2}
        case 'pd'
            getMov=1;
        case 'mov'
            getPd=0;
    end
end
   
Data=[];
if getMov
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
end

if nargout>1
    Fs = opt.utils.loadHWS(fn,'imaging','hz'); % get framerate
end

pdData=[];
if nargout>2 && getPd
    pdData = opt.utils.loadHWS(fn,'ephys','photodiode'); % get photodiode data
end

if nargout>3
    pdFs = opt.utils.loadHWS(fn,'ephys','hz'); % get framerate
end