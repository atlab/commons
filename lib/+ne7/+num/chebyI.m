function y = chebyI(x, n)
% chebyI(x, n) -- fast chebyshev polynomials of the first kind
switch n
    case 0, y = ones(size(x));
    case 1, y = x;
    case 2, y = 2*x.*x-1;
    case 3, y = (4*x.*x-3).*x;
    case 4, xx=x.*x; y = 8*(xx-1).*xx+1;
    case 5, xx=x.*x; y = ((16*xx-20).*xx+5).*x;
    case 6, xx=x.*x; y = ((32*xx-48).*xx+18).*xx-1;
    otherwise
        error('The %dth-degree ChebyI polynomial is not defined', n)
end
end