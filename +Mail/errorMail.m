function errorMail( tileInfo, outputCode,outputMsg,Settings )
recipients = Settings.mailingList;
for i=1:length(recipients)
    recipient = recipients(i);
    subject = sprintf('%s - %s - Error Code %i',Settings.Name,tileInfo.sampleID, outputCode);
    message = sprintf('%s reports:\nSample %s has run into error code %i:\n\t%s',Settings.Name,tileInfo.folder,outputCode, outputMsg);
    Mail.matlabmail(recipient, message, subject,Settings.senderMail,Settings.senderpass);
end
end

