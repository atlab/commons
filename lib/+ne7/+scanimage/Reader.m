classdef Reader < handle
    % scanimage.Reader - ScanImage file interface
    
    properties(SetAccess = protected)
        filepaths
        info     % output of iminfo
        hdr      % header info
        nChans   % number of channels
        nFrames  % total number of frames (may be less if interrupted)
        nSlices  % number of slices
        width    % in pixels
        height   % in pixels
    end
    
    
    methods
        function self = Reader(filepath)
            % The filepath must specify the full local path to the tiff file or
            % multiple files. Multiple files are generated using sprintf
            % numerical placeholders. For example, '/path/scan001_%03u.tif'
            % will translate into /path/scan001_001.tif,
            % /path/scan001_002.tif, etc
            
            % generate the file list
            self.filepaths = {};
            
            if exist([filepath '.tif'],'file')
                self.filepaths{1} = [filepath '.tif'];
            else
                for i=1:40
                    f = sprintf('%s_%03u.tif', filepath, i);
                    if ismember(f,self.filepaths)
                        break
                    end
                    if ~exist(f, 'file')
                        break
                    end
                    self.filepaths{end+1}=f;
                end
            end
            if isempty(self.filepaths)
                error('file %s not found', filepath)
            end
            
            disp 'reading TIFF header...'
            for i=1:length(self.filepaths)
                self.info{i} = imfinfo(self.filepaths{i});
            end
            evalc(self.info{1}(1).ImageDescription);
            self.hdr = state;
            
            %self.nChans  = self.hdr.acq.numberOfChannelsSave; %% Changed JR 11/16/12
            self.nChans = self.hdr.acq.savingChannel1 +...
                          self.hdr.acq.savingChannel2 +...
                          self.hdr.acq.savingChannel3 +...
                          self.hdr.acq.savingChannel4;
            
            self.nFrames = sum(cellfun(@length, self.info))/self.nChans;
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
            assert(self.hasChannel(iChan), 'Channel %d was not recorded', iChan)
            
            % change iChan to the channel number in the gif file.
            for i=1:iChan
                iChan = iChan - 1 + self.hasChannel(i);
            end
            
            img = zeros(self.height, self.width, length(frameIdx), 'single');
            for iFrame=1:length(frameIdx(:))
                frameNum = (frameIdx(iFrame)-1)*self.nChans + iChan;
                [fileNum, frameNum] = self.getFileNum(frameNum);
                img(:,:,iFrame) = imread(self.filepaths{fileNum}, ...
                    'Index', frameNum, 'Info', self.info{fileNum});
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
        
         function signal = readCh4(self)
            iChan = 4;   
            assert(self.hasChannel(iChan), ...
                'Channel 4 was not recorded')
            signal = self.read(iChan, [], false);
            signal = squeeze(mean(signal,2));
            signal = reshape(signal, 1, []);
        end
    end
    
    
    methods(Access = private)
        function [fileNum, frameNum] = getFileNum(self, frameNum)
            for i=1:length(self.filepaths)
                if frameNum <= length(self.info{i})
                    fileNum = i;
                    break
                end
                frameNum = frameNum - length(self.info{i});
            end
        end
    end
end