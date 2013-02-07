%{
common.BrainSliceRegistration (imported) # registration points against the previous slice
-> common.BrainSliceImage
-----
n_points        : smallint  # the number of control points
input_points  : longblob   # control points
base_points     : longblob   # same points in the base image (previous slice)
%}

classdef BrainSliceRegistration < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('common.BrainSliceRegistration')
        popRel = common.BrainSliceImage & 'first_slice=0'
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            baseKey = key;
            baseKey.slice_id = key.slice_id - 1;
            if ~exists(common.BrainSliceImage & baseKey)
                warning 'no previous slice found... skipped'
            else
                inputImg = imread(strtrim(fetch1(common.BrainSliceImage & key, ...
                    'slice_filepath')));
                baseImg  = imread(strtrim(fetch1(common.BrainSliceImage & baseKey,...
                    'slice_filepath')));
                
                [key.input_points, key.base_points] = cpselect(inputImg, baseImg, 'Wait', true);
                tform = cp2tform(key.input_points, key.base_points, 'similarity');
                
                clf
                disp 'displaying results'
                subplot 121
                imshowpair(inputImg(:,:,2), baseImg(:,:,2))
                title original
                subplot 122
                imshowpair(imtransform(inputImg(:,:,2), tform, 'xdata', [1 size(baseImg,2)], 'ydata', [1 size(baseImg,1)]), baseImg)
                title registered
                
                if strncmpi('y', input('Commit results? y|n >', 's'), 1)
                    key.n_points=size(key.input_points,1);
                    self.insert(key)
                end
            end
        end
    end
end
