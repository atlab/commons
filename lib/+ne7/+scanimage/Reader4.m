classdef reader < handle
    %  pre.reader is a ScanImage filereader with random access indexed as reader(col, row, frame, slice, channel)
    %
    %  Usage:
    %    r = reader(path)
    %    r(:,:,:,:,2);  % the entire stack from channel 2
    %    r(:,:,1:10,1,2);   % first ten frames from slice 1 from channel 2
    
    properties(SetAccess=private)
        files
        stacks
        header
    end
    
    properties(Dependent)
        nslices
        channels
        nframes
    end
    
    methods
        
        function self = reader(path)
            % r = reso.reader('/fullpath/files.tif')
            % If path.ext is not found, look for 'path_001.ext'. If found,
            % then loads all files matching pattern 'path_%03u.ext';
            
            self.find_files(path)
            self.load_header
            self.init_stacks
        end
        
        function n = get.nslices(self)
            n = self.header.stackNumSlices;
        end
        
        function channels = get.channels(self)
            channels = self.header.channelsSave;
        end
        
        function n = get.nframes(self)
            n = sum(cellfun(@(s) size(s, 5), self.stacks));
        end
        
        function sz = size(self)
            sz = size(self.stacks{1});
            sz(5) = self.nframes;
        end
        
        function data = subsref(self, S)
            if ~strcmp(S.type, '()')
                data = builtin('subsref', self, S);
            else
                assert(length(S.subs)==5, 'subscript error')
                frame_indices = S.subs{5};
                if isequal(frame_indices, ':')
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
            if exist(path,'file')==2
                self.files = {path};
            else
                [p,f,e] = fileparts(path);
                index = 1;
                path = fullfile(p,sprintf('%s_%03u%s',f,index,e));
                assert(exist(path, 'file')==2, 'Files %s or %s not found', path, fullfile(p,[f e]))
                while exist(path, 'file')
                    self.files{index} = path;
                    index = index + 1;
                    path = fullfile(p,sprintf('%s_%03u%s',f,index,e));
                end
            end
        end
        
        function load_header(self)
            % read header information from the first frame
            tiff = Tiff(self.files{1});
            hdr = textscan(tiff.getTag('ImageDescription'),'%s','Delimiter',char(10));
            hdr = strtrim(hdr{1});
            hdr = regexp(hdr, '^scanimage\.SI4\.(?<attr>\w*)\s*=\s*(?<value>.*\S)\s*$', 'names');
            hdr = [hdr{~cellfun(@isempty, hdr)}];
            assert(~isempty(hdr), 'empty header -- possibly wrong ScanImage version.') 
            self.header = cell2struct(cellfun(@(x) {evaluate(x)}, {hdr.value})', {hdr.attr});
            
            function str = evaluate(str)
                % if str is not in the form '<value>', then evaluate it.
                if str(1)~='<' && str(end)~='>'
                    str = eval(str);
                end
            end
        end
        
        function init_stacks(self)
            self.stacks = arrayfun(@(ifile) ...
                TIFFStack(self.files{ifile}, [], [self.nslices length(self.channels)]), ...
                1:length(self.files), 'uni', false);
        end
        
    end
end