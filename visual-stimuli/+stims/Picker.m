classdef Picker
    % stims.Picker allows picking one of several preconfigured visual stimuli
    
    properties(Constant)
        static = stims.Picker   % instantiates upon loading the class
        parentTable = common.Animal
        
        menu = {% menu-item    callback
            'grating: 1s ON/1s OFF (384 s)'               setParams(stims.Grating, 2, 'direction', 0:15:359, 'pre_blank', 1.0, 'trial_duration', 1.0, 'aperture_radius', 0.63, 'init_phase', 0:0.25:0.75)
            'grating: 1s ON/0s OFF (288 s)'               setParams(stims.Grating, 4, 'direction', 0:15:359, 'pre_blank', 0.0, 'trial_duration', 1.0, 'aperture_radius', 0.63, 'init_phase', 0:0.25:0.75)
            'grating: [0.5 1.0 2.0]s ON/0.5s OFF (960 s)' setParams(stims.Grating, 2, 'direction', 0:15:359, 'pre_blank', 0.5, 'aperture_radius', 0.63, 'trial_duration', [0.5 1.0 2.0], 'init_phase', [0 .5])
            %'grating: in four spots (960 s)'              setParams(stims.Grating, 12, 'pre_blank', 6, 'trial_duration', 4.0, 'direction', [90 180], 'aperture_radius', 0.4, 'aperture_x', [-0.56 0.56], 'aperture_y',[-0.42 0.42], 'temp_freq',4,'spatial_freq',.04)
            'grating: in one spot (480 s)'              setParams(stims.Grating, 15, 'pre_blank', 6, 'trial_duration', 4.0, 'direction', [90 180], 'aperture_radius', 0.3, 'aperture_x', -.4, 'aperture_y',-.4, 'temp_freq',[2 4 8])
            'looming:                    '              setParams(stims.Looming, 20, 'pre_blank', 6, 'loom_duration', 2, 'looming_rate', [0.5 1.0 2.0], 'color', 0, 'bg_color', 0.5, 'luminance', 5, 'contrast', 0.95)
            'moving bar: white on black (384 s)'      setParams(stims.MovingBar, 12, 'luminance', 10, 'contrast', 0.97, 'bg_color', 0, 'bar_color', 254, 'trial_duration', 4)
            'moving bar: 2 contrasts (384 s)'         setParams(stims.MovingBar, 6, 'luminance', 10, 'contrast', 0.97, 'bg_color', 92, 'bar_color', [0 254], 'trial_duration', 4)
            'noise map (800 s)'   setParams(stims.NoiseMap,1)
            'dot map (792 s)'     setParams(stims.DotMap, 1)
            }
    end
    
    properties
        key
        monitorDistance
    end
    
    methods(Access=private)
        function self = Picker
            clc, disp 'Welcome to stims.Picker'
            % enter primary key
            while true
                try
                    for keyField = self.parentTable.primaryKey
                        self.key.(keyField{1}) = input(sprintf('Enter %s: ', keyField{1}));
                        assert(~isempty(self.key.(keyField{1})), 'cannot have empty key')
                    end
                    disp 'Entered:'
                    disp(self.key)
                    assert(count(self.parentTable & self.key)>0, 'not found in database')
                    break
                catch err
                    disp(err.message)
                end
            end
            
            while isempty(self.monitorDistance)
                self.monitorDistance = input('\nenter monitor distance (cm): ');
            end
        end
    end
    
    
    methods(Static)
        function pick
            assert(isempty(javachk('desktop')), 'no MATLAB desktop! Restart.')
            fprintf '\nAt runtime, press numbers to select stimulus, "r"=run, "q"=quit:\n'
            for i = 1:size(stims.Picker.menu,1)
                fprintf('%d. %s\n', i, stims.Picker.menu{i,1})
            end
            fprintf \n\n
            disp 'Click <a href="matlab:stims.Picker.run">start</a> when ready'
        end
        
        
        
        %%%%% callbacks %%%%%%%%%%%%%%q
        function run
            stims.core.Visual.screen.open;
            stims.core.Visual.screen.setContrast(3, 0.5); % default luminance while waiting
            stim = [];
            ch = ' ';
            while ch~='q'
                FlushEvents
                ch = GetChar;
                FlushEvents
                if ch=='q'
                    break
                elseif ismember(ch, '1':char('0'+length(stims.Picker.menu)))
                    stim = stims.Picker.menu{str2double(ch),2};
                    stim.init(stims.Picker.static.key, 'monitor_distance', stims.Picker.static.monitorDistance)
                    fprintf('Selected stimulus %c\n', ch);
                elseif ch=='r' && ~isempty(stim)
                    stim.run
                end
            end
            stims.core.Visual.screen.close
            disp 'To restart, "clear classes" and "stims.Picker.pick"'
        end
    end
end