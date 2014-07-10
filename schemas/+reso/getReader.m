function reader = getReader(key)
% Returns reader object for key. Key can be a key struture or 
% any relvar where fetch(reso.Align & key) returns a single tuple.

if ~isstruct(key)
    key = fetch(reso.Align & key);
end

assert(length(key) == 1, 'one scan at a time please')

% Fetch path and basename from TpSession and TpScan
[path, basename, scanIdx] = fetch1(...
    common.TpSession*common.TpScan & key, ...
    'data_path', 'basename', 'scan_idx');

% Manually override path if using an external drive, etc
[~,hostname] = system('hostname'); 
hostname = hostname(1:end-1);
if strcmp(hostname,'JakesLaptop')
    path = ['C:\Two-Photon\Jake\' path(end-5:end) '\'];
end


try % try to use TpScan basename (usually 'scan')
    reader = reso.reader(path,basename,scanIdx);
catch % if that doesn't work, try to use basename from associated patch Recording (i.e. 'm2394A')
    basename = fetch1(pro(patch.Recording * patch.Patch, ...
        'file_num->scan_idx','filebase') & key, 'filebase');
    reader = reso.reader(path,basename,scanIdx);
end