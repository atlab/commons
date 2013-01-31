%{
tp.Segment3D (imported) # extraction of calcium traces
-> tp.Motion3D
-> tp.Segment
-----
mask3d      : longblob                      # boolean stack marking cell bodies
mask2d      : longblob                      # boolean image marking cells in the imaged planed
valid_frames: longblob                      # boolean array marking frames for which mask 2D is valid
%}

classdef Segment3D < dj.Relvar 
    
    properties(Constant)
        table = dj.Table('tp.Segment3D')
    end
    
    methods    
        function makeTuples(self, key)
            disp 'raster correction...'
            stack = fetch1(tp.Ministack & key, 'green_slices');
            warp = zeros(size(stack,3),3,7);
            for iSlice = 1:size(stack,3)
                 warp(iSlice,:,:) = ne7.micro.RasterCorrection.fit(stack(:,:,iSlice), [3 7]);
            end
            warp = median(warp);
            s = ne7.micro.RasterCorrection.apply(stack,warp);
                            
            opt = fetch(tp.SegOpt & key, '*');
            
            [dx, dy] = fetch1(tp.Align & key, '(px_width/um_width)->px', '(px_height/um_height)->py');
            dz = fetch1(tp.Ministack & key, 'abs(zstep)->dz');
            voxelDims = [dy dx dz];
            debug = true;
            contrast = double(0.05*mean(stack(:)));
            cellRadius = opt.min_radius;
            mask3d = ne7.ip.segmentCells3D(double(stack), voxelDims, cellRadius, contrast, debug);
            
            
            self.insert(key)
        end
    end
end