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
                d.type = input('Please enter the type of SpotMap: ');
                if d.type == 1
                    d.key = fetch(opt.SpotMap(varargin{:}))';
                else
                    d.key = fetch(opt.SpotMap2(varargin{:}))';
                end
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
            if d.type == 1
                amp = fetch1(opt.SpotMap(key), 'spot_amp');
            else
                amp = fetch1(opt.SpotMap2(key), 'spot_amp');
            end
            
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
                %keyTitle(key);
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
            %keyTitle(structKey);
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
        
        function SpotMapMerge(varargin)
            % merge the SpotMap on top of the vessels
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
                d.type = input('Please enter the type of the spotmap: ');
                
                if d.type==1
                    d.key = fetch(opt.SpotMap(varargin{:}))';
                else
                    d.key = fetch(opt.SpotMap2(varargin{:}))';
                end
                if ~length(d.key)
                    warning('No tuples found');
                    return
                end
                d.keyInd = 1;
                figure(101)
                set(101,'userdata',d);
                if length(d.key)>1
                    uicontrol('string','<<','units','pixels','position',[0 5 50 20],'tag','prev','callback',@opt.plots.SpotMapMerge)
                    uicontrol('style','text','units','pixels','position',[60 5 50 20],'tag','index','string',[num2str(d.keyInd) '/' num2str(length(d.key))])
                    uicontrol('string','>>','units','pixels','position',[120 5 50 20],'tag','next','callback',@opt.plots.SpotMapMerge)
                end
            end
            
            key = d.key(d.keyInd);
            % fetch spotmap
            if d.type==1
                [amp, p] = fetch1(opt.SpotMap(key), 'spot_amp', 'spot_fp');
            else
                amp = fetch1(opt.SpotMap2(key), 'spot_amp');
            end
            % fetch structure
            structKey.animal_id=key.animal_id;
            structKey.opt_sess=key.opt_sess;
            structImg=fetchn(opt.Structure(structKey),'structure_img');
            structMask=fetchn(opt.StructureMask(structKey),'structure_mask');
            if length(structImg)>1
                structNum = length(structImg);
                num = input(['Please enter which structure image do you need 1-' num2str(structNum) ': ']);
                structImg=structImg{num};
                structMask=structMask{num};
                structImg=double(structImg.*uint8(structMask));
                amp = bsxfun(@times, amp, double(structMask));
            else
                structImg=double(structImg{1}.*uint8(structMask{1}));
                amp = bsxfun(@times, amp, double(structMask{1}));
            end
            
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
                for ii = 1:4
                    im = squeeze(amp(:,:,ii));
                    amp2(:,:,ii) = info.plots.normalize(im);
                end
                
                m = cat(3,1,0,1);
                y = cat(3,1,1,0);
                b = 1-y;
                g = 1-m;
                img = bsxfun(@times, amp2(:,:,1), g) ...
                    + bsxfun(@times, amp2(:,:,2), b) ...
                    + bsxfun(@times, amp2(:,:,3), y) ...
                    + bsxfun(@times, amp2(:,:,4), m);
                
                R = img(:,:,1);
                G = img(:,:,2);
                B = img(:,:,3);
               
                img = cat(3,R,G,B)*3+0.1;
                img = max(0, min(1, img));
                % % Luminance info
                              
                h=imshow(img);
                set(h,'buttondownfcn',@opt.plots.moveMarker);
                %keyTitle(key);
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
            %keyTitle(structKey);
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
            figure(103)
            img2 = rgb2hsv(img);
            structImg = convn(structImg, gausswin(5)*gausswin(5)', 'valid');
            structImg = (structImg-min(structImg(:)))./(max(structImg(:))-min(structImg(:)));
            img2(:,:,3) = structImg;
            img3 = hsv2rgb(img2);
            image(img3);
            set(gca,'xdir','reverse','xtick',[],'ytick',[])
            axis image
            %keyTitle(structKey);
            information.img = img2;
            information.key = structKey;
            uicontrol('style','slider','min',0,'max',0.1,'value',0,'units','normalized','position',p,'tag','min','callback',@opt.plots.SliderMerge,'userdata',information);
            uicontrol('style','slider','min',0.9,'max',1,'value',1,'units','normalized','position',p-[0 .03 0 0],'tag','max','callback',@opt.plots.SliderMerge,'userdata',information);
            
            
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
        function SliderMerge(src,event)
            figure(103)
            information = get(src,'userdata');
            structImg = squeeze(information.img(:,:,3));
            img = information.img;
            v = get(src,'value');
            t = get(src,'tag');
            
            switch t
                case 'min'
                    structImg(structImg<quantile(structImg(:),v)) = quantile(structImg(:),v);
                case 'max'
                    structImg(structImg>quantile(structImg(:),v)) = quantile(structImg(:),v);
                    
            end
            structImg = (structImg-min(structImg(:)))./(max(structImg(:))-min(structImg(:)));
            img(:,:,3) = structImg;
            img = hsv2rgb(img);
            image(img);
            set(gca,'xdir','reverse','xtick',[],'ytick',[])
            axis image
            %keyTitle(information.key);

        end
        
        function BarMap(varargin)
             
            % merge the SpotMap on top of the vessels
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
               
                d.key = fetch(opt.BarMap(varargin{:}))';
                if isempty(d.key)
                    warning('No tuples found');
                    return
                end
                d.keyInd = 1;
                figure(101)
                set(101,'userdata',d);
                if length(d.key)>1
                    uicontrol('string','<<','units','pixels','position',[0 5 50 20],'tag','prev','callback',@opt.plots.BarMap)
                    uicontrol('style','text','units','pixels','position',[60 5 50 20],'tag','index','string',[num2str(d.keyInd) '/' num2str(length(d.key))])
                    uicontrol('string','>>','units','pixels','position',[120 5 50 20],'tag','next','callback',@opt.plots.BarMap)
                end
            end
            
            key = d.key(d.keyInd);
            % fetch barmap
            [imP,imA] = fetch1(opt.BarMap(key), 'bar_phase_map', 'bar_amp_map');
            % fetch structure
            structKey.animal_id=key.animal_id;
            structKey.opt_sess=key.opt_sess;
            structImg=fetchn(opt.Structure(structKey),'structure_img');
            structMask=fetchn(opt.StructureMask(structKey),'structure_mask');
            if length(structImg)>1
                structNum = length(structImg);
                num = input(['Please enter which structure image do you need 1-' num2str(structNum) ': ']);
                structImg=structImg(num);
                structMask=structMask(num);
                
               
                
               
            end
            structImg=double(structImg{1}.*uint8(structMask{1}));
            
            
            % filter spotmap
            % set parameters for the filtering
            params.sigma = 2; %sigma of the gaussian filter
            params.exp = 1; % exponent factor of rescaling
            params.reverse = 1; % reverse the axis
            params.range = 3.14/2; % angle limit
            
            imA(imA>prctile(imA(:),99)) = prctile(imA(:),99);
            [h1,h2] = hist(reshape(imP(imP~=0),[],1),100);
            mxv = h2(h1 == max(h1));
            imP = imP - mxv(1);
            imP(imP<-3.14) = imP(imP<-3.14) +3.14*2;
            imP(imP>3.14) = imP(imP>3.14) -3.14*2;
            imP(imP<0) = -exp((imP(imP<0)+ params.range)*params.exp);
            imP(imP>0) = exp((abs(imP(imP>0)- params.range))*params.exp);
            
            h = normalize(imP);
            h = bsxfun(@times, h, double(structMask{1}));
            s = ones(size(imP));
            v = normalize(imA);
            v = bsxfun(@times, v, double(structMask{1}));
            s2 = normalize(imA);
            s2 = bsxfun(@times, s2, double(structMask{1}));
            v2 = normalize(structImg);
            
            
            % bar map
            figure(101)
            
            set(gcf,'position',[50 200 920 435])

            subplot(121)
            im = (hsv2rgb(cat(3,h,cat(3,s,v))));
%             im = convn(im, gausswin(params.sigma)*gausswin(params.sigma)', 'valid');
            imshow(im)
            if params.reverse
                set(gca,'xdir','reverse')
            end

            subplot(122)
            im = (hsv2rgb(cat(3,h,cat(3,s2,v2))));
%             im = convn(im, gausswin(params.sigma)*gausswin(params.sigma)', 'valid');
            imshow(im)

            if params.reverse
                set(gca,'xdir','reverse')
            end
            keyTitle(key);       
        
        
        end
        
        function BarrelMap(varargin)
            
            % set the GUI environment
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
                d.key = fetch(opt.BarrelMap & varargin{:})';
                if isempty(d.key)
                    warning('No tuples found');
                    return
                end
                d.keyInd = 1;
                figure(101)
                set(101,'userdata',d);
                if length(d.key)>1
                    uicontrol('string','<<','units','pixels','position',[0 5 50 20],'tag','prev','callback',@opt.plots.BarrelMap)
                    uicontrol('style','text','units','pixels','position',[60 5 50 20],'tag','index','string',[num2str(d.keyInd) '/' num2str(length(d.key))])
                    uicontrol('string','>>','units','pixels','position',[120 5 50 20],'tag','next','callback',@opt.plots.BarrelMap)
                end
            end
            
            % fetch barrel map
            key = d.key(d.keyInd);
            amp = fetch1(opt.BarrelMap & key,'barrel_amp');
            
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
            
           
            % plot barrel map
            figure(101)
            h=imagesc(img,[-1 1]*max(abs(img(:))));
            
            set(h,'buttondownfcn',@opt.plots.moveMarker);
            colormap('gray')
            axis image
            set(gca,'xdir','reverse','xtick',[],'ytick',[])

            p=get(gca,'position');
            p=[p(1) p(2)-.01 p(3) .03];
            c=caxis;
            uicontrol('style','slider','min',c(1)-.005,'max',c(1)+.005,'value',c(1),'units','normalized','position',p,'tag','min','callback',@opt.plots.slider,'userdata',gca);
            uicontrol('style','slider','min',c(2)-.005,'max',c(2)+.005,'value',c(2),'units','normalized','position',p-[0 .03 0 0],'tag','max','callback',@opt.plots.slider,'userdata',gca);
            
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
    end
end