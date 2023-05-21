%% 用21年数据预测DC9相关
if ~exist('data_pre2.mat','file')
    Data_predict2 = Data_predict;
    
    for routeIDX = 2:TotalRoute + 1
        if Data_route_detail(routeIDX,2) == 9 || Data_route_detail(routeIDX,3) == 9
            inVal = Data_route(routeIDX,1:367)';            
            Data_predict2(routeIDX,:) = LSTMPred(inVal)';
            fprintf("预测进度%f\n",routeIDX/(TotalRoute+1));
        end
    end
    Data_predict2 = abs(round(Data_predict2));
    save('data_pre2.mat','Data_predict2');
else
    Data_predict2 = load('data_pre2.mat');  
    Data_predict2 = Data_predict2.Data_predict2;
end
Data_predict2 = abs(round(Data_predict2));
for i=1:size(Data_predict2,1)
   for j=1:size(Data_predict2,2)
      Data_predict2(i,j) = min(Data_predict2(i,j),Data_route_detail(i,5)); 
   end    
end
% figure(2)
% plot(inVal,'-ob','LineWidth',1.5,'MarkerSize',3);
% hold on 
% plot([length(inVal)+1:1:length(inVal)+length(out)],out',"LineWidth",1.5,"MarkerSize", ...
%     3,"LineStyle","-.","Marker","*","MarkerEdgeColor",'r');
% 
% title('DC25→DC62');

% dateIdxList = [6,12,15];
% texts = {'DC5-DC9','DC7-DC9','DC9-DC3'};
% for k = 1:3
%     figure(3+k)
%     xList = Date_unique;
% %     for i =1:length(dateIdxList)
%     plot(xList, Data_route(dateIdxList(k),2:end));
%     hold on
%     out = Data_predict2(dateIdxList(k),:);
%     plot([738887:1:738886+length(out)],out,"LineWidth",1.5,"MarkerSize", ...
%      3,"LineStyle","-.","Marker","*","MarkerEdgeColor",'r');
% %     end
% %     legend(texts(k));
%     datetick('x', 'mm/dd');
%     title(['路线' , texts{k} , '货量折线图']);
% end

%% 保存数据
[m1,n1] = size(Data_predict2);
ResultData7 = cell(m1,n1+2);
ResultData7{1,1} = '场地1';
ResultData7{1,2} = '场地2';
ResultData7(1,3:end) = num2cell([1:31]);
ResultData7(2:end,1) = num2cell(Data_route_detail(2:end,2));
ResultData7(2:end,2) = num2cell(Data_route_detail(2:end,3));
ResultData7(2:end,3:end) = num2cell(Data_predict2(2:end,:));
fnew = "23年1月路线货物量预测数据2.xlsx";
xlswrite(fnew,ResultData7);%写进excel文件
fprintf('预测数据已经保存在 ' + fnew + "文件中。\n");
save('ResultData7.mat','ResultData7');

%% 函数部分
function PredVal = LSTMPred(inVal)
    PredVal=[];
    %%分别进行时间序列预测
    dataTrain=inVal;
    mu = mean(dataTrain);
    sig = std(dataTrain);
    dataTrainStandardized = (dataTrain - mu) / sig;
    % 训练数据
    XTrain = dataTrainStandardized(1:end-1);
    YTrain = dataTrainStandardized(2:end);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 创建 LSTM 网络
    numFeatures = 1;
    numResponses = 1;
    numHiddenUnits = 120;
    layers = [sequenceInputLayer(numFeatures)
        lstmLayer(numHiddenUnits)
        fullyConnectedLayer(numResponses)
        regressionLayer];
    % 设置网络参数
    options = trainingOptions('adam', ...
        'MaxEpochs', 200, ...
        'GradientThreshold', 1, ...
        'InitialLearnRate', 0.005, ...
        'LearnRateSchedule', 'piecewise', ...
        'LearnRateDropPeriod', 50, ...
        'LearnRateDropFactor', 0.25, ...
        'Verbose', 0);%,...
        %'Plots', 'training-progress');
    % 训练
    XTrain=XTrain';
    YTrain=YTrain';
    net = trainNetwork(XTrain,YTrain,layers,options);
    net = predictAndUpdateState(net, XTrain);
    % 使用训练响应的最后一个时间步 YTrain(end) 进行第一次预测
    [net, YPred] = predictAndUpdateState(net, YTrain(end));
    % 循环其余预测，使用前一次的预测结果作为输入
    numTimeStepsTest = 31; % 预测未来多少年的
    for i = 2:numTimeStepsTest
        [net, YPred(:, i)] = predictAndUpdateState(net, YPred(:, i-1));%, 'ExecutionEnvironment', 'cpu');
    end
    % 去标准化
    YPredout = sig*YPred + mu;
    PredVal=[PredVal YPredout'];
end

