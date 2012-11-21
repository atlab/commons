% convert lower triangle indices to matrix indices and vice versa.
% 
% Here are the first few indices of the triangular matrix
%   1 
%   2  3
%   4  5  6
%   7  8  9 10
%  11 12 13 14 15
%      ....
%
% EXAMPLES:
%   [y,x] = triCoord([10 12])  ::: returns y=[4,5], x=[4,2] 
%   i = triCoord(4,1)          ::: returns 7

% -- Dimitri Yatsenko, 2012-11-20

function varargout = itril(varargin)

eps = 1e-7;  % a smaller number to ensure correct rounding
switch nargout
    case {0,1}
        assert(nargin==2, 'invalid usage. See help ne7.num.triCoord')
        y = varargin{1}; 
        x = varargin{2};
        assert(all(y>=x), 'coordinates must be from the left bottom corner of square matrix')
        varargout{1} = (y-1).*y/2 + x;
    case 2
        assert(nargin==1, 'invalid usage. See help ne7.num.triCoord')
        i = varargin{1};
        y = ceil((sqrt(8*(i-eps) + 1)-1)/2);
        x = i - (y - 1).*y/2;
        varargout = {y x};
    otherwise
        error 'invalid output arguments. See help ne7.num.triCoord'        
end
end