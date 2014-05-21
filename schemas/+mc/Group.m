% Sort connections into groups 

max_tang = 400;

exc = fetch(mc.PatchCells & 'type="excitatory"');
inh = fetch(mc.PatchCells & 'type="inhibitory"');

sis = fetch(mc.PatchCells & exc & 'label="positive"');
nsis = fetch(mc.PatchCells & exc & 'label="negative"');

ss_count = 0; sn_count = 0; ns_count = 0; nn_count = 0;
ss_conn = {}; sn_conn = {}; ns_conn = {}; nn_conn = {};
ss_tang = []; sn_tang = []; ns_tang = []; nn_tang = [];
ss_euc = []; sn_euc = []; ns_euc = []; nn_euc = [];
ss_yes = 0; ss_no = 0; sn_yes = 0; sn_no = 0; ns_yes = 0; ns_no = 0; nn_yes = 0; nn_no = 0;

count = 0;
conn = fetch(mc.Connections,'*');

for i=1:size(conn,1)
    skip=0;
    if fetchn(mc.Distances & conn(i),'tang_dist') > max_tang
        skip=1;
    end
    for j = 1:size(inh,1)
        a=fetch(mc.Connections & conn(i) & inh(j));
        if ~isempty(a) && ((strcmp(conn(i).cell_pre,inh(j).p_cell_id)) || (strcmp(conn(i).cell_post,inh(j).p_cell_id)))
            skip = 1;
        end
    end
    if skip == 0;
        count = count+1;
        connections{count}  = conn(i);
    end
end   

connections = [connections{1,:}];

for i = 1:size(connections,2)
    pre_cell = fetchn(mc.PatchCells & ['animal_id=' num2str(connections(i).animal_id)] & ['slice_id="' connections(i).slice_id '"'] & ['p_column_id=' num2str(connections(i).p_column_id)] & ['p_cell_id="' connections(i).cell_pre '"'],'label');
    post_cell = fetchn(mc.PatchCells & ['animal_id=' num2str(connections(i).animal_id)] & ['slice_id="' connections(i).slice_id '"'] & ['p_column_id=' num2str(connections(i).p_column_id)] & ['p_cell_id="' connections(i).cell_post '"'],'label');
    if strcmp(pre_cell,'positive') && strcmp(post_cell,'positive')
        ss_count = ss_count +1;
        ss_conn{ss_count} = connections(i);
        if strcmp(connections(i).conn,'connected')
            ss_yes = ss_yes + 1;
        else ss_no = ss_no +1;
        end
        ss_tang(ss_count) = fetchn(mc.Distances & connections(i),'tang_dist');
        ss_euc(ss_count) = fetchn(mc.Distances & connections(i),'euc_dist');
    elseif strcmp(pre_cell,'positive') && strcmp(post_cell,'negative')
        sn_count = sn_count +1;
        sn_conn{sn_count} = connections(i);
        if strcmp(connections(i).conn,'connected')
            sn_yes = sn_yes + 1;
        else sn_no = sn_no +1;
        end
        sn_tang(sn_count) = fetchn(mc.Distances & connections(i),'tang_dist');
        sn_euc(sn_count) = fetchn(mc.Distances & connections(i),'euc_dist');
    elseif strcmp(pre_cell,'negative') && strcmp(post_cell,'positive')
        ns_count = ns_count +1;
        ns_conn{ns_count} = connections(i);
        if strcmp(connections(i).conn,'connected')
            ns_yes = ns_yes + 1;
        else ns_no = ns_no +1;
        end
        ns_tang(ns_count) = fetchn(mc.Distances & connections(i),'tang_dist');
        ns_euc(ns_count) = fetchn(mc.Distances & connections(i),'euc_dist');
    elseif strcmp(pre_cell,'negative') && strcmp(post_cell,'negative')
        nn_count = nn_count +1;
        nn_conn{nn_count} = connections(i);
        if strcmp(connections(i).conn,'connected')
            nn_yes = nn_yes + 1;
        else nn_no = nn_no +1;
        end
        nn_tang(nn_count) = fetchn(mc.Distances & connections(i),'tang_dist');
        nn_euc(nn_count) = fetchn(mc.Distances & connections(i),'euc_dist');
    end
end

