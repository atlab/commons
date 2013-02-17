classdef plots < handle
    methods(Static)
        function MaxEnt(varargin)
            for key = fetch(tp.FineVonMap & maxent.Gauss & varargin)'
                clf
                subplot 221
                [g, r] = fetch1(tp.FineAlign & key, 'fine_green_img', 'fine_red_img');
                imshowpair(g,r)
                axis on
                grid on
                set(gca, 'XColor', 'b', 'YColor', 'b')
                title 'fluorescence'
                
                
                subplot 221
                masks = fetchn(tp.Trace & key, 'mask_pixels');
                if ~isempty(masks)
                    bw = false(size(g));
                    for m = masks'
                        bw(m{:}) = true;
                    end
                    hold on
                    b = bwboundaries(bw,4);
                    for i=1:length(b)
                        plot(b{i}(:,2),b{i}(:,1),'r')
                    end
                    hold off
                end
                
                % superpose maxent connections
                me = maxent.Gauss & key;
                assert(me.count==1)
                regs = regionprops(bw,'Centroid','EquivDiameter');
                [pairs,w] = me.fetch1('pairs','pair_interactions');
                [ix1,ix2] = ne7.num.itril(pairs);
                for i=1:length(pairs)
                    p1 = regs(ix1(i)).Centroid;
                    p2 = regs(ix2(i)).Centroid;
                    hold on
                    c = [0 1 0];
                    if w(i)>0
                        c = [1 0 0];
                    end
                    plot([p1(1) p2(1)],[p1(2) p2(2)],'Color',c)
                    hold off
                end
                
                subplot 222
                [p, ori, r2, amp1, amp2] = fetch1(tp.FineVonMap & key, ...
                    'von_fp', 'pref_dir', 'von_r2', 'peak_amp1', 'peak_amp2');
                imagesc((amp1+amp2)/2,[0 1])
                %imagesc(r2,[0 0.05])
                colormap(gray)
                axis image
                grid on
                set(gca, 'XColor', 'b', 'YColor', 'b')
                title 'dF/F in range [0 1]'
                
                subplot 223
                h = mod(ori,pi)/pi;   % orientation is represented as hue
                s = p<0.0001 & amp1>0.1;   % only significantly tuned pixels are shown in color
                v = ones(size(p));  % brightness is proportional to variance explained, scaled between 0 and 10 %
                v = min(amp1,0.8)/0.8;
                img = hsv2rgb(cat(3, h, s, v));
                image(img)
                axis image
                grid on
                set(gca, 'XColor', 'k', 'YColor', 'k')
                title 'preferred orientation of tuned pixels @ p<0.01'
                
                % superpose maxent tuning
                hold on
                ori = me.fetch1('stim_drives');
                for iCell = find(any(ori))
                    p = regs(iCell).Centroid;
                    r = regs(iCell).EquivDiameter/2;
                    c = atan2(ori(1,iCell),ori(2,iCell));
                    plot(p(1)+r*cos(c)*[-1 1], p(2)+r*sin(c)*[-1 1], 'Color', hsv2rgb([mod(c,pi)/pi 1 1]));                    
                end
                hold off
                
                % title
                depth = fetch1(tp.Geometry & key, 'depth');
                suptitle(sprintf('%d  %2d::%2d #%d z=%1.1f\\mum "%s"', ...
                    key.animal_id, key.tp_session, key.scan_idx, ...
                    key.ca_opt, depth,  ...
                    fetch1(common.TpScan(key), 'scan_notes')))
                
                f = sprintf('./maxent_ori_%05d_%d_%03d_%02d', ...
                    key.animal_id, key.tp_session, key.scan_idx, key.ca_opt);
                set(gcf, 'PaperSize', [12 10], 'PaperPosition', [0 0 12 10])
                print('-dpng', f, '-r300')
            end
        end
    end
end