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
            reader = reso.getReader(reso.Align & key);
            [fillFraction, rasterPhase] = fetch1(reso.Align & key, 'fill_fraction', 'raster_phase');
            for iSlice=1:reader.nSlices
                fprintf('loading slice %d: \n', iSlice);
                reader.reset
                blockSize = 500;
                xymotion = fetch1(reso.Align & key, 'motion_xy');
                xymotion(:,:,end+1) = xymotion(:,:,end);  %#ok<AGROW> % extend by one frame
                
                [width,height,nFrames] = fetch1(reso.Align*reso.ScanInfo & key, ...
                    'px_width','px_height','nframes');
                X = nan(nFrames,width*height,'single');
                lastPos = 0;
                while ~reader.done
                    block = getfield(reader.read(1, iSlice, blockSize),'channel1'); %#ok<GFLD>
                    sz = size(block);
                    xy = xymotion(:,:,1:sz(4));
                    xymotion(:,:,1:size(block,4)) = [];
                    block = ne7.ip.correctRaster(block,rasterPhase,fillFraction);
                    block = ne7.ip.correctMotion(block, xy);
                    X(lastPos+(1:sz(4)),:) = reshape(block,[],sz(4))';
                    lastPos = lastPos + sz(4);
                    fprintf('frame %4d\n',lastPos);
                end
                clear block
                
                assert(~any(any(isnan(X))))
                fps = fetch1(reso.ScanInfo & key, 'fps');
                G = fetch1(reso.OriDesign & key, 'design_matrix');
                G = G(1:size(X,1),:);
                opt = fetch(reso.CaOpt & key, '*');
                
                B = zeros(size(G,2),size(X,2));
                R2 = zeros(1,size(X,2));
                DoF = zeros(1,size(X,2));
                chunkSize = 4096;
                disp 'computing responses...'
                for i=1:chunkSize:size(X,2)-1
                    ix = i:min(size(X,2),i+chunkSize-1);
                    X_ = X(:,ix);
                    
                    % high-pass filtration
                    X_ = bsxfun(@rdivide, X_, mean(X_))-1;  %use dF/F
                    if opt.highpass_cutoff>0
                        k = hamming(round(fps/opt.highpass_cutoff)*2+1);
                        k = k/sum(k);
                        X_ = X_ - ne7.dsp.convmirr(X_,k);
                    end
                    fprintf .
                    [B(:,ix),R2(ix),~,DoF(ix)] = ne7.stats.regress(X_, G, 0);
                end
                fprintf \n
                
                % insert results
                tuple = key;
                tuple.slice_num = iSlice;
                tuple.ndirections = size(G,2);
                tuple.regressor_cov = single(G'*G);
                tuple.regr_coef_maps = reshape(single(B'), width, height,[]);
                tuple.r2_map = reshape(R2, width, height);
                tuple.dof_map = reshape(DoF, width, height);
                self.insert(tuple)
            end
        end
    end
end
