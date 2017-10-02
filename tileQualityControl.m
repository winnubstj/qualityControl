function [ outputCode,outputMsg,varargout ] = tileQualityControl( tileFile,settingsFile, ~, paramA , paramB, varargin )
%tileQualityControl Monitors quality of aquired image tiles.
%Function reads in provided tiff files and analyzes different aspect of the imaging quality for
%instance the obstruction of the objective.

tileInfo = [];
varargout{1} = [];

%% Load settings file
[mainFolder,~,~] = fileparts(which('tileQualityControl'));
try
    Settings = JSON.loadjson(fullfile(mainFolder,settingsFile));
catch
    error('Could not read %s',fullfile(mainFolder,settingsFile));
end
outParam = Settings.outParam;
% Set default output code (Okay).
outputCode = outParam.default.code; outputMsg = outParam.default.msg;

% Process tilefile.
tileFile = strrep(tileFile,'.0.',sprintf('.%i.',Settings.Channel));
tileFile = fullfile(tileFile);

%% Store usefull info on sample.
sampleID = regexp(tileFile,'\d{4}-\d{2}-\d{2}','match');
sampleID = sampleID{1};
tileInfo.sampleID = char(sampleID);
tileInfo.mainFolder = char(regexp(tileFile,'.*(?=\d{4}-\d{2}-\d{2}\\\d{2}\\\d{5}\\)','match'));
tileInfo.folder = char(regexp(tileFile,'\d{4}-\d{2}-\d{2}\\\d{2}\\\d{5}','match'));

qcFolder = fullfile(Settings.storeFolder,tileInfo.sampleID);
if isempty(dir(qcFolder)), mkdir(qcFolder);end

%% Open/create logging file.
logFile = fullfile(qcFolder,'log.txt');
fid = fopen(logFile,'a');
logMessage(fid,sprintf('%s Tile: %s',Settings.Name, tileInfo.folder),true);
c = onCleanup(@()fclose(fid)); % Close log file on cleanup.

%% Try to load previous store or create new.
try
    qcFile = fullfile(qcFolder,'QC.mat');
    if isempty(dir(qcFile))
        QC = [];
        save(qcFile,'QC');
    else
        load(qcFile);
    end
catch
    [ outputCode,outputMsg ] = processError( outParam.storage,fid,tileInfo,outputCode,outputMsg,Settings );
    return
end

%% Read image data.
try
    I = Tiff.readTifFast(tileFile, Settings.ImageSize,Settings.FrameAvg(1):Settings.FrameAvg(2), 'uint16');
    Iavg = uint16(mean(I,3));
catch
    %% Process fault.
    [ outputCode,outputMsg ] = processError( outParam.imageFile,fid,tileInfo,outputCode,outputMsg,Settings );
    return
end

%% Get info .microscope file (required).
protoLoc = [tileFile(1:end-6),'.microscope'];
try
    tileInfo.FOV            = ProtoBuf.fastProtoBuf( protoLoc, {'x_size_um','y_size_um','x_overlap_um','y_overlap_um'} );
    tileInfo.autotile       = ProtoBuf.fastProtoBuf( protoLoc, {{'autotile','intensity_threshold'},{'autotile','area_threshold'}} );
    tileInfo.trip_detect    = ProtoBuf.fastProtoBuf( protoLoc, {{'trip_detect','intensity_threshold'}} );
    tileInfo.pos_mm         = ProtoBuf.fastProtoBuf( protoLoc,{{'last_target_mm','x'},{'last_target_mm','y'},{'last_target_mm','z'}});
    tileInfo.x_pix_size     = tileInfo.FOV.x_size_um/Settings.ImageSize(2); tileInfo.y_pix_size = tileInfo.FOV.y_size_um/Settings.ImageSize(1);
catch
    %% Process fault.
    [ outputCode,outputMsg ] = processError( outParam.microMissing,fid,tileInfo,outputCode,outputMsg,Settings );
    return
end

%% Get Latice info (optional).
protoLoc = [tileFile(1:end-6),'.acquisition'];
try
    tileInfo.pos_lat = ProtoBuf.fastProtoBuf( protoLoc, {{'current_lattice_position','x'},{'current_lattice_position','y'},{'current_lattice_position','z'}} );
catch
    tileInfo.pos_lat = struct('x',[],'y',[],'z',[]);
end

%% Calls to quality checks %%%%

    %% Slice Thickness check.
    if ~isempty(QC) && ~isempty(tileInfo.pos_lat.z)
        [code,~,~] = sliceCheck( tileInfo, QC, outParam.sliceThick.threshold);
        if code ~= 100
            [ outputCode,outputMsg ] = processError( outParam.sliceThick,fid,tileInfo,outputCode,outputMsg,Settings );
            if outputCode~=100
                return
            end
        end
    end
    
    %% Line offset check.
    [code, ~] = lineOffsetCheck( I, tileInfo, outParam.lineOff.threshold );
    if code ~= 100
        [ outputCode,outputMsg ] = processError( outParam.lineOff,fid,tileInfo,outputCode,outputMsg,Settings );
        if outputCode~=100
            return
        end
    end
    
    %% Blocked Objective detection.
    [ code, ~, tileInfo ] = blockDetection( Iavg, tileInfo,QC, outParam.block.threshold, fid );

%% Store data.
QC = [QC;tileInfo];
try
    save(qcFile,'QC');
catch
    [ outputCode,outputMsg ] = processError( outParam.storage,fid,tileInfo,outputCode,outputMsg,Settings );
end

%% throwing error code of blocked objective after save for counter persistence.
if code ~=100
    [ outputCode,outputMsg ] = processError( outParam.block,fid,tileInfo,outputCode,outputMsg,Settings );
    if outputCode~=100
        return
    end
end

%% Send default output if no error.
if outputCode == 100, varargout{1} = Iavg; end
fprintf('\n');
end

