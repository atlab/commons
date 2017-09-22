classdef StackMultiROI < ne7.scanreader.scans.ScanMultiROI & ne7.scanreader.stacks.BaseStack
    methods
        function obj = StackMultiROI(joinContiguous)
            % make sure the right constructor is called
            obj@ne7.scanreader.scans.ScanMultiROI(joinContiguous)
        end
    end
end