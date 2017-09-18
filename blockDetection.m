function [ code, msg,tileInfo ] = blockDetection( Iavg, tileInfo,QC, threshold,fid)
%BlockDetection. Performs the detection of bubble or debris blocking the
%objective.
% requires lat position.
filterSize = 20;
padSize = 500;
edgeCrop = 15;

%% Some default values.
pass = true;
fprintf('\n\tObjective block detection');

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
    
%% Pad image and gaussian filter.
h = fspecial('gaussian',filterSize,7);
Ipad = padarray(IavgCrop,[padSize,padSize]);
IavgFilt = imfilter(Ipad,h);
IavgFilt = IavgFilt(padSize+edgeCrop:end-padSize-edgeCrop,padSize+edgeCrop:end-padSize-edgeCrop);

%% calculate threshold value (percentage of gelatine-baseline Int).
bgVal = mean2(Iavg(:,1:10)); % use slits for bg intensity.
thresValue = bgVal+((threshold.expInt-bgVal)*(threshold.shadowThres/100));
mask = IavgFilt<thresValue;
se = strel('disk',10,8);
mask =imerode(mask,se);

%% Check area that is blocked.
percArea = sum(sum(mask==1))/(size(mask,1)*size(mask,2))*100;
fprintf('\n\t\tAverage BG Int\t: %.0f\n\t\tAverage Baseline Int\t: %.0f\n\t\tExpected Int\t: %.0f\n\t\tBlocked Area\t: %.2f',bgVal,mean(mean(IavgFilt)),threshold.expInt,percArea);
if percArea>threshold.areaThres
    counter = counter + 1;
    pass = false;
    logMessage(fid,sprintf('Tile: %s\n\tBlocked area (%i%%),counter: %i, z: %i ',tileInfo.folder,round(percArea),counter,tileInfo.pos_lat.z),true);        
    if counter>=threshold.counterThres
        counter = 0; % reset so value is zero after restart.
        code = 300; msg = sprintf('Blocked area (%i%%)',round(percArea));
    end
end

%% update blockdetection info.
tileInfo.blockDetection.percArea = percArea;
tileInfo.blockDetection.counter = counter;
tileInfo.blockDetection.pass = pass;

end

