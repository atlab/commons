function masks = paintCells(im)
% lets the user outline cells in the image on the current axis

% initialize parameters
radius = 10; % mask pixel radius
sz = size(im);
im = (im - min(im(:)))./(max(im(:))-min(im(:))); % normalize image
masks = zeros(sz);
colors = 0;
sat = 0.5;
sat_tog = 0.5;
undoBuffer = {masks};
winsz = 32; % max size of the pointer window
running = true;

% Plot
h = figure('NumberTitle','off',...
    'Name','Paint cells',...
    'KeyPressFcn',@dispkeyevent,...
    'WindowScrollWheelFcn', @adjMaskSize);
printInstructions
redraw
updatePointer

% wait until done
while running
   pause(0.1)
end

function dispkeyevent(~, event)
    switch event.Key
        case 'backspace' % UNDO
            if length(undoBuffer)>1
                masks = undoBuffer{end-1};
                undoBuffer(end-1:end) = [];
                redraw
            end
        case 'space'  % SPACE - toggle outlines
            if sat>0
                sat_tog = sat;
                sat = 0;
                redraw
            else
                sat = sat_tog;
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
        otherwise
            disp '---'
            disp(['key: "' event.Key '" not assigned!'])
            printInstructions
    end
end

% update masks
function updateMasks(h,~)
    coordinates = get (gca, 'CurrentPoint');
    xLoc = coordinates(1,1);
    yLoc = coordinates(1,2);
    neuron = masks(round(yLoc),round(xLoc));
    if neuron == 0
        neuron = max(masks(:))+1;
        colors(end+1) = rand(1);
    end
    [gx, gy] = meshgrid(1:sz(2),1:sz(1));
    data = (gx(:) - xLoc).^2 + (gy(:) - yLoc).^2;
    idx =  data < (radius/pixelPitch)^2;
    if strcmp('alt',get(gcf,'Selectiontype'))
        masks(idx)=0;
    else
        masks(idx)=neuron;
    end
    redraw
    
    % get the values and store them in the figure's appdata
    props.WindowButtonMotionFcn = get(h,'WindowButtonMotionFcn');
    props.WindowButtonUpFcn = get(h,'WindowButtonUpFcn');
    setappdata(h,'TestGuiCallbacks',props);

    % set the new values for the WindowButtonMotionFcn and
    % WindowButtonUpFcn
    set(h,'WindowButtonMotionFcn',{@updateMasks})
    set(h,'WindowButtonUpFcn',{@wbu})
end

% executes when the mouse button is released
function wbu(h,~)
    % get the properties and restore them
    props = getappdata(h,'TestGuiCallbacks');
    set(h,props);
end

% draw image with masks
function redraw
    % make image with colored masks
    map(:,:,1) = colors(masks+1);
    map(:,:,2) = sat*(masks>0);
    map(:,:,3) = im;
    
    % show image
    clf
    hh = image(hsv2rgb(map));
    axis image
    set(hh,'HitTest','off')
    set(gca,'buttondownfcn',@updateMasks)
    set(gcf,'name',sprintf('Cell#: %d', max(masks(:))))
end

% change selection size
function adjMaskSize(~,e)
    if e.VerticalScrollCount<0
        if radius~=1
            radius = radius-1;
        end
    elseif e.VerticalScrollCount>0
        if winsz/2 ~= radius
            radius = radius+1;
        end
    end
    updatePointer
end

% update selection size
function updatePointer
    c = nan(winsz,winsz);
    [gy, gx] = meshgrid(1:winsz,1:winsz);
    data = (gx(:) - winsz/2).^2 + (gy(:) - winsz/2).^2;
    idx =  data < radius^2 & data > floor(radius*0.8)^2;
    c(idx) = 2;
    set(gcf,'PointerShapeCData',c,'pointer','custom','PointerShapeHotSpot',[winsz winsz]/2)
end

% Returns the pixel pitch of the image
function ppitch = pixelPitch 
    h = gca;
        
    % Get position of axis in pixels
    currunit = get(h, 'units');
    set(h, 'units', 'pixels');
    axisPos = get(h, 'Position');
    set(h, 'Units', currunit);

    % Calculate box position based axis limits and aspect ratios
    darismanual  = strcmpi(get(h, 'DataAspectRatioMode'),    'manual');
    pbarismanual = strcmpi(get(h, 'PlotBoxAspectRatioMode'), 'manual');

    if ~darismanual && ~pbarismanual
        pos = axisPos;
    else
        dx = diff(get(h, 'XLim'));
        dy = diff(get(h, 'YLim'));
        dar = get(h, 'DataAspectRatio');
        pbar = get(h, 'PlotBoxAspectRatio');

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
    temp = axes('Units', 'Pixels', 'Position', pos, 'Visible', 'off', 'parent', get(h, 'parent'));
    set(temp, 'Units', currunit);
    pos = get(temp, 'position');
    delete(temp);
    
    % compute pixel pitch
    p = get(gcf,'Position');
    ppitch = pos(3)*p(3)/sz(2);
end

% instructions
function printInstructions
    disp INSTRUCTIONS:
    disp 'Click to add pixels to mask'
    disp 'Shift-click to delete pixels from mask'
    disp 'Press BACKSPACE to undo'
    disp 'Press 1-9 to set brush size'
    disp '[ to reduce brightness'
    disp '] to increase brightness'
    disp 'Press SPACE to toggle outlines'
    disp 'Press ESC to discard all edits'
    disp 'Press ENTER to commit'
end
end