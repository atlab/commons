%{
reso.ConditionMap (imported) # site averages conditioned on reso.Indicator
-> reso.Indicator
-> reso.VolumeSlice
---
mean_map        : longblob     # pixelwise average for frames where reso.Indicator=1
std_map         : longblob     # pixelwise std for frames where reso.Indicator=1
%}

classdef ConditionMap < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.ConditionMap')
        popRel = reso.Align & reso.Indicator
    end
    
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            reader = reso.getReader(reso.Align & key);
            [fillFraction, rasterPhase] = fetch1(reso.Align & key, 'fill_fraction', 'raster_phase');
            for iSlice=1:reader.nSlices
                fprintf('loading slice %d: \n', iSlice);
                reader.reset
                blockSize = 500;
                xymotion = fetch1(reso.Align & key, 'motion_xy');
                xymotion(:,:,end+1) = xymotion(:,:,end);  %#ok<AGROW> % extend by one frame
                
                [width,height,nFrames] = fetch1(reso.Align*reso.ScanInfo & key, ...
                    'px_width','px_height','nframes');
                X = nan(nFrames,width,height,'single');
                lastPos = 0;
                while ~reader.done
                    block = getfield(reader.read(1, iSlice, blockSize),'channel1'); %#ok<GFLD>
                    sz = size(block);
                    xy = xymotion(:,:,1:sz(4));
                    xymotion(:,:,1:size(block,4)) = [];
                    block = reso.Align.correctRaster(block,rasterPhase,fillFraction);
                    block = reso.Align.correctMotion(block, xy);
                    X(lastPos+(1:sz(4)),:,:) = permute(squeeze(block),[3 1 2]);
                    lastPos = lastPos + sz(4);
                    fprintf('frame %4d\n',lastPos);
                end
                clear block
                
                assert(~any(any(any(isnan(X)))))
                
                % dF/F
                % X = bsxfun(@rdivide,X,mean(X))-1;
                 
                key = fetch(reso.Indicator & key);
                for i=1:length(key)
                    indicator = fetch1(reso.Indicator & key(i),'indicator');
                    tuple = key(i);
                    tuple.slice_num = iSlice;

                    tuple.mean_map = squeeze(mean(X(indicator,:,:)));
                    tuple.std_map = squeeze(std(X(indicator,:,:)));

%                     figure(1)
%                     subplot(1,length(key),i)
%                     imagesc(tuple.mean_map);
%                     title(fetch1(reso.Conditions & key(i),'condition_name'));
%                     axis image off
%                     drawnow
%                     
%                     figure(2)
%                     subplot(1,length(key),i)
%                     imagesc(tuple.std_map);
%                     title(fetch1(reso.Conditions & key(i),'condition_name'));
%                     axis image off
%                     drawnow
                    self.insert(tuple);
                end
            end
        end
    end
end
