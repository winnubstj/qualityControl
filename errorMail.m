function errorMail( tileInfo, outputCode,outputMsg )
recipients = {'winnubstj@janelia.hhmi.org'};
for i=1:length(recipients)
    recipient = recipients(i);
    subject = sprintf('%s - Error Code %i',tileInfo.sampleID, outputCode);
    message = sprintf('Sample %s has run into error code %i:\n\t%s',tileInfo.folder,outputCode, outputMsg);
    matlabmail(recipient, message, subject);
end
end

