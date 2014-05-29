function [chi2stat,p] = ChiSquared(x)

n1 = x(1) + x(2);
n2 = x(3) + x(4);
prob = (x(1) + x(3))/(n1 + n2);
e = [prob*n1 n1-(prob*n1) prob*n2 n2-(prob*n2)];
chi2stat = sum((x-e).^2 ./e);
p = 1 - (chi2cdf(chi2stat,1));
end