function [ code, msg ] = blockDetection( Iavg, tileInfo,QC, paramA, paramB )
%BlockDetection. Performs the detection of bubble or debris blocking the
%objective.

code = 100;
msg = 'Okay';

figure;
imshow(Iavg,[]);
%% Crop overlap regions image.
x_overlap_pix = ceil(tileInfo.FOV.x_overlap_um/tileInfo.x_pix_size)+1;
y_overlap_pix = ceil(tileInfo.FOV.y_overlap_um/tileInfo.y_pix_size)+1;
Iavg = Iavg(x_overlap_pix:end-x_overlap_pix,y_overlap_pix:end-y_overlap_pix);

end

