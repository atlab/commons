classdef Reader4 < handle
    %  ne7.scanimage.Reader4 is a ScanImage filereader with random access
    %  indexed as reader(col, row, frame, slice, channel).
    %  It works with scanimage 4 and scanimage 5.
    %
    %  The reader can then be addressed with subscripts 
    %         reader(y, x, channel, slice, frame)
    %
    %  Example:
    %    r = reader(filename_mask)
    %    r(:,:,2,:,:);  % the entire stack from channel 2
    %    r(:,:,2,1,1:10);   % first ten frames from slice 1 from channel 2
    
    properties(SetAccess=private)
        files
        stacks
        header
        scanimage_version
    end
    
    properties(Dependent)
        nslices
        channels
        nchannels
        nframes
        requested_frames
        zoom
        slice_pitch
        fps
        dwell_time
        bidirectional
        fill_fraction
    end
    
    methods
        
        function self = Reader4(path)
            % r = reso.reader('/fullpath/file_001_*.tif')
            % Opens the stack reader.  All files that match the mask are
            % treated as one movie.  The files matching the mask are sorted
            % alphanumerically.
            
            self.find_files(path)
            self.load_header
            self.init_stacks
            
            if self.scanimage_version == 4
                assert(strcmp(self.header.fastZImageType, 'XY-Z'), ...
                    'we assume XY-Z scanning')
                assert(self.header.acqNumAveragedFrames==1, 'averaging should be disabled')
                assert(self.header.scanAngleMultiplierSlow == 1 && ...
                    self.header.scanAngleMultiplierFast == 1, 'altered scanAngleMultipliers');
            else
                assert(strcmp(self.header.hMotors_motorDimensionConfiguration, 'xyz-z'), ...
                    'we assume xyz-z scanning')
                % TODO: Figure out what the averaging fields are called in scanimage5
                
            end
        end
        
        function n = get.nslices(self)
            if self.scanimage_version == 4
                n = self.header.stackNumSlices;
            else
                n = self.header.hStackManager_numSlices;
                assert(n == self.header.hFastZ_numFramesPerVolume)
            end
        end
        
        function f = get.fill_fraction(self)
            if self.scanimage_version == 4
                f = self.header.scanFillFraction;
            else
                f = self.header.hScan2D_fillFractionTemporal;
            end
        end
        
        function fps = get.fps(self)
            if self.scanimage_version == 4
                if self.header.fastZActive
                    fps = 1/self.header.fastZPeriod;
                else
                    assert(self.nslices==1)
                    fps = self.header.scanFrameRate;
                end
            else
                if self.nslices >= 1
                    %fps = 1/self.header.hFastZ_period;
                    fps = self.header.hRoiManager_scanVolumeRate;
                else
                    fps = self.header.hRoiManager_scanFrameRate;
                end
            end
        end
        
        function p = get.slice_pitch(self)
            if self.scanimage_version == 4
                if self.header.fastZActive
                    p = self.header.stackZStepSize;
                else
                    p = 0;
                end
            else
                p = self.header.hStackManager_stackZStepSize;
            end
        end
        
        function channels = get.channels(self)
            if self.scanimage_version == 4
                channels = self.header.channelsSave;
            else
                channels = self.header.hChannels_channelSave;
            end
        end
        
        function n = get.requested_frames(self)
            if self.scanimage_version == 4
                if self.header.fastZActive
                    n = self.header.fastZNumVolumes;
                else
                    n = self.header.acqNumFrames;
                end
            else
                n = self.header.hFastZ_numVolumes;
            end
            
        end
        
        function n = get.nframes(self)
            % actually acquired frames
            n = sum(cellfun(@(s) size(s, 5), self.stacks));
        end
        
        function yes = get.bidirectional(self)
            if self.scanimage_version == 4
                yes = ~strncmpi(self.header.scanMode, 'uni', 3);
            else
                yes = self.header.hScan2D_bidirectional;
            end
        end
        
        function t = get.dwell_time(self)
            if self.scanimage_version == 4
                t = self.header.scanPixelTimeMean*1e6;
            else
                t = self.header.hScan2D_scanPixelTimeMean*1e6;
            end
        end
        
        function n = get.nchannels(self)
            n = length(self.channels);
        end
        
        function z = get.zoom(self)
            if self.scanimage_version == 4
                z = self.header.scanZoomFactor;
            else
                z = self.header.hRoiManager_scanZoomFactor;
            end
        end
        
        function sz = size(self)
            sz = size(self.stacks{1});
            sz(5) = self.nframes;
        end
        
        
        function data = subsref(self, S)
            if ~strcmp(S(1).type, '()')
                data = builtin('subsref', self, S);
            else
                assert(length(S.subs)==5, 'subscript error')
                frame_indices = S.subs{5};
                if ischar(frame_indices) && strcmp(frame_indices, ':')
                    frame_indices = 1:self.nframes;
                end
                subs = S.subs(1:4);
                assert(isnumeric(frame_indices) && ...
                    all(frame_indices == round(frame_indices)) && ...
                    all(frame_indices >= 1) && ...
                    all(frame_indices <= self.nframes), ...
                    'invalid frame subscript')
                data = zeros(0, 'int16');
                for i=1:length(frame_indices)
                    iframe = frame_indices(i);
                    for istack=1:length(self.stacks)
                        frames_in_stack = size(self.stacks{istack}, 5);
                        if iframe <= frames_in_stack
                            data(:,:,:,:,i) = self.stacks{istack}(subs{:}, iframe);
                            break
                        else
                            iframe = iframe - frames_in_stack;
                        end
                    end
                end
            end
        end
        
    end
    
    
    methods(Access=private)
        
        function find_files(self, path)
            file_list = dir(path);  % may contain a wild card
            assert(~isempty(file_list), 'Files %s not found %s', path)
            self.files = sort(...
                cellfun(@(f) fullfile(fileparts(path),f), {file_list.name}, 'uni', false));
        end
        
        function load_header(self)
            % read header information from the first frame
            tiff = Tiff(self.files{1});
            hdr = textscan(tiff.getTag('ImageDescription'),'%s','Delimiter',char(10));
            hdr = strtrim(hdr{1});
            self.scanimage_version = 4;
            temp = regexp(hdr, '^scanimage\.SI4\.(?<attr>\w*)\s*=\s*(?<value>.*\S)\s*$', 'names');
            if all(cellfun(@isempty, temp))
                self.scanimage_version = 5;
                temp = regexp(hdr, '^scanimage\.SI\.(?<attr>[\.\w]*)\s*=\s*(?<value>.*\S)\s*$', 'names');
            end
            hdr = temp;
            hdr = [hdr{~cellfun(@isempty, hdr)}];
            assert(~isempty(hdr), 'empty header -- possibly wrong ScanImage version.')
            self.header = cell2struct(cellfun(@(x) {evaluate(x)}, {hdr.value})', strrep({hdr.attr}, '.', '_'));
            
            
            function str = evaluate(str)
                % if str is not in the form '<value>', then evaluate it.
                if str(1)~='<' && str(end)~='>'
                    str = eval(str);
                end
            end
        end
        
        function init_stacks(self)
            self.stacks = arrayfun(@(ifile) ...
                TIFFStack(self.files{ifile}, [], [length(self.channels) self.nslices]), ...
                1:length(self.files), 'uni', false);
        end
        
    end
end