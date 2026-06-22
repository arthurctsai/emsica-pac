% This function checks if the directory exists and is not a symbolic link.
% % Example 1:
% cd /1_esspfmriyear1/7raicar/3ica/ICs'
% ls clusters.txt
% islink('clusters.txt')
% ans: 1
% Example 2:
% Check if the given mridir is a symbolic link
% eg. I have a mri directory which is linked to other place
% mri -> ../.colin27/mri

function [isLink,result ]= islink(filepath)
% ISLINK - Check if a file or folder is a symbolic link
%
%   ISLINK = ISLINK(FILEPATH) returns 1 if the specified FILEPATH is
%   a symbolic link, 0 if it is not, and -1 if the file or folder does
%   not exist.
%
%   Inputs:
%       FILEPATH - Path to the file or folder to check.
%
%   Outputs:
%       ISLINK - Returns 1 if the file or folder is a symbolic link,
%                returns 0 if it is not, and returns -1 if the file or
%                folder does not exist.
%
%   Example:
%       isLink = islink('/path/to/file_or_folder')
%
%   Author: [Author Name]
%   Email: [Author Email]
%   Date: [Date]

% Execute the ls -l command to get the details of the file or folder
[status, result] = system(['ls -l ', filepath]);

% Check if the command executed successfully
if status == 0
    % Parse the first character of the result
    % If it is 'l', it indicates a symbolic link
    isLink = result(1) == 'l';
    % Convert logical true/false to 1/0
    isLink = double(isLink);
else
    % Check if the error is due to the file or folder not existing
    if contains(result, 'No such file or directory')
        isLink = -1;
    else
        error('Failed to execute the command: %s', result);
    end
end

end

