function [ outputCode,outputMsg ] = processError( faultStruct,fid,tileInfo,outputCode,outputMsg )
    if faultStruct.exit, outputCode = faultStruct.code; outputMsg = faultStruct.msg; end
    if faultStruct.log,  logMessage(fid,faultStruct.msg); end
    if faultStruct.mail, errorMail( tileInfo, faultStruct.code, faultStruct.msg ); end
end

