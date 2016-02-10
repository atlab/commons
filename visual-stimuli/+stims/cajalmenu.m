function choices = cajalmenu()

logger = @() stims.core.Logger(psy.Session, psy.Condition, psy.Trial);

stims.core.Visual.screen.enableContrast(false);  % when false, disables contrast and brightness settings and uses default monitor settings

constants = struct(...
    'monitor_distance', 15, ... (cm)
    'monitor_size', 25, ...      (inches) diagonal
    'monitor_aspect', 1.78, ...  (physical aspect ratio W/H)
    'resolution_x', 2560, ...   (pixels)
    'resolution_y',  1440 ...    (pixels)
    );


quadrantGrating = struct(...
    'prompt', 'Shan''s quadrant grating (960 s)', ...
    'logger', logger(), ...
    'constants', setfield(constants, 'stimulus', 'grating'), ...
    'blocks', 8, ...
    'stim', {{
    setParams(stims.Grating, psy.Grating, ...
    'pre_blank', 3, ...
    'luminance', 10, ...
    'contrast', 0.95, ...
    'trial_duration', 2, ...
    'direction', [90, 180], ...
    'init_phase', 0, ...
    'grating', 'sqr', ...  'sqr or 'sin' 
    'aperture_radius', 0.15, ...
    'aperture_x', [-0.4,0.2], ...
    'aperture_y', [-0.36,0.32], ...
    'temp_freq', 4, ...
    'spatial_freq', 0.08, ...
    'phase2_fraction', 0, ...  between 0 and 1
    'phase2_temp_freq', 2, ...
    'second_photodiode', 0, ...  1 = paint white photodiode patch, -1=black, 0=none
    'second_photodiode_time', 0 ... (s) time delay of the second photodiode to the onset of the stimulus
    )
    }}); %#ok<SFLD>


flashingBar = struct(...
    'prompt', 'flashing bar (3 min)', ...
    'logger', logger(), ...
    'constants', setfield(constants, 'stimulus', 'flashing bar'), ...
    'blocks', 2, ...
    'stim', {{
    setParams(stims.FlashingBar, psy.FlashingBar, ...
    'pre_blank', 1.0, ...   (s) blank period preceding trials
    'luminance', 30, ...    cd/m^2 mid-value luminance"
    'contrast', 0.99, ...  Michelson contrast
    'bg_color', 127, ...   0-254
    'orientation', [0 90], ... (degrees) 0=north, 90=east
    'offset', -linspace(-0.6, 0.6, 30), ... normalized by half-diagonal
    'width', 0.02,  ... normalized by half-diagonal
    'trial_duration', 0.5, ... (s) ON time of flashing bar
    'pattern_frequency', 20 ... (Hz) will be rounded to nearest fraction of fps
    )
    }}); %#ok<SFLD>


movingNoise = struct(...
    'prompt', 'Monet (30 min)', ...
    'logger', logger(), ...
    'constants', setfield(constants, 'stimulus', 'grating'), ...
    'blocks', 1, ... % 100 for imaging @38000 frames
    'stim', {{
    setParams(stims.MovingNoise, psy.MovingNoise, ...
    'rng_seed',    1:30,         ... RNG seed 1:30
    'luminance',   10,           ... cd/m^2
    'contrast',    0.95,        ... Michelson's 0-1
    'tex_ydim',    90,          ... (pixels) texture dimension
    'tex_xdim',    160,          ... (pixels) texture dimension
    'spatial_freq_half', 0.04,  ... deprecated in version 3 -- (cy/deg) spatial frequency modulated to 50 - 
    'spatial_freq_stop',0.08,    ... (cy/deg), spatial lowpass cutoff
    'temp_bandwidth',4,        ... (Hz) temporal bandwidth
    'frame_downsample', 1,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
    'n_dirs', 16, ...  number of directions of motion
    'ori_bands', 2, ...  orientation width expressed in units of 2*pi/n_dirs.  Must be integer
    'ori_modulation', 1, ...  mix-in proportion of oriented noise
    'ori_on_secs', 1.0, ...  seconds of movement and orientation bias
    'ori_off_secs', 2.75, ...  second with no movement or orientation bias
    'speed', 20 ...  degrees per second
    )
    }}); %#ok<SFLD>


