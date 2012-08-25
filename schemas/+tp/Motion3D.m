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

classdef Motion3D < dj.Relvar & dj.AutoPopulate
    
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
            % load movie and stack
            f = getFilename(common.TpScan(key));
            scim = ne7.scanimage.Reader(f{1});
            raster = fetch1(tp.Align(key), 'raster_correction');
            assert(~isempty(raster), 'always do raster correction')
            ministack = fetch1(tp.Ministack(key), 'green_slices');            
            
            % pixel pitch along x and y
            [px,py] = fetch1(tp.Align(key), 'um_width/px_width->px', 'um_height/px_height->py');
            pz = fetch1(tp.Ministack(key), 'zstep');
            
            disp 'computing movement trajectory...'
            
            % apply raster correction from the last frame in the movie,
            % assuming it has the most accurate estimate.
            ministack = ne7.ip.Stack(ne7.micro.RasterCorrection.apply(ministack, raster(end,:,:)));
            
            for iFrame = 1:scim.nFrames;
                % progress indication
                if isprime(iFrame), fprintf('[%4d/%4d]\n', iFrame, scim.nFrames), end
                
                % read frame and apply raster correction
                frame = ne7.micro.RasterCorrection.apply(scim.read(1,iFrame), raster(iFrame,:,:));
                
                % get optimal offsets
                [x(iFrame), y(iFrame), z(iFrame), peakcorr(iFrame)] = ministack.xcorrpeak3d(frame); %#ok<AGROW>
            end
            
            % convert xyz trajectory microns
            xyz =[x(:)*px y(:)*py z(:)*pz];
            
            % compute the range of drift along each dimension (95% interval)
            xyzDrift = diff(quantile(xyz,[0.025 0.975]));
            
            % insert results into database
            key.xyz_trajectory = single(xyz);
            key.frame_corr = peakcorr;
            key.xdrift = xyzDrift(1);
            key.ydrift = xyzDrift(2);
            key.zdrift = xyzDrift(3);
            self.insert(key)
        end
    end
end