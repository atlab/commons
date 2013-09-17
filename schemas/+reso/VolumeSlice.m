%{
reso.VolumeSlice (lookup) # scanimage piezo slices
slice_num  : smallint   # slice number in volume
%}

classdef VolumeSlice < dj.Relvar

	properties(Constant)
		table = dj.Table('reso.VolumeSlice')
	end
end
