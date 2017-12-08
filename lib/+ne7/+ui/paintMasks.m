function masks = paintMasks(im , masks)
% lets the user outline masks in the image on the current axis

% store backgrounds if multiple provided
all_images = im;
im = im(:,:,:,1);

% use masks if provided 
if nargin<2
    masks = zeros(size(im,1),size(im,2)); 
    colors = 0;
    neuron = 0;
else
    neuron = max(masks(:));
    colors = [0 rand(1,neuron)];
end

% initialize parameters
processed_image = [];
original_im = []; 
hthr = 99.9; % highlights threshold value
radius = 10; % mask pixel radius
sz = size(im);
sat = 0.5;
val = 0.5;
sat_tog = 0.5;
val_tog = 0.5;
undoBuffer = {masks};
winsz = 32; % max size of the pointer window
running = true;
drawing = false;
xLoc = 0;
yLoc = 0;
assisted = false;
thresh = 0.01;
fit_center = false(winsz,winsz);fit_center(round(winsz/2),round(winsz/2))=true;
fit_mask = zeros(winsz,winsz);
ppitch = 1;
contrast = 0.5;
hp =[];
threshold = false;

% normalize image
normalize = @(x) (x - min(x(:)))./(max(x(:))-min(x(:))); 

% Plot
prepareImage
hf = figure('NumberTitle','off',...
    'Name','Paint masks',...
    'KeyPressFcn',@dispkeyevent,...
    'WindowScrollWheelFcn', @adjMaskSize,...
    'HitTest','off',...
    'units','normalized');
f_pos = get(hf,'outerposition');
set(gcf,'color',[0.3 0.3 0.3])
set(hf,'units','pixels')
h = image(im);
axis image
set(gca,'xtick',[],'ytick',[])
set(h,'buttondownfcn',@updateMasks)
printInstructions
redraw
adjMaskSize
hold on

% wait until done
while running && nargout>0
    try if ~ishandle(h);masks = [];break;end;catch;break;end
    pause(0.1);
end

