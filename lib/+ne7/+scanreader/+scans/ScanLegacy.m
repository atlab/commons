classdef ScanLegacy < ne7.scanreader.scans.BaseScan
    %SCANLEGACY Scan versions 4 and below. Not implemented.
    
    methods
        function obj = ScanLegacy()
            error('ScanLegacy:NotImplementedError', 'Legacy scans not supported')
        end
    end
    
end

