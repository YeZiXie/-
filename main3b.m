%% 模拟退火优化DC9关闭后的路线
if ~exist('Data_day_detail','var')
    fprintf("请先运行main1.m！\n");
    return;
end

s_all = Data_route_detail(2:end,2);
t_all = Data_route_detail(2:end,3);
G_all = digraph(s,t);

TargetPos = 9;%要删除的节点
ResultData7 = load('ResultData7.mat');
ResultData7 = ResultData7.ResultData7;

ResultData3 = cell(TotalRoute+1,33);
for i=2:TotalRoute+1
    ResultData3{i,1} = Data_route_detail(i,2);
    ResultData3{i,2} = Data_route_detail(i,3);
end
ResultData5 = cell(1,4);
ResultData5(1,:) = {"站点1","站点2","添加时间","流量"};
for kkk = 1:31       
    dateIdx = kkk;
    s = [];
    t = [];
    for i = 2:size(ResultData7,1)
        if ResultData7{i,2+dateIdx} > 0
            s = [s  ResultData7{i,1}];
            t = [t  ResultData7{i,2}];
        end
    end
    G = digraph(s,t);
    if dateIdx == 1
        figure(1)
        h = plot(G);
        title([datestr(738886 + dateIdx,'yyyy/mm/dd') '各节点流量有向图']);
        [eid,nid] = outedges(G,TargetPos);
        [eid2,nid2] = inedges(G,TargetPos);
        highlight(h,[TargetPos],'NodeColor','red','MarkerSize',5);
        highlight(h,'Edges',eid,'EdgeColor','g','LineWidth',2);
        highlight(h,'Edges',eid2,'EdgeColor','r','LineWidth',2);
    end
    ToPosList_in = CalNearPos(G,TargetPos,0,dateIdx,ResultData7,Data_route_detail);
    ToPosList_out = CalNearPos(G,TargetPos,1,dateIdx,ResultData7,Data_route_detail);
    
    %模拟退火参数设置
    TemS=20000; % 初始温度
    CoolRate=0.98; % 冷却系数
    DiffMax = 0.005;%稳定误差范围
    TemE=1; % 结束温度
    
    P1 = 0.15;%分流比例，0-1，越小越好但太小可能爆容量
    P2 = 10;%权重上限，越高越好但太大可能跑不出
    P3 = 0.5;%每次扰动比例
    
    timeidx = dateIdx;
    %构造初始解
    StartVal = CreateNewSolution(ToPosList_in,ToPosList_out,P2);
    
    Solution0 = StartVal;
    TemN=TemS; % 当前温度
    % 初始数据
    [Result,VC]=CalValue(G,StartVal,TargetPos,timeidx,ToPosList_in,ToPosList_out,ResultData7,Data_route_detail);
    BEST_VAL_List = [];
    BEST_Solution = Solution0;
    totalCount = 0;
    % 降温过程
    while TemN >= TemE
        % 等温过程
        while true
            % 扰动当前的解
            Solution1=Disturb(Solution0,ToPosList_in,ToPosList_out,P2,P3);
            % 扰动形成新解与旧解的比较
            [Result0,VC0]=CalValue(G,Solution0,TargetPos,timeidx,ToPosList_in,ToPosList_out,ResultData7,Data_route_detail);
            [Result1,VC1]=CalValue(G,Solution1,TargetPos,timeidx,ToPosList_in,ToPosList_out,ResultData7,Data_route_detail);
            diff0 = Result1 - Result0;
            diff= diff0/(Result0 + 1e-7);
            
            totalCount = totalCount + 1;
            % 该温度下已经达到了平衡则退出等温过程，降温
            if abs(diff) < DiffMax
                break;
                % 否则以退火准则接受新的最优解
            elseif diff<0 || rand < exp(-diff0/TemN)
                Solution0=Solution1;
            end
            
            if diff <0
                BEST_Solution = Solution1;
            end
        end
        
        TemN=TemN*CoolRate; % 更新温度
        BEST_VAL_List = [BEST_VAL_List,Result1];
        if TemN<TemE % 判断是否达到结束温度，结束降温
            break;
        end
    end
    
    [BEST_VAL,BESTVC]=CalValue(G,Solution0,TargetPos,timeidx,ToPosList_in,ToPosList_out,ResultData7,Data_route_detail); % 最终总距离
    
    ResultData3(:,kkk+2) = BESTVC{3};
    ResultData3{1,kkk+2} = datestr(738886 + dateIdx,'yyyy/mm/dd');
    
    Addages = BESTVC{4};
    startLen = size(ResultData5,1);
    for idx1 = 1:size(Addages,1)
       ResultData5(startLen + idx1,:) = {Addages(idx1,1),Addages(idx1,2),ResultData3{1,kkk+2},Addages(idx1,3)};        
    end
    
    %% 显示替换后结果
    if dateIdx == 1        
        figure(2)
        s = [];
        t = [];
        for i = 2:size(ResultData7,1)
            if BESTVC{3}{i} > 0 &&  ResultData7{i,1} ~= TargetPos ...
                    && ResultData7{i,2} ~= TargetPos
                s = [s  ResultData7{i,1}];
                t = [t  ResultData7{i,2}];
            end
        end
        G = digraph(s,t);