function dispkeyevent(~, event)
    switch event.Key
        case 'a' % assisted segmentation
            if assisted
                assisted = false;
                try delete(hp);end
                set(hf,'WindowButtonMotionFcn','','WindowButtonUpFcn','');
                set(hf,'WindowScrollWheelFcn', @adjMaskSize)
                set(gcf,'pointer','custom','PointerShapeHotSpot',[winsz winsz]/2)
                adjMaskSize
            else
                c = nan(16,16);
                c(8,4:12)=2;
                c(4:12,8)=2;
                assisted = true;
                adjMaskFit
                set(hf,'WindowScrollWheelFcn', @adjMaskFit)
                set(hf,'WindowButtonMotionFcn',@adjMaskFit)
                set(gcf,'PointerShapeCData',c,'pointer','custom','PointerShapeHotSpot',[8 8])
            end
        case 'f' % toggle fullscreen
            set(hf,'units','normalized')
            p = get(hf,'outerposition');
            if all(p~=[0 0 1 1])
               set(hf,'outerposition',[0 0 1 1]);
            else
               set(hf,'outerposition',f_pos);
            end
            set(hf,'units','pixels')
        case 'comma' % decrease contrast
            if contrast>0.1
                im = normalize(original_im);
                if threshold
                    im(im>prctile(im(:),hthr)) = prctile(im(:),hthr);
                    im = normalize(im);
                end
                contrast = contrast-0.05;
                im = normalize(im.^contrast);
                redraw
            end
        case 'period' % increase contrast
            if contrast<2
                im = normalize(original_im);
                if threshold
                    im(im>prctile(im(:),hthr)) = prctile(im(:),hthr);
                    im = normalize(im);
                end
                contrast = contrast+0.1;
                im = normalize(im.^contrast);
                redraw
            end
        case 't' % threshold
            im = normalize(original_im);
            if ~threshold
                threshold = true;
                im(im>prctile(im(:),hthr)) = prctile(im(:),hthr);
            else
                threshold = false;
            end
            processed_image = (imfilter(imfill(im),gausswin(2)*gausswin(2)'));
            im = normalize(im.^contrast);
            redraw
        case 'backspace' % UNDO
            if length(undoBuffer)>1
                masks = undoBuffer{end-1};
                undoBuffer(end) = [];
                redraw
            end
        case 'space'  % SPACE - toggle outlines
            if sat>0
                sat_tog = sat;
                val_tog = val;
                sat = 0;
                val = 0;
                redraw
            else
                sat = sat_tog;
                val = val_tog;
                redraw
            end
        case 'leftbracket'
            if sat>=0.1
                sat = sat-0.1;
                redraw
            end
        case 'rightbracket'
            if sat<=0.9
                sat = sat+0.1;
                redraw
            end
        case 'semicolon'
            if val>=0.1
                val = val-0.1;
                redraw
            end
        case 'quote'
            if val<=0.9
                val = val+0.1;
                redraw
            end
        case 'escape'
            yes = questdlg('Do you wish to abort segmenting this image?','Finish segmentation', 'yes','no','no');
            if strcmpi('yes', yes)
                masks = [];  % destroy mask
                running = false;
                close(gcf)
            end
        case 'return'
            yes = questdlg('Ready to commit?','Finish segmentation', 'yes','no','no');
            if strcmpi('yes', yes)
                running = false;
                close(gcf)
            end
        case cellfun(@(x) num2str(x),num2cell(1:size(all_images,4)),'uni',0)
            im = all_images(:,:,:,str2num(event.Key));
            prepareImage
            redraw
        otherwise
            disp '---'
            disp(['key: "' event.Key '" not assigned!'])
            printInstructions
    end
end

% prepare image
function prepareImage
    % process image for assisted segmentation
    processed_image = im;  if size(im,3)>1; processed_image = mean(rgb2gray(im),3);end
    processed_image = (imfilter(imfill(processed_image),gausswin(2)*gausswin(2)'));
    original_im = im; 
    im = normalize(im.^contrast); 
end

% update masks
function updateMasks(~,~)
    % get click coordinates
    coordinates = get (gca, 'CurrentPoint');
    xLoc = coordinates(1,1);
    yLoc = coordinates(1,2);
    
    % handle out of boundaries clicks
    if xLoc>sz(2) || yLoc>sz(1) || xLoc<0 || yLoc<0
        return
    end
    
    % get neuron info
    neuron = masks(round(yLoc),round(xLoc));
    if drawing % use neuron id of first mouse down click
        neuron = drawing;
    elseif neuron == 0 % new cell
        neuron = max(masks(:))+1;
        colors(end+1) = rand(1);
    end
    
    % update mask
    idx = getMaskIdx;
    if strcmp('alt',get(gcf,'Selectiontype')) % right click delete
        masks(idx)=0;
    else
        masks(idx)=neuron;
    end
    
    % fill in undo buffer only if modified
    if ~all(undoBuffer{end}(:)==masks(:))
        undoBuffer = [undoBuffer(max(1,end-30):end) {masks}];  % append but limit buffer size
    end
    
    redraw

    % set the new values for the WindowButtonMotionFcn and
    % WindowButtonUpFcn
    if assisted
        set(hf,'WindowButtonMotionFcn',@(h,e)(cellfun(@(x)feval(x,h,e),...
            {@wmt,@adjMaskFit, @updateMasks})))
        set(hf,'WindowButtonUpFcn',{@wbu_assisted})
    else
        set(hf,'WindowButtonMotionFcn',@(h,e)(cellfun(@(x)feval(x,h,e),...
            {@wmt,@updateMasks})))
        set(hf,'WindowButtonUpFcn',{@wbu})
    end
    
end

function wmt(~,~)
    drawing = neuron;
end

% executes when the mouse button is released
function wbu_assisted(hh,~)
    set(hh,'WindowButtonUpFcn','','WindowButtonMotionFcn',@adjMaskFit);
    drawing = false;
end

% executes when the mouse button is released
function wbu(hh,~)
    set(hh,'WindowButtonMotionFcn','','WindowButtonUpFcn','');
    drawing = false;
end

% draw image with masks
function redraw
    % make image with colored masks
    map(:,:,1) = colors(masks+1);
    map(:,:,2) = sat*(masks>0);
    map(:,:,3) = val*(masks>0);
    
    if size(im,3)>2
        map = imfuse(hsv2rgb(map),im,'blend');
    else
        map(:,:,3) = im;
        map = hsv2rgb(map);
    end
    
    % show image
    h.CData = map;
    set(gcf,'name',sprintf('Mask#: %d', length(unique(masks(:)))-1))
end

function idx = getMaskIdx
    if assisted
        idx = fit_mask>0;
    else
        [gx, gy] = meshgrid(1:sz(2),1:sz(1));
        data = (gx(:) - xLoc).^2 + (gy(:) - yLoc).^2;
        idx =  data < (radius/pixelPitch)^2;
    end
end

% change selection size
function adjMaskSize(varargin)
    if nargin>1
        if varargin{2}.VerticalScrollCount<0
            if radius~=1
                radius = radius-1;
            end
        elseif varargin{2}.VerticalScrollCount>0
            if winsz/2 ~= radius
                radius = radius+1;
            end
        end
    end
    c = nan(winsz,winsz);
    [gy, gx] = meshgrid(1:winsz,1:winsz);
    data = (gx(:) - winsz/2).^2 + (gy(:) - winsz/2).^2;
    idx =  data < radius^2 & data > floor(radius*0.8)^2;
    c(idx) = 2;
    set(gcf,'PointerShapeCData',c,'pointer','custom','PointerShapeHotSpot',[winsz winsz]/2)
end

% change selection size
function adjMaskFit(varargin)
    %disp running
    if nargin>1
        try
            if varargin{2}.VerticalScrollCount<0
                if thresh>0.001
                    thresh = thresh*0.9;
                end
            elseif varargin{2}.VerticalScrollCount>0
                thresh = thresh*1.1;
            end
        end
    end
     % get click coordinates
    coordinates = get (gca, 'CurrentPoint');
    xLoc = round(coordinates(1,1));
    yLoc = round(coordinates(1,2));
    
    if xLoc>sz(2) || yLoc>sz(1) || xLoc<=0 || yLoc<=0
        return
    end
    try delete(hp);end
    fit_center = zeros(sz(1),sz(2));
    fit_center(round(yLoc),round(xLoc)) = 1;
    fit_mask = imsegfmm(processed_image, fit_center>0, thresh);
    bounds = bwboundaries(fit_mask,4);
    hp = plot(bounds{1}(:,2), bounds{1}(:,1),'r','buttondownfcn',@updateMasks);
end

% Returns the pixel pitch of the image
function pixpitch = pixelPitch
    ah = gca;
        
    % Get position of axis in pixels
    currunit = get(ah, 'units');
    set(ah, 'units', 'pixels');
    axisPos = get(ah, 'Position');
    set(ah, 'Units', currunit);

    % Calculate box position based axis limits and aspect ratios
    darismanual  = strcmpi(get(ah, 'DataAspectRatioMode'),    'manual');
    pbarismanual = strcmpi(get(ah, 'PlotBoxAspectRatioMode'), 'manual');

    if ~darismanual && ~pbarismanual
        pos = axisPos;
    else
        dx = diff(get(ah, 'XLim'));
        dy = diff(get(ah, 'YLim'));
        dar = get(ah, 'DataAspectRatio');
        pbar = get(ah, 'PlotBoxAspectRatio');

        limDarRatio = (dx/dar(1))/(dy/dar(2));
        pbarRatio = pbar(1)/pbar(2);
        axisRatio = axisPos(3)/axisPos(4);

        if darismanual
            if limDarRatio > axisRatio
                pos(1) = axisPos(1);
                pos(3) = axisPos(3);
                pos(4) = axisPos(3)/limDarRatio;
                pos(2) = (axisPos(4) - pos(4))/2 + axisPos(2);
            else
                pos(2) = axisPos(2);
                pos(4) = axisPos(4);
                pos(3) = axisPos(4) * limDarRatio;
                pos(1) = (axisPos(3) - pos(3))/2 + axisPos(1);
            end
        elseif pbarismanual
            if pbarRatio > axisRatio
                pos(1) = axisPos(1);
                pos(3) = axisPos(3);
                pos(4) = axisPos(3)/pbarRatio;
                pos(2) = (axisPos(4) - pos(4))/2 + axisPos(2);
            else
                pos(2) = axisPos(2);
                pos(4) = axisPos(4);
                pos(3) = axisPos(4) * pbarRatio;
                pos(1) = (axisPos(3) - pos(3))/2 + axisPos(1);
            end
        end
    end

    % Convert plot box position to the units used by the axis
    temp = axes('Units', 'Pixels', 'Position', pos, 'Visible', 'off',...
        'parent', get(ah, 'parent'));
    set(temp, 'Units', currunit);
    pos = get(temp, 'position');
    delete(temp);
    
    % compute pixel pitch
    p = get(hf,'Position');
    ppitch = pos(3)*p(3)/sz(2);
    pixpitch = ppitch;
end

% instructions
function printInstructions
    disp INSTRUCTIONS:
    disp 'Click to add pixels to mask'
    disp 'Right-click to delete pixels from mask'
    disp 'Scroll to set brush size'
    disp '[ to reduce saturation'
    disp '] to increase saturation'
    disp ', to reduce contrast'
    disp '. to increase contrast'
    disp 'Press "a" for assisted selection'
    disp 'Press "f" for full screen'
    fprintf('Press "t" to limit values under %.1f%%\n',hthr)
    disp 'Press BACKSPACE to undo'
    disp 'Press SPACE to toggle outlines'
    disp 'Press ESC to discard all edits'
    disp 'Press ENTER to commit'
end
end