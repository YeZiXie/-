%% 数据处理
clc
clear
Data_ori = readtable("附件1：物流网络历史货量数据.xlsx",'VariableNamingRule','preserve');
Data_cell = table2cell(Data_ori);
[m,n] = size(Data_cell);
Data_int = zeros(m,n);
TotalPosNum = 81;

%将原始数据转换成整数数据
for i = 1:m
   Data_int(i,1) = getint(Data_cell{i,1});
   Data_int(i,2) = getint(Data_cell{i,2});
   Data_int(i,3) = datenum(Data_cell{i,3});
   Data_int(i,4) = Data_cell{i,4};
end

%按时间归类，每天的数据归到一类
Date_unique = unique(Data_int(:,3));
TotalDateNum = size(Date_unique,1);
Data_day_detail = cell(TotalDateNum,4);
startidx = 0;
Data_route = [0:TotalDateNum];
for i=1:m
    sendIdx = Data_int(i,1);
    receIdx = Data_int(i,2);
    if startidx == 0 || Data_day_detail{startidx,2} ~= Data_int(i,3)
        startidx = startidx + 1;
        Data_day_detail{startidx,1} = datestr(Data_int(i,3),'yyyy-mm-dd');        
        Data_day_detail{startidx,2} = Data_int(i,3);
        Data_day_detail{startidx,3} = Data_int(i,:);
        Data_day_detail{startidx,4} = zeros(TotalPosNum,3);
        Data_day_detail{startidx,4}(:,1) = [1:TotalPosNum]';        
    else
        Data_day_detail{startidx,3} = [Data_day_detail{startidx,3};Data_int(i,:)];          
    end 
    Data_day_detail{startidx,4}(sendIdx,2) = Data_day_detail{startidx,4}(sendIdx,2) + Data_int(i,4);
    Data_day_detail{startidx,4}(receIdx,3) = Data_day_detail{startidx,4}(receIdx,3) + Data_int(i,4); 
    routeIDX = sendIdx * 100 + receIdx;
    findResult = find(Data_route(:,1)==routeIDX);
    if isempty(findResult)
        tempdata = zeros(1,TotalDateNum+1);
        tempdata(1,1) = routeIDX;
        tempdata(1,startidx+1) = Data_int(i,4);
        Data_route = [Data_route;tempdata];
    else
        Data_route(findResult(1,1),startidx+1) = Data_int(i,4);
    end
    
end

%计算每条路线的数据(路线ID，起点，终点，最小流量，最大流量，总平均流量，22年最大值，22年平均流量)
Data_route_detail = zeros(size(Data_route,1),8);
Data_route_detail(:,1) = Data_route(:,1);
Data_route_detail(:,2) = floor(Data_route(:,1)/100);
Data_route_detail(:,3) = mod(Data_route(:,1),100);
Data_route_detail(:,4:5) = minmax(Data_route(:,2:end));
% Data_route_detail(:,5) = max(Data_route(:,2:end),[],2);
Data_route_detail(:,6) = mean(Data_route(:,2:end),2);
Data_route_detail(:,7) = max(Data_route(:,368:end),[],2);
Data_route_detail(:,8) = mean(Data_route(:,368:end),2);
TotalRoute = size(Data_route,1) - 1;

%计算每个节点流入流出数据
Data_pos_out = zeros(TotalPosNum + 1, TotalDateNum + 1);
Data_pos_out(:,1) = [0:TotalPosNum];
Data_pos_in = zeros(TotalPosNum + 1, TotalDateNum + 1);
Data_pos_in(:,1) = [0:TotalPosNum];
for i = 1:TotalDateNum
    Data_pos_out(2:end,i+1) = Data_day_detail{i,4}(:,2);
    Data_pos_in(2:end,i+1) = Data_day_detail{i,4}(:,3);
end
%分析节点数据(节点序号，出减入)
Data_pos_val = Data_pos_out - Data_pos_in;
Data_pos_in(:,1) = [0:TotalPosNum];




%% 绘图显示
figure(1)
s = Data_route_detail(2:end,2);
t = Data_route_detail(2:end,3);
G_all = digraph(s,t);
h_all = plot(G_all);
% n36 = neighbors(G,5)
[eid,nid] = outedges(G_all,5);
[eid2,nid2] = inedges(G_all,5);
highlight(h_all,[5],'NodeColor','red','MarkerSize',5)
highlight(h_all,'Edges',eid,'EdgeColor','g','LineWidth',2)
highlight(h_all,'Edges',eid2,'EdgeColor','r','LineWidth',2)
title('全节点流量有向图');

figure(2)
dateIdx = 1;
s = Data_day_detail{dateIdx,3}(:,1);
t = Data_day_detail{dateIdx,3}(:,2);
G = digraph(s,t);
h = plot(G);
highlight(h,[14,10,20,35,25,62],'NodeColor','red','MarkerSize',5)
highlight(h,[14,10,20,35,25,62],'EdgeColor','red','LineWidth',3)
title([Data_day_detail{dateIdx,1} '各节点流量有向图']);


figure(3)
dateIdxList = [34,62,730];
xList = Date_unique;
hold on
for i =1:length(dateIdxList)
    plot(xList, Data_route(dateIdxList(i),2:end));    
end
legend('DC14-DC10','DC20-DC35','DC25-DC62');
datetick('x', 'mm/dd');
title('部分路线货量折线图');


% PosLabel = Data_cell(:,1);
% PosLabel_Cate = categorical(PosLabel);
% PosLabel_int = double(PosLabel_Cate);
% TotalPosNum = size(unique(PosLabel_int),1);

%% 保存数据
[m1,n1] = size(Data_route);
ResultData = cell(m1,n1+1);
ResultData{1,1} = '场地1';
ResultData{1,2} = '场地2';
ResultData(1,3:end) = Data_day_detail(:,1)';
ResultData(2:end,1) = num2cell(Data_route_detail(2:end,2));
ResultData(2:end,2) = num2cell(Data_route_detail(2:end,3));
ResultData(2:end,3:end) = num2cell(Data_route(2:end,2:end));
fnew = "所有路线流量数据.xlsx";
xlswrite(fnew,ResultData);%写进excel文件
fprintf('所有路线流量数据已经保存在' + fnew + "文件中。\n");




%% 函数部分

function val = getint(str)
    newstr = strip(str,'left','D');
    newstr2 = strip(newstr,'left','C');
    val = str2num(newstr2);
end
function outval = toint(inval)
    [m,n] = size(inval);
    outval = zeros(m,n);
    for i=1:m
        for j=1:n
            outval(i,j) = round(inval(i,j));
        end
    end

end

