%{
reso.AxonMask (computed) # segmentation of axons
-> reso.Align
-> reso.VolumeSlice
-----
axon_mask               : longblob      # binary image of axons
axon_mask_kernel_size   : float         # size hamming window (um)
axon_mask_thresh        : float         # segmentation threshold (sigmas)
axon_mask_mean          : float         # mean fluorescence of all pixels in mask
%}

classdef AxonMask < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = reso.Align * common.TpSession & 'compartment="axons"'
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            img = fetch1(reso.Align & key, 'green_img');
            pp = double(fetch1(reso.ScanInfo & key, 'um_height/px_height->pp'));
            
            kernelSize = 5;
            k = hamming(ceil(kernelSize/pp)*2+1);
            k = k/sum(k);
            
            nSlices = size(img,3);
            for iSlice = 1:nSlices
                key.slice_num = iSlice;
                
                im = img(:,:,iSlice);
                bg = imfilter(imfilter(im,k,'symmetric'), k','symmetric');
                thresh = 3.5;  % sigmas
                thresh = thresh * sqrt(mean((im(:)-bg(:)).^2));
                
                key.axon_mask = im > bg + thresh;
                key.axon_mask_kernel_size = kernelSize;
                key.axon_mask_thresh = thresh;
                key.axon_mask_mean = mean(mean(im .* key.axon_mask));
                
                self.insert(key)
            end
        end
    end
    
end