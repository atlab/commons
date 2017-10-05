% Test suite for the different functionality of scanreader. It takes three minutes.
classdef ScanTest < matlab.unittest.TestCase
    %SCANTEST Test scans from different ScanImage versions.
    properties
       dataDir = '/home/ecobost/Documents/scanreader/data'
       scanFile5_1 % 2 channels, 3 slices
       scanFile5_2 % 2 channels, 3 slices
       scanFile2016b % 1 channel, 1 slice, mroiEnable = false
       scanFile2016bMultiroi % all rois have same dimensions, 1 channel 5 slices
       scanFile2016bMultiroiHard % rois have diff dimensions and they are volumes, 2 channels, 3 slices, roi1 at depth1, roi1 and 2 at depth 2, roi 2 at depth 2, thus 4 fields
       scanFile5_1Multifiles % second file has less pages
       scanFile2016bMultiroiMultifiles
       scanFileJoinContiguous
    end
    
    methods (TestClassSetup)
        function createfilenames(testCase)
            testCase.scanFile5_1 = fullfile(testCase.dataDir, 'scan_5_1_001.tif');
            testCase.scanFile5_2 = fullfile(testCase.dataDir, 'scan_5_2.tif');
            testCase.scanFile2016b = fullfile(testCase.dataDir, 'scan_2016b.tif');
            testCase.scanFile2016bMultiroi = fullfile(testCase.dataDir, 'scan_2016b_multiroi_001.tif');
            testCase.scanFile2016bMultiroiHard = fullfile(testCase.dataDir, 'scan_2016b_multiroi_hard.tif');
            testCase.scanFile5_1Multifiles = {fullfile(testCase.dataDir, 'scan_5_1_001.tif'), fullfile(testCase.dataDir, 'scan_5_1_002.tif')};
            testCase.scanFile2016bMultiroiMultifiles = {fullfile(testCase.dataDir, 'scan_2016b_multiroi_001.tif'), fullfile(testCase.dataDir, 'scan_2016b_multiroi_002.tif')};
            testCase.scanFileJoinContiguous = testCase.scanFile2016bMultiroi;
        end
    end
    
    methods (Test)
        
        function testattributes (testCase)
            
            % 5.1
            scan = ne7.scanreader.readscan(testCase.scanFile5_1);
            testCase.verifyEqual(scan.version, '5.1')
            testCase.verifyEqual(scan.nFields, 3)
            testCase.verifyEqual(scan.nChannels, 2)
            testCase.verifyEqual(scan.nFrames, 1000)
            testCase.verifyEqual(scan.nScanningDepths, 3)
            testCase.verifyEqual(scan.scanningDepths, [-5, 10, 25])
            testCase.verifyEqual(scan.fieldDepths, [-5, 10, 25])
            testCase.verifyEqual(scan.isMultiROI, false)
            testCase.verifyEqual(scan.isBidirectional, true)
            testCase.verifyEqual(scan.scannerFrequency, 7920.62)
            testCase.verifyEqual(scan.secondsPerLine, 6.31264e-05)
            testCase.verifyEqual(scan.fps, 11.0467)
            testCase.verifyEqual(scan.spatialFillFraction, 0.9)
            testCase.verifyEqual(scan.temporalFillFraction, 0.712867)
            testCase.verifyEqual(scan.usesFastZ, true)
            testCase.verifyEqual(scan.nRequestedFrames, 60500)
            testCase.verifyEqual(scan.scannerType, 'Resonant')
            testCase.verifyEqual(scan.motorPositionAtZero, [-1025, -495.5, -202.8])
            
            testCase.verifyEqual(scan.imageHeight, 256)
            testCase.verifyEqual(scan.imageWidth, 256)
            testCase.verifyEqual(size(scan), [3, 256, 256, 2, 1000])
            testCase.verifyEqual(scan.zoom, 1.8)
            
            % 2016b
            scan = ne7.scanreader.readscan(testCase.scanFile2016b);
            testCase.verifyEqual(scan.version, '2016b')
            testCase.verifyEqual(scan.nFields, 1)
            testCase.verifyEqual(scan.nChannels, 1)
            testCase.verifyEqual(scan.nFrames, 200)
            testCase.verifyEqual(scan.nScanningDepths, 1)
            testCase.verifyEqual(scan.scanningDepths, [0])
            testCase.verifyEqual(scan.fieldDepths, [0])
            testCase.verifyEqual(scan.isMultiROI, false)
            testCase.verifyEqual(scan.isBidirectional, false)
            testCase.verifyEqual(scan.scannerFrequency, 7926.87)
            testCase.verifyEqual(scan.secondsPerLine, 0.000126153)
            testCase.verifyEqual(scan.fps, 30.0255)
            testCase.verifyEqual(scan.spatialFillFraction, 0.9)
            testCase.verifyEqual(scan.temporalFillFraction, 0.712867)
            testCase.verifyEqual(scan.usesFastZ, false)
            testCase.verifyEqual(scan.nRequestedFrames, 4000)
            testCase.verifyEqual(scan.scannerType, 'Resonant')
            testCase.verifyEqual(scan.motorPositionAtZero, [1359.5, 46710.5, -5323])
            
            testCase.verifyEqual(scan.imageHeight, 256)
            testCase.verifyEqual(scan.imageWidth, 256)
            testCase.verifyEqual(size(scan), [1, 256, 256, 1, 200])
            testCase.verifyEqual(scan.zoom, 1.9)
            %testCase.verifyEqual(max(max(scan.fieldOffsets{1})), 0.032289, 'absTol', 1e-4)
            testCase.verifyEqual(scan.imageHeightInMicrons, 307.08)
            testCase.verifyEqual(scan.imageWidthInMicrons, 307.08)
            
            % 2016b MultiROI
            scan = ne7.scanreader.readscan(testCase.scanFile2016bMultiroiHard);
            testCase.verifyEqual(scan.version, '2016b')
            testCase.verifyEqual(scan.nFields, 4)
            testCase.verifyEqual(scan.nChannels, 2)
            testCase.verifyEqual(scan.nFrames, 10)
            testCase.verifyEqual(scan.nScanningDepths, 3)
            testCase.verifyEqual(scan.scanningDepths, [50, 100, 150])
            testCase.verifyEqual(scan.fieldDepths, [50, 100, 100, 150])
            testCase.verifyEqual(scan.isMultiROI, true)
            testCase.verifyEqual(scan.isBidirectional, true)
            testCase.verifyEqual(scan.scannerFrequency, 12045.5)
            testCase.verifyEqual(scan.secondsPerLine, 4.15092e-05)
            testCase.verifyEqual(scan.fps, 5.00651)
            testCase.verifyEqual(scan.spatialFillFraction, 0.9)
            testCase.verifyEqual(scan.temporalFillFraction, 0.712867)
            testCase.verifyEqual(scan.usesFastZ, true)
            testCase.verifyEqual(scan.nRequestedFrames, 10)
            testCase.verifyEqual(scan.scannerType, 'Resonant')
            testCase.verifyEqual(scan.motorPositionAtZero, [0, 0, 0])
            
            testCase.verifyEqual(scan.nRois, 2)
            testCase.verifyEqual(scan.fieldHeights, [800, 800, 512, 512])
            testCase.verifyEqual(scan.fieldWidths, [512, 512, 512, 512])
            testCase.verifyEqual(scan.fieldSlices, [1, 2, 2, 3])
            testCase.verifyEqual(scan.fieldRois, {1, 1, 2, 2})
            testCase.verifyEqual(scan.fieldMasks, {ones(800, 512), ones(800, 512), ...
                2 * ones(512, 512), 2 * ones(512, 512)});
            testCase.verifyEqual(cellfun(@(offsets) max(max(offsets)), scan.fieldOffsets), ...
                [0.033205, 0.099786, 0.127099, 0.154412], 'absTol', 1e-4)
            testCase.verifyEqual(scan.fieldHeightsInMicrons, [800, 800, 500, 613.21963], 'absTol', 1e-4)
            testCase.verifyEqual(scan.fieldWidthsInMicrons, [400, 400, 400, 400], 'absTol', 1e-4)
            
        end
        
        function test5_1(testCase)
            scan = ne7.scanreader.readscan(testCase.scanFile5_1);
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [3, 256, 256, 2, 1000], 359735877593)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [256, 256, 2, 1000], 114187329049)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [3, 256, 2, 1000], 917519804)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [3, 256, 2, 1000], 498901499)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [3, 256, 256, 1000], 340492324453)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [3, 256, 256, 2], 337564522)
        end
        
        function test5_2(testCase)
            scan = ne7.scanreader.readscan(testCase.scanFile5_2);
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [3, 512, 512, 2, 366], 491935416968)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [512, 512, 2, 366], 165077647124)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [3, 512, 2, 366], 879446899)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [3, 512, 2, 366], 236836271)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [3, 512, 512, 366], 468225501096)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [3, 512, 512, 2], 1381773476)
        end
        
        function test5_1multifile(testCase)
            scan = ne7.scanreader.readscan(testCase.scanFile5_1Multifiles);
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [3, 256, 256, 2, 1500], 515266262098)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [256, 256, 2, 1500], 163553755531)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [3, 256, 2, 1500], 1328396733)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [3, 256, 2, 1500], 734212945)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [3, 256, 256, 1500], 487380452100)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [3, 256, 256, 2], 337564522)
        end
        
        function test2016b(testCase)
            scan = ne7.scanreader.readscan(testCase.scanFile2016b);
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [1, 256, 256, 1, 200], -7855587)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [256, 256, 1, 200], -7855587)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [1, 256, 1, 200], -30452)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [1, 256, 1, 200], -31680)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [1, 256, 256, 200], -7855587)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [1, 256, 256], -42389)
        end
        
        function test2016bmultiroi(testCase)
             scan = ne7.scanreader.readscan(testCase.scanFile2016bMultiroi);
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [10, 500, 250, 1, 100], 71606466393)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [500, 250, 1, 100], 10437019861)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [10, 250, 1, 100], 147185283)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [10, 500, 1, 100], 224378620)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [10, 500, 250, 100], 71606466393)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [10, 500, 250], 663727054)
        end
        
        function test2016bmultiroimultifile(testCase)
            scan = ne7.scanreader.readscan(testCase.scanFile2016bMultiroiMultifiles);
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [10, 500, 250, 1, 200], 141624141678)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [500, 250, 1, 200], 20522111917)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [10, 250, 1, 200], 291067934)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [10, 500, 1, 200], 442948597)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [10, 500, 250, 200], 141624141678)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [10, 500, 250], 663727054)
        end
        
        function test2016bmultiroihard(testCase)
            scan = ne7.scanreader.readscan(testCase.scanFile2016bMultiroiHard);
            
            % Test it can NOT be obtained as array
            testCase.verifyError(@() scan(), 'getitem:FieldDimensionMismatch')
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [800, 512, 2, 10], 2248989268)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [4, 512, 2, 10], 10999488)
            testCase.verifyError(@() scan(:, :, 1, :, :), 'getitem:FieldDimensionMismatch')
            testCase.verifyError(@() scan(:, :, :, 1, :), 'getitem:FieldDimensionMismatch')
            testCase.verifyError(@() scan(:, :, :, :, 1), 'getitem:FieldDimensionMismatch')
            
            % Test indexation for last two slices
            firstColumn = scan(end - 1: end, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [2, 512, 2, 10], 3436369)
            firstChannel = scan(end - 1: end, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [2, 512, 512, 10], 2944468254)
            firstFrame = scan(end - 1: end, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [2, 512, 512, 2], 290883684)
        end
        
        function testadvancedindexing(testCase)
            % TESTADVANCEDINDEXING Testing advanced indexing functionality.
            scan = ne7.scanreader.readscan(testCase.scanFile5_1);
            
            % Testing slices 
            part = scan(:, 1:200, :, 1, end-99: end);
            testCase.assertequalshapeandsum(part, [3, 200, 256, 100],  22309059758)
            part = scan(end:-2:1, :, :, :, :);
            testCase.assertequalshapeandsum(part, [2, 256, 256, 2, 1000], 240032548887)
           
            % Testing lists
            part = scan(:, :, :, [end, 1, 1, 2], :);
            testCase.assertequalshapeandsum(part, [3, 256, 256, 4, 1000], 719471755186)
                       
            % Testing empty indices
            part = scan(:, :, :, 2:1, :);
            testCase.assertequalshapeandsum(part, [0, 0], 0)
            
            % Testing filling last dimensions with 1
            part = scan(:);
            testCase.assertequalshapeandsum(part, [3, 1], 203)
            part = scan(:, 1, 3);
            testCase.assertequalshapeandsum(part, [3, 1], 4896)
            part = scan(:, 1, :);
            testCase.assertequalshapeandsum(part, [3, 256], 863241)
            
            % One field from a page appears twice separated by a field in another page
            scan = ne7.scanreader.readscan(testCase.scanFile2016bMultiroi);
            part = scan([10, 4, 9, 4, 10, 9], :, :, :, :);
            testCase.assertequalshapeandsum(part, [6, 500, 250, 1, 100], 35610995260)
        end
        
        function testjoincontiguous(testCase)
            % TESTJOINCONTIGUOUS Testing whether contiguous fields are joined together.
            scan = ne7.scanreader.readscan(testCase.scanFileJoinContiguous, 'int16', true);
            
            % Test attributes
            testCase.verifyEqual(scan.version, '2016b')
            testCase.verifyEqual(scan.nFields, 5)
            testCase.verifyEqual(scan.nChannels, 1)
            testCase.verifyEqual(scan.nFrames, 100)
            testCase.verifyEqual(scan.nScanningDepths, 5)
            testCase.verifyEqual(scan.scanningDepths, [-40, -20, 0, 20, 40])
            testCase.verifyEqual(scan.fieldDepths, [-40, -20, 0, 20, 40])
            testCase.verifyEqual(scan.isMultiROI, true)
            testCase.verifyEqual(scan.isBidirectional, true)
            testCase.verifyEqual(scan.scannerFrequency, 12045.4)
            testCase.verifyEqual(scan.secondsPerLine, 4.15097e-05)
            testCase.verifyEqual(scan.fps, 3.72926)
            testCase.verifyEqual(scan.spatialFillFraction, 0.9)
            testCase.verifyEqual(scan.temporalFillFraction, 0.712867)
            testCase.verifyEqual(scan.usesFastZ, true)
            testCase.verifyEqual(scan.nRequestedFrames, 500)
            testCase.verifyEqual(scan.scannerType, 'Resonant')
            testCase.verifyEqual(scan.motorPositionAtZero, [0, 0, 0])
            
            testCase.verifyEqual(scan.nRois, 2)
            testCase.verifyEqual(scan.fieldHeights, [500, 500, 500, 500, 500])
            testCase.verifyEqual(scan.fieldWidths, [500, 500, 500, 500, 500])
            testCase.verifyEqual(scan.fieldSlices, [1, 2, 3, 4, 5])
            testCase.verifyEqual(scan.fieldRois, {[1, 2], [1, 2], [1, 2], [1, 2], [1, 2]})
            roiMask = ones(500, 500); roiMask(:, 251:500) = 2;
            testCase.verifyEqual(scan.fieldMasks, {roiMask, roiMask, roiMask, roiMask, roiMask})
            testCase.verifyEqual(cellfun(@(offsets) max(max(offsets)), scan.fieldOffsets), ...
                [0.047568, 0.101198, 0.154829, 0.208460, 0.262090], 'absTol', 1e-4)
            testCase.verifyEqual(scan.fieldHeightsInMicrons, [1000, 1000, 1000, 1000, 1000], 'absTol', 1e-4)
            testCase.verifyEqual(scan.fieldWidthsInMicrons, [1000, 1000, 1000, 1000, 1000], 'absTol', 1e-4)
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [5, 500, 500, 1, 100], 71606466393)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [500, 500, 1, 100], 18725846688)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [5, 500, 1, 100], 147185283)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [5, 500, 1, 100], 116583780)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [5, 500, 500, 100], 71606466393)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [5, 500, 500], 663727054)  
        end
        
        function testexceptions(testCase)
            % TESTEXCEPTIONS Tests some exceptions are raised correctly.
            scan = ne7.scanreader.readscan(testCase.scanFile5_1);
            
            % Too many dimensions
            testCase.verifyError(@() scan(1, 2, 3, 4, 5, 6), 'fillkey:IndexError')
            
            % Out of bounds, shape is (3, 256, 256, 2, 1000)
            testCase.verifyError(@() scan(4), 'checkindexisinbounds:IndexError')
            testCase.verifyError(@() scan(:, 257), 'checkindexisinbounds:IndexError')
            testCase.verifyError(@() scan(:, :, 257), 'checkindexisinbounds:IndexError')
            testCase.verifyError(@() scan(:, :, :, 3), 'checkindexisinbounds:IndexError')
            testCase.verifyError(@() scan(:, :, :, :, 1001), 'checkindexisinbounds:IndexError')
            
            % Wrong index type
            testCase.verifyError(@() scan(1, 'sup'), 'checkindextype:TypeError')
            testCase.verifyError(@() scan([true, false, true]), 'checkindextype:TypeError')
            testCase.verifyError(@() scan(0.1), 'checkindextype:TypeError')
            
            % No file on disk error
            testCase.verifyError(@() ne7.scanreader.readscan('unexistent_file.tif'), 'readscan:PathnameError')
        end
    end
    
    methods
        % Local functions
        function assertequalshapeandsum(testCase, array, expectedShape, expectedSum)
            testCase.verifyEqual(size(array), expectedShape)
            testCase.verifyEqual(sum(array(:)), expectedSum)
        end
    end
end