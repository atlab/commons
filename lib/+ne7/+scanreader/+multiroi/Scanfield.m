classdef Scanfield < handle
    %SCANFIELD Small container for scanfield information. Used to define ROIs.
    
    properties
        height % height of the field in pixels
        width % width of the field in pixels
        depth % depth at which this field was recorded (in microns relative to absolute z)
        y % y coordinate of the center of the field in the scan (in scan angle degrees)
        x % x coordinate of the center of the field in the scan (in scan angle degrees)
        heightInDegrees % height of the field in degrees of the scan angle
        widthInDegrees % width of the field in degrees of the scan angle
    end
    
    methods
        function obj = Scanfield(height, width, depth, y, x, heightInDegrees, widthInDegrees)
            if nargin >= 1 obj.height = height; end
            if nargin >= 2 obj.width = width; end
            if nargin >= 3 obj.depth = depth; end
            if nargin >= 4 obj.y = y; end
            if nargin >= 5 obj.x = x; end
            if nargin >= 6 obj.heightInDegrees = heightInDegrees; end
            if nargin >= 7 obj.widthInDegrees = widthInDegrees; end
        end
        
        function field = asField(obj)
            field = ne7.scanreader.multiroi.Field(obj.height, obj.width, obj.depth, ...
                obj.y, obj.x, obj.heightInDegrees, obj.widthInDegrees);
        end
    end
    
end

