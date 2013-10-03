%{
reso.Align (imported) # motion correction
-> reso.ScanInfo
---
nframes                     : smallint                      # actual number of recorded frames
fill_fraction               : float                         # scan fill fraction (see scanimage)
raster_phase                : float                         # shift of odd vs even raster lines
motion_xy                   : longblob                      # (pixels) y,x motion correction offsets
motion_rms                  : float                         # (um) stdev of motion
xcorr_traces                : longblob                      # peak correlations between frames
green_upper                 : float                         # 99th pecentile of intensity on green channel from the beginning of the movie
raw_green_img = null        : longblob                      # unaligned mean green image
raw_red_img = null          : longblob                      # unaligned mean red image
green_img = null            : longblob                      # aligned mean green image
red_img = null              : longblob                      # aligned mean red image
align_ts= CURRENT_TIMESTAMP : timestamp                     # automatic
%}

classdef Align < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.Align')
        popRel = reso.ScanInfo
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            [path, basename, scanIdx] = fetch1(...
                common.TpSession*common.TpScan & key, ...
                'data_path', 'basename', 'scan_idx');
            try
                reader = reso.reader(path,basename,scanIdx);
            catch
                basename = fetch1(pro(patch.Recording * patch.Patch, 'file_num->scan_idx','filebase') & key, 'filebase');
                reader = reso.reader(path,basename,scanIdx);
            end
            
            info = fetch(reso.ScanInfo & key, '*');
            minFrames = 300;
            assert(info.nframes_requested > minFrames, ...
                'we assume at least %d frames', minFrames)
            assert(strcmp(reader.hdr.scanMode, 'bidirectional'), ...
                'scanning must be bidirectional')
            
            disp 'computing template for motion alignment...'
            reader.read([], [], 60);    % skip some frames (stacks)
            blockSize = 300;   % number of frames used for template
            templateBlock = getfield(reader.read(1,1:info.nslices,blockSize),'channel1'); %#ok<GFLD>
            
            % compute raster correction
            fillFraction = reader.hdr.scanFillFraction;
            rasterPhase = computeRasterCorrection(squeeze(mean(templateBlock(:,:,1,:),4)), fillFraction);
            
            % compute motion correction template
            templateBlock = reso.Align.correctRaster(templateBlock, rasterPhase, fillFraction);
            key.green_upper = quantile(templateBlock(:),0.99);
            c = ones(1,blockSize);
            for iter=1:3
                c = reshape(c.^4/sum(c.^4),[1 1 1 blockSize]);
                template = conditionStack(sum(bsxfun(@times, templateBlock, c),4));
                c = arrayfun(@(i) mean(sum(sum(template.*conditionStack(templateBlock(:,:,:,i))))), ...
                    1:blockSize);
            end
            
            disp 'aligning motion...'
            reader.reset
            blockSize = 320;
            fTemplate = conj(fft2(template));  % template in frequency domain
            accum = [];
            channels = intersect(1:2, reader.hdr.channelsSave);
            hasRed = length(channels)>=2;
            
            raw = struct('green',0,'red',0);
            img = struct('green',0,'red',0);
            
            while ~reader.done
                % load block
                block = reader.read(channels,1:info.nslices,blockSize);
                sz = size(block.channel1);
                greenBlock = block.channel1;
                
                % compute motion correction
                xymotion = zeros(2,sz(3),sz(4),'single');
                cc = zeros(sz(3),sz(4));
                for iFrame=1:sz(4)
                    if ~mod(iFrame,32), fprintf ., end
                    for iSlice = 1:sz(3)
                        % compute cross-corelation as product in frequency domain
                        frame = reso.Align.correctRaster(greenBlock(:,:,iSlice,iFrame), rasterPhase, fillFraction);
                        [x,y] = measureShift(fft2(conditionStack(frame)).*fTemplate(:,:,iSlice));
                        xymotion(:,iSlice,iFrame) = [x y];
                    end
                end
                
                % accumulate motion correction
                if isempty(accum)
                    accum.xymotion = xymotion;
                    accum.cc = cc;
                else
                    accum.xymotion = cat(3, accum.xymotion,xymotion);
                    accum.cc = cat(2, accum.cc, cc);
                end
                
                % display raw averaged block
                if hasRed, redBlock = block.channel2; end
                g = reshape(mean(greenBlock,4), size(greenBlock,1),[])/key.green_upper;
                if hasRed
                    g = cat(3,reshape(mean(redBlock,4), size(redBlock,1),[])/quantile(redBlock(:),0.99),g);
                    g(:,:,3) = 0;
                end
                imshow(g)
                title(sprintf('frames %d-%d', length(accum.cc)-length(cc)+1, length(accum.cc)))
                drawnow
                
                % accumuluate raw frames and corrected frame
                raw.green = raw.green + sum(greenBlock,4);
                img.green = img.green + sum(reso.Align.correctMotion(reso.Align.correctRaster(greenBlock, rasterPhase, fillFraction), xymotion),4);
                if hasRed
                    raw.red = raw.red + sum(redBlock,4);
                    img.red = img.red + sum(reso.Align.correctMotion(reso.Align.correctRaster(redBlock, rasterPhase, fillFraction), xymotion),4);
                end
                
                fprintf(' Aligned %4d frames\n', size(accum.cc,2))
            end
            nFrames = size(accum.cc,2);
            key.fill_fraction = fillFraction;
            key.raster_phase = rasterPhase;
            key.nframes = nFrames;
            key.motion_xy = accum.xymotion;
            key.xcorr_traces = single(accum.cc);
            key.raw_green_img = single(raw.green/nFrames/key.green_upper);
            key.green_img     = single(img.green/nFrames/key.green_upper);
            if hasRed
                key.raw_red_img = single(raw.red/nFrames/key.green_upper);
                key.red_img     = single(img.red/nFrames/key.green_upper);
            end
            pixelPitch = info.um_width / info.px_width;
            key.motion_rms = pixelPitch*sqrt(mean(mean(var(double(accum.xymotion),[],3))));
            self.insert(key)
        end
    end
    
    
    methods
        function obj = getReader(self)
            assert(self.count == 1, 'one scan at a time please')
            
            [path, basename, scanIdx] = fetch1(...
                common.TpSession*common.TpScan & self, ...
                'data_path', 'basename', 'scan_idx');
            
            try
                obj = reso.reader(path,basename,scanIdx);
            catch
                basename = fetch1(pro(patch.Recording * patch.Patch, ...
                    'file_num->scan_idx','filebase') & self, 'filebase');
                obj = reso.reader(path,basename,scanIdx);
            end
            
        end
        
    end
    
    
    methods(Static)
        
        function img = correctMotion(img, xymotion)
            sz = size(img);
            for iFrame = 1:sz(4)
                for iSlice = 1:sz(3)
                    im = img(:,:,iSlice,iFrame);
                    g = griddedInterpolant(im,'linear','nearest');
                    [y,x] = ndgrid((1:sz(1))+xymotion(2,iSlice,iFrame), (1:sz(2))+xymotion(1,iSlice,iFrame));
                    img(:,:,iSlice,iFrame) = g(y,x);
                end
            end
        end
        
        
          function block = correctMotion2(block, xymotion)
            sz = size(block);
            for iFrame = 1:sz(4)
                for iSlice = 1:sz(3)
                    block(:,:,iSlice,iFrame) = ...
                        ne7.ip.shift(block(:,:,iSlice,iFrame), xymotion([2 1],iSlice,iFrame));
                end
            end
        end
        
        function img = correctRaster(img, rasterPhase, fillFraction)
            sz = size(img);
            ix = (-sz(2)/2+0.5:sz(2)/2-0.5)/(sz(2)/2);
            tx = asin(ix*fillFraction);  % convert index to time
            for iSlice = 1:size(img,3)
                for iFrame = 1:size(img, 4)
                    im = img(:,:,iSlice,iFrame);
                    extrapVal = mean(im(:));
                    img(1:2:end,:,iSlice,iFrame) = interp1(ix, im(1:2:end,:)', ...
                        sin(tx'+rasterPhase)/fillFraction,'linear',extrapVal)';
                    img(2:2:end,:,iSlice,iFrame) = interp1(ix, im(2:2:end,:)', ...
                        sin(tx'-rasterPhase)/fillFraction,'linear',extrapVal)';
                end
            end
        end
        
    end
end



function rasterPhase = computeRasterCorrection(img, fillFraction)

k = hamming(7); k = k/sum(k);
odd   = imfilter(img(1:2:end,:), k,'symmetric');
even  = imfilter(img(2:2:end,:), k,'symmetric');
odd  =  odd(4:end-3,:);
even = even(4:end-3,:);
odd = odd - mean(odd(:));
odd = odd / sqrt(sum(odd(:).^2));
even = even - mean(even(:));
even = even / sqrt(sum(even(:).^2));
sz = size(odd);
ix = (-sz(2)/2+0.5:sz(2)/2-0.5)/(sz(2)/2);
tx = asin(ix*fillFraction);  % convert index to time
odd = odd';
even = even';

rasterPhase = 0;
step = 0.02;
while step>1e-4
    phases = rasterPhase + step*[-0.5 -0.25 -0.1 0.1 0.25 0.5]*fillFraction;
    c= nan(size(phases));
    for iPhase = 1:length(phases);
        odd_  = interp1(ix,  odd, sin(tx'+phases(iPhase))/fillFraction,'linear');
        even_ = interp1(ix, even, sin(tx'-phases(iPhase))/fillFraction,'linear');
        c(iPhase) = sum(sum(odd_(18:end-17,:).*even_(18:end-17,:)));
    end
    p = polyfit(phases,c,2);
    rasterPhase = max(phases(1),min(phases(end),-p(2)/2/p(1)));
    assert(abs(rasterPhase)<0.02, 'weird raster correction')
    step = step/4;
end
end





function stack = conditionStack(stack)
% condition images in stack for computing image cross-correlation

% low-pass filter
k = hamming(5);
k = k/sum(k);
stack = imfilter(imfilter(stack,k,'symmetric'),k','symmetric');

% unsharp masking
sigma = 41;  % somewhat arbitrary
k = gausswin(sigma);
k = k/sum(k);
stack = stack - imfilter(imfilter(stack, k, 'symmetric'), k', 'symmetric');

% taper image boundaries
sz = size(stack);
mask = atan(10*hanning(sz(1)))*atan(10*hanning(sz(2)))' /atan(10)^2;
stack = bsxfun(@times, stack, mask);

% normalize
stack = bsxfun(@rdivide, stack, sqrt(sum(sum(stack.^2))));
end


function [x,y] = measureShift(ixcorr)
% measure the shift of img relative to refImg from xcorr = fft2(img).*conj(fft2(refImg))
sz = size(ixcorr);
assert(length(sz)==2 && all(sz(1:2)>=128 & mod(sz(1:2),2)==0), ...
    'image must have even height and width, at least 128 in size')

phase = fftshift(angle(ixcorr));
mag   = fftshift(abs(ixcorr));
center = sz/2+1;
phaseSlope = [0 0];
for r=[10 15 20]
    [x,y] = meshgrid(-r:r,-r:r);
    plane  = phaseSlope(1)*x + phaseSlope(2)*y;
    phase_ = mod(pi + phase(center(1)+(-r:r),center(2)+(-r:r)) - plane, 2*pi) - pi + plane;
    mag_ = mag(center(1)+(-r:r),center(2)+(-r:r));
    mdl = LinearModel.fit([x(:) y(:)], phase_(:), 'Weights', mag_(:));
    phaseSlope = mdl.Coefficients.Estimate(2:3)';
end
x = -phaseSlope(1)*sz(2)/(2*pi);
y = -phaseSlope(2)*sz(1)/(2*pi);
end