function [ code, msg,tileInfo ] = blockDetection( Iavg, tileInfo,QC, paramA, paramB,fid)
%BlockDetection. Performs the detection of bubble or debris blocking the
%objective.
% requires lat position.
%% Hardcoded parameters.
paramA = 11250;
shadowThres     = 75;   % as percentage of gelatine intensity -'dark' intensity.
areaThres       = 10;   % as percentage of total area.
counterThres    = 2;    % number of tiles that need to have failed check to trigger error code.
filterSize = 20;
padSize = 500;
edgeCrop = 15;

%% Some default values.
percArea = 0;
pass = true;
%% Get previous counter or check for reset.
% first tile counter 0
if isempty(QC)
    counter= 0;
else
    if ~isempty(tileInfo.pos_lat.z) || ~isempty(QC.pos_lat.z)
        % perpetuate excisting counter if same Z.
        if QC(end).pos_lat.z == tileInfo.pos_lat.z
            counter = QC(end).blockDetection.counter;
        % Reset counter on new Z.
        else
            counter = 0;
        end
    %cant determine lattice position so just persist.
    else
        counter = QC(end).blockDetection.counter;  
    end
end

%% Default message code.
code = 100;
msg = 'Okay';

%% Crop overlap regions image.
x_overlap_pix = ceil(tileInfo.FOV.x_overlap_um/tileInfo.x_pix_size)+1;
y_overlap_pix = ceil(tileInfo.FOV.y_overlap_um/tileInfo.y_pix_size)+1;
IavgCrop = Iavg(x_overlap_pix:end-x_overlap_pix,y_overlap_pix:end-y_overlap_pix);

%% Detect gelatine tile used for even background.
pixValues = reshape(IavgCrop,[],1);
autotileValue = prctile(pixValues,(1-(tileInfo.autotile.area_threshold))*100);
if autotileValue<=tileInfo.autotile.intensity_threshold
    
    %% Pad image and gaussian filter.
    h = fspecial('gaussian',filterSize,7);
    Ipad = padarray(IavgCrop,[padSize,padSize]);
    IavgFilt = imfilter(Ipad,h);
    IavgFilt = IavgFilt(padSize+edgeCrop:end-padSize-edgeCrop,padSize+edgeCrop:end-padSize-edgeCrop);
    
    %% calculate threshold value (percentage of gelatine-baseline Int).
    bgVal = mean2(Iavg(:,1:10)); % use slits for bg intensity.
    thresValue = bgVal+((paramA-bgVal)*(shadowThres/100));
    mask = IavgFilt<thresValue;
    se = strel('disk',10,8);
    mask =imerode(mask,se);

    %% Check area that is blocked.
    percArea = sum(sum(mask==1))/(size(mask,1)*size(mask,2))*100;
    if percArea>areaThres
        counter = counter + 1;
        pass = false;
        logMessage(fid,sprintf('Tile: %s\n\tBlocked area (%i%%),counter: %i, z: %i ',tileInfo.folder,round(percArea),counter,tileInfo.pos_lat.z),true);        
%         figure; imshowpair(IavgFilt,mask,'blend');
        if counter>=counterThres
            counter = 0; % reset so value is zero after restart.
            code = 500; msg = sprintf('Blocked area (%i%%)',round(percArea));
        end
    end
    
end
%% update blockdetection info.
tileInfo.blockDetection.percArea = percArea;
tileInfo.blockDetection.counter = counter;
tileInfo.blockDetection.pass = pass;

end

