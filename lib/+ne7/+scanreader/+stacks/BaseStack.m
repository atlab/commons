classdef (Abstract) BaseStack < ne7.scanreader.scans.BaseScan
    % BASESTACK Properties and methods shared among all stack versions.

    properties (Dependent)
        requestedScanningDepths
    end
    properties
        requestedScanningDepths_
    end
    
    methods    
        function nFrames = getNFrames(obj)
            nFrames = obj.nRequestedFrames;
        end
        
        function nScanningDepths = getNScanningDepths(obj)
            % Number of scanning depths actually recorded in this stack.
            nPages = sum(obj.pagesPerFile);
            nScanningDepths = nPages / (obj.nFrames * obj.nChannels);
            nScanningDepths = floor(nScanningDepths); % discard last slice if incomplete
        end
        
        function requestedScanningDepths = get.requestedScanningDepths(obj)
            if isempty(obj.requestedScanningDepths_)
                obj.getScanningDepths(); % this sets requestedScanningDepths
            end
            requestedScanningDepths = obj.requestedScanningDepths_;
        end
        
        function scanningDepths = getScanningDepths(obj)
            % Set requestedScanningDepths. Superclass getScanningDepths can only be called from here
            if isempty(obj.requestedScanningDepths_)
                obj.requestedScanningDepths_ = getScanningDepths@ne7.scanreader.scans.BaseScan(obj); 
            end
            
            scanningDepths = obj.requestedScanningDepths(1:obj.nScanningDepths);
        end
    end
    
    methods (Access = protected)
        function pages = readpages(obj, sliceList, yList, xList, channelList, frameList)
            % READPAGES Reads the tiff pages with the content of each slice, channel, 
            % frame combination and indexes them in the y, x dimension.
            %
            % pages = READPAGES(SLICELIST, YLIST, XLIST, CHANNELLIST, FRAMELIST) returns a
            % 5-d array shaped (nSlices, outputHeight, outputWidth, nChannels, nFrames): 
            % the pages specified by the slices in SLICELIST, channels in CHANNELLIST and 
            % frames in FRAMELIST indexed using YLIST and XLIST. Array is reshaped to have
            % slice, channel and frame as different dimensions. Channel, slice and frame 
            % order received in the input lists are respected; for instance, if slice_list
            % = [2, 1, 3, 1], then the first dimension will have four slices: [2, 1, 3, 1]. 
            %
            % Each tiff page holds a single depth/channel/frame combination. Channels
            % change first, timeframes change second and slices/depths change last.
            % 
            % Example:
            %     For two channels, three slices, two frames.
            %     Page:       1   2   3   4   5   6   7   8   9   10  11  12
            %     Channel:    1   2   1   2   1   2   1   2   1   2   1   2
            %     Frame:      1   1   2   2   3   3   1   1   2   2   3   3
            %     Slice:      1   1   1   1   1   1   2   2   2   2   2   2
           
            % Compute pages to load from tiff files (a bit dirty but does the trick)
            frameStep = obj.nChannels;
            sliceStep = obj.nChannels * obj.nFrames;
            pagesToRead = [];
            for frame = frameList
                for slice = sliceList
                    for channel = channelList
                        newPage = (slice - 1) * sliceStep + (frame - 1) * frameStep + channel;
                        pagesToRead = [pagesToRead, newPage];
                    end
                end
            end
            
            % Read pages
            pages = zeros([length(pagesToRead), length(yList), length(xList)], obj.classname);
            startPage = 1;
            for i = 1:length(obj.tiffFiles)
                tiffFile = obj.tiffFiles(i);
                nTiffPages = obj.pagesPerFile(i);

                % Get indices in this tiff file and in output array
                finalPageInFile = startPage + nTiffPages - 1;
                pagesInFileIndices = pagesToRead >= startPage & pagesToRead <= finalPageInFile;
                fileIndices = pagesToRead(pagesInFileIndices) - startPage + 1;
                globalIndices = find(pagesInFileIndices);
                
                % Read from this tiff file
                for j = 1:length(fileIndices)
                    fileIndex = fileIndices(j);
                    globalIndex = globalIndices(j);
                    
                    tiffFile.setDirectory(fileIndex)
                    filePage = tiffFile.read();
                    pages(globalIndex, :, :) = filePage(yList, xList);
                end
                startPage = startPage + nTiffPages; 
            end
            
            % Reshape the pages into slices, y, x, channels, frames
            newShape = [length(channelList), length(sliceList), length(frameList), ...
                length(yList), length(xList)];
            pages = permute(reshape(pages, newShape), [2, 4, 5, 1, 3]);
        end
    end
end

