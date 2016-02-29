%% Parameters.
mainFolder = 'Y:\mousebrainmicro\data\2015-07-11\Tiling';
outputFolder = 'Y:\mousebrainmicro\data\Dashboard training set';
imSize = [1536,1024];
frames = [120:129];
bufferSize = 500;
warning off MATLAB:imagesci:tiffmexutils:libtiffWarning

%% Prepare stack.
stack = zeros(imSize(1), imSize(2), bufferSize, 'uint16');

%% Get folder list.
dayList = dir(mainFolder);
dayList = vertcat({dayList.name});
dayList = regexp(dayList,'^(\d{4}-\d{2}-\d{2})$','match');
dayList = vertcat(dayList{:});

%% Go through days
nDays = size(dayList,1);
count = 1;
frameCount = 1; % Wont go over buffer size.
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
            cFile = fileList{iFile};
            fprintf('%s - %s - %s\tFrame: %i File Frame: %i\n',cDay,cSub,cFile,count,frameCount);
            %% Read file.
            I = readTifFast(fullfile(mainFolder,cDay,cSub,cFile,[cFile,'-ngc.0.tif']), imSize,frames, 'uint16');
            I = mean(I,3);
            stack(:,:,frameCount) = I;
            
            %% Check if buffer size is reached and start writing.
            if mod(frameCount,bufferSize) == 0
                writeTifFast( stack, fullfile(outputFolder,[num2str(count),'.tif']), 'uint16');
                frameCount = 0;
                stack = zeros(imSize(1), imSize(2), bufferSize, 'uint16');
            end
            count = count + 1;
            frameCount = frameCount + 1;
        end
    end
end