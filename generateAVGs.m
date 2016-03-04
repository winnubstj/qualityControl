function generateAVGs(mainFolder,outputFolder,varargin)
%genAVGs. Generates stack averages off all tiles in Fetch generated data
%folder <Date\00\ID>
%   Function scans content of main folder and outputs AVGs stacks at
%   requested location. Used for testing quality control.
%
% Syntax:  bilinearJobList( mainFolder,outputFolder, imSize, frames, bufferSize )
%
% Inputs:
%       mainFolder          - Main directory of tile database (must be full,unmapped, path).
%       outputFolder        - Location where resulting AVG stacks will be
%                             saved.
% Optional Inputs:
%       imSize              - Image size
%       frames              - frames used for average.
%       bufferSize          - number of frames in output stacks


%% Setting optional inputs.
if nargin<3, imSize = [1536,1024];end
if nargin<4, frames = [120:129];end
if nargin<5, bufferSize = 500;end

%% Tiff library warning.
warning off MATLAB:imagesci:tiffmexutils:libtiffWarning

%% Prepare stack.
stack = zeros(imSize(1), imSize(2), bufferSize, 'uint16');
%% Prepare Output text file.
fid = fopen(fullfile(outputFolder,'pathlist.txt'),'w');
if fid==-1, error('Could not create pathlist file for writing'); end

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
            %% Read file.
            try % Catch smaller file
                tic
                I = readTifFast(fullfile(mainFolder,cDay,cSub,cFile,[cFile,'-ngc.0.tif']), imSize,frames, 'uint16');
                toc
                fprintf('%s - %s - %s\tFrame: %i File Frame: %i\n',cDay,cSub,cFile,count,frameCount);
                I = mean(I,3);
                stack(:,:,frameCount) = I;
                fprintf(fid,'%s\n',fullfile(mainFolder,cDay,cSub,cFile,[cFile,'-ngc.0.tif']));
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
end
fclose(fid);