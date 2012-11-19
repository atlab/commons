function GiB = getFreeMemory
% returns free memory in GiB

[~,s] = unix('vm_stat | grep free');
s = regexp(s,'\d+','match');  
GiB = str2double(s{1});  % in pages of 4 kiB 
GiB = GiB*4/1024/1024;   