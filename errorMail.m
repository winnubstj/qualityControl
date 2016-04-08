function errorMail( tileInfo, outputCode,outputMsg )
recipient = 'winnubstj@janelia.hhmi.org';
subject = sprintf('%s - Error Code %i',tileInfo.sampleID, outputCode);
message = sprintf('Sample %s has run into error code %i:\n\t%s',tileInfo.folder,outputCode, outputMsg);
matlabmail(recipient, message, subject);
end

