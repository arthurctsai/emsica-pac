% myrm() Remove specified file or folder.
%
% This function deletes the specified file or folder. If the input is a
% folder, it attempts to remove it using MATLAB's rmdir function. If rmdir
% fails, a system command (`rm -rf`) is used as a fallback to ensure the
% folder is deleted. For files, the function uses MATLAB's delete function.
%
% Syntax:
%   myrm(filename)
%
% Input:
%   filename - A string specifying the path to the file or folder to be
%              deleted. Can be an absolute or relative path.
%
% Output:
%   No explicit output, but a message is displayed indicating the file
%   or folder has been successfully removed. An error is raised if 
%   deletion fails.
%
% Notes:
%   - The function uses the system command `rm -rf` as a backup for folders
%     that cannot be deleted with rmdir. This may prompt for permissions
%     on certain systems.
%   - Ensure the filename provided is correct, as this function will
%     permanently delete the specified file or folder.
%
% Created: 2014-03-14
% Refined: 2024-11-09 with additional checks to make it more robust for parallel processing, parfor.
% 
% See original help documentation for full details...

% Check if filename is a folder and attempt removal if so
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function myrm(filename)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

if isfolder(filename)
    % Try to remove the folder with rmdir first
    status = rmdir(filename, 's');
    
    % Check if the folder was already deleted by another worker
    if ~status && isfolder(filename)
        % Fall back to system command if rmdir fails and folder still exists
        [status, result] = system(['rm -rf ' filename]);
        
        if ~status && isfolder(filename)
            error(['Failed to remove folder: ' filename]);
        end
    end
    
    mdisp([filename ' is removed.']);
    return;
end

% Check if filename is a file and delete if it exists
if exist(filename, 'file')
    delete(filename);
    mdisp([filename ' is removed.']);
end

 
% 
% 
% if isfolder(filename)
%    rmdir(filename, 's'); 
%    [status, result, cmdexists] = mysystem(['rm -rf ' filename]);
%    mdisp([filename ' is removed.']);
%   return;
% end
% % 
%  if exist(filename, 'file')
%    delete(filename); 
%    mdisp([filename ' is removed.']);
%  end
% 
% 
% 
% 
% 
