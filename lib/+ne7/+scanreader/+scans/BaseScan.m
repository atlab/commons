classdef (Abstract) BaseScan < handle
    % BASESCAN Properties and methods shared among all scan versions.
    %
    % Scan objects are a collection of recording fields: rectangular planes at a given x,
    % y,  z position in the scan recorded in a number of channels during a preset amount
    % of time. All fields have the same number of channels and number of frames.
    % Scan objects are:
    %   indexable: scan(field, y, x, channel, frame) works as long as the fields' spatial
    %       dimensions (y, x) match.
    %
    % Examples:
    %   scan.version                ScanImage version of the scan.
    %   scan(:, :, 1:3, :, 1:1000)    5-d array with the first 1000 frames of the first 3 
    %       fields (if x, y dimensions match).
    %
    % Note:
    %   We use frames as in video frames, i.e., number of timesteps the scan was recorded.
    %   ScanImage uses frames to refer to slices/scanning depths in the scan.
    
    properties (SetAccess = private)
        filenames % all tiff filenames
        classname % classname of the output array
        header % tiff header
        nFrames % number of frames
    end
    properties (SetAccess = private, Dependent)
        tiffFiles % opened Tiff files
        version % ScanImage version
        nChannels % number of channels
        scanningDepths % relative z depths or slices
        nScanningDepths % number of slices
        isMultiROI % true if scan is multiROI
        isBidirectional % true if scan is bidirectional
        secondsPerLine % time it takes to scan a line
        fps % frames per seconds
        spatialFillFraction
        temporalFillFraction
        usesFastZ % whether scan was recorded with FastZ/Piezo on
        nRequestedFrames % number of requested frames
        zStepInMicrons % factor to go from z depth units to microns
        scannerType % type of scanner
        scannerFrequency % scanner frequency (Hz)
        motorPositionAtZero % motor position (x, y and z in microns) at ScanImage's (0, 0)
    end
    properties (SetAccess = private, Dependent, Hidden)
        pageHeight % height of the tiff page
        pageWidth % width of the tiff page
        yAngleScaleFactor % angle range in y is scaled by this factor
        xAngleScaleFactor % angle range in x is scaled by this factor
    end
    properties (SetAccess = private, Dependent, Abstract)
        nFields % number of fields
        fieldDepths % scaning depths per field
    end
    properties (Access = private)
        tiffFiles_
        pagesPerFile
    end
    
    methods
        function tiffFiles = get.tiffFiles(obj)
            if isempty(obj.tiffFiles_)
                tiffFilesAsCell = cellfun(@Tiff, obj.filenames, 'uniformOutput', false);
                obj.tiffFiles_ = [tiffFilesAsCell{:}];                
            end
            tiffFiles = obj.tiffFiles_;
        end
        
        function delete(obj)
            % DELETE Close all opened tiff files.
            if ~isempty(obj.tiffFiles_)
                arrayfun(@(file) file.close(), obj.tiffFiles_);
                obj.tiffFiles_ = [];
            end
        end
        
        function version = get.version(obj)
            pattern = 'SI.?\.VERSION_MAJOR = ''(.*)''';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) version = match{1}{1}; end
        end
        
        function nChannels = get.nChannels(obj)
            pattern = 'hChannels\.channelSave = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) nChannels = length(eval(match{1}{1})); end
        end
        
        function scanningDepths = get.scanningDepths(obj)
            pattern = 'hStackManager\.zs = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) scanningDepths = eval(match{1}{1}); end
        end
        
        function nScanningDepths = get.nScanningDepths(obj)
            nScanningDepths = length(obj.scanningDepths);
        end
        
        function set.filenames(obj, filenames)
            % Add step to recompute number of frames if filenames are changed.
            obj.filenames = filenames;
            obj.updateNFrames(); % recompute number of frames
        end
        
        function updateNFrames(obj)
            % Each tiff page is an image at a given channel, scanning depth combination.
            obj.pagesPerFile = cellfun(@(filename) length(imfinfo(filename)), obj.filenames);
            nPages = sum(obj.pagesPerFile);
            nFrames_ = nPages / (obj.nScanningDepths * obj.nChannels);
            obj.nFrames = floor(nFrames_); % discard last frame if incomplete
        end
                
        function isMultiROI = get.isMultiROI(obj)
            % Only true if mroiEnable exists (2016b and up) and is set to true.
            pattern = 'hRoiManager\.mroiEnable = (.)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if isempty(match)
                isMultiROI = false;
            else
                isMultiROI = strcmp(match{1}{1}, '1');
            end
        end
       
        function isBidirectional = get.isBidirectional(obj)
            pattern = 'hScan2D\.bidirectional = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if isempty(match)
                isBidirectional = false;
            else
                isBidirectional = strcmp(match{1}{1}, 'true');
            end
        end
        
        function secondsPerLine = get.secondsPerLine(obj)
            pattern = 'hRoiManager\.linePeriod = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) secondsPerLine = str2double(match{1}{1}); end
        end
        
        function pageHeight = get.pageHeight(obj)
            pattern = 'Image Length: (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) pageHeight = str2double(match{1}{1}); end
        end
        
        function pageWidth = get.pageWidth(obj)
            pattern = 'Image Width: (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) pageWidth = str2double(match{1}{1}); end
        end
        
        
        % Properties from here on are not strictly necessary
        function fps = get.fps(obj)
            pattern = 'hRoiManager\.scanVolumeRate = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) fps = str2double(match{1}{1}); end
        end
        
        function spatialFillFraction = get.spatialFillFraction(obj)
            pattern = 'hScan2D\.fillFractionSpatial = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) spatialFillFraction = str2double(match{1}{1}); end
        end
        
        function temporalFillFraction = get.temporalFillFraction(obj)
            pattern = 'hScan2D\.fillFractionTemporal = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) temporalFillFraction = str2double(match{1}{1}); end
        end
        
        function usesFastZ = get.usesFastZ(obj)
            pattern = 'hFastZ\.enable = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if isempty(match)
                usesFastZ = false;
            else
                usesFastZ = strcmp(match{1}{1}, 'true') || strcmp(match{1}{1}, '1');
            end
        end
        
        function nRequestedFrames = get.nRequestedFrames(obj)
            if obj.usesFastZ
                pattern = 'hFastZ\.numVolumes = (.*)';
            else
                pattern = 'hStackManager\.framesPerSlice = (.*)';
            end
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) nRequestedFrames = str2double(match{1}{1}); end
        end
        
        function zStepInMicrons = get.zStepInMicrons(obj)
            pattern = 'hStackManager\.stackZStepSize = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) zStepInMicrons = str2double(match{1}{1}); end
        end
        
        function scannerType = get.scannerType(obj)
            pattern = 'hScan2D\.scannerType = ''(.*)''';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) scannerType = match{1}{1}; end
        end
        
        function scannerFrequency = get.scannerFrequency(obj)
            pattern = 'hScan2D\.scannerFrequency = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) scannerFrequency = str2double(match{1}{1}); end
        end
        
        function motorPositionAtZero = get.motorPositionAtZero(obj)
            % Motor position (x, y and z in microns) at ScanImage's (0, 0) point.
            % For non-multiroi scans, (0, 0) is in the center of the FOV.
            pattern = 'hMotors\.motorPosition = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match)
                motorCoordinates = eval(match{1}{1});
                motorPositionAtZero = motorCoordinates(1:3);
            end
        end
        
        function yAngleScaleFactor = get.yAngleScaleFactor(obj)
            % Scan angles in y are scaled by this factor, shrinking the angle range.
            pattern = 'hRoiManager\.scanAngleMultiplierSlow = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) yAngleScaleFactor = str2double(match{1}{1}); end
        end
        
        function xAngleScaleFactor = get.xAngleScaleFactor(obj)
            % Scan angles in x are scaled by this factor, shrinking the angle range.
            pattern = 'hRoiManager\.scanAngleMultiplierFast = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) xAngleScaleFactor = str2double(match{1}{1}); end
        end
        
        function readdata(obj, filenames, classname)
            % READDATA Set header, filenames and classname. Data is read lazily when 
            % needed.
            %
            % READDATA(FILENAMES, CLASSNAME) sets filename using the info from the first
            % file in FILENAMES, and sets obj.classname to CLASSNAME.

            % Set header
            tiffFile = Tiff(filenames{1});
            obj.header = ne7.scanreader.utils.gettiffinfo(tiffFile);
            tiffFile.close();
            
            % Set classname
            obj.classname = classname;
            
            % Set filenames
            obj.filenames = filenames;
        end
        
        function disp(obj)
            % DISP Override default display behaviour.
            asterisks = repmat('*', 1, 80); % line of asterisks
            fprintf('%s\n%s\n%s\n', asterisks, obj.header, asterisks);
        end
        
        function len = length(obj)
            % LENGTH Override length to be equals to the number of fields. Eases
            % iteration over fields.
            len = obj.nFields;
        end
        
        function varargout = subsref(obj, S)
            % SUBSREF Index scans by field, y, x, channels and frames. Supports integer 
            % indices (no logical or linear indexing).
            if strcmp(S(1).type, '()') % array indexing
                % Get item (implemented in subclasses)
                key = S(1).subs;
                item = obj.getitem(key);
                
                % In case more indexing is needed
                if length(S) > 1
                    [varargout{1:nargout}] = builtin('subsref', item, S(2:end));
                else 
                    varargout = {item};
                end
            else
                [varargout{1:nargout}] = builtin('subsref', obj, S);
            end
         end
            
    end
    
    methods (Abstract)       
        index = end(obj, dim, ~)
        % END End index for each dimension.
    end
    
    methods (Abstract, Hidden)
        item = getitem(obj, key)
        % GETITEM Load scan from tiff files and slice using key
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
            % change first, slices/depths change second and timeframes change last.
            % 
            % Example:
            %     For two channels, three slices, two frames.
            %     Page:       1   2   3   4   5   6   7   8   9   10  11  12
            %     Channel:    1   2   1   2   1   2   1   2   1   2   1   2
            %     Slice:      1   1   2   2   3   3   1   1   2   2   3   3
            %     Frame:      1   1   1   1   1   1   2   2   2   2   2   2
           
            % Compute pages to load from tiff files (a bit dirty but does the trick)
            sliceStep = obj.nChannels;
            frameStep = obj.nChannels * obj.nScanningDepths;
            pagesToRead = [];
            for frame = frameList
                for slice = sliceList
                    for channel = channelList
                        newPage = (frame - 1) * frameStep + (slice - 1) * sliceStep + channel;
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