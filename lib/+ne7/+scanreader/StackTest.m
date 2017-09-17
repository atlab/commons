classdef StackTest < matlab.unittest.TestCase
    %STACKTEST Test stacks from different ScanImage versions.
    properties
       dataDir = '/home/ecobost/Documents/scanreader/data'
       stackFile5_1 % 2 channels, 60 slices
       stackFile5_1Multifiles % second has 10 slices
    end
    
    methods (TestClassSetup)
        function createfilenames(testCase)
            testCase.stackFile5_1 = fullfile(testCase.dataDir, 'stack_5_1_001.tif');
            testCase.stackFile5_1Multifiles = {fullfile(testCase.dataDir, 'stack_5_1_001.tif'), fullfile(testCase.dataDir, 'stack_5_1_002.tif')};
        end
    end
    
    methods (Test)
        
        function testattributes (testCase)
            
            % 5.1
            scan = ne7.scanreader.readstack(testCase.stackFile5_1);
            testCase.verifyEqual(scan.version, '5.1')
            testCase.verifyEqual(scan.nFields, 60)
            testCase.verifyEqual(scan.nChannels, 2)
            testCase.verifyEqual(scan.nFrames, 25)
            testCase.verifyEqual(scan.nScanningDepths, 60)
            testCase.verifyEqual(scan.requestedScanningDepths, 0:309)
            testCase.verifyEqual(scan.scanningDepths, 0:59)
            testCase.verifyEqual(scan.fieldDepths, 0:59)
            testCase.verifyEqual(scan.isMultiROI, false)
            testCase.verifyEqual(scan.isBidirectional, false)
            testCase.verifyEqual(scan.scannerFrequency, 7919.95)
            testCase.verifyEqual(scan.secondsPerLine, 0.000126264, 'absTol', 1e-5)
            testCase.verifyEqual(scan.fps, 0.0486657)
            testCase.verifyEqual(scan.spatialFillFraction, 0.9)
            testCase.verifyEqual(scan.temporalFillFraction, 0.712867)
            testCase.verifyEqual(scan.usesFastZ, false)
            testCase.verifyEqual(scan.nRequestedFrames, 25)
            testCase.verifyEqual(scan.scannerType, 'Resonant')
            testCase.verifyEqual(scan.motorPositionAtZero, [0.5, 0, -320.4])
            
            testCase.verifyEqual(scan.imageHeight, 512)
            testCase.verifyEqual(scan.imageWidth, 512)
            testCase.verifyEqual(size(scan), [60, 512, 512, 2, 25])
            testCase.verifyEqual(scan.zoom, 2.1)
        end
        
        function test5_1(testCase)
            scan = ne7.scanreader.readstack(testCase.stackFile5_1);
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [60, 512, 512, 2, 25], 1766199881650)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [512, 512, 2, 25], 27836374986)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [60, 512, 2, 25], 2838459027)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [60, 512, 2, 25], 721241569)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [60, 512, 512, 25], 1649546136958)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [60, 512, 512, 2], 69769537416)
        end
        
        function test5_1multifile(testCase)
            scan = ne7.scanreader.readstack(testCase.stackFile5_1Multifiles);
            
            % Test it can be obtained as array
            scanAsArray = scan();
            testCase.assertequalshapeandsum(scanAsArray, [70, 512, 512, 2, 25], 2021813090863)
            
            % Test indexation
            firstField = scan(1, :, :, :, :);
            testCase.assertequalshapeandsum(firstField, [512, 512, 2, 25], 27836374986)
            firstRow = scan(:, 1,  :, :, :);
            testCase.assertequalshapeandsum(firstRow, [70, 512, 2, 25], 3294545077)
            firstColumn = scan(:, :, 1, :, :);
            testCase.assertequalshapeandsum(firstColumn, [70, 512, 2, 25], 885838245)
            firstChannel = scan(:, :, :, 1, :);
            testCase.assertequalshapeandsum(firstChannel, [70, 512, 512, 25], 1832276046863)
            firstFrame = scan(:, :, :, :, 1);
            testCase.assertequalshapeandsum(firstFrame, [70, 512, 512, 2], 79887927681)
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