ss_conn = [ss_conn{1,:}];
sn_conn = [sn_conn{1,:}];
ns_conn = [ns_conn{1,:}];
nn_conn = [nn_conn{1,:}];
ctl_conn = [sn_conn ns_conn nn_conn];
ctl_tang = [sn_tang ns_tang nn_tang];

% Sort connections into layer-specific groups

s23s23_count = 0; s23s4_count = 0; s23s5_count = 0; s23s6_count = 0; s4s23_count = 0; s4s4_count = 0; s4s5_count = 0; s4s6_count = 0; s5s23_count = 0; s5s4_count = 0; s5s5_count = 0; s5s6_count = 0; s6s23_count = 0; s6s4_count = 0; s6s5_count = 0; s6s6_count = 0;
s23n23_count = 0; s23n4_count = 0; s23n5_count = 0; s23n6_count = 0; s4n23_count = 0; s4n4_count = 0; s4n5_count = 0; s4n6_count = 0; s5n23_count = 0; s5n4_count = 0; s5n5_count = 0; s5n6_count = 0; s6n23_count = 0; s6n4_count = 0; s6n5_count = 0; s6n6_count = 0;
n23s23_count = 0; n23s4_count = 0; n23s5_count = 0; n23s6_count = 0; n4s23_count = 0; n4s4_count = 0; n4s5_count = 0; n4s6_count = 0; n5s23_count = 0; n5s4_count = 0; n5s5_count = 0; n5s6_count = 0; n6s23_count = 0; n6s4_count = 0; n6s5_count = 0; n6s6_count = 0;
n23n23_count = 0; n23n4_count = 0; n23n5_count = 0; n23n6_count = 0; n4n23_count = 0; n4n4_count = 0; n4n5_count = 0; n4n6_count = 0; n5n23_count = 0; n5n4_count = 0; n5n5_count = 0; n5n6_count = 0; n6n23_count = 0; n6n4_count = 0; n6n5_count = 0; n6n6_count = 0;

s23s23 = {}; s23s4 = {}; s23s5 = {}; s23s6 = {}; s4s23 = {}; s4s4 = {}; s4s5 = {}; s4s6 = {}; s5s23 = {}; s5s4 = {}; s5s5 = {}; s5s6 = {}; s6s23 = {}; s6s4 = {}; s6s5 = {}; s6s6 = {};
s23n23 = {}; s23n4 = {}; s23n5 = {}; s23n6 = {}; s4n23 = {}; s4n4 = {}; s4n5 = {}; s4n6 = {}; s5n23 = {}; s5n4 = {}; s5n5 = {}; s5n6 = {}; s6n23 = {}; s6n4 = {}; s6n5 = {}; s6n6 = {};
n23s23 = {}; n23s4 = {}; n23s5 = {}; n23s6 = {}; n4s23 = {}; n4s4 = {}; n4s5 = {}; n4s6 = {}; n5s23 = {}; n5s4 = {}; n5s5 = {}; n5s6 = {}; n6s23 = {}; n6s4 = {}; n6s5 = {}; n6s6 = {};
n23n23 = {}; n23n4 = {}; n23n5 = {}; n23n6 = {}; n4n23 = {}; n4n4 = {}; n4n5 = {}; n4n6 = {}; n5n23 = {}; n5n4 = {}; n5n5 = {}; n5n6 = {}; n6n23 = {}; n6n4 = {}; n6n5 = {}; n6n6 = {};


