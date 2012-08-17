classdef plots
    
    
    methods(Static)
        
        function SpotMap(varargin)
            
            m = cat(3,1,0,1);
            y = cat(3,1,1,0);
            b = 1-y;
            g = 1-m;
            
            for key = fetch(opt.SpotMap(varargin{:}))'
                [amp, p] = fetch1(opt.SpotMap(key), 'spot_amp', 'spot_fp');
                %mask = p<0.05;
                %amp = bsxfun(@times, amp, mask);
                
                figure
                method = 'mg-yb with luminance';
                switch method
                    
                    case 'four pictures'
                        for i=1:4
                            subplot(2,2,i)
                            img = amp(:,:,i);
                            imagesc(img,[-1 1]*max(abs(img(:))))
                            colormap(trove.bipolar)
                            axis image
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
                        imgFile = sprintf('opticalSpotMap_%05d_%d_%d_%d.png', ...
                            key.animal_id, key.opt_sess, key.opt_movie, key.tau_idx);
                        imwrite(img, imgFile, 'png')
                        
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
                        imgFile = sprintf('opticalSpotMap_%05d_%d_%d_%d.png', ...
                            key.animal_id, key.opt_sess, key.opt_movie, key.tau_idx);
                        imwrite(img, imgFile, 'png')
                        
                end
            end
        end
        
        
    end
    
end