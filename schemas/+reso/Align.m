%{
reso.Align (imported) # motion corrections and raster artifact correction
-> reso.ScanInfo
-----
nframes                     : smallint                      # actual number of recorded frames
motion_xy                   : longblob                      # (pixels) y,x motion correction offsets
motion_rms                  : float                         # (um) stdev of motion
xcorr_traces                : longblob                      # peak correlations between frames
align_ts=CURRENT_TIMESTAMP  : timestamp                     # automatic
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
            info = fetch(reso.ScanInfo & key, '*');
            reader = reso.reader(path,basename,scanIdx);
            
            disp 'computing template for motion alignment...'
            reader.readBlock([], [], 60)    % skip some frames (stacks)
            blockSize = 300;   % number of frames used for template
            templateBlock = reader.readBlock(1,1:info.nslices,blockSize);
            c = ones(1,blockSize);
            for iter=1:3
                c = reshape(c.^4/sum(c.^4),[1 1 1 blockSize]);
                template = conditionStack(sum(bsxfun(@times, templateBlock, c),4));
                c = arrayfun(@(i) mean(sum(sum(template.*conditionStack(templateBlock(:,:,:,i))))), ...
                    1:blockSize);
            end
            
            disp 'aligning motion...'
            reader.setDirectory(1)   % reset to the start
            blockSize = 256;
            
            fTemplate = conj(fft2(template));  % template in frequency domain
            accum = [];
            
            while true
                block = reader.readBlock(1,1:info.nslices,blockSize);
                if isempty(block), break, end;
                sz = size(block);
                block = conditionStack(block);
                xymotion = zeros(2,sz(3),sz(4),'int8');
                cc = zeros(sz(3),sz(4));
                for iFrame=1:sz(4)
                    if ~mod(iFrame,32), fprintf ., end
                    for iSlice = 1:sz(3)
                        % compute cross-corelation as product in frequency domain
                        c = real(fftshift(ifft2(fft2(block(:,:,iSlice,iFrame)).*fTemplate(:,:,iSlice))));
                        [cc(iSlice,iFrame), idx] = max(c(:));
                        [y,x] = ind2sub(sz(1:2),idx);
                        y = y - ceil((sz(1)+1)/2);
                        x = x - ceil((sz(2)+1)/2);
                        xymotion(:,iSlice,iFrame) = [x y];
                    end
                end
                if isempty(accum)
                    accum.xymotion = xymotion;
                    accum.cc = cc;
                else
                    accum.xymotion = cat(3, accum.xymotion,xymotion);
                    accum.cc = cat(2, accum.cc, cc);
                end
                fprintf(' Aligned %4d frames\n', size(accum.cc,2))
            end
            key.nframes = size(accum.cc,2);
            key.motion_xy = accum.xymotion;            
            key.xcorr_traces = single(accum.cc);
            pixelPitch = info.um_width / info.px_width;
            key.motion_rms = pixelPitch*sqrt(mean(mean(var(double(accum.xymotion),[],3))));
            self.insert(key)
        end
    end
end



function readCorrected(self, nframes)
end




function stack = conditionStack(stack)
% condition images in stack for computing image cross-correlation


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
