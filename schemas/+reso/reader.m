classdef reader < Tiff
    % scanimage 4.0 reader
    
    properties(SetAccess=private)
        hdr
    end
    
    methods
        function self = reader(path, base, number)
            filename = getLocalPath(fullfile(path,sprintf('%s_%03u.tif', base, number)));
            
            % clean up filename
            if iscellstr(filename)
                assert(numel(filename)==1, 'one file at a time');
                filename = filename{1};
            end
            filename = strtrim(filename);
            if isempty(regexp(filename,'\.tif?f$','once'))
                filename = [filename '.tif'];
            end
            
            % open Tiff
            self = self@Tiff(filename, 'r');
            
            % read header
            self.hdr = self.getTag('ImageDescription');
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
        
        
        function varargout = readBlock(self, channels, slices, blockSize)
            % [stack1, stack2, ...] = reader.readBlock(channels, slices, blockSize)
            % Read scanimage4 tiff file.
            % INPUTS:
            %   channels: list of channels to read, will be returned in spearate output arguments
            %   slices:  list of slices to read in each channel
            %   bloackSize: number of frames (stacks)
            
            nSlices = self.hdr.stackNumSlices;
            assert(all(slices>=1 & slices <= nSlices), 'invalid slice indices')
            assert(all(ismember(channels, self.hdr.channelsSave)), ...
                'requested channel was not recorded')
            sz = [self.hdr.scanLinesPerFrame self.hdr.scanPixelsPerLine length(slices) blockSize];
            blocks = repmat({nan(sz)}, length(channels), 1);
            done = false;
            for iFrame=1:blockSize
                for iSlice = 1:nSlices
                    for iChannel = self.hdr.channelsSave
                        % read frame
                        if ismember(iChannel, channels) && ismember(iSlice, slices)
                            blocks{iChannel==channels}(:,:,iSlice==slices,iFrame) = self.read;
                        end
                        try
                            self.nextDirectory
                        catch
                            done = true;
                            for i=1:length(channels)
                                blocks{i}(:,:,:,iFrame:end)=[];
                            end
                            break
                        end
                    end
                    if done, break, end
                end
                if done, break, end
            end
            varargout = blocks;
        end
    end
end