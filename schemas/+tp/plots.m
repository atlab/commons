classdef plots
    
    methods(Static)
        
        function FineAlign(varargin)
            for key = fetch(tp.FineAlign & varargin)'
                
                [raster, motion, warp] = fetch1(tp.Align * tp.FineAlign & key, ...
                    'raster_correction', 'motion_correction', 'warp_polynom');
                    
                clf
                f = getFilename(common.TpScan & key);
                scim = ne7.scanimage.Reader(f{1});
                m = -inf;
                for iFrame=1:scim.nFrames
                    g = scim.read(1,iFrame);
                    if iFrame < 5
                        m = max(m, quantile(g(:),0.999));
                    end                        
                    g = ne7.micro.RasterCorrection.apply(g, raster(iFrame,:,:));
                    g1 = ne7.micro.MotionCorrection.apply(g, motion(iFrame,:));
                    g2 = ne7.ip.YWarp.apply(g, warp(iFrame,:));
                    
                    subplot 121, imagesc(g1, [0 m]), axis image
                    subplot 122, imagesc(g2, [0 m]), axis image
                    colormap gray
                    drawnow
                end                    
                
                disp key
            end
        end
        
        
        function Cos2Map(varargin)
            for key = fetch(tp.Cos2Map(varargin{:}))'
                clf
                subplot 221
                [g, r] = fetch1(tp.Align(key), 'green_img', 'red_img');
                imshowpair(g,r)
                grid on
                set(gca, 'XColor', 'b', 'YColor', 'b')
                title 'fluorescence'
                
                subplot 222
                [p, ori, r2, amp] = fetch1(tp.Cos2Map(key), ...
                    'cos2_fp', 'pref_ori', 'cos2_r2', 'cos2_amp');
                imagesc(amp/2,[0 1])
                %imagesc(r2,[0 0.05])
                colormap(1-gray)
                axis image
                grid on
                set(gca, 'XColor', 'b', 'YColor', 'b')
                title 'dF/F in range [0 1]'
                
                subplot 223
                h = mod(ori,pi)/pi;   % orientation is represented as hue
                s = p<0.01;   % only significantly tuned pixels are shown in color
                v = ones(size(p));  % brightness is proportional to variance explained, scaled between 0 and 10 %
                img = hsv2rgb(cat(3, h, s, v));
                image(img)
                axis image
                grid on
                set(gca, 'XColor', 'w', 'YColor', 'w')
                title 'preferred orientation of tuned pixels @ p<0.01'
                
                suptitle(sprintf('%d  %2d::%2d  #%d "%s"', ...
                    key.animal_id, key.tp_session, key.scan_idx, key.ca_opt, ...
                    fetch1(common.TpScan(key), 'scan_notes')))
                
                f = sprintf('~/figures/ori_maps/cos2map_%05d_%d_%03d_%02d', ...
                    key.animal_id, key.tp_session, key.scan_idx, key.ca_opt);
                set(gcf, 'PaperSize', [8 8], 'PaperPosition', [0 0 8 8])
                print('-dpng', f, '-r150')
            end
        end
        
        
        function VonMap(varargin)
            for key = fetch(tp.VonMap(varargin{:}))'
                clf
                subplot 221
                [g, r] = fetch1(tp.Align(key), 'green_img', 'red_img');
                imshowpair(g,r)
                grid on
                set(gca, 'XColor', 'b', 'YColor', 'b')
                title 'fluorescence'

                
                subplot 222
                [p, ori, r2, amp1, amp2] = fetch1(tp.VonMap(key), ...
                    'von_fp', 'pref_dir', 'von_r2', 'peak_amp1', 'peak_amp2');
                imagesc((amp1+amp2)/2,[0 1])
                %imagesc(r2,[0 0.05])
                colormap(1-gray)
                axis image
                grid on
                set(gca, 'XColor', 'b', 'YColor', 'b')
                title 'dF/F in range [0 1]'
                
                %                 % if vonMasks exist, outline cells
                %                 masks = fetchn(tp.VonMask(key), 'pixels');
                %                 if ~isempty(masks)
                %                     bw = false(size(g));
                %                     for m = masks'
                %                         bw(m{:}) = true;
                %                     end
                %                     hold on
                %                     b = bwboundaries(bw,4);
                %                     for i=1:length(b)
                %                         plot(b{i}(:,2),b{i}(:,1),'r')
                %                     end
                %                     hold off
                %                 end
                %
                subplot 223
                h = mod(ori,pi)/pi;   % orientation is represented as hue
                s = p<0.01;   % only significantly tuned pixels are shown in color
                v = ones(size(p));  % brightness is proportional to variance explained, scaled between 0 and 10 %
                img = hsv2rgb(cat(3, h, s, v));
                image(img)
                axis image
                grid on
                set(gca, 'XColor', 'w', 'YColor', 'w')
                title 'preferred orientation of tuned pixels @ p<0.01'
                
                suptitle(sprintf('%d  %2d::%2d  #%d "%s"', ...
                    key.animal_id, key.tp_session, key.scan_idx, key.ca_opt, ...
                    fetch1(common.TpScan(key), 'scan_notes')))
                
                f = sprintf('~/figures/ori_maps/orimap_%05d_%d_%03d_%02d', ...
                    key.animal_id, key.tp_session, key.scan_idx, key.ca_opt);
                set(gcf, 'PaperSize', [8 8], 'PaperPosition', [0 0 8 8])
                print('-dpng', f, '-r150')
            end
        end
        
        
        
        function Segment3D(varargin)
            for key = fetchn(tp.Segment3D & varargin)
            end
        end
        
        
        function Motion3D(varargin)
            for key = fetch(tp.Motion3D & varargin)
                fps = fetch1(tp.Align,'fps');
                xyz = fetch1(tp.Motion3D(key),'xyz_trajectory');
                time = (1:size(xyz,1))/fps;
                plot(time',xyz)
                xlabel time(s)
                ylabel offset(\mu m)
                legend x y z
                grid on
                drawnow
            end
        end
        
        
        function Ministack(varargin)
            for key = fetch(tp.Ministack(varargin{:}) & 'green_slices is not null' & 'red_slices is not null' & tp.Align)'
                f = sprintf('~/figures/ministacks/mini%05d_%d_%02d.gif', key.animal_id, key.tp_session, key.scan_idx);
                if ~exist(f, 'file')
                    [zstep, gstack, rstack] = fetch1(tp.Ministack(key),'zstep', 'green_slices', 'red_slices');
                    [sy,sx] = fetch1(tp.Align(key),'um_height','um_width');
                    [ny,nx,nSlices] = size(gstack);
                    h = (-floor((nSlices-1)/2):ceil((nSlices-1)/2))*zstep;
                    raster = fetch1(tp.Align(key), 'raster_correction');
                    gstack = conditionStack(gstack, raster);
                    rstack = conditionStack(rstack, raster);
                    
                    % make movie
                    nFrames = 16;
                    mag = 2;
                    F = zeros(mag*ny,mag*nx,3,nFrames);
                    udata = [-sx sx]/2;
                    vdata = [-sy sy]/2;
                    for i=1:nFrames
                        frame = zeros(mag*ny,mag*nx,3);
                        tilt = -pi/8*(i-1)/(nFrames-1);
                        rotation  = 0; %pi/60*sin((i-1)/nFrames*2*pi);
                        for iSlice = 1:nSlices
                            r = projectFrame(rstack(:,:,iSlice), h(iSlice), udata, vdata, udata*1.2, vdata*1.2, tilt, rotation,mag);
                            g = projectFrame(gstack(:,:,iSlice), h(iSlice), udata, vdata, udata*1.2, vdata*1.2, tilt, rotation,mag);
                            b = projectFrame(0.2*ones(ny,nx),    h(iSlice), udata, vdata, udata*1.2, vdata*1.2, tilt, rotation,mag);
                            transparency = 1-g.^0.8/nSlices;
                            frame = bsxfun(@times, frame, transparency);
                            frame = frame + cat(3,r,g,b)/nSlices;
                        end
                        imshow(frame)
                        drawnow
                        
                        F(:,:,:,i) = frame;
                        fprintf('frame %2d/%d\n', i, nFrames)
                    end
                    F = F/max(F(:));
                    frames = zeros([mag*ny mag*nx 1 nFrames], 'uint8');
                    [~,map] = rgb2ind(F(:,:,:,1),255);
                    for i = 1:nFrames
                        frames(:,:,1,i) = rgb2ind(F(:,:,:,i), map);
                    end
                    imwrite(frames, map, f, 'gif', 'DelayTime',0.05,'LoopCount',20,'DisposalMethod','leaveInPlace');
                end
            end
            
            function im = projectFrame(im,h,udata,vdata,xdata,ydata,tilt,rotation,mag)
                u = udata([1 1 2 2])';
                v = vdata([1 2 2 1])';
                x = u;
                y = v;
                z = -h*[1 1 1 1]';
                [x, y] = deal(cos(rotation)*x-sin(rotation)*y, sin(rotation)*x+cos(rotation)*y);
                [y, z] = deal(cos(tilt)*y-sin(tilt)*z, sin(tilt)*y+cos(tilt)*z);
                x = x./(1+z/150);
                y = y./(1+z/150);
                T = maketform('projective', [u v], [x y]);
                im = imtransform(im, T, 'bicubic', 'size', mag*size(im), ...
                    'udata', udata, 'vdata', vdata, ...
                    'xdata', xdata, 'ydata', ydata);
                im = max(0,im);
            end
            
            
            function stack = conditionStack(stack, raster)
                stack = ne7.micro.RasterCorrection.apply(stack, raster(end,:,:));
                stack = sqrt(max(0,stack+20));
                stack = max(0,stack-quantile(stack(:), 0.01));
                stack = stack/max(stack(:));
            end
        end                
    end
end