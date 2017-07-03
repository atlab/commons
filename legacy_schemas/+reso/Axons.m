%{
reso.Axons (computed) # axon metrics and traces
-> reso.AxonMask
axon_idx            : int       # axon index
-----
axon_x              : float     # centroid x position in image (pixels)
axon_y              : float     # centroid y position in image (pixels)
axon_area           : float     # area (pixels)
axon_eccentricity   : float     # eccentricity of axon region (0 = circular, 1 = line)
axon_mean           : float     # mean fluorescence of segmented pixels
axon_trace          : longblob  # calcium trace of segmented pixels
%}

classdef Axons < dj.Relvar & dj.AutoPopulate

	properties
		popRel  = reso.AxonMask
	end

	methods(Access=protected)

		function makeTuples(self, key)
            mask = fetch1(reso.AxonMask & key, 'axon_mask');
            mask = bwlabel(mask);
            img = fetch1(reso.Align & key, 'green_img');
            
            nTraces = max(mask(:));
            iSlice = key.slice_num;
            
            reader = reso.getReader(key);
            [xymotion, rasterPhase, fillFraction] = fetch1(reso.Align & key, ...
                'motion_xy', 'raster_phase', 'fill_fraction');
            
            % extract pixels for each trace
            regions = regionprops(mask,img,'PixelIdxList','Centroid','Area','Eccentricity','MeanIntensity');  %#ok<MRPBW>
            
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

            for i = 1:length(regions)
                tuple = key;
                tuple.axon_idx = i;
                tuple.axon_x = regions(i).Centroid(1);
                tuple.axon_y = regions(i).Centroid(2);
                tuple.axon_area = regions(i).Area;
                tuple.axon_eccentricity = regions(i).Eccentricity;
                tuple.axon_mean = regions(i).MeanIntensity;
                tuple.axon_trace = single(traces(:,i));
                self.insert(tuple)
            end
		end
	end

end