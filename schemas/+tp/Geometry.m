%{
tp.Geometry (imported) # the position of the scan
-> common.TpScan

-----
center_x  : float   # (um) 
center_y  : float   # (um)
depth     : float   # (um) below pia
flipped_x : tinyint # 1 if flipped
flipped_y : tinyint # 1 if flipped 
%}

classdef Geometry < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('tp.Geometry')
		popRel = tp.Align 
	end

	methods
		function self = Geometry(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            f = getFilename(common.TpScan(key));
            f = ne7.scanimage.Reader(f{1});
            key.center_x = f.hdr.motor.relXPosition;
            key.center_y = f.hdr.motor.relYPosition;
            key.depth = f.hdr.motor.relZPosition - fetch1(common.TpScan(key), 'surfz');
            
            % this configuration is specific to two-photon setup #2. 
            key.flipped_x = f.hdr.acq.scanAngleMultiplierFast > 0;   
            key.flipped_y = f.hdr.acq.scanAngleMultiplierSlow < 0;
			self.insert(key)
		end
	end
end