for i = 1:size(ss_conn,2)
    pre_layer = fetchn(mc.PatchCells & ['animal_id=' num2str(ss_conn(i).animal_id)] & ['slice_id="' ss_conn(i).slice_id '"'] & ['p_column_id=' num2str(ss_conn(i).p_column_id)] & ['p_cell_id="' ss_conn(i).cell_pre '"'],'layer');
    post_layer = fetchn(mc.PatchCells & ['animal_id=' num2str(ss_conn(i).animal_id)] & ['slice_id="' ss_conn(i).slice_id '"'] & ['p_column_id=' num2str(ss_conn(i).p_column_id)] & ['p_cell_id="' ss_conn(i).cell_post '"'],'layer');
    if strcmp(pre_layer,'2/3')
        if strcmp(post_layer,'2/3')
            s23s23_count = s23s23_count + 1;
            s23s23{s23s23_count} = ss_conn(i);
        elseif strcmp(post_layer,'4')
            s23s4_count = s23s4_count + 1;
            s23s4{s23s4_count} = ss_conn(i);
        elseif strcmp(post_layer,'5')
            s23s5_count = s23s5_count + 1;
            s23s5{s23s5_count} = ss_conn(i);
        elseif strcmp(post_layer,'6')
            s23s6_count = s23s6_count + 1;
            s23s6{s23s6_count} = ss_conn(i);
        end
    elseif strcmp(pre_layer,'4')
        if strcmp(post_layer,'2/3')
            s4s23_count = s4s23_count + 1;
            s4s23{s4s23_count} = ss_conn(i);
        elseif strcmp(post_layer,'4')
            s4s4_count = s4s4_count + 1;
            s4s4{s4s4_count} = ss_conn(i);
        elseif strcmp(post_layer,'5')
            s4s5_count = s4s5_count + 1;
            s4s5{s4s5_count} = ss_conn(i);
        elseif strcmp(post_layer,'6')
            s4s6_count = s4s6_count + 1;
            s4s6{s4s6_count} = ss_conn(i);
        end
    elseif strcmp(pre_layer,'5')
        if strcmp(post_layer,'2/3')
            s5s23_count = s5s23_count + 1;
            s5s23{s5s23_count} = ss_conn(i);
        elseif strcmp(post_layer,'4')
            s5s4_count = s5s4_count + 1;
            s5s4{s5s4_count} = ss_conn(i);
        elseif strcmp(post_layer,'5')
            s5s5_count = s5s5_count + 1;
            s5s5{s5s5_count} = ss_conn(i);
        elseif strcmp(post_layer,'6')
            s5s6_count = s5s6_count + 1;
            s5s6{s5s6_count} = ss_conn(i);
        end
    elseif strcmp(pre_layer,'6')
        if strcmp(post_layer,'2/3')
            s6s23_count = s6s23_count + 1;
            s6s23{s6s23_count} = ss_conn(i);
        elseif strcmp(post_layer,'4')
            s6s4_count = s6s4_count + 1;
            s6s4{s6s4_count} = ss_conn(i);
        elseif strcmp(post_layer,'5')
            s6s5_count = s6s5_count + 1;
            s6s5{s6s5_count} = ss_conn(i);
        elseif strcmp(post_layer,'6')
            s6s6_count = s6s6_count + 1;
            s6s6{s6s6_count} = ss_conn(i);
        end
    end
end

for i = 1:size(sn_conn,2)
    pre_layer = fetchn(mc.PatchCells & ['animal_id=' num2str(sn_conn(i).animal_id)] & ['slice_id="' sn_conn(i).slice_id '"'] & ['p_column_id=' num2str(sn_conn(i).p_column_id)] & ['p_cell_id="' sn_conn(i).cell_pre '"'],'layer');
    post_layer = fetchn(mc.PatchCells & ['animal_id=' num2str(sn_conn(i).animal_id)] & ['slice_id="' sn_conn(i).slice_id '"'] & ['p_column_id=' num2str(sn_conn(i).p_column_id)] & ['p_cell_id="' sn_conn(i).cell_post '"'],'layer');
    if strcmp(pre_layer,'2/3')
        if strcmp(post_layer,'2/3')
            s23n23_count = s23n23_count + 1;
            s23n23{s23n23_count} = sn_conn(i);
        elseif strcmp(post_layer,'4')
            s23n4_count = s23n4_count + 1;
            s23n4{s23n4_count} = sn_conn(i);
        elseif strcmp(post_layer,'5')
            s23n5_count = s23n5_count + 1;
            s23n5{s23n5_count} = sn_conn(i);
        elseif strcmp(post_layer,'6')
            s23n6_count = s23n6_count + 1;
            s23n6{s23n6_count} = sn_conn(i);
        end
    elseif strcmp(pre_layer,'4')
        if strcmp(post_layer,'2/3')
            s4n23_count = s4n23_count + 1;
            s4n23{s4n23_count} = sn_conn(i);
        elseif strcmp(post_layer,'4')
            s4n4_count = s4n4_count + 1;
            s4n4{s4n4_count} = sn_conn(i);
        elseif strcmp(post_layer,'5')
            s4n5_count = s4n5_count + 1;
            s4n5{s4n5_count} = sn_conn(i);
        elseif strcmp(post_layer,'6')
            s4n6_count = s4n6_count + 1;
            s4n6{s4n6_count} = sn_conn(i);
        end
    elseif strcmp(pre_layer,'5')
        if strcmp(post_layer,'2/3')
            s5n23_count = s5n23_count + 1;
            s5n23{s5n23_count} = sn_conn(i);
        elseif strcmp(post_layer,'4')
            s5n4_count = s5n4_count + 1;
            s5n4{s5n4_count} = sn_conn(i);
        elseif strcmp(post_layer,'5')
            s5n5_count = s5n5_count + 1;
            s5n5{s5n5_count} = sn_conn(i);
        elseif strcmp(post_layer,'6')
            s5n6_count = s5n6_count + 1;
            s5n6{s5n6_count} = sn_conn(i);
        end
    elseif strcmp(pre_layer,'6')
        if strcmp(post_layer,'2/3')
            s6n23_count = s6n23_count + 1;
            s6n23{s6n23_count} = sn_conn(i);
        elseif strcmp(post_layer,'4')
            s6n4_count = s6n4_count + 1;
            s6n4{s6n4_count} = sn_conn(i);
        elseif strcmp(post_layer,'5')
            s6n5_count = s6n5_count + 1;
            s6n5{s6n5_count} = sn_conn(i);
        elseif strcmp(post_layer,'6')
            s6n6_count = s6n6_count + 1;
            s6n6{s6n6_count} = sn_conn(i);
        end
    end
