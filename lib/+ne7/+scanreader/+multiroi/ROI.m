classdef ROI < handle
    %ROI Holds ROI info and computes an xy plane (scanfield) at a given z.
    %
    % ScanImage defines a ROI as the interpolation between a set of scanfields. See their
    % docs for details.
    properties
        roiInfo
    end
    properties (Dependent)
        scanfields
        isDiscretePlaneModeOn
    end
    properties (Hidden)
        scanfields_
    end
    
    methods
        function obj = ROI(roiInfo)
            % ROI Read the scanfields that define this ROI and other required info.
            %
            % ROI(ROIINFO) reads ROIINFO, a struct containing the definition of this ROI
            % as extracted from the tiff header.
            obj.roiInfo = roiInfo;
        end
        
        function scanfields = get.scanfields(obj)
            if isempty(obj.scanfields_) 
                obj.scanfields_ = obj.createscanfields(); 
            end
            scanfields = obj.scanfields_;
        end
        
        function isDiscretePlaneModeOn = get.isDiscretePlaneModeOn(obj)
            isDiscretePlaneModeOn = logical(obj.roiInfo.discretePlaneMode);
        end
    end
        
    methods(Access = private)
        function scanfields_ = createscanfields(obj)
            % CREATESCANFIELDS Create all the scanfields that form this ROI.
            % Get scanfield configuration info
            scanfieldInfos = obj.roiInfo.scanfields;
            
            % Get scanfield depths
            scanfieldDepths = obj.roiInfo.zs;
            
            scanfields_ = [];
            for i = 1:length(scanfieldInfos)
                scanfieldInfo = scanfieldInfos(i);
                scanfieldDepth = scanfieldDepths(i);
                
                % Get scanfield info
                width = scanfieldInfo.pixelResolutionXY(1);
                height = scanfieldInfo.pixelResolutionXY(2);
                xCenter = scanfieldInfo.centerXY(1);
                yCenter = scanfieldInfo.centerXY(2);
                sizeInX = scanfieldInfo.sizeXY(1);
                sizeInY = scanfieldInfo.sizeXY(2);
                
                % Create scanfield
                newScanfield = ne7.scanreader.multiroi.Scanfield(height, width,...
                    scanfieldDepth, yCenter, xCenter, sizeInY, sizeInX);
                scanfields_ = [scanfields_, newScanfield];
            end
            
            % Sort them by depth (to ease interpolation)
            [~, newOrder] = sort(scanfieldDepths);
            scanfields_ = scanfields_(newOrder);
        end
    end
    
    methods
        function field = getfieldat(obj, scanningDepth)
            % GETFIELDAT Get the 2-d field that cuts this ROI at a given depth
            %
            % field = GETFIELDAT(SCANNINGDEPTH) interpolates between the ROI scanfields to
            % generate the field at SCANNINGDEPTH.
            %
            % Warning: 
            %   Does not work for rotated ROIs. 
            %   If there were more than one scanfield at the same depth, it will only 
            %   consider the one defined last.
            field = []; % null/None
            if obj.isDiscretePlaneModeOn % only check at each scanfield depth
                for scanfield = obj.scanfields
                    if scanfield.depth == scanningDepth
                        field = scanfield.asField();
                    end
                end               
            else
                if length(obj.scanfields) == 1 % single scanfield extending from -inf to inf
                    field = obj.scanfields(1).asField();
                    field.depth = round(scanningDepth);
                else % interpolate between scanfields
                    scanfieldDepths = arrayfun(@(sf) sf.depth, obj.scanfields);
                    if scanningDepth >= min(scanfieldDepths) && scanningDepth <= max(scanfieldDepths)
                        field = ne7.scanreader.multiroi.Field();
                        
                        scanfieldHeights = arrayfun(@(sf) sf.height, obj.scanfields);
                        field.height = interp1(scanfieldDepths, scanfieldHeights, scanningDepth);
                        field.height = round(field.height /2) * 2; % round to the closest even
                        
                        scanfieldWidths = arrayfun(@(sf) sf.width, obj.scanfields);
                        field.width = interp1(scanfieldDepths, scanfieldWidths, scanningDepth);
                        field.width = round(field.width /2) * 2; % round to the closest even
                        
                        field.depth = round(scanningDepth);
                        
                        scanfieldYs = arrayfun(@(sf) sf.y, obj.scanfields);
                        field.y = interp1(scanfieldDepths, scanfieldYs, scanningDepth);
                        
                        scanfieldXs = arrayfun(@(sf) sf.x, obj.scanfields);
                        field.x = interp1(scanfieldDepths, scanfieldXs, scanningDepth);
                        
                        scanfieldHeights = arrayfun(@(sf) sf.heightInDegrees, obj.scanfields);
                        field.heightInDegrees = interp1(scanfieldDepths, scanfieldHeights, scanningDepth);
                        
                        scanfieldWidths = arrayfun(@(sf) sf.widthInDegrees, obj.scanfields);
                        field.widthInDegrees = interp1(scanfieldDepths, scanfieldWidths, scanningDepth);
                    end                    
                end                 
            end
        end
        
    end
    
end

