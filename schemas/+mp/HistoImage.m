%{
mp.HistoImage (manual) # my newest table
-> mp.Slice
-----
staining ="": varchar(80)    # immunohistochemistry
mounting ="": varchar(80)    # 
image = null: longblob       # 2D image or 3D stack
exc_wavelength : float      # (nm)
filter="" : varchar(80)     # fluorescence filter 
%}

classdef HistoImage < dj.Relvar

	properties(Constant)
		table = dj.Table('mp.HistoImage')
	end

	methods
		function self = HistoImage(varargin)
			self.restrict(varargin)
		end
	end
end