end

for i = 1:size(ns_conn,2)
    pre_layer = fetchn(mc.PatchCells & ['animal_id=' num2str(ns_conn(i).animal_id)] & ['slice_id="' ns_conn(i).slice_id '"'] & ['p_column_id=' num2str(ns_conn(i).p_column_id)] & ['p_cell_id="' ns_conn(i).cell_pre '"'],'layer');
    post_layer = fetchn(mc.PatchCells & ['animal_id=' num2str(ns_conn(i).animal_id)] & ['slice_id="' ns_conn(i).slice_id '"'] & ['p_column_id=' num2str(ns_conn(i).p_column_id)] & ['p_cell_id="' ns_conn(i).cell_post '"'],'layer');
    if strcmp(pre_layer,'2/3')
        if strcmp(post_layer,'2/3')
            n23s23_count = n23s23_count + 1;
            n23s23{n23s23_count} = ns_conn(i);
        elseif strcmp(post_layer,'4')
            n23s4_count = n23s4_count + 1;
            n23s4{n23s4_count} = ns_conn(i);
        elseif strcmp(post_layer,'5')
            n23s5_count = n23s5_count + 1;
            n23s5{n23s5_count} = ns_conn(i);
        elseif strcmp(post_layer,'6')
            n23s6_count = n23s6_count + 1;
            n23s6{n23s6_count} = ns_conn(i);
        end
    elseif strcmp(pre_layer,'4')
        if strcmp(post_layer,'2/3')
            n4s23_count = n4s23_count + 1;
            n4s23{n4s23_count} = ns_conn(i);
        elseif strcmp(post_layer,'4')
            n4s4_count = n4s4_count + 1;
            n4s4{n4s4_count} = ns_conn(i);
        elseif strcmp(post_layer,'5')
            n4s5_count = n4s5_count + 1;
            n4s5{n4s5_count} = ns_conn(i);
        elseif strcmp(post_layer,'6')
            n4s6_count = n4s6_count + 1;
            n4s6{n4s6_count} = ns_conn(i);
        end
    elseif strcmp(pre_layer,'5')
        if strcmp(post_layer,'2/3')
            n5s23_count = n5s23_count + 1;
            n5s23{n5s23_count} = ns_conn(i);
        elseif strcmp(post_layer,'4')
            n5s4_count = n5s4_count + 1;
            n5s4{n5s4_count} = ns_conn(i);
        elseif strcmp(post_layer,'5')
            n5s5_count = n5s5_count + 1;
            n5s5{n5s5_count} = ns_conn(i);
        elseif strcmp(post_layer,'6')
            n5s6_count = n5s6_count + 1;
            n5s6{n5s6_count} = ns_conn(i);
        end
    elseif strcmp(pre_layer,'6')
        if strcmp(post_layer,'2/3')
            n6s23_count = n6s23_count + 1;
            n6s23{n6s23_count} = ns_conn(i);
        elseif strcmp(post_layer,'4')
            n6s4_count = n6s4_count + 1;
            n6s4{n6s4_count} = ns_conn(i);
        elseif strcmp(post_layer,'5')
            n6s5_count = n6s5_count + 1;
            n6s5{n6s5_count} = ns_conn(i);
        elseif strcmp(post_layer,'6')
            n6s6_count = n6s6_count + 1;
            n6s6{n6s6_count} = ns_conn(i);
        end
    end
