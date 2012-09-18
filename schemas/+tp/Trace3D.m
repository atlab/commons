%{
tp.Trace3D (imported) # Segmented objects in the scan and their fluorescence traces
->tp.Segment3D
trace_idx      : smallint  # cell index within the segmentation
---
gtrace         : longblob  # fluorescence trace in green channel
centroid_x     : float  # (pixels) centroid x-coordinate
centroid_y     : float  # (pixels) centroid y-coordinate
major_length   : float  # (um) major axis length
minor_length   : float  # (um) minor axis length
mask_pixels      : mediumblob                    # indices of segment pixels in the image
g_contrast=null  : float                         # Michelson contrast in the green channel
r_contrast=null  : float                         # Michelson contrast in the red channel
%}

classdef Trace3D < dj.Relvar
    properties(Constant)
        table = dj.Table('tp.Trace3D')
    end
    methods
        function self = Trace3D(varargin)
            self.restrict(varargin)
        end
        
        
        function makeTuples(self, key)
            
            % compute pixel pitch (um/pixel)
            [px,py] = fetch1(tp.Align(key), 'um_width/px_width->px', 'um_height/px_height->py');
            assert(max(px/py, py/px)<1.1, 'the present algorithm cannot accept non-isometric pixels')
            
            opt = fetch(tp.SegOpt(key), '*');
            switch opt.seg_algo
                case 'convex 3D'
                    disp 'filtering stack...'
                    % check tissue drift
                    [stack, zstep, drift]  = fetch1(tp.Ministack(key)*tp.Motion3D, ...
                        'green_slices', 'zstep', 'xyz_trajectory');
                    validTimes = fetch1(tp.Segment3D & key, 'validity_trace');
                    validTimes = logical(validTimes);
                    zrange = mean(drift(validTimes,3)) + [-2.0 2.0];   % cell centroids must be within 2.5 microns of imaging plane
                    
                    stack = ne7.ip.Stack(stack, [px py zstep]);
                    raster = fetch1(tp.Align(key), 'raster_correction');
                    stack.applyRasterCorrection(raster)
                    stack.applyAnscombe(10)
                    sigma = 4*(0.6*opt.min_radius + 0.4*opt.max_radius);
                    stack.removeBackground(sigma)
                    sigma = 1.0*opt.min_radius;
                    stack.lowpass3(sigma*[1 1 1])
                    
                    disp 'segmenting by convexity...'
                    [maskPixels, z] = stack.segmentConvex(zrange, opt.min_radius);
                    nTraces = length(maskPixels);
                    mask = zeros(size(stack.stack,1),size(stack.stack,2),'uint16');
                    for i=1:length(maskPixels)
                        mask(maskPixels{i}) = i;
                    end
                    imagesc(mask)
                    clear stack
                    
                    disp 'extracting traces...'
                    f = getFilename(common.TpScan(key));
                    scim = ne7.scanimage.Reader(f{1});
                    nFrames = scim.nFrames;
                    traces = nan(nFrames, nTraces, 'single');
                    
                    drift = round(bsxfun(@rdivide, drift, [px py zstep]));
                    gframe = 0;
                    rframe = 0;
                    for iFrame=find(validTimes(:)')
                        % report progress periodically
                        if isprime(iFrame) && mod(iFrame,7)==mod(iFrame,13),
                            fprintf('[%4d/%4d]\n', iFrame, scim.nFrames),
                        end
                        frame = scim.read(1,iFrame);
                        frame = ne7.micro.RasterCorrection.apply(frame, raster(iFrame,:,:));
                        frame = ne7.ip.shift(frame,drift(iFrame,[2 1]));   % TODO: check that the motion in the right direction
                        imagesc(frame,[0 4000]), axis image, colormap(gray), drawnow
                        traces(iFrame,:) = cellfun(@(ix) mean(frame(ix)), maskPixels);
                        
                        %accumulate frames for contrast computation
                        if ~mod(iFrame,10)
                            gframe = gframe + frame;
                            frame = scim.read(2,iFrame);
                            frame = ne7.micro.RasterCorrection.apply(frame, raster(iFrame,:,:));
                            frame = ne7.ip.shift(frame,drift(iFrame,[2 1]));
                            rframe = rframe + frame;
                        end
                    end
                    
                    disp 'computing contrast...'
                    radius = 4*(0.6*opt.min_radius + 0.4*opt.max_radius);
                    radius = radius/min(px,py);
                    gcontrast = cellfun(@(ix) getContrast(gframe, ix, radius), maskPixels);
                    rcontrast = cellfun(@(ix) getContrast(rframe, ix, radius), maskPixels);
                    props = regionprops(mask,'MajorAxisLength','MinorAxisLength','Centroid');
                    
                    % insert data
                    disp 'inserting...'
                    key.trace_idx = 0;
                    for ix = find(gcontrast(:)'>=opt.min_contrast)
                        key.trace_idx = key.trace_idx + 1;
                        tuple = key;
                        tuple.gtrace = single(traces(:,ix));
                        tuple.g_contrast = gcontrast(ix);
                        tuple.r_contrast = rcontrast(ix);
                        tuple.major_length = props(ix).MajorAxisLength * mean([px py]);
                        tuple.minor_length = props(ix).MinorAxisLength * mean([px py]);
                        tuple.mask_pixels = uint32(maskPixels{ix});
                        tuple.centroid_x = props(ix).Centroid(2);
                        tuple.centroid_y = props(ix).Centroid(1);
                        self.insert(tuple);
                    end
                    
                otherwise
                    error 'unfinished segmentation algorithm'
            end
        end
    end
end



function contrast = getContrast(img, maskPixels, radius)
% Michelson contrast of pixels at maskPixels compared to others within radius
sz = size(img);
[y,x] = ind2sub(sz,maskPixels);
y = mean(y);
x = mean(x);
[yi,xi] = ndgrid(...
    max(1,round(y-radius)):min(sz(1),round(y+radius)),...
    max(1,round(x-radius)):min(sz(2),round(x+radius)));
hood = (yi-y).^2+(xi-x).^2 < radius^2;
hood = sub2ind(sz, yi(hood), xi(hood));
object     = mean(img(maskPixels));
background = quantile(img(hood),0.4);
contrast = (object-background)/(object+background)*2;
end