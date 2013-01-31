function K=computeKernelMatrix(A,B,option)
% computer the kernel matrix between matrices A and B
% Usage:
% K=computeKernelMatrix(A,B) % rbf kernel
% K=computeKernelMatrix(A,B,option)
% A: matrix, each column is a data point
% B: matrix, each column is a data point
% option: struct, include files:
% option.kernel: string, the name of kernel function, it can be one of {'linear','rbf','polynomial','sigmoid','ds'(dynamic systems kernel for 3-way GST data)}, the default is 'rbf'
% option.param: the parameter of a kernel function
%%%%
% Copyright (C) <2012>  <Yifeng Li>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% 
% Contact Information:
% Yifeng Li
% University of Windsor
% li11112c@uwindsor.ca; yifeng.li.cn@gmail.com
% September 03, 2011
%%%%

if nargin<3
    option=[];
end
optionDefault.kernel='rbf';
optionDefault.param=[];
option=mergeOption(option,optionDefault);
switch option.kernel
    case 'rbf'
        if isempty(option.param)
            option.param=1; % sigma
        end
%     sigma=param(1);
%     kfun= @kernelRBF; % my rbf kernel
    kfun=@kernelRBF; % fast rbf kernel from official matla
    case 'polynomial'
        if isempty(option.param)
            option.param=[1;0;2];
        end
%     Gamma=param(1);
%     Coefficient=param(2);
%     Degree=param(3);
    kfun= @kernelPoly;
    case 'linear'
        if any(any(isnan(A))) % any(any(isnan([A,B]))) % missing values
            kfun=@innerProduct;
        else
           kfun= @kernelLinear; % no missing values
        end
    case 'sigmoid'
        if isempty(option.param)
            option.param=[1;0];
        end
%         alpha=param(1);
%         beta=param(2);
        kfun=@kernelSigmoid;
    case 'ds' % dynamical systems kernel
%         kfun=@dynamicSystems_kernel;%(D1,D2,param), param=[numR,numC,rank,lambda]
        kfun=@dynamicSystems_kernel2;%(D1,D2,param), param=[rank,lambda]
    otherwise
        eval(['kfunc=@',option.kernel,';']);
end

K=feval(kfun,A,B,option.param); % kernel matrix
end