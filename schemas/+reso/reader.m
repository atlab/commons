classdef reader < handle
    % scanimage 4.0 sequential reader
    
    properties(SetAccess=private)
        fullfile 
        path
        base
        scanNumber
        
        
        tiff
        hdr
        multifile
        currentFrame
        done
        
        currentFileNumber
    end
    
    properties(Dependent)
        filename
        nSlices
        channels
    end
    
    methods
        function f = get.filename(self)
            if ~isempty(self.fullfile)
                f = self.fullfile;
            else
                if ~self.multifile
                    f = getLocalPath(fullfile(self.path,sprintf('%s_%03u.tif', self.base, self.scanNumber)));
                else
                    f = getLocalPath(fullfile(self.path,sprintf('%s_%03u_%03u.tif', self.base, self.scanNumber, self.currentFileNumber)));
                end
            end
        end
        
        function self = reader(path, base, scanNumber)
            % r = reso.reader('/fullpath/fullfile.tif')
            % OR
            % r = reso.reader('path', 'basename', scanNumer)
            
            self.multifile = false;
            if exist(path,'file')
                self.fullfile = path;
            else
                self.path = path;
                self.base = base;
                self.scanNumber = scanNumber;
                if ~exist(self.filename,'file')
                    self.multifile = true;
                    self.currentFileNumber = 1;
                    assert(exist(self.filename,'file')==2, 'can''t find scanimage file "%s"', self.filename)
                end
            end
            
            % open Tiff
            self.tiff = Tiff(self.filename, 'r');
            self.currentFrame = 0;
            self.done = false;
            
            % read header
            self.hdr = self.tiff.getTag('ImageDescription');
            self.hdr = textscan(self.hdr,'%s','Delimiter',char([10]));
            self.hdr = strtrim(self.hdr{1});
            self.hdr = regexp(self.hdr,'^scanimage\.SI4\.(?<attr>\w*)\s*=(?<value>.*)$','names');
            self.hdr = self.hdr(~cellfun(@isempty,self.hdr));
            self.hdr = cellfun(@(x) struct('attr',x.attr,'value',{evaluate(x.value)}), self.hdr, 'uni',false);
            assert(~isempty(self.hdr), 'empty header -- possibly wrong ScanImage version')
            s = struct;
            for h = [self.hdr{:}]
                s.(h.attr) = h.value;
            end
            self.hdr = s;
            
            function v = evaluate(str)
                str = strtrim(str);
                if regexp(str,'^<.*>$')
                    v = str;
                else
                    v = eval(str);
                end
            end
        end
        
        function reset(self)
            self.done = false;
            self.currentFrame = 0;
            self.tiff.setDirectory(1);
            if self.multifile
                self.currentFileNumber = 1;
            end
            
        end
        
        
        function advance(self)
            % advance to next directory
            if ~self.tiff.lastDirectory
                try
                    self.tiff.nextDirectory;
                catch err
                    disp(err)
                    self.done = true;
                end
            else
                if ~self.multifile
                    self.done = true;
                else
                    % advance to next file
                    self.currentFileNumber = self.currentFileNumber+1;
                    self.done = ~exist(self.filename,'file');
                    if ~self.done
                        self.tiff = Tiff(self.filename);
                    end
                end
            end
        end
        
        
        function n = get.nSlices(self)
            n = self.hdr.stackNumSlices;
        end
        
        
        function channels = get.channels(self)
            channels = self.hdr.channelsSave;
        end
        
        
        function block = read(self, channels, slices, blockSize)
            % [stack1, stack2, ...] = reader.readBlock(channels, slices, blockSize)
            % Read scanimage4 tiff file.
            % INPUTS:
            %   channels: list of channels to read, will be returned in spearate output arguments
            %   slices:  list of slices to read in each channel
            %   bloackSize: number of frames (stacks)
            
            assert(all(slices>=1 & slices <= self.nSlices), 'invalid slice indices')
            assert(all(ismember(channels, self.channels)), ...
                'requested channel was not recorded')
            sz = [self.hdr.scanLinesPerFrame self.hdr.scanPixelsPerLine length(slices) blockSize];
            blocks = repmat({nan(sz)}, length(channels), 1);
            for iFrame=1:blockSize
                self.currentFrame = self.currentFrame + 1;
                for iSlice = 1:self.nSlices
                    for iChannel = self.channels(:)'
                        % read frame
                        if ismember(iChannel, channels) && ismember(iSlice, slices)
                            blocks{iChannel==channels}(:,:,iSlice==slices,iFrame) = self.tiff.read;
                        end
                        self.advance
                        if self.done, break, end
                    end
                    if self.done, break, end
                end
                if self.done, break, end
            end
            
            % remove extra frames
            if ~isempty(blocks)
                ix = find(any(any(any(isnan(blocks{self.channels==channels(end)}),1),2),3),1,'first');
                if ix
                    for iChannel = 1:length(channels)
                        blocks{iChannel==channels}(:,:,:,ix:end)=[];
                    end
                end
                
                block = struct;
                for i = 1:length(channels)
                    block.(sprintf('channel%u',channels(i))) = blocks{i};
                end
            end
        end
    end
end