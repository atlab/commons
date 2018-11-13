%{
opt.Structure (imported) # structural images from optical sessions
-> common.OpticalMovie
-----
structure_img  :  longblob   # image
structure_mask :  longblob   # mask of craniotomy
%}

classdef Structure < dj.Imported

	properties
		popRel = common.OpticalMovie('purpose="structure"')
	end

	methods
		function self = Structure(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            filename = fullfile(...
                fetch1(common.OpticalSession(key), 'opt_path'),...
                [fetch1(common.OpticalMovie(key), 'filename') '.h5']);
            X = opt.utils.getOpticalData(getLocalPath(filename));
            X = squeeze(median(X));
            X = X-quantile(X(:),0.005);
            X = X/quantile(X(:),0.999);
            key.structure_img = uint8(255*X);            
			self.insert(key)
		end
	end
end
