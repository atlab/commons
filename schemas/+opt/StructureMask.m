%{
opt.StructureMask (imported) # structural images from optical sessions
-> common.OpticalMovie
-----
structure_mask :  longblob   # mask of craniotomy
%}

classdef StructureMask < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('opt.StructureMask')
		popRel = opt.Structure;
	end

	methods
		function self = StructureMask(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            structImg=fetchn(opt.Structure(key),'structure_img');
            structImg=double(structImg{end});
            imagesc(structImg); colormap('gray');
            axis image
            set(gca,'xdir','reverse')
            key.structure_mask=[];
            key=opt.utils.drawOptMask(key);
			self.insert(key)
		end
	end
end
