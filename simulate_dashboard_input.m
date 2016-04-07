%% simulate_dashboard_input.
% Quick notepad for simulating tile inputs from the dashboard to
% qualityControl.

%% Parameters
mainFolder = 'Y:\mousebrainmicro\acquisition\2016-04-04\Data\';
storeFolder = 'C:\dashTemp\';
paramA = 0;
paramB = 0;
displayRange = [10,99]; %in percentage.

%% Output window.
hFig = figure('Position',[400,400,700,900],'Name','Quality control test');
hAx = axes('Position',[0.05,0.075,0.9,0.9]);
hIm = [];
info.lowBox = uicontrol('Style', 'edit', 'String', num2str(displayRange(1)),...
    'Position', [20 10 50 25],...
    'FontSize', 9); 
info.highBox = uicontrol('Style', 'edit', 'String', num2str(displayRange(2)),...
    'Position', [120 10 50 25],...
    'FontSize', 9); 
info.fileText = uicontrol('Style','text','String','File: ','Position',[190 5 300 25],'HorizontalAlignment','left');

%% Get folder list.
dayList = dir(mainFolder);
dayList = vertcat({dayList.name});
dayList = regexp(dayList,'^(\d{4}-\d{2}-\d{2})$','match');
dayList = vertcat(dayList{:});

%% Go through days
nDays = size(dayList,1);
for iDay = 1:nDays
    cDay = dayList{iDay};
    %% Get sub-folders.
    subList = dir(fullfile(mainFolder,cDay));
    subList = regexp(vertcat({subList.name}),'^(\d{2})$','match');
    subList = vertcat(subList{:});
    nSubs = size(subList,1);
    for iSub = 1:nSubs
        cSub = subList{iSub};
        fileList = dir(fullfile(mainFolder,cDay,cSub));
        fileList = regexp(vertcat({fileList.name}),'^(\d{5})$','match');
        fileList = vertcat(fileList{:});
        
        %% Go through files.
        nFiles = size(fileList,1);
        for iFile = 1:nFiles
            cFile = fullfile(mainFolder, cDay, cSub, fileList{iFile},[fileList{iFile},'-ngc.0.tif']);
            %% Call quality control like the dashboard
            [code,msg,Iavg] = qualityControl( cFile,storeFolder, paramA , paramB );
            %% Display image
            % get display range
            Ipix = reshape(Iavg,[],1);
            low = str2double(info.lowBox.String); high = str2double(info.highBox.String); 
            if low<0, low = 0;end
            if high>100, high=100; end
            info.lowBox.String = num2str(low);info.highBox.String = num2str(high);
            range = [prctile(Ipix,low),prctile(Ipix,high)];
            % Update file text.
            info.fileText.String = ['File: ',fullfile(cDay, cSub, fileList{iFile})];
            if isempty(hIm)
               hIm = imshow(Iavg,range);
            else
                hIm.CData = Iavg;
                hAx.CLim = range;
            end
            drawnow
        end
    end
end