end

for i = 1:size(nn_conn,2)
    pre_layer = fetchn(mc.PatchCells & ['animal_id=' num2str(nn_conn(i).animal_id)] & ['slice_id="' nn_conn(i).slice_id '"'] & ['p_column_id=' num2str(nn_conn(i).p_column_id)] & ['p_cell_id="' nn_conn(i).cell_pre '"'],'layer');
    post_layer = fetchn(mc.PatchCells & ['animal_id=' num2str(nn_conn(i).animal_id)] & ['slice_id="' nn_conn(i).slice_id '"'] & ['p_column_id=' num2str(nn_conn(i).p_column_id)] & ['p_cell_id="' nn_conn(i).cell_post '"'],'layer');
    if strcmp(pre_layer,'2/3')
        if strcmp(post_layer,'2/3')
            n23n23_count = n23n23_count + 1;
            n23n23{n23n23_count} = nn_conn(i);
        elseif strcmp(post_layer,'4')
            n23n4_count = n23n4_count + 1;
            n23n4{n23n4_count} = nn_conn(i);
        elseif strcmp(post_layer,'5')
            n23n5_count = n23n5_count + 1;
            n23n5{n23n5_count} = nn_conn(i);
        elseif strcmp(post_layer,'6')
            n23n6_count = n23n6_count + 1;
            n23n6{n23n6_count} = nn_conn(i);
        end
    elseif strcmp(pre_layer,'4')
        if strcmp(post_layer,'2/3')
            n4n23_count = n4n23_count + 1;
            n4n23{n4n23_count} = nn_conn(i);
        elseif strcmp(post_layer,'4')
            n4n4_count = n4n4_count + 1;
            n4n4{n4n4_count} = nn_conn(i);
        elseif strcmp(post_layer,'5')
            n4n5_count = n4n5_count + 1;
            n4n5{n4n5_count} = nn_conn(i);
        elseif strcmp(post_layer,'6')
            n4n6_count = n4n6_count + 1;
            n4n6{n4n6_count} = nn_conn(i);
        end
    elseif strcmp(pre_layer,'5')
        if strcmp(post_layer,'2/3')
            n5n23_count = n5n23_count + 1;
            n5n23{n5n23_count} = nn_conn(i);
        elseif strcmp(post_layer,'4')
            n5n4_count = n5n4_count + 1;
            n5n4{n5n4_count} = nn_conn(i);
        elseif strcmp(post_layer,'5')
            n5n5_count = n5n5_count + 1;
            n5n5{n5n5_count} = nn_conn(i);
        elseif strcmp(post_layer,'6')
            n5n6_count = n5n6_count + 1;
            n5n6{n5n6_count} = nn_conn(i);
        end
    elseif strcmp(pre_layer,'6')
        if strcmp(post_layer,'2/3')
            n6n23_count = n6n23_count + 1;
            n6n23{n6n23_count} = nn_conn(i);
        elseif strcmp(post_layer,'4')
            n6n4_count = n6n4_count + 1;
            n6n4{n6n4_count} = nn_conn(i);
        elseif strcmp(post_layer,'5')
            n6n5_count = n6n5_count + 1;
            n6n5{n6n5_count} = nn_conn(i);
        elseif strcmp(post_layer,'6')
            n6n6_count = n6n6_count + 1;
            n6n6{n6n6_count} = nn_conn(i);
        end
    end
end

