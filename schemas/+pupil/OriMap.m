%{
pupil.OriMap (computed) # orientation tuning map
-> pupil.OriDesign
-> reso.VolumeSlice
---
ndirections                 : tinyint                       # number of directions
regressor_cov               : longblob                      # regressor covariance matrix,  nConds x nConds
regr_coef_maps              : longblob                      # regression coefficients, width x height x nConds
r2_map                      : longblob                      # pixelwise r-squared after gaussinization
dof_map                     : longblob                      # degrees of in original signal, width x height
%}

classdef OriMap < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = pupil.OriDesign & 'ca_opt=11'
    end
    
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            reader = getReader(reso.Align & key);
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
                    block = reso.Align.correctRaster(block,rasterPhase,fillFraction);
                    block = reso.Align.correctMotion(block, xy);
                    X(lastPos+(1:sz(4)),:) = reshape(block,[],sz(4))';
                    lastPos = lastPos + sz(4);
                    fprintf('frame %4d\n',lastPos);
                end
                
                assert(~any(any(isnan(X))))
                fps = fetch1(reso.ScanInfo & key, 'fps');                
                G = fetch1(pupil.OriDesign & key, 'design_matrix');
                G = G(1:size(X,1),:);
                
                % high-pass filtration
                X = bsxfun(@rdivide, X, mean(X))-1;  %use dF/F
                opt = fetch(pupil.CaOpt & key, '*');
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
                tuple.regr_coef_maps = reshape(single(B'), width, height,[]);
                tuple.r2_map = reshape(R2, width, height);
                tuple.dof_map = reshape(DoF, width, height);
                self.insert(tuple)
            end
        end
    end
end
