%{
reso.AxonTraces (computed) # my newest table
-> reso.Axons
-----
axon_traces : longblob    # calcium traces from regions of the mask in reso.Axons
%}

classdef AxonTraces < dj.Relvar & dj.AutoPopulate

	properties
		popRel  = reso.Axons
	end

	methods(Access=protected)

		function makeTuples(self, key)
            mask = fetch1(reso.Axons & key, 'axon_mask');
            mask = bwlabel(mask);
            nTraces = max(mask(:));
            iSlice = key.slice_num;
            
            reader = reso.getReader(key);
            [xymotion, rasterPhase, fillFraction] = fetch1(reso.Align & key, ...
                'motion_xy', 'raster_phase', 'fill_fraction');
            
            % extract pixels for each trace
            regions = regionprops(mask,'PixelIdxList');  %#ok<MRPBW>
            
            disp 'loading traces...'
            nTimes = size(xymotion,3);
            traces = zeros(nTimes,nTraces);
            
            blockSize = 500;           
            for i=1:blockSize:nTimes-1
                ix =i:min(nTimes,i+blockSize-1);
                block = getfield(reader.read(1, iSlice, length(ix)), 'channel1'); %#ok<GFLD>
                block = reso.Align.correctRaster(block, rasterPhase, fillFraction);
                block = reso.Align.correctMotion(block, xymotion(:,iSlice,ix));
                t = reshape(block(:,:,1,:), [], length(ix));
                t = arrayfun(@(reg) mean(t(reg.PixelIdxList,:),1)', regions, 'uni', false);
                traces(ix,:) = [t{:}];
                fprintf('%5d / %5d frames\n', ix(end), nTimes);
            end

            key.axon_traces = single(traces);
			self.insert(key)
		end
	end

end