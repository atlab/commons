%{
reso.MiniStack (imported) # motion in 3D computed from a ministack
-> reso.Align
-----
zstep = 0 : float  # (um) distance between slices
nslices = 0 : float # number of slices in the stack
stack = null  : longblob   # (um) movement x component
%}

classdef MiniStack < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = reso.Align
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            [path, basename, scanIdx] = fetch1(...
                common.TpSession*common.TpScan & key, ...
                'data_path', 'basename', 'scan_idx');
            if count(reso.Align & setfield(key,'scan_idx', scanIdx+1)) %#ok<SFLD>
                % if the next scan is regular scan, skip
                self.insert(key)
                return
            end
            try
                reader = reso.reader(path,basename,scanIdx+1);
            catch
                basename = fetch1(pro(patch.Recording * patch.Patch, 'file_num->scan_idx','filebase') & key, 'filebase');
                try
                    reader = reso.reader(path,basename,scanIdx+1);
                catch
                    self.insert(key)
                    return
                end
            end
            
            key.zstep = reader.hdr.stackZStepSize;
            key.nslices = reader.hdr.stackNumSlices;
            channel1 = reader.read(1,1:reader.hdr.stackNumSlices,reader.hdr.stackNumSlices);
            key.stack = single(channel1.channel1);
            self.insert(key)
        end
    end
    
end