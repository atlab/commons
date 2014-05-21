%% Plot connection probability for each group

figure('OuterPosition',[0 1000 1500 500]);

% First plot each group separately

subplot(1,3,1);
Title = 'Connection Probability by Group';
groups = {ss_conn,sn_conn,ns_conn,nn_conn};
xticklabels = {'Sis-Sis' 'Sis-NSis' 'NSis-Sis' 'NSis-NSis'};
for i=1:size(groups,2)
    total=fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end
labels = strcat(label);
bar(x,y);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
text(x(end),0.133,['n=' num2str(sum(total_count))],'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:size(groups,2),'XTickLabel',xticklabels,'Box','off');

clear total total_count pos_count x y label

% Second plot sister-sister connections v. controls

subplot(1,3,2);
Title = 'Connection Probability by Group';
groups = {ss_conn,[sn_conn ns_conn],nn_conn};
xticklabels = {'Sis-Sis' 'Sis-NSis' 'NSis-NSis'};
for i=1:size(groups,2)
    total=fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end
labels = strcat(label);
bar(x,y);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
text(x(end),0.133,['n=' num2str(sum(total_count))],'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:size(groups,2),'XTickLabel',xticklabels,'Box','off');

clear total total_count pos_count x y label

% Second plot sister-sister connections v. controls

subplot(1,3,3);
Title = 'Connection Probability by Group';
groups = {ss_conn,ctl_conn};
xticklabels = {'Sister' 'Non-Sister'};
for i=1:size(groups,2)
    total=fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end
labels = strcat(label);
bar(x,y);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
text(x(end),0.133,['n=' num2str(sum(total_count))],'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:size(groups,2),'XTickLabel',xticklabels,'Box','off');

clear total total_count pos_count x y label



%% Plot connection probability for sister or nonsister pairs within or between layers

figure('OuterPosition',[0 500 1500 1000]);

% First plot each group within layer connectivity

subplot(2,3,1);
Title = 'Connection Probability Within Layers';
groups = {ss_within,sn_within,ns_within,nn_within};
xticklabels = {'Sis-Sis' 'Sis-NSis' 'NSis-Sis' 'NSis-NSis'};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end

labels = strcat(label);
bar(x,y);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:size(groups,2),'XTickLabel',xticklabels,'Box','off');

clear total total_count pos_count x y label

% Second Plot each group betweenlayer connectivity
subplot(2,3,2);
Title = 'Connection Probability Between Layers';
groups = {ss_between,sn_between,ns_between,nn_between};
xticklabels = {'Sis-Sis' 'Sis-NSis' 'NSis-Sis' 'NSis-NSis'};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end

labels = strcat(label);
bar(x,y);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:size(groups,2),'XTickLabel',xticklabels,'Box','off');

clear total total_count pos_count x y label

% Third plot each group within/between layer connectivity, pooling controls

subplot(2,3,3);
Title = 'Connection Probability';
groups = {ss_within,ctl_within};
xticklabels = {'Within' 'Between'};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    within(i) = pos_count(i)/total_count(i);
end
wtotal = sum(total_count);
clear total total_count pos_count x y label

groups = {ss_between,ctl_between};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    between(i) = pos_count(i)/total_count(i);
end
btotal = sum(total_count);

y = [within;between];
h = bar(y);

ylim([0 0.14]);
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',[1 2],'XTickLabel',xticklabels,'Box','off');
set(h(1),'FaceColor','r');
set(h(2),'FaceColor','b');

clear total total_count pos_count x y label within between

% Fourth plot each group within layer connectivity,pooling controls

subplot(2,3,4);
Title = 'Connection Probability Within Layers';
groups = {ss_within,ctl_within};
xticklabels = {'Sister' 'Non-Sister'};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end

labels = strcat(label);
bar(x,y);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:size(groups,2),'XTickLabel',xticklabels,'Box','off');

clear total total_count pos_count x y label

% Fifth Plot each group between layer connectivity, poooling controls
subplot(2,3,5);
Title = 'Connection Probability Between Layers';
groups = {ss_between,ctl_between};
xticklabels = {'Sister' 'Non-Sister'};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end

labels = strcat(label);
bar(x,y);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:size(groups,2),'XTickLabel',xticklabels,'Box','off');

clear total total_count pos_count x y label