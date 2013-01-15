%{
tp.Motion3D (computed) # my newest table
-> tp.FineAlign
-> tp.Ministack
-----
frame_corr      : longblob  # (um) the correlation coefficient of frame to stack
xyz_trajectory  : longblob  # (um) xyz trajectory of scan relative to the middle of the stack
zdist           : longblob  # (um) z trajectory centered around the median frame
xdrift          : float     # (um) the 95th percentile range of x motion
ydrift          : float     # (um) the 95th percentile range of y motion
zdrift          : float     # (um) the 95th percentile range of z motion
%}

classdef Motion3D < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('tp.Motion3D')
        popRel = tp.FineAlign*tp.Ministack('green_slices is not null')
    end
    
    methods
        function self = Motion3D(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            % pixel pitch along x and y
            [px,py] = fetch1(tp.Align(key), 'um_width/px_width->px', 'um_height/px_height->py');
            pz = fetch1(tp.Ministack(key), 'zstep');
                        
            % load stack
            % apply raster correction from the last frame in the movie,
            % assuming it has the most accurate estimate.
            raster = fetch1(tp.Align(key), 'raster_correction');
            assert(~isempty(raster), 'always do raster correction')
            ministack = fetch1(tp.Ministack(key), 'green_slices');            
            ministack = ne7.ip.Stack(ne7.micro.RasterCorrection.apply(ministack, raster(round(0.9*end),:,:)));
            movie = tp.utils.Movie(key);
            
            disp 'computing movement trajectory...'
            for iFrame = 1:movie.nFrames
                % progress indication
                if ~mod(sqrt(iFrame),1), fprintf('[%4d/%4d]\n', iFrame, movie.nFrames), end
                
                % read frame and apply raster correction
                frame = movie.getFrames(1,iFrame);
                
                % get optimal offsets
                [x(iFrame), y(iFrame), z(iFrame), peakcorr(iFrame)] = ministack.xcorrpeak3d(frame); %#ok<AGROW>
            end
            
            % convert xyz trajectory microns
            xyz =[x(:)*px y(:)*py z(:)*pz];
            
            % compute the range of drift along each dimension (95% interval)
            xyzDrift = diff(quantile(xyz,[0.025 0.975]));
        
            zdist = xyz(:,3) - mean(quantile(xyz(:,3), [0.1 0.9]));
            fprintf('%2.2f%% of the movie was within 1 um of the central plane\n', mean(abs(zdist<1))*100);

            
            % insert results into database
            key.xyz_trajectory = single(xyz);
            key.frame_corr = peakcorr;
            key.zdist = single(zdist); 
            key.xdrift = xyzDrift(1);
            key.ydrift = xyzDrift(2);
            key.zdrift = xyzDrift(3);
            self.insert(key)
        end
    end
end