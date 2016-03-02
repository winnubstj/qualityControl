function [ outputCell ] = fastProtoBuf( fileLoc, fields )
%fastProtoBuf. Quick and dirty way of reading field values from protobuf
%file generated by Fetch software
%   Function is unaware of overall sctructure of protobuf file but simply
%   reads in values for certain field. Currently considers everything to be
%   a numeric value.
%
% Syntax:  fastProtoBuf( fileLoc, fields )
%
% Inputs:
%       fileLoc             - Location of protobuf file.
%       fields              - Cell array of requested fields names
% Optional Inputs:
%       outputCell          - Cell array containing the requested values

fileLoc = 'Y:\mousebrainmicro\acquisition\2016-02-21\2016-02-21\00\00033\00033-ngc.microscope';
fields = {'x_overlap','y_overlap','x_size_um','y_size_um'};

%% Validate inputs
if ~ischar(fileLoc)
    error('File location is of type %s and must be a string',class(fileLoc));
end
if ~iscell(fields)
    error('Requested fields is of type %s and must be a cell',class(fields));
end


end
