%{
tp.Ministack (imported) # stacks taken around two-photon image planes scans

-> common.TpScan
---
filepath=""                 : varchar(255)                  # file in which the ministack was found
zstep=0                     : float                         # (um) distance between slices
green_slices=null           : longblob                      # averaged, self-aligned stack of slice images
red_slices=null             : longblob                      # same thing for channel 2
%}

classdef Ministack < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('tp.Ministack')
		popRel = common.TpScan 
	end

	methods
		function self = Ministack(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            
            % make candidate names
            [path, basename] = fetch1(common.TpSession(key), 'data_path', 'basename');
            path = getLocalPath(path);
            
            % ministacks are stored either in ministack###.tif with same
            % number or scan###.tif with next number
            s = [];
            key.filepath = fullfile(path, sprintf('ministack%03u.tif', key.scan_idx));
            try
                s = neurosci.scanimage.Reader(key.filepath);
            catch %#ok<CTCH>
                key.filepath = fullfile(path, sprintf([basename '%03u.tif'], key.scan_idx+1));
                try 
                    s = neurosci.scanimage.Reader(key.filepath);
                    key.filepath = f;                    
                catch %#ok<CTCH>
                    key.filepath = '';
                    disp 'No ministack was found'
                end
            end
            if ~isempty(s)
                if s.hdr.acq.numberOfZSlices == 1
                    key.filepath = '';
                else
                    disp 'loading stack'
                    key.zstep = s.hdr.acq.zStepSize;
                    nz = s.hdr.acq.numberOfZSlices;                    
                    key.green_slices = single(collapseRepeats(s.read(1),nz));
                    try
                        key.red_slices = single(collapseRepeats(s.read(2),nz));
                    catch %#ok<CTCH>
                        disp 'no red signal'
                    end
                end
            end
            
			self.insert(key)
        end
	end
end


function y = collapseRepeats(x, nz)
y = zeros(size(x,1),size(x,2),nz);
nstep = size(x,3)/nz;
for i = 1:nz
    y(:,:,i) = median(x(:,:,(i-1)*nstep + (1:nstep)),3);
end
end
