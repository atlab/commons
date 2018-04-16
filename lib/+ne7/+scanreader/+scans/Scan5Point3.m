classdef Scan5Point3 < ne7.scanreader.scans.Scan5Point2
    %SCAN5POINT3 ScanImage 5.3

    methods       
        function isSlowStackWithFastZ = getIsSlowStackWithFastZ(obj)
            pattern = 'hStackManager\.slowStackWithFastZ = (.*)';
            match = regexp(obj.header, pattern, 'tokens', 'dotexceptnewline');
            if isempty(match)
                isSlowStackWithFastZ = false;
            else
                isSlowStackWithFastZ = strcmp(match{1}{1}, 'true') || strcmp(match{1}{1}, '1');
            end
        end
    end
end

