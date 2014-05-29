% Plot connection probability for each group

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

% Third plot sister-sister connections v. controls

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

