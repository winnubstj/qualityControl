function [ outputCode,outputMsg,varargout ] = qualityControl( tileFile,storeFile, paramA , paramB, varargin )
%tileQualityControl Monitors quality of aquired image tiles.
%Function reads in provided tiff files and analyzes different aspect of the imaging quality for
%instance the obstruction of the objective.

%% Setting optional inputs.
if nargin<5, figHandle = [];end

%% Hard coded Parameters.
imSize = [1536,1024];
frameAvg = 100:105;

%% Set default output code (Okay).
outputCode = 100; outputMsg = 'Okay';

%% Read image data.
try
    I = readTifFast(tileFile, imSize,frameAvg, 'uint16');
    Iavg = uint16(mean(I,3));
catch
    outputCode = 400; outputMsg = 'Could not open tile image for reading';
    return
end

%% Get Image info (required).
protoLoc = [tileFile(1:end-6),'.microscope'];
try
    tileInfo = fastProtoBuf( protoLoc, {{'last_target_mm','z'},'x_size_um','y_size_um','x_overlap_um','y_overlap_um'}, {'num','num','num','num','num'} );
    tileInfo.x_pix_size = tileInfo.x_size_um/imSize(2); tileInfo.y_pix_size = tileInfo.y_size_um/imSize(2)
catch
    outputCode = 410; outputMsg = 'Could access microscope file';
    return
end

%% Get Latice info (required).
protoLoc = [tileFile(1:end-6),'.acquisition'];
try
    tileInfo = fastProtoBuf( protoLoc, {{'last_target_mm','z'},'x_size_um','y_size_um','x_overlap_um','y_overlap_um'}, {'num','num','num','num','num'} );
    tileInfo.x_pix_size = tileInfo.x_size_um/imSize(2); tileInfo.y_pix_size = tileInfo.y_size_um/imSize(2)
catch
    %some logging here.
end

%% Send default output if no error.
if outputCode == 100, varargout{1} = Iavg; end


end