vanGogh = struct(...
    'prompt', 'Van Gogh (30 min)', ...
    'logger', logger(), ...
    'constants', setfield(constants, 'stimulus', 'vangogh'), ...
    'blocks', 1, ...
    'stim', {{
    setParams(stims.VanGogh, psy.VanGogh, ...
    'rng_seed',    1:60,         ... RNG seed 1:150
    'frame_downsample', 1,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
    'luminance',   10,           ... cd/m^2
    'contrast',    0.95,        ... Michelson's 0-1
    'duration', 30,            ... (seconds)
    'tex_ydim', 90,           ... (pixels) texture dimension
    'tex_xdim', 160,           ... (pixels) texture dimension
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
    }}); %#ok<SFLD>

trippy = struct(...
    'prompt', 'Trippy (30 mins)', ...
    'logger', logger(), ...
    'constants', setfield(constants, 'stimulus', 'trippy'), ...
    'blocks', 1, ...
    'stim', {{
    setParams(stims.Trippy, psy.Trippy, ...
    'rng_seed',    1:30,         ... RNG seed 1:150
    'frame_downsample', 1,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
    'luminance',   10,           ... cd/m^2
    'contrast',    0.95,        ... Michelson's 0-1
    'duration', 60,            ... (seconds)
    'tex_ydim',  90,           ... (pixels) texture dimension
    'tex_xdim', 160,           ... (pixels) texture dimension
    'xnodes', 8, ...     % x dimension of low-res phase movie
    'ynodes', 6, ...      % y dimension of low-res phase movie
    'up_factor', 24, ...  % upscale factor from low-res to texture dimensions
    'temp_freq', 2.5, ...   % (Hz) temporal frequency if the phase pattern were static
    'temp_kernel_length', 61, ...  % length of Hanning kernel used for temporal filter. Controls the rate of change of the phase pattern.
    'spatial_freq', 0.06 ...  % (cy/degree) approximate max. Actual frequency spectrum ranges propoprtionally.
    )}}); %#ok<SFLD>


trippyMonet = struct( ...
    'prompt', 'TrippyMonet (40 mins)', ...
    'logger', logger(), ...
    'constants', setfield(constants, 'stimulus', 'grating'), ...
    'blocks', 1, ...
    'stim', {{
    setParams(stims.Trippy, psy.Trippy, ...
    'rng_seed',    1:20,         ... RNG seed 1:150
    'frame_downsample', 1,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
    'luminance',   10,           ... cd/m^2
    'contrast',    0.95,        ... Michelson's 0-1
    'duration', 60,            ... (seconds)
    'tex_ydim',  90,           ... (pixels) texture dimension
    'tex_xdim', 160,           ... (pixels) texture dimension
    'xnodes', 8, ...     % x dimension of low-res phase movie
    'ynodes', 6, ...      % y dimension of low-res phase movie
    'up_factor', 24, ...  % upscale factor from low-res to texture dimensions
    'temp_freq', 2.5, ...   % (Hz) temporal frequency if the phase pattern were static
    'temp_kernel_length', 61, ...  % length of Hanning kernel used for temporal filter. Controls the rate of change of the phase pattern.
    'spatial_freq', 0.06 ...  % (cy/degree) approximate max. Actual frequency spectrum ranges propoprtionally.
    )
    setParams(stims.MovingNoise, psy.MovingNoise, ...
    'rng_seed',    1:20,         ... RNG seed 1:60
    'luminance',   10,           ... cd/m^2
    'contrast',    0.95,        ... Michelson's 0-1
    'tex_ydim',    90,          ... (pixels) texture dimension
    'tex_xdim',    160,          ... (pixels) texture dimension
    'spatial_freq_half', 0.04,  ... deprecated in version 3 -- (cy/deg) spatial frequency modulated to 50 - 
    'spatial_freq_stop',0.08,    ... (cy/deg), spatial lowpass cutoff
    'temp_bandwidth',4,        ... (Hz) temporal bandwidth
    'frame_downsample', 1,      ... 1=60 fps, 2=30 fps, 3=20 fps, 4=15 fps, etc
    'n_dirs', 16, ...  number of directions of motion
    'ori_bands', 2, ...  orientation width expressed in units of 2*pi/n_dirs.  Must be integer
    'ori_modulation', 0, ...  mix-in proportion of oriented noise
    'ori_on_secs', 1.75, ...  seconds of movement and orientation bias
    'ori_off_secs', 2, ...  second with no movement or orientation bias
    'speed', 0 ...  degrees per second
    )
    }}); %#ok<SFLD>




choices = [
     quadrantGrating
     flashingBar
     movingNoise
     vanGogh
     trippy
     trippyMonet
    ];