%         Addages = BESTVC{4};
        highLightEd = [];
        for idx1 = 1:size(Addages,1)
%            G = G.addedge(Addages(idx1,1),Addages(idx1,2)); 
           highLightEd = [highLightEd,Addages(idx1,1),Addages(idx1,2)];
        end
        
        h = plot(G);
        title([datestr(738886 + dateIdx,'yyyy/mm/dd') '各节点流量有向图(删去DC' num2str(TargetPos)  ')']);
        % [eid,nid] = outedges(G,5);
        % [eid2,nid2] = inedges(G,5);
        if ~isempty(ToPosList_in)
            highlight(h,ToPosList_in(1:length(Solution0{1}),1)','NodeColor','red','MarkerSize',5);
        end
        if ~isempty(ToPosList_out)
            highlight(h,ToPosList_out(1:length(Solution0{2}),1)','NodeColor','green','MarkerSize',5);
        end
        highlight(h,'Edges',highLightEd,'EdgeColor','black','LineWidth',2);
        % highlight(h,'Edges',eid2,'EdgeColor','r','LineWidth',2);
        BESTVC{3}{1} = 0;
        valout1 = sum(cell2mat(BESTVC{3}));
        valout2 = sum(Data_route_detail(:,5))-Data_route_detail(1,5);
        fprintf(['全路网负荷量'  num2str(valout1/valout2*100) '\n' ]);
        
    end
    
    fprintf(['进度 ' num2str(kkk/31*100)  '...\n']);
end
%% 保存结果数据
ResultData4 = ResultData3(1,:);
idx4 = 2;
for i=2:TotalRoute+1
    if ResultData3{i,1}~=TargetPos && ResultData3{i,2} ~= TargetPos
        ResultData4(idx4,:) = ResultData3(i,:);
        idx4 = idx4 + 1;
    end
end
ResultData4{1,1} = '站点1';
ResultData4{1,2} = '站点2';

fnew = ['23年1月删除DC' num2str(TargetPos)  '后所有路线数据.xlsx'] ;
xlswrite(fnew,ResultData4);%写进excel文件
fprintf(['数据已经保存在 ' fnew '文件中。\n']);

fnew5 = ['23年1月删除DC' num2str(TargetPos)  '后新增路线数据.xlsx'] ;
xlswrite(fnew5,ResultData5);%写进excel文件
fprintf(['新增路线数据已经保存在 ' fnew5 '文件中。\n']);

%% 函数部分

function targetList = CalNearPos(G,idx,isout,timeidx,ResultData2,Data_route_detail)
%     targetList = cell(2);
    if isout > 0
        [~,nid] = outedges(G,idx);
    else
        [~,nid] = inedges(G,idx);
    end
    if isempty(nid)
       targetList = [];
       return;
    end
    temp1 = zeros(length(nid),4);    
    
    for i = 1:length(nid)
        if isout > 0
            routeIDX = idx*100 + nid(i);
        else
            routeIDX = nid(i)*100 + idx;
        end
        findResult = find(Data_route_detail(:,1)==routeIDX);
        if isempty(findResult)
            fprintf("ERROR!\n");
            targetList = [];
            return;          
        end
        temp1(i,1) = nid(i);
        temp1(i,2) = Data_route_detail(findResult(1),5);
        temp1(i,3) = ResultData2{findResult(1),timeidx+2};
        temp1(i,4) = temp1(i,2) - temp1(i,3);
    end
    temp1s = sortrows(temp1,4,'descend');
    targetList = temp1s;   
    
end
function StartVal = CreateNewSolution(ToPosList_in,ToPosList_out,P2)
    P1 = rand;
    if isempty(ToPosList_in)
        StartVal{1} = [];
    else
        slectPosList_in = ToPosList_in(1:max(1,round(P1*size(ToPosList_in,1))),1);
        StartVal{1} = CreateRand(1,length(slectPosList_in),P2);
    end
    if isempty(ToPosList_out)
        StartVal{2} = [];
    else
        slectPosList_out = ToPosList_out(1:max(1,round(P1*size(ToPosList_out,1))),1);
        StartVal{2} = CreateRand(1,length(slectPosList_out),P2);
    end
    StartVal{3} = P1;
end



function temps0 = CreateRand(a,b,P2)
    temps0 = round(P2*rand(a,b));
    if(sum(temps0)==0)
        temps0 = ones(a,b)./(a*b);
    else
        temps0 = temps0./sum(temps0);
    end
end
function Soultion = Disturb(Solution0,ToPosList_in,ToPosList_out,P2,P3)
     Soultion = CreateNewSolution(ToPosList_in,ToPosList_out,P2);
%     Soultion{1} = Disturb2(Solution0{1},P2,P3);
%     Soultion{2} = Disturb2(Solution0{2},P2,P3);
end
function Soultion = Disturb2(Solution0,P2,P3)
    Soultion = Solution0;
    if ~isempty(Solution0)
        le = length(Solution0);
        for i=1:le
           if rand < P3
              Soultion(i) = round(rand*P2); 
           end            
        end
        if(sum(Soultion)==0)
            Soultion = ones(1,le)./le;
        else
            Soultion = Soultion./sum(Soultion);
        end
    end    
end
function [Result,Vals] = CalValue(G,StartVal,TargetPos,timeidx,ToPosList_in,ToPosList_out,ResultData2,Data_route_detail)
    Result = (length(StartVal{1}) + length(StartVal{2}))*50;
    Vals = cell(1,4);%爆仓站点数量,爆仓路线数量
    Vals{1} = 0;
    Vals{2} = 0;
    tempRouteData = ResultData2(:,timeidx+2);
    if ~isempty(StartVal{1})
        totalValIn = sum(ToPosList_in(:,3));
        for i=1:length(StartVal{1})
           addVal =  round(totalValIn*StartVal{1}(i));
           tempPos1 = ToPosList_in(i,1);
           targetList1 = CalNearPos(G,tempPos1,0,timeidx,ResultData2,Data_route_detail);
           if ~isempty(targetList1)
               for j = 1:size(targetList1,1)
                   if targetList1(j,1) ~= TargetPos
                       routeIDX = targetList1(j,1)*100 + tempPos1;
                       findResult = find(Data_route_detail(:,1)==routeIDX); 
                       if isempty(findResult)
                           break;
                       end
                       if targetList1(j,4) - addVal > 0
                           tempRouteData{findResult(1),1} = targetList1(j,3) + addVal;
                           addVal = 0;
                           break;
                       else
                           temp2 = addVal - targetList1(j,4);
                           addVal = temp2;
                           tempRouteData{findResult(1),1} = targetList1(j,2);
                       end
                   end
               end
           else
               Result = Result + 1000;
               Vals{1} = Vals{1} + 1;
               for mm = 1:81
                   routeIDX = mm *100 + tempPos1;
                   findResult = find(Data_route_detail(:,1)==routeIDX);
                   if isempty(findResult)
                       Vals{4} = [Vals{4};mm,tempPos1,addVal];
                       break;
                   end
               end
           end
           if addVal > 0
               Result = Result + addVal;
               Vals{2} = Vals{2} + 1;
           end
        end
    end
    if ~isempty(StartVal{2})
        totalValOut = sum(ToPosList_out(:,3));
        for i=1:length(StartVal{2})
           addVal2 =  round(totalValOut*StartVal{2}(i));
           tempPos2 = ToPosList_out(i,1);
           targetList2 = CalNearPos(G,tempPos2,1,timeidx,ResultData2,Data_route_detail);
           if ~isempty(targetList2)
               for j = 1:size(targetList2,1)
                   if targetList2(j,1) ~= TargetPos
                       routeIDX = targetList2(j,1) + tempPos2*100;
                       findResult = find(Data_route_detail(:,1)==routeIDX); 
                       if isempty(findResult)
                           break;
                       end
                       if targetList2(j,4) - addVal2 > 0
                           tempRouteData{findResult(1),1} = targetList2(j,3) + addVal2;
                           addVal2 = 0;
                           break;
                       else
                           temp2 = addVal2 - targetList2(j,4);
                           addVal2 = addVal2 - temp2;
                           tempRouteData{findResult(1),1} = targetList2(j,2);
                       end
                   end
               end
           else
               Result = Result + 1000;
               Vals{1} = Vals{1} + 1;
               for mm = 1:81
                   routeIDX = mm + tempPos2*100;
                   findResult = find(Data_route_detail(:,1)==routeIDX);
                   if isempty(findResult)
                       Vals{4} = [Vals{4};tempPos2,mm,addVal2];
                       break;
                   end
               end
           end
           if addVal2 > 0
               Result = Result + addVal2;
               Vals{2} = Vals{2} + 1;
           end
        end
    end
    Vals{3} = tempRouteData;
end