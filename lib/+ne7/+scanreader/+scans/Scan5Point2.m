classdef Scan5Point2 < ne7.scanreader.scans.BaseScan5
    % SCAN5POINT2 ScanImage 5.2. Addition of FOV measures in microns.
    properties (SetAccess = private, Dependent)
        imageHeightInMicrons
        imageWidthInMicrons   
    end
    
    methods
        function imageHeightInMicrons = get.imageHeightInMicrons(obj)
            pattern = 'hRoiManager\.imagingFovUm = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) 
                fov_corners = eval(match{1}{1});
                imageHeightInMicrons = fov_corners(3, 2) - fov_corners(2, 2); % y1-y0
            end
        end

        function imageWidthInMicrons = get.imageWidthInMicrons(obj)
            pattern = 'hRoiManager\.imagingFovUm = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if ~isempty(match) 
                fov_corners = eval(match{1}{1});
                imageWidthInMicrons = fov_corners(2, 1) - fov_corners(1, 1); % x1-x0
            end
        end  
    end
end