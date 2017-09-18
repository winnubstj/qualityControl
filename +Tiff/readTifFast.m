function [ I ] = readTifFast(fileName, imSize,frames, dataType)
%readTifFast Efficient Tiff reading using Tiff library and memory preallocation.
warning off MATLAB:imagesci:tiffmexutils:libtiffWarning
tiffObj = Tiff(fileName, 'r');
c = onCleanup(@()tiffObj.close); % Close file on cleanup.
I = zeros(imSize(1),imSize(2),length(frames),dataType);
cnt = 0;
for iFrame = frames
    cnt = cnt+1;
    tiffObj.setDirectory(iFrame);
    I(:,:,cnt) = tiffObj.read;       
end

end

