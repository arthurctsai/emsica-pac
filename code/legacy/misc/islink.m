% islink() Check whether a file or folder is a symbolic link.
%
% [isLink,result] = islink(filepath) returns 1 when filepath is a symbolic
% link, 0 when it is not, and -1 when the file or folder does not exist.
%
% Input:
%   filepath - Path to the file or folder to check.
%
% Outputs:
%   isLink - Symbolic-link status: 1, 0, or -1.
%   result - Text returned by the underlying `ls -l` command.
%
% Examples:
%   islink('clusters.txt')
%   islink('../.colin27/mri')
%
% % ======================== (1) Query filesystem =========================
%
% Execute the ls -l command to get the details of the file or folder
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [isLink,result ]= islink(filepath)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

[status, result] = system(['ls -l ', filepath]);

%% ========================== (1) Interpret result ===========================

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
