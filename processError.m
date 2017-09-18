function [ outputCode,outputMsg ] = processError( faultStruct,fid,tileInfo,outputCode,outputMsg, Settings )
    if faultStruct.exit, outputCode = faultStruct.code; outputMsg = faultStruct.msg; end
    if faultStruct.log,  logMessage(fid,faultStruct.msg); end
    if faultStruct.mail, Mail.errorMail( tileInfo, faultStruct.code,faultStruct.msg,Settings ); end
end

