classdef Scan2016b < ne7.scanreader.scans.Scan5Point2
    %SCAN2016B ScanImage 2016b

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

