%{
tp.ExtractOpt (lookup) # my newest table
extract_opt  : tinyint   # trace extraction method
-----
pixel_averaging :  enum("mean","median","PCA","ICA","NNMF")   # how pixels are combined to produce trace
%}

classdef ExtractOpt < dj.Relvar

	properties(Constant)
		table = dj.Table('tp.ExtractOpt')
	end
end
