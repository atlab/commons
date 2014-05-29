figure('OuterPosition',[0 1000 1500 500]);

% First plot connectivity matrix for all connections

subplot(1,3,1);
Title = 'All Connections';
groups = {[s23s23 ctl23ctl23],[s23s4 ctl23ctl4],[s23s5 ctl23ctl5],[s4s23 ctl4ctl23],[s4s4 ctl4ctl4],[s4s5 ctl4ctl5],[s5s23 ctl5ctl23],[s5s4 ctl5ctl4],[s5s5 ctl5ctl5]};
xlabels = {'2/3' '4' '5'};
ylabels = {'5' '4' '2/3'};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end

data = [y(7) y(8) y(9);
    y(4) y(5) y(6)
    y(1) y(2) y(3)];
clims = [0 0.4];
imagesc(data,clims);
colormap(gray)
colorbar
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:3,'XTickLabel',xlabels,'yTick',1:3,'YTickLabel',ylabels,'Box','off','FontName','Arial','FontSize',14);
xlabel('Postsynaptic Cell Layer','FontName','Arial','FontSize',14,'FontWeight','Bold');
ylabel('Presynaptic Cell Layer','FontName','Arial','FontSize',14,'FontWeight','Bold');
y = [3 3 3 2 2 2 1 1 1];
x = [1 2 3 1 2 3 1 2 3];
labels = strcat(label);
text(x,y,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold','Color','k','BackgroundColor','w');

% Second plot connectivity matrix for sister connections

subplot(1,3,2);
Title = 'Sister Connections';
groups = {s23s23,s23s4,s23s5,s4s23,s4s4,s4s5,s5s23,s5s4,s5s5};
xlabels = {'2/3' '4' '5'};
ylabels = {'5' '4' '2/3'};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end

data1 = [y(7) y(8) y(9);
    y(4) y(5) y(6)
    y(1) y(2) y(3)];
clims = [0 0.4];
imagesc(data1,clims);
colormap(gray)
colorbar
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:3,'XTickLabel',xlabels,'yTick',1:3,'YTickLabel',ylabels,'Box','off','FontName','Arial','FontSize',14);
xlabel('Postsynaptic Cell Layer','FontName','Arial','FontSize',14,'FontWeight','Bold');
ylabel('Presynaptic Cell Layer','FontName','Arial','FontSize',14,'FontWeight','Bold');
y = [3 3 3 2 2 2 1 1 1];
x = [1 2 3 1 2 3 1 2 3];
labels = strcat(label);
text(x,y,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold','Color','k','BackgroundColor','w');

% Third plot connectivity matrix for non-sister connections

subplot(1,3,3);
Title = 'Non-Sister Connections';
groups = {ctl23ctl23,ctl23ctl4,ctl23ctl5,ctl4ctl23,ctl4ctl4,ctl4ctl5,ctl5ctl23,ctl5ctl4,ctl5ctl5};
xlabels = {'2/3' '4' '5'};
ylabels = {'5' '4' '2/3'};
for i=1:size(groups,2)
    total = fetch(mc.Connections & groups{i});
    total_count(i) = size(total,1);
    pos_count(i)=size(fetch(mc.Connections & total & 'conn="connected"'),1);
    label{i} = [num2str(pos_count(i)) '/' num2str(total_count(i))];
    y(i) = pos_count(i)/total_count(i);
    x(i) = i;
end

data2 = [y(7) y(8) y(9)
    y(4) y(5) y(6)
    y(1) y(2) y(3)];
clims = [0 0.4];
imagesc(data2,clims);
colormap(gray)
colorbar
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:3,'XTickLabel',xlabels,'yTick',1:3,'YTickLabel',ylabels,'Box','off','FontName','Arial','FontSize',14);
xlabel('Postsynaptic Cell Layer','FontName','Arial','FontSize',14,'FontWeight','Bold');
ylabel('Presynaptic Cell Layer','FontName','Arial','FontSize',14,'FontWeight','Bold');
y = [3 3 3 2 2 2 1 1 1];
x = [1 2 3 1 2 3 1 2 3];
labels = strcat(label);
text(x,y,labels,'HorizontalAlignment','center','FontName','Arial','FontSize',12,'FontWeight','Bold','Color','k','BackgroundColor','w');

% Fourth plot connectivity matrix all connections sister/all

figure('OuterPosition',[0 500 500 500]);
Title = 'Sister/Nonsister Connection Probability';
data = data1./data2;

for i = 1:size(data,1)
    for j = 1:size(data,2)
        if isinf(data(i,j))
            data(i,j) = 6;
        elseif isnan(data(i,j))
            data(i,j) = 1;
        end
    end
end

xlabels = {'2/3' '4' '5'};
ylabels = {'5' '4' '2/3'};
clims = [0 5];
imagesc(data,clims);
colorbar
title(Title,'FontName','Arial','FontSize',16,'FontWeight','Bold');
set(gca,'XTick',1:3,'XTickLabel',xlabels,'yTick',1:3,'YTickLabel',ylabels,'Box','off','FontName','Arial','FontSize',14);
xlabel('Postsynaptic Cell Layer','FontName','Arial','FontSize',14,'FontWeight','Bold');
ylabel('Presynaptic Cell Layer','FontName','Arial','FontSize',14,'FontWeight','Bold');




clear x y labels data
