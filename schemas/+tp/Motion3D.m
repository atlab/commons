%{
tp.Motion3D (computed) # my newest table
-> tp.Align
-> tp.Ministack
-----
xyz_trajectory  : longblob  # (um) xyz trajectory of scan relative to the middle of the stack
frame_corr : longblob   # (um) the correlation coefficient of frame to stack
xdrift : float     # (um) the 95th percentile range of x motion
ydrift : float     # (um) the 95th percentile range of y motion
zdrift : float     # (um) the 95th percentile range of z motion
%}

classdef Motion3D < dj.Relvar & dj.Automatic
    
    properties(Constant)
        table = dj.Table('tp.Motion3D')
        popRel = tp.Align*tp.Ministack('green_slices is not null')
    end
    
    methods
        function self = Motion3D(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            f = getFilename(common.TpScan(key));
            scim = neurosci.scanimage.Reader(f{1});
            raster = fetch1(tp.Align(key), 'raster_correction');
            assert(~isempty(raster), 'always do raster correction')
            ministack = fetch1(tp.Ministack(key), 'green_slices');
            
            
            % pixel pitch along x and y
            [px,py] = fetch1(tp.Align(key), 'um_width/px_width->px', 'um_height/px_height->py');
            pz = fetch1(tp.Ministack(key), 'zstep');
            
            disp 'computing movement trajectory...'
            xyz = zeros(scim.nFrames,3);  % 3D trajectory
            nz = size(ministack,3);
            frameCorr = zeros(scim.nFrames,1);
            
            for iFrame = 1:scim.nFrames
                if ~mod(iFrame, 20)
                    fprintf('[%4d/%4d]\n', iFrame, scim.nFrames)
                end
                if iFrame==1 || any(raster(iFrame,:)~=raster(iFrame-1,:))
                    cstack = neurosci.micro.RasterCorrection.apply(ministack, raster(iFrame,:,:));
                end
                frame = scim.read(1,iFrame);
                frame = neurosci.micro.RasterCorrection.apply(frame, raster(iFrame,:,:));
                % find optimal offset
                if iFrame == 1
                    [x,y,z,fcorr] = findFrameInStack(frame,cstack);
                else
                    z = max(3,min(nz-2,z));
                    [x,y,zz,fcorr] = findFrameInStack(frame,cstack(:,:,z+(-2:2)));
                    z = zz + (z-3);
                end
                frameCorr(iFrame) = fcorr;
                xyz(iFrame,:) = [x y z-(nz+1)/2].*[px py pz];
            end
            xyzDrift = diff(quantile(xyz,[0.025 0.975]));
            key.xyz_trajectory = xyz;
            key.frame_corr = frameCorr;
            key.xdrift = xyzDrift(1);
            key.ydrift = xyzDrift(2);
            key.zdrift = xyzDrift(3);
            
            self.insert(key)            
        end
    end
end



function [xi,yi,zi,peakCorr] = findFrameInStack(frame, stack)
%frame and stack must have the same xy dimensions
% return x,y,z offsets relative to the center of the stack
sigmas = [3 15];  % these work for a broad range of magnifications
[offsets, peakCorr] = neurosci.micro.MotionCorrection.xcorrpeak(stack, frame, sigmas);
[peakCorr,zi] = max(peakCorr);
yi = offsets(zi,1);
xi = offsets(zi,2);
end