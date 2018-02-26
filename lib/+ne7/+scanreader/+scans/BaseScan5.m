classdef (Abstract) BaseScan5 < ne7.scanreader.scans.BaseScan
    % BASESCAN5 ScanImage 5 scans: one field per scanning depth and all fields have the
    % same height and width.
    
    properties (SetAccess = private, Dependent) % inherited abstract properties
        nFields % number of fields
        fieldDepths % scaning depths per field
        isSlowStackWithFastZ % slow stack using the secondary/fastZ motor
        fieldOffsets % seconds elapsed between start of frame scanning and each pixel.
    end
    properties (SetAccess = private, Dependent)
        imageHeight 
        imageWidth
        zoom % amount of zoom used during scanning
    end
    properties (SetAccess = private, Dependent, Hidden)
        yAngleScaleFactor % angle range in y is scaled by this factor
        xAngleScaleFactor % angle range in x is scaled by this factor
    end

    methods
        function nFields = get.nFields(obj)
            nFields = obj.nScanningDepths; % one field per scanning depth
        end
        
        function fieldDepths = get.fieldDepths(obj)
            fieldDepths = obj.scanningDepths;
        end
        
        function imageHeight = get.imageHeight(obj)
            imageHeight = obj.pageHeight;
        end
        
        function imageWidth = get.imageWidth(obj)
            imageWidth = obj.pageWidth;
        end
        
        function s = size(obj)
            s = [obj.nFields, obj.imageHeight, obj.imageWidth, obj.nChannels, obj.nFrames];
        end
        
        function zoom = get.zoom(obj)
            pattern = 'hRoiManager\.scanZoomFactor = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) zoom = str2double(match{1}{1}); end 
        end
        
        % Define getter as a diff method so I can override it in subclasses (get.* are not
        % overridable)
        function isSlowStackWithFastZ = get.isSlowStackWithFastZ(obj)
            isSlowStackWithFastZ = obj.getIsSlowStackWithFastZ();
        end
        function isSlowStackWithFastZ = getIsSlowStackWithFastZ(obj)
            pattern = 'hMotors\.motorSecondMotorZEnable = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if isempty(match)
                isSlowStackWithFastZ = false;
            else
                isSlowStackWithFastZ = strcmp(match{1}{1}, 'true') || strcmp(match{1}{1}, '1');
            end
        end
        
        function fieldOffsets = get.fieldOffsets(obj)
            % Seconds elapsed between start of frame scanning and each pixel.
            nextLine = 0;
            fieldOffsets = {};
            for i = 1:obj.nFields
                fieldOffsets = [fieldOffsets, obj.computeoffsets(obj.imageHeight, nextLine)];
                nextLine = nextLine + obj.nLinesBetweenFields;
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
        
        function index = end(obj, dim, ~)
            if dim <= 5
                scanSize = size(obj);
                index = scanSize(dim);
            else
                index = 1;
            end
        end     
    end
    
    methods (Hidden)
        function item = getitem(obj, key)
            % GETITEM  In non-multiROI, all fields have the same x, y dimensions.
            
            % Fill key to size 5 (raises IndexError if more than 5)
            fullKey = ne7.scanreader.utils.fillkey(key, 5);
            
            % Check index types are valid
            for i = 1:length(fullKey)
                index = fullKey{i};
                ne7.scanreader.utils.checkindextype(i, index)
            end
            
            % Check each dimension is in bounds 
            maxDimensions = size(obj);
            for i = 1:length(fullKey)
                index = fullKey{i};
                dimSize = maxDimensions(i);
                ne7.scanreader.utils.checkindexisinbounds(i, index, dimSize)
            end
            
            % Get fields, channels and frames as lists
            fieldList = ne7.scanreader.utils.listifyindex(fullKey{1}, obj.nFields);
            yList = ne7.scanreader.utils.listifyindex(fullKey{2}, obj.imageHeight);
            xList = ne7.scanreader.utils.listifyindex(fullKey{3}, obj.imageWidth);
            channelList = ne7.scanreader.utils.listifyindex(fullKey{4}, obj.nChannels);
            frameList = ne7.scanreader.utils.listifyindex(fullKey{5}, obj.nFrames);
            
            % Edge case when slice gives 0 elements or index is empty list, e.g., scan(10:0)
            if isempty(fieldList) || isempty(yList) || isempty(xList) || isempty(channelList) || isempty(frameList)
                item = double.empty();
                return
            end
            
            % Read the required pages (and index in y, x)
            item = obj.readpages(fieldList, yList, xList, channelList, frameList);

            % If original index was a single integer delete that axis
            if ~isempty(key)
                squeezeDims = cellfun(@(index) ~strcmp(index, ':') && length(index) == 1, fullKey);
                item = permute(item, [find(~squeezeDims), find(squeezeDims)]); % send empty dimensions to last axes
            end
        end
    end
    
end