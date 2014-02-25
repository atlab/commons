%{
reso.Trace (imported) # calcium trace
-> reso.Segment
trace_id   : smallint   #  mask number in segmentation
-----
ca_trace   : longblob   # raw calcium trace
%}

classdef Trace < dj.Relvar 

    methods
        
        function makeTuples(self, key)
            
            reader = getReader(reso.Align & key);
            [masks,slices] = fetchn(reso.Segment & key, 'mask');
            xymotion = fetch1(reso.Align & key, 'motion_xy');
            
            nSlices = length(slices);
            assert(reader.nSlices == nSlices)
            
            % extract pixels for each trace
            pixels = ...
                cellfun(@(mask) arrayfun(@(x) x.PixelIdxList, ...
                regionprops(logical(mask),'PixelIdxList'), 'uni', false), ...
                masks, 'uni', false);
            
            disp 'loading traces...'
            traces = cell(nSlices, 1);
            blockSize = 500;
            [rasterPhase, fillFraction] = fetch1(reso.Align & key, ...
                'raster_phase', 'fill_fraction');
            while ~reader.done
                block = getfield(reader.read(1, 1:reader.nSlices, blockSize),'channel1'); %#ok<GFLD>
                xy = xymotion(:,:,1:size(block,4));
                xymotion(:,:,1:size(block,4)) = [];
                block = reso.Align.correctRaster(block, rasterPhase, fillFraction);
                block = reso.Align.correctMotion(block, xy);
                sz = size(block);
                for iSlice = 1:length(slices)
                    t = reshape(block(:,:,iSlice,:), [], sz(4));
                    t = cellfun(@(ix) mean(t(ix,:),1)', pixels{iSlice}, 'uni', false);
                    traces{iSlice} = cat(1,traces{iSlice},cat(2,t{:}));
                end
                fprintf('%5d frames\n', size(traces{1},1))
            end
            
            disp 'saving traces...'
            for iSlice = 1:nSlices
                tuple = slices(iSlice);
                for iTrace=1:size(traces{iSlice},2)
                    tuple.trace_id = iTrace;
                    tuple.ca_trace = single(traces{iSlice}(:,iTrace));
                    self.insert(tuple)
                end
            end
        end
    end
end
