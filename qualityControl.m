function [ outputCode,outputMsg,varargout ] = qualityControl( tileFile,storeFolder, paramA , paramB, varargin )
%tileQualityControl Monitors quality of aquired image tiles.
%Function reads in provided tiff files and analyzes different aspect of the imaging quality for
%instance the obstruction of the objective.

%% Setting optional inputs.
if nargin<5, figHandle = [];end

%% Hard coded Parameters.
imSize = [1536,1024];   % PRedetermined size of images.
frameAvg = 100:105;     % Frames read for averaging.
scaleFactor = 0.2;      % Determines size of stored thumbnail.
dZThreshold = 0.2;       % Slice thickness threshold in mm.

% Create some variables.
tileInfo = [];
varargout{1} = [];

%% Determine sample ID by start date.
sampleID = regexp(tileFile,'(?<=acquisition\\)\d{4}-\d{2}-\d{2}','match');
if isempty(sampleID)
    outputCode = 420; outputMsg = 'Could not determine sample ID date';
    return
end
% Store other usefull directories etc.
tileInfo.sampleID = char(sampleID);
tileInfo.mainFolder = char(regexp(tileFile,'.*(?=\d{4}-\d{2}-\d{2}\\\d{2}\\\d{5}\\)','match'));
tileInfo.folder = char(regexp(tileFile,'\d{4}-\d{2}-\d{2}\\\d{2}\\\d{5}\\','match'));

%% Try to load previous store or create new.
try
    qcFolder = fullfile(storeFolder,tileInfo.sampleID);
    if isempty(dir(qcFolder))
        mkdir(qcFolder);
        %some logging here.
    end
    qcFile = fullfile(storeFolder,tileInfo.sampleID,'QC.mat');
    if isempty(dir(qcFile))
        QC = [];
        save(qcFile,'QC');
    else
        load(qcFile);
    end
catch
    outputCode = 430; outputMsg = 'Could not access/create QC storage file.';
end

%% Set default output code (Okay).
outputCode = 100; outputMsg = 'Okay';

%% Read image data.
try
    I = readTifFast(tileFile, imSize,frameAvg, 'uint16');
    Iavg = uint16(mean(I,3));
    tileInfo.Iavg = imresize(Iavg,scaleFactor);
catch
    outputCode = 400; outputMsg = 'Could not open tile image for reading';
    return
end

%% Get Image info (required).
protoLoc = [tileFile(1:end-6),'.microscope'];
try
    tileInfo.FOV = fastProtoBuf( protoLoc, {'x_size_um','y_size_um','x_overlap_um','y_overlap_um'} );
    tileInfo.pos_mm = fastProtoBuf( protoLoc,{{'last_target_mm','x'},{'last_target_mm','y'},{'last_target_mm','z'}});
    tileInfo.x_pix_size = tileInfo.FOV.x_size_um/imSize(2); tileInfo.y_pix_size = tileInfo.FOV.y_size_um/imSize(2);
catch
    outputCode = 410; outputMsg = 'Could access microscope file';
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
        [code,msg,deltaZ] = sliceCheck( tileInfo, QC, dZThreshold );
        deltaZ
        if code == 300
            outputCode = 300; outputMsg = 'Slice thickness was over thresold';
            return
        end
    end
    
    %% Blocked Objective detection.
    

%% Store data.
QC = [QC;tileInfo];
try
    save(qcFile,'QC');
catch
    outputCode = 430; outputMsg = 'Could not store QC storage file.';
end

%% Send default output if no error.
if outputCode == 100, varargout{1} = Iavg; end


end

