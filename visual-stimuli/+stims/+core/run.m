function run(menu, key)

% blank the screen and set default luminance
stims.core.Visual.screen.open;
stims.core.Visual.screen.setContrast(3, 0.5);
% wait for user input
ch = ' ';
protocol = [];
while ch~='q'
    FlushEvents
    ch = GetChar;
    fprintf('Pressed %c\n', ch)
    if ch=='q'
        break
    elseif ismember(ch, '1':char('0'+length(menu)))
        protocol = menu(str2double(ch));
        fprintf('Selected stimulus %c\n', ch);
        initProtocol(protocol, key)
        disp 'ready to run'        
    elseif ch=='r' && ~isempty(protocol)
        executeProtocol(protocol)
    end
end
stims.core.Visual.screen.close
disp 'To restart run stims.pick again'
end


function initProtocol(protocol, key)
init(protocol.logger, key, protocol.constants);
rect = stims.core.Visual.screen.rect;
if false && any([protocol.constants.resolution_x protocol.constants.resolution_y] ~= rect(3:4))
    disp 'Mismatching screen size'
    fprintf('Stimulus specifies [%d,%d]\n', protocol.constants.resolution_x, protocol.constants.resolution_y)
    fprintf('Screen resolution is [%d,%d]\n', rect(3), rect(4))
    stims.core.Visual.screen.close
    error 'incorrect screen resolution'
else
    assert(iscell(protocol.stim), 'protocol.stim must be a cell array of structures')
    for i=1:length(protocol.stim)
        init(protocol.stim{i}, protocol.logger, protocol.constants);
    end
end
end


function executeProtocol(protocol)
if ~stims.core.Visual.DEBUG
    HideCursor;
    Priority(MaxPriority(stims.core.Visual.screen.win)); % Use realtime priority for better timing precision:
end
for iBlock = 1:protocol.blocks
    for i=1:length(protocol.stim)
        protocol.stim{i}.run    % do the work
        if stims.core.Screen.escape, break, end
        fprintf \n
    end
    if stims.core.Screen.escape, break, end
end
Priority(0);
ShowCursor;
end