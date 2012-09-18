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
        
        
        
        function [img, discardedFinalLine] = read(self, iChan, frameIdx, removeFlyback)
            if nargin<3 || isempty(frameIdx)
                frameIdx = 1:self.nFrames;
            end
            removeFlyback = nargin<4 || removeFlyback;
            assert(ismember(iChan,1:4), 'iChan must be between 1 and 4')
            assert(eval(sprintf('self.hdr.acq.savingChannel%u',iChan))==1, ...
                'Channel %d was not recorded', iChan)
            for i=1:iChan
                iChan = iChan - 1 + eval(sprintf('self.hdr.acq.savingChannel%u',i));
            end
            
            % --------------Added JR 9/6/12
            % Based on: http://www.matlabtips.com/how-to-load-tiff-stacks-fast-really-fast/
            % Requires tifflib.mexa64 in the class directory
            img = zeros(self.info(1).Height, self.info(1).Width, length(frameIdx),'single');
            mImage=self.info(1).Width;
            nImage=self.info(1).Height;
            
            
            FileID = tifflib('open',self.info(1).Filename,'r');
            rps = tifflib('getField',FileID,Tiff.TagID.RowsPerStrip);

            chanFrames = [iChan : self.nChans : (self.nFrames*self.nChans)];
            for i=1:length(frameIdx(:))
                tifflib('setDirectory',FileID,chanFrames(frameIdx(i)));
                % Go through each strip of data.
                rps = min(rps,mImage);
                for r = 1:rps:mImage
                    row_inds = r:min(mImage,r+rps-1);
                    stripNum = tifflib('computeStrip',FileID,r);
                    img(row_inds,:,i) = tifflib('readEncodedStrip',FileID,stripNum);
                end
            end
            tifflib('close',FileID);
            % -----------------------
            %
            %             img = single(zeros(self.info(1).Height, self.info(1).Width, length(frameIdx)));
            %             for iFrame=1:length(frameIdx(:))
            %                 img(:,:,iFrame) = ...
            %                     imread(self.info(1).Filename, ...
            %                     (frameIdx(iFrame)-1)*self.nChans + iChan, 'Info', self.info);
            %             end
            
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
            signal = self.read(3, [], false);  % assumed on 3rd channel
            signal = squeeze(mean(signal,2));
            signal = reshape(signal, 1, []);
        end
    end
end