s23s23 = [s23s23{1,:}]; s23s4 = [s23s4{1,:}]; s23s5 = [s23s5{1,:}]; s23s6 = [s23s6{1,:}]; s4s23 = [s4s23{1,:}]; s4s4 = [s4s4{1,:}]; s4s5 = [s4s5{1,:}]; s4s6 = [s4s6{1,:}]; s5s23 = [s5s23{1,:}]; s5s4 = [s5s4{1,:}]; s5s5 = [s5s5{1,:}]; s5s6 = [s5s6{1,:}]; s6s23 = [s6s23{1,:}]; s6s4 = [s6s4{1,:}]; s6s5 = [s6s5{1,:}]; s6s6 = [s6s6{1,:}];
s23n23 = [s23n23{1,:}]; s23n4 = [s23n4{1,:}]; s23n5 = [s23n5{1,:}]; s23n6 = [s23n6{1,:}]; s4n23 = [s4n23{1,:}]; s4n4 = [s4n4{1,:}]; s4n5 = [s4n5{1,:}]; s4n6 = [s4n6{1,:}]; s5n23 = [s5n23{1,:}]; s5n4 = [s5n4{1,:}]; s5n5 = [s5n5{1,:}]; s5n6 = [s5n6{1,:}]; s6n23 = [s6n23{1,:}]; s6n4 = [s6n4{1,:}]; s6n5 = [s6n5{1,:}]; s6n6 = [s6n6{1,:}];
n23s23 = [n23s23{1,:}]; n23s4 = [n23s4{1,:}]; n23s5 = [n23s5{1,:}]; n23s6 = [n23s6{1,:}]; n4s23 = [n4s23{1,:}]; n4s4 = [n4s4{1,:}]; n4s5 = [n4s5{1,:}]; n4s6 = [n4s6{1,:}]; n5s23 = [n5s23{1,:}]; n5s4 = [n5s4{1,:}]; n5s5 = [n5s5{1,:}]; n5s6 = [n5s6{1,:}]; n6s23 = [n6s23{1,:}]; n6s4 = [n6s4{1,:}]; n6s5 = [n6s5{1,:}]; n6s6 = [n6s6{1,:}];
n23n23 = [n23n23{1,:}]; n23n4 = [n23n4{1,:}]; n23n5 = [n23n5{1,:}]; n23n6 = [n23n6{1,:}]; n4n23 = [n4n23{1,:}]; n4n4 = [n4n4{1,:}]; n4n5 = [n4n5{1,:}]; n4n6 = [n4n6{1,:}]; n5n23 = [n5n23{1,:}]; n5n4 = [n5n4{1,:}]; n5n5 = [n5n5{1,:}]; n5n6 = [n5n6{1,:}]; n6n23 = [n6n23{1,:}]; n6n4 = [n6n4{1,:}]; n6n5 = [n6n5{1,:}]; n6n6 = [n6n6{1,:}];

ctl23ctl23 = [s23n23 n23s23 n23n23];
ctl23ctl4 = [s23n4 n23s4 n23n4];
ctl23ctl5 = [s23n5 n23s5 n23n5];
ctl23ctl6 = [s23n6 n23s6 n23n6];
ctl4ctl23 = [s4n23 n4s23 n4n23];
ctl4ctl4 = [s4n4 n4s4 n4n4];
ctl4ctl5 = [s4n5 n4s5 n4n5];
ctl4ctl6 = [s4n6 n4s6 n4n6];
ctl5ctl23 = [s5n23 n5s23 n5n23];
ctl5ctl4 = [s5n4 n5s4 n5n4];
ctl5ctl5 = [s5n5 n5s5 n5n5];
ctl5ctl6 = [s5n6 n5s6 n5n6];
ctl6ctl23 = [s6n23 n6s23 n6n23];
ctl6ctl4 = [s6n4 n6s4 n6n4];
ctl6ctl5 = [s6n5 n6s5 n6n5];
ctl6ctl6 = [s6n6 n6s6 n6n6];

ss_within = [s23s23 s4s4 s5s5 s6s6];
ss_between = [s23s4 s23s5 s23s6 s4s23 s4s5 s4s6 s5s23 s5s4 s5s6 s6s23 s6s4 s6s5];
sn_within = [s23n23 s4n4 s5n5 s6n6];
sn_between = [s23n4 s23n5 s23n6 s4n23 s4n5 s4n6 s5n23 s5n4 s5n6 s6n23 s6n4 s6n5];
ns_within = [n23s23 n4s4 n5s5 n6s6];
ns_between = [n23s4 n23s5 n23s6 n4s23 n4s5 n4s6 n5s23 n5s4 n5s6 n6s23 n6s4 n6s5];
nn_within = [n23n23 n4n4 n5n5 n6n6];
nn_between = [n23n4 n23n5 n23n6 n4n23 n4n5 n4n6 n5n23 n5n4 n5n6 n6n23 n6n4 n6n5];
ctl_within = [sn_within ns_within nn_within];
ctl_between = [sn_between ns_between nn_between];