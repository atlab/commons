classdef plots
    
    
    methods(Static)
        function slider(src, event)
            ax = get(src,'userdata');
            c = caxis(ax);
            v = get(src,'value');
            t = get(src,'tag');
            switch t
                case 'min'
                    assert(v<c(2),'Image caxis min must be less than caxis max')
                    caxis(ax,[v c(2)]);
                case 'max'
                    assert(v>c(1),'Image caxis max must be greater than caxis min')
                    caxis(ax,[c(1) v]);
            end
        end
        
        function moveMarker(src,event)
            xy = get(gca,'currentpoint');
            xy = xy(1,:);
            h = [findobj(101,'type','axes');findobj(102,'type','axes')];
            for i=1:length(h)
                pHandle = get(h(i),'userdata');
                if ishandle(pHandle) && ~isempty(pHandle)
                    set(pHandle,'xdata',xy(1),'ydata',xy(2));
                else
                    axes(h(i));
                    hold on
                    pHandle = plot(xy(1),xy(2),'marker','x','linewidth',2);
                    set(h(i),'userdata',pHandle,'buttondownfcn',@opt.plots.moveMarker);
                end
            end
        end
        
        function SpotMap(varargin)
            
            if ishandle(varargin{1})
                src = varargin{1};
                t = get(src,'tag');
                d = get(101,'userdata');
                switch t
                    case 'prev'
                        if d.keyInd == 1
                            return
                        end
                        
                        d.keyInd = max(1,d.keyInd-1);
                    case 'next'
                        if d.keyInd == length(d.key)
                            return
                        end
                        d.keyInd = min(length(d.key),d.keyInd+1);
                end
                set(101,'userdata',d);
                h = findobj(101,'tag','index');
                set(h,'string',[num2str(d.keyInd) '/' num2str(length(d.key))]);
            else
                d.key = fetch(opt.SpotMap(varargin{:}))';
                if ~length(d.key)
                    warning('No tuples found');
                    return
                end
                d.keyInd = 1;
                figure(101)
                set(101,'userdata',d);
                if length(d.key)>1
                    uicontrol('string','<<','units','pixels','position',[0 5 50 20],'tag','prev','callback',@opt.plots.SpotMap)
                    uicontrol('style','text','units','pixels','position',[60 5 50 20],'tag','index','string',[num2str(d.keyInd) '/' num2str(length(d.key))])
                    uicontrol('string','>>','units','pixels','position',[120 5 50 20],'tag','next','callback',@opt.plots.SpotMap)
                end
            end
            
            key = d.key(d.keyInd);
            % fetch spotmap
            amp = fetch1(opt.SpotMap(key), 'spot_amp');
            
            % fetch structure
            structKey.animal_id=key.animal_id;
            structKey.opt_sess=key.opt_sess;
            structImg=fetchn(opt.Structure(structKey),'structure_img');
            structMask=fetchn(opt.StructureMask(structKey),'structure_mask');
            if length(structImg)>1
                structImg=structImg{end};
                warning('More than one structural image for this session. Using {end}');
            end
            
            if length(structMask)>1
                structMask=structMask{1};
                warning('More than one structural mask for this session. Using {1}');
            end
            
            structImg=double(structImg{1}.*uint8(structMask{1}));
            
            amp = bsxfun(@times, amp, double(structMask{1}));
            
            % filter spotmap
            k = hamming(5);
            k = k/sum(k);
            amp = imfilter(amp,k,'symmetric');
            amp = imfilter(amp,k','symmetric');
            img = amp;
            
            
            % Spot map
            figure(101)
            if size(amp,3)==1
                % One spot
                subplot(2,1,1)
                hold off
                h=imagesc(img,[-1 1]*max(abs(img(:))));
                set(h,'buttondownfcn',@opt.plots.moveMarker);
                colormap('summer')
                axis image
                set(gca,'xdir','reverse','xtick',[],'ytick',[])
                
                p=get(gca,'position');
                p=[p(1) p(2)-.01 p(3) .03];
                c=caxis;
                uicontrol('style','slider','min',c(1)-.005,'max',c(1)+.005,'value',c(1),'units','normalized','position',p,'tag','min','callback',@opt.plots.slider,'userdata',gca);
                uicontrol('style','slider','min',c(2)-.005,'max',c(2)+.005,'value',c(2),'units','normalized','position',p-[0 .03 0 0],'tag','max','callback',@opt.plots.slider,'userdata',gca);
            elseif size(amp,3)==4
                
                % Four spots - separate subplots
                pos=[1 5 2 6];
                for i=1:4
                    subplot(2,4,pos(i))
                    hold off
                    img = amp(:,:,i);
                    h=imagesc(img,[-1 1]*max(abs(img(:))));
                    set(h,'buttondownfcn',@opt.plots.moveMarker);
                    colormap('bone')
                    axis image
                    set(gca,'xdir','reverse','xtick',[],'ytick',[])
                    p=get(gca,'position');
                    p=[p(1) p(2)-.01 p(3) .03];
                    c=caxis;
                    uicontrol('style','slider','min',c(1)-.005,'max',c(1)+.005,'value',c(1),'units','normalized','position',p,'tag','min','callback',@opt.plots.slider,'userdata',gca);
                    uicontrol('style','slider','min',c(2)-.005,'max',c(2)+.005,'value',c(2),'units','normalized','position',p-[0 .03 0 0],'tag','max','callback',@opt.plots.slider,'userdata',gca);
                end
                
                % Four spots - mgyb
                subplot(1,2,2)
                hold off
                m = cat(3,1,0,1);
                y = cat(3,1,1,0);
                b = 1-y;
                g = 1-m;
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
                % % Luminance info
                % v = sqrt(R.^2+G.^2+B.^2);
                % v = v/quantile(v(:),0.999);
                % img = rgb2hsv(img);
                % img(:,:,3) = v;
                % img = hsv2rgb(img);
                
                h=imshow(img);
                set(h,'buttondownfcn',@opt.plots.moveMarker);
                keyTitle(key);
                axis image
                set(gca,'xdir','reverse')
                
            else
                error('Can only plot for 1 or 4 spots');
            end
            
            
            % Structural image
            figure(102)
            hold off
            h=imagesc(structImg); colormap('gray');
            set(h,'buttondownfcn',@opt.plots.moveMarker);
            keyTitle(structKey);
            axis image
            set(gca,'xdir','reverse','xtick',[],'ytick',[])
            p=get(gca,'position');
            p=[p(1) p(2)-.03 p(3) .03];
            uicontrol('style','slider','min',0,'max',127,'value',0,'units','normalized','position',p,'tag','min','callback',@opt.plots.slider,'userdata',gca);
            uicontrol('style','slider','min',128,'max',255,'value',255,'units','normalized','position',p-[0 .03 0 0],'tag','max','callback',@opt.plots.slider,'userdata',gca);
            
            h = [findobj(101,'type','axes');findobj(102,'type','axes')];
            for i=1:length(h)
                if  isempty(get(h(i),'userdata')) || ~ishandle(get(h(i),'userdata'))
                    axes(h(i));
                    hold on
                    pHandle = plot(0,0,'marker','x','linewidth',2);
                    set(h(i),'userdata',pHandle);
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