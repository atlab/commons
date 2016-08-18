classdef Reader5 < handle
    %  ne7.scanimage.Reader5 is a ScanImage filereader with random access
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
        data
        files
        stacks
        header
        scanimage_version
        nframes
        frames_per_file
    end
        
    properties(Dependent)
        nslices
        channels
        nchannels
        requested_frames
        zoom
        slice_pitch
        fps
        dwell_time
        bidirectional
        fill_fraction
        is_functional
    end
    
    methods
        
        function self = Reader5(path)
            % r = reso.reader('/fullpath/file_001_*.tif')
            % Opens the stack reader.  All files that match the mask are
            % treated as one movie.  The files matching the mask are sorted
            % alphanumerically.
            
            self.find_files(path)
            self.load_header
            self.init_stacks
            self.compute_nframes
            
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
        
        function f = get.is_functional(self)
            if self.scanimage_version == 4
                f = 1;
                %f = self.header.fastZEnable;
            else
                f = self.header.hFastZ_enable;
            end
        end
        
        
        function n = get.nslices(self)
            if self.scanimage_version == 4
                n = self.header.stackNumSlices;
            else
                n = self.header.hStackManager_numSlices;
                %assert(n == self.header.hFastZ_numFramesPerVolume)
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
                if self.header.hFastZ_enable
                    n = self.header.hFastZ_numVolumes;
                else
                    n = hStackManager_framesPerSlice;
                end
            end
            
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
            if self.is_functional
                sz(1) = self.header.hRoiManager_linesPerFrame; % not sure this is lines or pixels (JR)
                sz(2) = self.header.hRoiManager_pixelsPerLine; % not sure this is lines or pixels (JR)
                sz(3) = self.nchannels;
                sz(4) = self.nslices;
                sz(5) = self.nframes;
            else
                sz = size(self.data);
            end
        end
        
        
        function data = subsref(self, S)
            if ~strcmp(S(1).type, '()')
                data = builtin('subsref', self, S);
            elseif ~self.is_functional
                data = builtin('subsref', self.data, S);
            else
                assert(length(S.subs)==5, 'subscript error')
                sz = size(self);
                
                yInd = S.subs{1};
                if ischar(yInd) && strcmp(yInd, ':')
                    yInd = 1:sz(1);
                end
                assert(isnumeric(yInd) && all(yInd == round(yInd)) &&...
                    all(yInd >= 1) && all(yInd <= sz(1)), 'invalid pixel subscripts')
                
                xInd = S.subs{2};
                if ischar(xInd) && strcmp(xInd, ':')
                    xInd = 1:sz(2);
                end
                assert(isnumeric(xInd) && all(xInd == round(xInd)) &&...
                    all(xInd >= 1) && all(xInd <= sz(2)), 'invalid line subscripts')
                
                chanInd = S.subs{3};
                if ischar(chanInd) && strcmp(chanInd, ':')
                    chanInd = 1:self.nchannels;
                end
                assert(isnumeric(chanInd) && all(chanInd == round(chanInd)) &&...
                    all(chanInd >= 1) && all(chanInd <= self.nchannels), 'invalid channel subscript')
                
                sliceInd = S.subs{4};
                if ischar(sliceInd) && strcmp(sliceInd, ':')
                    sliceInd = 1:self.nslices;
                end
                assert(isnumeric(sliceInd) && all(sliceInd == round(sliceInd)) &&...
                    all(sliceInd >= 1) && all(sliceInd <= self.nslices), 'invalid slice subscript')
                
                frameInd = S.subs{5};
                if ischar(frameInd) && strcmp(frameInd, ':')
                    frameInd = 1:self.nframes;
                end
                assert(isnumeric(frameInd) && all(frameInd == round(frameInd)) &&...
                    all(frameInd >= 1) && all(frameInd <= self.nframes), 'invalid frame subscript')
                
                ind = false(sz(3:5));
                ind(chanInd,sliceInd,frameInd) = true;
                
                data = zeros([length(yInd) length(xInd) length(chanInd)*length(sliceInd)*length(frameInd)], 'int16');
                k=1;
                for i=1:length(self.stacks)
                    stackInd = find(ind(sum(self.frames_per_file(1:i-1))+1 : sum(self.frames_per_file(1:i))));
                    for j=stackInd
                        setDirectory(self.stacks{i},j);
                        f = read(self.stacks{i});
                        data(:,:,k) = f(yInd,xInd);
                        k=k+1;
                    end
                end
                data = reshape(data,[length(yInd) length(xInd) length(chanInd) length(sliceInd) length(frameInd)]);
            end
        end
        
    end
    
    
    methods(Access=private)
        
        function compute_nframes(self)
            % actually acquired frames or volumes
            if self.scanimage_version == 4
                n = self.header.acqNumFrames;
            else
                n = (length(self.files)-1) * self.header.hScan2D_logFramesPerFile;
                
                disp('Reading number of frames in last file...');
                k=1; 
                while ~lastDirectory(self.stacks{end})
                    nextDirectory(self.stacks{end}); 
                    k=k+1; 
                end; 
                setDirectory(self.stacks{end},1);
                
                n = floor((n + (k / self.nchannels)) / self.nslices);
                
%                 assert(n == round(n),'Total nframes / nslices must be an integer. Maybe scan aborted?')
            end
            self.nframes = n;
            self.frames_per_file(1:length(self.files)-1) = deal(self.header.hScan2D_logFramesPerFile * self.nchannels);
            self.frames_per_file(length(self.files)) = n - sum(self.frames_per_file);

        end
        
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
            if isempty(hdr)
                hdr = textscan(tiff.getTag('Software'),'%s','Delimiter',char(10));
                hdr = strtrim(hdr{1});
                self.scanimage_version = 5.2;
                temp = regexp(hdr, '^SI4\.(?<attr>\w*)\s*=\s*(?<value>.*\S)\s*$', 'names');
                hdr = temp;
                hdr = [hdr{~cellfun(@isempty, hdr)}];
            end
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
            if self.is_functional
                self.stacks = arrayfun(@(ifile) ...
                    Tiff(self.files{ifile}), ...
                    1:length(self.files), 'uni', false);
                
                %self.stacks = arrayfun(@(ifile) ...
                %    TIFFStack(self.files{ifile}, [], [self.nchannels self.nslices]), ...
                %    1:length(self.files), 'uni', false);
                
                %self.stacks = arrayfun(@(ifile) TIFFStack(self.files{ifile}),1:length(self.files), 'uni', false);
            else
                % if structural data, then load the entire stack into
                % memory. The loaded data is initially flat and needs
                % reshaping as well as permutation of axis as frames and
                % slices are flipped.
                data = [];
                for idx = 1:length(self.files)
                    stack = TIFFStack(self.files{idx}, [], self.nchannels);
                    data = cat(4, data, stack(:,:,:,:));
                end
                sz = size(data);
                assert(sz(4) == self.nframes * self.nslices, ...
                    sprintf(['stack size mismatch: expected %d images but only %d '...
                    'found -- be sure to load all files together'], self.nframes*self.nslices, sz(4)));
                sz = [sz(1:end-1) self.nframes self.nslices];
                self.data = permute(reshape(data, sz), [1,2,3,5,4]);
            end
        end
        
    end
end