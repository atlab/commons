function pick(menu)    % stims.pick allows picking one of several preconfigured visual stimuli�

fprintf '\n\n\nWelcome to stims.pick\n'
parentTable = common.Animal;

% enter primary key
while true
    try
        for keyField = parentTable.primaryKey
            key.(keyField{1}) = input(sprintf('Enter %s: ', keyField{1}));
            assert(~isempty(key.(keyField{1})), 'cannot have empty key')
        end
        disp 'Entered:'
        disp(key)
        assert(count(parentTable & key)==1, 'not found in database')
        break
    catch err
        disp(err.message)
    end
end

assert(isempty(javachk('desktop')), 'no MATLAB desktop! Restart.')
fprintf '\nAt runtime, press numbers to select stimulus, "r"=run, "q"=quit:\n'
for i = 1:length(menu)
    fprintf('%d. %s\n', i, menu(i).prompt)
end
fprintf \n\n

disp 'While the screen is blanked you can:'
disp '   press 1-9 to select or change the stimulus (memorize them now)'
disp '   press "r" to run the selected stimulus'
disp '   press ESC to stop an ongoing stimulus (only while frames are flipping)'
disp '   press "q" to quit'
disp ' '
disp 'Now press any key when you are ready to blank the screen.'

pause
stims.core.run(menu, key)
end