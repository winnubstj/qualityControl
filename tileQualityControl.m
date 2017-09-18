function [ outputCode,outputMsg,varargout ] = tileQualityControl( tileFile,storeFolder, imSize, paramA , paramB, varargin )
%tileQualityControl Monitors quality of aquired image tiles.
%Function reads in provided tiff files and analyzes different aspect of the imaging quality for
%instance the obstruction of the objective.
% Add channel selection?
%% Hard coded Parameters.
imSize = [1536,1024];       % Predetermined size of images.
frameAvg = 100:105;         % Frames read for averaging.
channel = 1;
%% Output/logging Parameters.
% Default message
outParam.default.code       = 100;
outParam.default.msg        = 'Okay';
% Cant access/load storage file.
outParam.storage.code       = 404;
outParam.storage.msg        = 'Could not access/create QC storage file';
outParam.storage.log        = true;
outParam.storage.mail       = false; 
outParam.storage.exit       = false; 
% Couldnt open image file.
outParam.imageFile.code     = 400;
outParam.imageFile.msg      = 'Could not open image file';
outParam.imageFile.log      = true;
outParam.imageFile.mail     = false;
outParam.imageFile.exit     = false;
% Missing microscope file.
outParam.microMissing.code  = 405;      % Error code.
outParam.microMissing.msg   = 'Could not access .microscope file';
outParam.microMissing.log   = true;     % Log occurence.
outParam.microMissing.mail  = false;    % Send mail occurence.
outParam.microMissing.exit  = false;    % Report error code.
% Slice thickness .
outParam.sliceThick.code    = 700;
outParam.sliceThick.msg     = 'Slice thickness was over threshold';
outParam.sliceThick.threshold = 0.210; % in mm
outParam.sliceThick.log     = true;
outParam.sliceThick.mail    = true;
outParam.sliceThick.exit    = true;
% Line offset.
outParam.lineOff.code       = 500;
outParam.lineOff.msg        = 'Detected line offset was over threshold';
outParam.lineOff.threshold  = 2;    %in pix.
outParam.lineOff.log        = true;
outParam.lineOff.mail       = true;
outParam.lineOff.exit       = false;
% Blocked objective.
outParam.block.code         = 300;
outParam.block.msg          = 'Detected blocked objective';
outParam.block.threshold.expInt          = paramA;
outParam.block.threshold.shadowThres     = 70;   % as percentage of gelatine intensity -'dark' intensity.
outParam.block.threshold.areaThres       = 10;   % as percentage of total area.
outParam.block.threshold.counterThres    = 2;    % number of tiles that need to have failed check to trigger error code.
outParam.block.log          = true;
outParam.block.mail         = true;
outParam.block.exit         = true;
% Create some variables.
tileInfo = [];
varargout{1} = [];

% Process tilefile.
tileFile = strrep(tileFile,'.0.',sprintf('.%i.',channel));
% Set default output code (Okay).
outputCode = outParam.default.code; outputMsg = outParam.default.msg;

%% Store usefull info on sample.
sampleID = regexp(tileFile,'\d{4}-\d{2}-\d{2}','match');
sampleID = sampleID{1};
tileInfo.sampleID = char(sampleID);
tileInfo.mainFolder = char(regexp(tileFile,'.*(?=\d{4}-\d{2}-\d{2}\\\d{2}\\\d{5}\\)','match'));
tileInfo.folder = char(regexp(tileFile,'\d{4}-\d{2}-\d{2}\\\d{2}\\\d{5}','match'));
qcFolder = fullfile(storeFolder,tileInfo.sampleID);
if isempty(dir(qcFolder)), mkdir(qcFolder);end

%% Open/create logging file.
logFile = fullfile(qcFolder,'log.txt');
fid = fopen(logFile,'a');
logMessage(fid,sprintf('Tile: %s',tileInfo.folder),true);
c = onCleanup(@()fclose(fid)); % Close log file on cleanup.

%% Try to load previous store or create new.
try
    qcFile = fullfile(storeFolder,tileInfo.sampleID,'QC.mat');
    if isempty(dir(qcFile))
        QC = [];
        save(qcFile,'QC');
    else
        load(qcFile);
    end
catch
    [ outputCode,outputMsg ] = processError( outParam.storage,fid,tileInfo,outputCode,outputMsg );
    return
end

%% Read image data.
try
    I = readTifFast(tileFile, imSize,frameAvg, 'uint16');
    Iavg = uint16(mean(I,3));
catch
    %% Process fault.
    [ outputCode,outputMsg ] = processError( outParam.imageFile,fid,tileInfo,outputCode,outputMsg );
    return
end

%% Get info .microscope file (required).
protoLoc = [tileFile(1:end-6),'.microscope'];
try
    tileInfo.FOV            = fastProtoBuf( protoLoc, {'x_size_um','y_size_um','x_overlap_um','y_overlap_um'} );
    tileInfo.autotile       = fastProtoBuf( protoLoc, {{'autotile','intensity_threshold'},{'autotile','area_threshold'}} );
    tileInfo.trip_detect    = fastProtoBuf( protoLoc, {{'trip_detect','intensity_threshold'}} );
    tileInfo.pos_mm         = fastProtoBuf( protoLoc,{{'last_target_mm','x'},{'last_target_mm','y'},{'last_target_mm','z'}});
    tileInfo.x_pix_size     = tileInfo.FOV.x_size_um/imSize(2); tileInfo.y_pix_size = tileInfo.FOV.y_size_um/imSize(2);
catch
    %% Process fault.
    [ outputCode,outputMsg ] = processError( outParam.microMissing,fid,tileInfo,outputCode,outputMsg );
    return
end

%% Get Latice info (optional).
protoLoc = [tileFile(1:end-6),'.acquisition'];
try
    tileInfo.pos_lat = fastProtoBuf( protoLoc, {{'current_lattice_position','x'},{'current_lattice_position','y'},{'current_lattice_position','z'}} );
catch
    tileInfo.pos_lat = struct('x',[],'y',[],'z',[]);
end

%% Calls to quality checks %%%%

    %% Slice Thickness check.
    if ~isempty(QC) && ~isempty(tileInfo.pos_lat.z)
        [code,~,~] = sliceCheck( tileInfo, QC, outParam.sliceThick.threshold);
        if code ~= 100
            [ outputCode,outputMsg ] = processError( outParam.sliceThick,fid,tileInfo,outputCode,outputMsg );
            return
        end
    end
    
    %% Line offset check.
    [code, ~] = lineOffsetCheck( I, tileInfo, outParam.lineOff.threshold );
    if code ~= 100
        [ outputCode,outputMsg ] = processError( outParam.lineOff,fid,tileInfo,outputCode,outputMsg );
        return
    end
    
    %% Blocked Objective detection.
    [ code, ~, tileInfo ] = blockDetection( Iavg, tileInfo,QC, outParam.block.threshold, fid );

%% Store data.
QC = [QC;tileInfo];
try
    save(qcFile,'QC');
catch
    [ outputCode,outputMsg ] = processError( outParam.storage,fid,tileInfo,outputCode,outputMsg );
end

%% throwing error code of blocked objective after save for counter persistence.
if code ~=100
    [ outputCode,outputMsg ] = processError( outParam.block,fid,tileInfo,outputCode,outputMsg );
    return
end

%% Send default output if no error.
if outputCode == 100, varargout{1} = Iavg; end
fprintf('\n');
end

