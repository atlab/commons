classdef Reader < handle
    % scanimage.Reader - ScanImage file interface
    
    properties(SetAccess = protected)
        filepath
        tiff     % Tiff object
        hdr      % header info
        nChans   % number of channels
        nFrames  % total number of frames (may be less if interrupted)
        nSlices  % number of slices
        width    % in pixels
        height   % in pixels
    end
    
    
    methods
        function self = Reader(filepath)
            self.filepath = filepath;
            self.tiff = Tiff(self.filepath);
            evalc(self.tiff.getTag('ImageDescription'));   % evaluate state
            self.hdr = state;
            self.nChans  = self.hdr.acq.numberOfChannelsSave;
            self.nFrames = self.hdr.acq.numberOfFrames;
            self.nSlices = self.hdr.acq.numberOfZSlices;
            self.height = self.hdr.acq.linesPerFrame;
            self.width  = self.hdr.acq.pixelsPerLine;
        end
        
        
        function yes = hasChannel(self, iChan)
            yes = ismember(iChan, 1:4) ...
                && self.hdr.acq.(sprintf('savingChannel%u', iChan))==1;
        end
        
        
        function [img, discardedFinalLine] = read(self, iChan, frameIdx, removeFlyback)
            if nargin<3 || isempty(frameIdx)
                frameIdx = 1:self.nFrames;
            end
            removeFlyback = nargin<4 || removeFlyback;
            assert(ismember(iChan,1:self.nChans), 'channel out of range')
            assert(self.hasChannel(iChan), 'Channel %d was not recorded', iChan)
            
            % change iChan to the channel number in the gif file.
            for i=1:iChan
                iChan = iChan - 1 + self.hasChannel(i);
            end
            
            img = zeros(self.height, self.width, length(frameIdx), 'single');
            for iFrame=1:length(frameIdx(:))
                dirNum = (frameIdx(iFrame)-1)*self.nChans + iChan;
                try
                    self.tiff.setDirectory(dirNum)
                catch   %#ok<CTCH> % interrupted scan
                    self.nFrames = iFrame-1;
                    img = img(:,:,1:self.nFrames);
                    break
                end
                img(:,:,iFrame) = self.tiff.read;
            end
            
            % determine if the last line is the flyback line and discard it if so
            discardedFinalLine = false;
            if removeFlyback && ~self.hdr.acq.slowDimDiscardFlybackLine
                if self.hdr.acq.slowDimFlybackFinalLine
                    img = img(1:end-1,:,:);
                    discardedFinalLine = true;
                else
                    img = img(2:end,:,:);
                end
            end
        end
        
        
        function signal = readPhotodiode(self)
            iChan = 3;   % assume 3rd channel
            assert(self.hasChannel(iChan), ...
                'Channel 3 (photodiode) was not recorded')
            signal = self.read(iChan, [], false);
            signal = squeeze(mean(signal,2));
            signal = reshape(signal, 1, []);
        end
    end
end