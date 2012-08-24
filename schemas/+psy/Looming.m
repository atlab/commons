%{
psy.Looming (manual) # my newest table
-> psy.Condition

-----
luminance     :  float    # cd/m^2
contrast      :  float    # 0 .. 1 
bg_color      :  float    # 0 .. 1 
color         :  float    # 0 .. 1
pre_blank     :  float    # seconds - blank screen duration
looming_rate  :  float    # 1/sec  --   speed / object size
loom_duration :  float    # seconds
final_radius  :  float    # degrees
%}

classdef Looming < dj.Relvar

	properties(Constant)
		table = dj.Table('psy.Looming')
	end
end
