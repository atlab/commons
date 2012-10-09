classdef plots
    
   
    methods(Static)
       
        function LoomMap(varargin)
            
            m = cat(3,1,0,1);
            y = cat(3,1,1,0);
            b = 1-y;
            g = 1-m;
            
            for key = fetch(opt.LoomMap(varargin{:}))'
                [amp, p] = fetch1(opt.LoomMap(key), 'spot_amp', 'spot_fp');
                %try
                mask = fetchn(opt.StructureMask(rmfield(key,'opt_movie')),'structure_mask');
                mask=mask{1};
                %mask = p<0.05;
                amp = bsxfun(@times, amp, double(mask));
                %catch
                %end
                figure
                method = 'four pictures';% with luminance';
                switch method
                    case 'onespot'
                        subplot 121
                        k = hamming(5);
                        k = k/sum(k);
                        amp = imfilter(amp,k,'symmetric');
                        amp = imfilter(amp,k','symmetric');
                        img = amp;
                        imagesc(img,[-1 1]*max(abs(img(:))))
                        %colormap(trove.bipolar)
                        colormap('summer')
                        axis image
                        set(gca,'xdir','reverse')
                        
                        subplot 122
                        k=[];
                        k.animal_id=key.animal_id;
                        k.opt_sess=key.opt_sess;
                        %try
                        structImg=fetchn(opt.Structure(k),'structure_img');
                        structMask=fetchn(opt.StructureMask(k),'structure_mask');
                        structImg=double(structImg{end}.*uint8(structMask{end}));
                        imagesc(structImg); colormap('gray');
                        axis image
                        set(gca,'xdir','reverse')
                        
                    case 'four pictures'
                        k = hamming(5);
                        k = k/sum(k);
                        amp = imfilter(amp,k,'symmetric');
                        amp = imfilter(amp,k','symmetric');
                        for i=1:3
                            subplot(2,2,i)
                            img = amp(:,:,i);
                            imagesc(img,[-1 1]*max(abs(img(:))))
                            colormap('summer')
                            axis image
                            set(gca,'xdir','reverse')
                        end
                        
                        
                    case 'two pictures'
                        subplot 121
                        img = sum(amp(:,:,[1 2]),3) - sum(amp(:,:,[3 4]),3);
                        imagesc(img, max(abs(img(:)))*[-1 1])
                        colormap(trove.bipolar)
                        
                        subplot 122
                        img = sum(amp(:,:,[1 3]),3) - sum(amp(:,:,[2 4]),3);
                        imagesc(img, max(abs(img(:)))*[-1 1])
                        colormap(trove.bipolar)
                        
                    case 'mg-yb'
                        k = hamming(5);
                        k = k/sum(k);
                        amp = imfilter(amp,k,'symmetric');
                        amp = imfilter(amp,k','symmetric');
                        
                        subplot 121
                        img = bsxfun(@times, amp(:,:,1), m) ...
                            + bsxfun(@times, amp(:,:,2), y) ...
                            + bsxfun(@times, amp(:,:,3), b) ...
                            + bsxfun(@times, amp(:,:,4), g);
                        
                        R = img(:,:,1);
                        G = img(:,:,2);
                        B = img(:,:,3);
                        R = R - median(R(:));    R = R / quantile(abs(R(:)),0.99);
                        G = G - median(G(:));    G = G / quantile(abs(G(:)),0.99);
                        B = B - median(B(:));    B = B / quantile(abs(B(:)),0.99);
                        img = cat(3,R,G,B)/2+0.5;
                        
                        img = max(0, min(1, img));
                        imshow(img)
                        set(gca,'xdir','reverse')
                        
                        subplot 122
                        k=[];
                        k.animal_id=key.animal_id;
                        k.opt_sess=key.opt_sess;
                        %try
                        structImg=fetchn(opt.Structure(k),'structure_img');
                        structMask=fetchn(opt.StructureMask(k),'structure_mask');
                        structImg=double(structImg{end}.*uint8(structMask{end}));
                        imagesc(structImg); colormap('gray');
                        axis image
                        set(gca,'xdir','reverse')
                        %catch
                        %    disp('No structure')
                        %end
                        
                end
            end
        end
        
        function SpotMap(varargin)
            
            m = cat(3,1,0,1);
            y = cat(3,1,1,0);
            b = 1-y;
            g = 1-m;
            
            for key = fetch(opt.SpotMap(varargin{:}))'
                [amp, p] = fetch1(opt.SpotMap(key), 'spot_amp', 'spot_fp');
                %try
                mask = fetchn(opt.StructureMask(rmfield(key,'opt_movie')),'structure_mask');
                mask=mask{1};
                %mask = p<0.05;
                amp = bsxfun(@times, amp, double(mask));
                %catch
                %end
                figure
                method = 'mg-yb';%'four pictures';% with luminance';
                switch method
                    case 'onespot'
                        subplot 121
                        k = hamming(5);
                        k = k/sum(k);
                        amp = imfilter(amp,k,'symmetric');
                        amp = imfilter(amp,k','symmetric');
                        img = amp;
                        imagesc(img,[-1 1]*max(abs(img(:))))
                        %colormap(trove.bipolar)
                        colormap('summer')
                        axis image
                        set(gca,'xdir','reverse')
                        
                        subplot 122
                        k=[];
                        k.animal_id=key.animal_id;
                        k.opt_sess=key.opt_sess;
                        %try
                        structImg=fetchn(opt.Structure(k),'structure_img');
                        structMask=fetchn(opt.StructureMask(k),'structure_mask');
                        structImg=double(structImg{end}.*uint8(structMask{end}));
                        imagesc(structImg); colormap('gray');
                        axis image
                        set(gca,'xdir','reverse')
                    
                    case 'four pictures'
                        k = hamming(5);
                        k = k/sum(k);
                        amp = imfilter(amp,k,'symmetric');
                        amp = imfilter(amp,k','symmetric');
                        pos=[1 3 2 4];
                        for i=1:4
                            subplot(2,2,pos(i))
                            img = amp(:,:,i);
                            imagesc(img,[-1 1]*max(abs(img(:))))
                            colormap('bone')
                            axis image
                            set(gca,'xdir','reverse')
                        end
                        
                        
                    case 'two pictures'
                     k = hamming(5);
                        k = k/sum(k);
                        amp = imfilter(amp,k,'symmetric');
                        amp = imfilter(amp,k','symmetric');
                        pos=[1 2];
                        for i=1:2
                            subplot(1,2,pos(i))
                            img = amp(:,:,i);
                            imagesc(img,[-1 1]*max(abs(img(:))))
                            colormap('bone')
                            axis image
                            set(gca,'xdir','reverse')
                        end
                        
                    case 'mg-yb'
                        k = hamming(5);
                        k = k/sum(k);
                        amp = imfilter(amp,k,'symmetric');
                        amp = imfilter(amp,k','symmetric');
                        
                        subplot 121
                        img = bsxfun(@times, amp(:,:,1), m) ...
                            + bsxfun(@times, amp(:,:,2), y) ...
                            + bsxfun(@times, amp(:,:,3), b) ...
                            + bsxfun(@times, amp(:,:,4), g);
                        
                        R = img(:,:,1);
                        G = img(:,:,2);
                        B = img(:,:,3);
                        R = R - median(R(:));    R = R / quantile(abs(R(:)),0.99);
                        G = G - median(G(:));    G = G / quantile(abs(G(:)),0.99);
                        B = B - median(B(:));    B = B / quantile(abs(B(:)),0.99);
                        img = cat(3,R,G,B)/2+0.5;
                        
                        img = max(0, min(1, img));
                        imshow(img)
                        set(gca,'xdir','reverse')
                        
                        subplot 122
                        k=[];
                        k.animal_id=key.animal_id;
                        k.opt_sess=key.opt_sess;
                        %try
                        structImg=fetchn(opt.Structure(k),'structure_img');
                        structMask=fetchn(opt.StructureMask(k),'structure_mask');
                        structImg=double(structImg{end}.*uint8(structMask{end}));
                        imagesc(structImg); colormap('gray');
                        axis image
                        set(gca,'xdir','reverse')
                        %catch
                        %    disp('No structure')
                        %end
                        
                    case 'mg-yb with luminance'
                        img = bsxfun(@times, amp(:,:,1), m) ...
                            + bsxfun(@times, amp(:,:,2), y) ...
                            + bsxfun(@times, amp(:,:,3), b) ...
                            + bsxfun(@times, amp(:,:,4), g);
                        
                        R = img(:,:,1);
                        G = img(:,:,2);
                        B = img(:,:,3);
                        R = R - median(R(:));    R = R / quantile(abs(R(:)),0.99);
                        G = G - median(G(:));    G = G / quantile(abs(G(:)),0.99);
                        B = B - median(B(:));    B = B / quantile(abs(B(:)),0.99);
                        v = sqrt(R.^2+G.^2+B.^2);
                        v = v/quantile(v(:),0.999);
                        img = cat(3,R,G,B)/2+0.5;
                        img = max(0, min(1, img));
                        img = rgb2hsv(img);
                        img(:,:,3) = v;
                        img = hsv2rgb(img);
                        imshow(img)
                        set(gca,'xdir','reverse')
                        %imgFile = sprintf('opticalSpotMap_%05d_%d_%d_%d.png', ...
                        %    key.animal_id, key.opt_sess, key.opt_movie, key.tau_idx);
                        %imwrite(img, imgFile, 'png')
                        
                    case 'mg-yb with luminance and structure'
                        subplot 121
                        img = bsxfun(@times, amp(:,:,1), m) ...
                            + bsxfun(@times, amp(:,:,2), y) ...
                            + bsxfun(@times, amp(:,:,3), b) ...
                            + bsxfun(@times, amp(:,:,4), g);
                        
                        R = img(:,:,1);
                        G = img(:,:,2);
                        B = img(:,:,3);
                        R = R - median(R(:));    R = R / quantile(abs(R(:)),0.99);
                        G = G - median(G(:));    G = G / quantile(abs(G(:)),0.99);
                        B = B - median(B(:));    B = B / quantile(abs(B(:)),0.99);
                        v = sqrt(R.^2+G.^2+B.^2);
                        v = v/quantile(v(:),0.999);
                        img = cat(3,R,G,B)/2+0.5;
                        img = max(0, min(1, img));
                        img = rgb2hsv(img);
                        img(:,:,3) = v;
                        img = hsv2rgb(img);
                        imshow(img)
                        set(gca,'xdir','reverse')
                        
                        subplot 122
                        k=[];
                        k.animal_id=key.animal_id;
                        k.opt_sess=key.opt_sess;
                        structImg=double(fetch1(opt.Structure(k),'structure_img'));
                        imagesc(structImg); colormap('gray'); caxis(caxis/1.5)
                        axis image
                        set(gca,'xdir','reverse')
                        %imgFile = sprintf('opticalSpotMap_%05d_%d_%d_%d.png', ...
                        %    key.animal_id, key.opt_sess, key.opt_movie, key.tau_idx);
                        %imwrite(img, imgFile, 'png')
                end
            end
        end
        
        function Structure(varargin)
            for key = fetch(opt.Structure(varargin{:}))'
                figure
                structImg=fetchn(opt.Structure(key),'structure_img');
                structMask=fetchn(opt.StructureMask(key),'structure_mask');
                %structImg=double(structImg{end});
                structImg=double(structImg{end}).*double(structMask{end});
                imagesc(structImg); colormap('gray');
                axis image
                set(gca,'xdir','reverse')
            end
        end
        
    end
end