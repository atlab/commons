% Plot connection probability as a function of tangential distance
nbins = 3;

select = [ss_conn ctl_conn];
figure('OuterPosition',[0 1000 1500 500]);
dist = fetchn(mc.Distances & select,'tang_dist');

% First plot for all connections
Title = 'All Connections';
for i = 1:nbins
    total = fetch (mc.Distances & select & ['tang_dist>' num2str((i-1)*((max(dist)+1)/nbins))] & ['tang_dist<=' num2str(i*((max(dist)+1)/nbins))]);
    total_count(i) = size(total,1);
    pos_count(i) = size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = (i*max(dist)/(nbins))-(max(dist)/(2*nbins));
end
labels = strcat(label);
subplot(1,3,1);
bar(x,y,'BarWidth',1);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
text(x(end),0.133,['n=' num2str(sum(total_count))],'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
xlim([0 round(max(dist))]);
xlabel('Tangential Distance (um)','FontName','Arial','FontSize',14,'FontWeight','Bold');
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',0:round(max(dist)/nbins):round(max(dist)),'Box','off');

clear total total_count pos_count x y label

% Second plot for sister-sister connections

select = ss_conn;
Title = 'Sister Connections';
for i = 1:nbins
    total = fetch (mc.Distances & select & ['tang_dist>' num2str((i-1)*((max(dist)+1)/nbins))] & ['tang_dist<=' num2str(i*((max(dist)+1)/nbins))]);
    total_count(i) = size(total,1);
    pos_count(i) = size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = (i*max(dist)/(nbins))-(max(dist)/(2*nbins));
end
labels = strcat(label);
subplot(1,3,2);
bar(x,y,'BarWidth',1);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
text(x(end),0.133,['n=' num2str(sum(total_count))],'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
xlim([0 round(max(dist))]);
xlabel('Tangential Distance (um)','FontName','Arial','FontSize',14,'FontWeight','Bold');
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',0:round(max(dist)/nbins):round(max(dist)),'Box','off');

clear total total_count pos_count x y label

% Third plot for Non-sister connections

select = ctl_conn;
Title = 'Non-Sister Connections';
for i = 1:nbins
    total = fetch (mc.Distances & select & ['tang_dist>' num2str((i-1)*((max(dist)+1)/nbins))] & ['tang_dist<=' num2str(i*((max(dist)+1)/nbins))]);
    total_count(i) = size(total,1);
    pos_count(i) = size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = (i*max(dist)/(nbins))-(max(dist)/(2*nbins));
end
labels = strcat(label);
subplot(1,3,3);
bar(x,y,'BarWidth',1);
text(x,y+0.0025,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
text(x(end),0.133,['n=' num2str(sum(total_count))],'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold');
ylim([0 0.14]);
xlim([0 round(max(dist))]);
xlabel('Tangential Distance (um)','FontName','Arial','FontSize',14,'FontWeight','Bold');
ylabel('Connection Probability','FontName','Arial','FontSize',14,'FontWeight','Bold');
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',0:round(max(dist)/nbins):round(max(dist)),'Box','off');

clear total total_count pos_count x y label

