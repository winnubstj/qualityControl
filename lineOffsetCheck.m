function [code, msg] = lineOffsetCheck( I, tileInfo,offsetThreshold )
%lineOffsetCheck. Check if there is a problem with the line end trigger
%that can cause a offset between even and uneven lines.

%% Default output
code = 100;
msg = 'Okay';

%% Remove likely hot pixels.
I(I>60000)=NaN;

%% Prepare optimizer.
[optimizer, metric]  = imregconfig('monomodal');
optimizer.MaximumIterations = 5;

%% Go through frames.
offsets = [];
for iFrame = 1:size(I,3)
%% Adjust contrast.
limits = stretchlim(I(:,:,iFrame),[0.15,0.99]);
I(:,:,iFrame) = imadjust(I(:,:,iFrame), limits, []);

%% Register.
tform = imregtform(double(I(1:2:end,:,iFrame)),double(I(2:2:end,:,iFrame)),'translation',optimizer, metric);
offsets = [offsets; tform.T(3,1)];
end
xOffset = abs(median(offsets));

if xOffset>=offsetThreshold
    code = 500;
end
fprintf('\n\tEnd of line offset detection\n\t\tOffset\t: %.4f',xOffset);

end

