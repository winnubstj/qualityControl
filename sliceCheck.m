function [ outputCode,outputMsg,sliceThickness ]= sliceCheck( tileInfo,QC, threshold )
%sliceCheck Takes tile position info from this tile and previous tiles to
%check that slice thickness is within expected range.

sliceThickness = 0;

% Find tiles that were on previous slice (lattice Z -1)
prevZ = [QC.pos_lat];
prevZ = [prevZ.z]';
prevZ = find(prevZ==tileInfo.pos_lat.z-1);

% Check if we have info from previous slice
if isempty(prevZ)
    %some bug report.
    outputCode = 100; outputMsg = 'No info on previous slice';
else
    % get minimum z pos (mm)
    minZ = [QC(prevZ).pos_mm];
    minZ = min([minZ.z]);
    sliceThickness = tileInfo.pos_mm.z-minZ;
    % Check if slice thickness is over threshold.
    if sliceThickness>threshold
        outputCode = 700; outputMsg = 'Slice thickness was over threshold';
    else
        outputCode = 100; outputMsg = 'Okay';
    end
end
fprintf('\n\tSlice thickness detection\n\t\tDelta Z\t: %.3f',sliceThickness);
end

