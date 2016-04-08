function success = logMessage(fid,  str, varargin)
%logMessage Logs message of quality control.
if nargin<3, timeStamp = false;else timeStamp =varargin{1}; end %Time stamp on by default.

if timeStamp
 str = sprintf('[%s] %s',datestr(now,'HH:MM:SS'),str);
end
% log to console.
if ~isdeployed, fprintf('\n%s',str); end
% log to file.
fprintf(fid,'\n%s',str);

end

