%{
tp.Trace (imported) # raw calcium trace
-> tp.Extract

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

classdef Trace < dj.Relvar
    
    properties(Constant)
        table = dj.Table('tp.Trace')
    end
    
    methods
        function makeTuples(self, key)
            % compute pixel pitch (um/pixel)
            [px,py] = fetch1(tp.Align(key), 'um_width/px_width->px', 'um_height/px_height->py');
            assert(max(px/py, py/px)<1.1, 'the present algorithm cannot accept non-isometric pixels')
            pitch = (px+py)/2;
            
            % get mean frames
            [g,r] = fetch1(tp.FineAlign & key, 'fine_green_img', 'fine_red_img');
            movie = tp.utils.Movie(key);
            
            % extract traces
            opt = fetch(tp.SegOpt & key,'*');
            switch opt.seg_algo
                case 'manual'
                    mask = logical(fetch1(tp.SegmentManual & key, 'manual_mask'));
                    regions = regionprops(mask,...
                        'Area', 'PixelIdxList','MajorAxisLength','MinorAxisLength','Centroid','EquivDiameter');
                
                otherwise
                    error 'not done yet'
            end
            X = movie.getFrames(1,1:movie.nFrames);
            sz = size(X);
            X = reshape(X,[],sz(3));
            f = getFilename(common.TpScan(key));
            scim = ne7.scanimage.Reader(f{1});
            
            tuple = key;
            for iTrace = 1:length(regions)
                pixels = regions(iTrace).PixelIdxList;
                tuple.trace_idx = iTrace;
                tuple.gtrace = single(mean(X(pixels,:),1))';
                tuple.centroid_x = regions(iTrace).Centroid(1);
                tuple.centroid_y = regions(iTrace).Centroid(2);
                tuple.mask_pixels = regions(iTrace).PixelIdxList;
                tuple.major_length = regions(iTrace).MajorAxisLength*pitch;
                tuple.minor_length = regions(iTrace).MinorAxisLength*pitch;
                bgRadius = regions(iTrace).EquivDiameter*1.5;
                
                tuple.g_contrast = getContrast(g, pixels, bgRadius);
                if scim.hdr.acq.savingChannel2
                    tuple.r_contrast = getContrast(r, pixels, bgRadius);
                end
                self.insert(tuple)
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