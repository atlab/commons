%{
reso.OriMap (imported) # responses to directions of full-field drifting gratings

-> reso.OriDesign
-> reso.VolumeSlice
---
ndirections                 : tinyint                       # number of directions
regressor_cov               : longblob                      # regressor covariance matrix,  nConds x nConds
regr_coef_maps              : longblob                      # regression coefficients, width x height x nConds
r2_map                      : longblob                      # pixelwise r-squared after gaussinization
dof_map                     : longblob                      # degrees of in original signal, width x height
%}

classdef OriMap < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('reso.OriMap')
        popRel = reso.OriDesign
    end
    
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            xymotion = fetch1(reso.Align & key, 'motion_xy');
            xymotion(:,:,end+1) = xymotion(:,:,end);  % extend by one frame 
            reader = getReader(reso.Align & key);
            
            for iSlice=1:reader.nSlices
                fprintf('loading slice %d: \n', iSlice);
                reader.reset
                blockSize = 500;
                xymotion = fetch1(reso.Align & key, 'motion_xy');
                xymotion(:,:,end+1) = xymotion(:,:,end);  % extend by one frame
                
                X = [];
                while ~reader.done
                    block = getfield(reader.read(1, iSlice, blockSize),'channel1'); %#ok<GFLD>
                    sz = size(block);
                    xy = xymotion(:,:,1:sz(4));
                    xymotion(:,:,1:size(block,4)) = [];
                    block = reso.Align.correctMotion(block, xy);
                    X = cat(3,X,reshape(block,sz([1 2 4])));
                    fprintf('frame %4d\n',size(X,3));
                end
                
                sz = size(X);
                fps = fetch1(reso.ScanInfo & key, 'fps');
                X = reshape(X,[],sz(3))';
                
                G = fetch1(reso.OriDesign & key, 'design_matrix');
                G = G(1:size(X,1),:);
                
                X = bsxfun(@rdivide, X, mean(X))-1;  %use dF/F
                opt = fetch(reso.CaOpt & key, '*');
                if opt.highpass_cutoff>0
                    k = hamming(round(fps/opt.highpass_cutoff)*2+1);
                    X = X - ne7.dsp.convmirr(X,k);
                end
                
                disp 'computing responses...'
                [B,R2,~,DoF] = ne7.stats.regress(X, G, 0);
                
                % insert results
                tuple = key;
                tuple.slice_num = iSlice;
                tuple.ndirections = size(G,2);
                tuple.regressor_cov = single(G'*G);
                tuple.regr_coef_maps = reshape(single(B'), sz(1), sz(2),[]);
                tuple.r2_map = reshape(R2, sz(1:2));
                tuple.dof_map = reshape(DoF, sz(1:2));
                self.insert(tuple)
            end
        end
    end
    
    
end
