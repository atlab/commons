function precompute(menu)

for protocol = menu(:)'
    fprintf('Protocol: %s:\n', protocol.constants.stimulus)
    for i=1:length(protocol.stim)
        init(protocol.stim{i}, [], protocol.constants);
    end
end