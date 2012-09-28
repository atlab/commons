%{
common.TpScan (manual) # scanimage scan info
->common.TpSession
scan_idx : smallint # scanimage-generated sequential number
-----
surfz  : float   # (um) z-coord at pial surface
laser_wavelength  : float # (nm)
laser_power :  float # (mW) to brain
scan_notes = "" : varchar(4095)  #  free-notes
scan_ts = CURRENT_TIMESTAMP : timestamp   # don't edit
%}

classdef TpScan < dj.Relvar

	properties(Constant)
		table = dj.Table('common.TpScan')
	end

	methods
		function self = TpScan(varargin)
			self.restrict(varargin)
        end
        
        function filenames = getFilename(self)
            keys = fetch(self);
            n = length(keys);
            filenames = cell(n,1);
            for i = 1:n
                key = keys(i);
                assert(length(key)==1, 'one scan at a time please')
                [path, basename] = fetch1(common.TpSession(key), 'data_path', 'basename');
                f = getLocalPath(fullfile(path, basename));
                filenames{i} = sprintf(f, key.scan_idx);
            end
        end
	end
end