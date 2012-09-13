classdef Reader
    % Reader - ScanImage file interface
    % Dimitri Yatsenko: 2012-02-05
    
    properties(SetAccess = private)
        filepath
        info     % tif file info. One per frame
        nChans   % number of channels
        nFrames  % total number of frames
    end
    
    properties(Dependent)
        hdr
    end
    
    
    methods
        function self = Reader(filepath)
            disp 'reading header'
            self.filepath = filepath;
            self.info = imfinfo(self.filepath);
            self.nChans = ...
                self.hdr.acq.savingChannel1 + ...
                self.hdr.acq.savingChannel2 + ...
                self.hdr.acq.savingChannel3 + ...
                self.hdr.acq.savingChannel4;
            self.nFrames = length(self.info)/self.nChans;
        end
        
        function hdr = get.hdr(self)
            hdr = self.getState(1);
        end
        
        function state = getState(self, i) %#ok<STOUT>
            evalc(self.info(i).ImageDescription);  % evaluate state
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
            assert(ismember(iChan,1:4), 'iChan must be between 1 and 4')
            assert(self.hasChannel(iChan), 'Channel %d was not recorded', iChan)
            
            % change iChan to the channel number in the gif file.
            for i=1:iChan
                iChan = iChan - 1 + self.hdr.acq.(sprintf('savingChannel%u',i));
            end
            
            img = single(zeros(self.info(1).Height, self.info(1).Width, length(frameIdx)));
            for iFrame=1:length(frameIdx(:))
                img(:,:,iFrame) = ...
                    imread(self.info(1).Filename, ...
                    (frameIdx(iFrame)-1)*self.nChans + iChan, 'Info', self.info);
            end
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