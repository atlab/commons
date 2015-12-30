function result = cajalmenu()


quadrantGrating = struct(...
    'prompt', 'Shan''s quadrant grating (960 s)', ...
    'logger', stims.core.Logger(psy.Session, psy.Condition, psy.Trial, psy.Grating), ...
    'constants', struct(...
    'stimulus', 'grating', ... % stimulus name recorded in the session table
    'monitor_distance', 10, ...  (cm)
    'monitor_size', 7, ...       (inches) diagonal
    'monitor_aspect', 1.7, ...   (physical aspect ratio W/H)
    'resolution_x', 1024, ...     (pixels)
    'resolution_y',  600 ...      (pixels)
    ), ...
    'blocks', 8, ...
    'stim', {{
    setParams(stims.Grating, ...
    'pre_blank', 3, ...
    'trial_duration', 2, ...
    'direction', [90, 180], ...
    'aperture_radius', 0.15, ...
    'aperture_x', [-0.4,0.2], ...
    'aperture_y', [-0.36,0.32], ...
    'temp_freq', 4,...
    'spatial_freq',0.08)...    
    }});

flashingBar = struct(...
    'prompt', 'flashing bar', ...
    'logger', stims.core.Logger(psy.Session, psy.Condition, psy.Trial, psy.FlashingBar), ...
    'constants', ...
    struct(...
    'stimulus', 'flashing bar', ...  % stimulus name recorded in the session table
    'monitor_distance', 10, ... (cm)
    'monitor_size', 7, ...      (inches) diagonal
    'monitor_aspect', 1.7, ...  (physical aspect ratio W/H)
    'resolution_x', 1024, ...   (pixels)
    'resolution_y',  600 ...    (pixels)
    ), ...
    'blocks', 2, ...
    'stim', {{
    setParams(stims.FlashingBar,...
    'pre_blank', 1.5, ...   (s) blank period preceding trials
    'luminance', 30, ...    cd/m^2 mid-value luminance"
    'contrast', 0.99, ...  Michelson contrast
    'bg_color', 127, ...   0-254
    'orientation', [45 135], ... (degrees) 0=north, 90=east
    'bg_color', 127, ...   0-254
    'offset', -linspace(-0.8,0.8,30), ... normalized by half-diagonal
    'width', 0.03,  ... normalized by half-diagonal
    'trial_duration', 0.5, ... (s) ON time of flashing bar
    'pattern_frequency', 15 ... (Hz) will be rounded to nearest fraction of fps
    )
    }});

movingNoise = struct(...
    'prompt', 'movingNoise', ...
    'logger', stims.core.Logger(psy.Session, psy.Condition, psy.Trial, psy.MovingNoise), ...
    'constants', ...
    struct(...
    'stimulus', 'movingNoise', ...  % stimulus name recorded in the session table
    'monitor_distance', 7, ... (cm)
    'monitor_size', 7, ...      (inches) diagonal
    'monitor_aspect', 1.7, ...  (physical aspect ratio W/H)
    'resolution_x', 1024, ...   (pixels)
    'resolution_y',  600 ...    (pixels)
    ), ...
    'blocks', 1, ... % 100 for imaging @38000 frames
    'stim', {{
    setParams(stims.MovingNoise, ...
    'rng_seed',    1:60,         ... RNG seed 1:60
    'luminance',   10,           ... cd/m^2
    'contrast',    0.95,        ... Michelson's 0-1
    'tex_ydim',    76,          ... (pixels) texture dimension
    'tex_xdim',    128,          ... (pixels) texture dimension
    'spatial_freq_half', 0.04,  ... (cy/deg) spatial frequency modulated to 50 - deprecated in version 3
    'spatial_freq_stop',0.2,    ... (cy/deg), spatial lowpass cutoff
    'temp_bandwidth',4,        ... (Hz) temporal bandwidth
    'frame_downsample', 1,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
    'n_dirs', 16, ...  number of directions of motion
    'ori_bands', 2, ...  orientation width expressed in units of 2*pi/n_dirs.  Must be integer
    'ori_modulation', 1.0, ...  mix-in proportion of oriented noise
    'ori_on_secs', 0.875, ...  seconds of movement and orientation bias
    'ori_off_secs', 1, ...  second with no movement or orientation bias
    'speed', 25 ...  degrees per second
    )
    }});

vanGogh = struct(...
    'prompt', 'Van Gogh', ...
    'logger', stims.core.Logger(psy.Session, psy.Condition, psy.Trial, psy.VanGogh), ...
    'constants', ...
    struct(...
    'stimulus', 'vangogh', ...  % stimulus name recorded in the session table
    'monitor_distance', 7, ... (cm)
    'monitor_size', 7, ...      (inches) diagonal
    'monitor_aspect', 1.7, ...  (physical aspect ratio W/H)
    'resolution_x', 1024, ...   (pixels)
    'resolution_y',  600 ...    (pixels)
    ), ...
    'blocks', 1, ...
    'stim', {{
    setParams(stims.VanGogh, ...
    'rng_seed',    1:60,         ... RNG seed 1:150
    'frame_downsample', 1,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
    'luminance',   10,           ... cd/m^2
    'contrast',    0.95,        ... Michelson's 0-1
    'duration', 30,            ... (seconds)
    'tex_ydim', 76,           ... (pixels) texture dimension
    'tex_xdim', 128,           ... (pixels) texture dimension
    'spatial_freq_half', 0.04, ... (cy/deg) spatial frequency modulated to 50 - deprecated in version 3
    'spatial_freq_stop', 0.3,  ... (cy/deg), spatial lowpass cutoff
    'temp_bandwidth', 4,       ... (Hz) temporal bandwidth
    'ori_bandwidth', pi / 20,  ... (rad) bandwidth of orientation filter
    'ori_map_spatial_bandwidth', 0.05,  ... (cy/deg) spatial bandwidth for ori map
    'ori_map_temp_bandwidth', 1,        ... (Hz) temporal bandwidth for ori map
    'contrast_spatial_bandwidth', 0.03, ... (cy/deg) spatial bandwidth of contrast map
    'contrast_temp_bandwidth', 1,       ... (Hz) temporal bandwidth of contrast map
    'contrast_exponent', 1/3            ... exponent of power function for contrast map
    )
    }});


result = [
     quadrantGrating
     flashingBar
     movingNoise
     vanGogh
    ];
