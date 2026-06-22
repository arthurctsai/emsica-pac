% backupfile() Set default value for optional parameter
%
% function backupfile(file_or_foldername, rmpreviousbak)
%
%   BACKUPFILE(FILE_OR_FOLDERNAME, RMPREVIOUSBAK) backs up the specified file or folder.
%
%   Inputs:
%       FILE_OR_FOLDERNAME - Name of the file or folder to be backed up.
%       RMPREVIOUSBAK    - Optional flag (default 0). If 1, previous backup files 
%                          (e.g., 'myfile_bak01.txt') are removed before making 
%                          a new backup. This only applies to files.
%
%   Example:
%       backupfile('myfile.txt') backs up 'myfile.txt' as 'myfile_bak01.txt'
%       backupfile('myfile.txt', 1) removes 'myfile_bak01.txt' and 'myfile_bak02.txt', 
%                                  then backs up 'myfile.txt' as 'myfile_bak01.txt'.
%
%   Note:
%       - The backup file or folder is saved in the same directory
%         as the original file or folder.
%
% See also, backupfolder
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function backupfile(file_or_foldername, rmpreviousbak)
if nargin < 2 || isempty(rmpreviousbak)
    rmpreviousbak = 0; % Default: DO NOT remove previous backups
end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

[filepath, name, ext] = fileparts(file_or_foldername);

if ~isempty(filepath)
    % Ensure filepath ends with a file separator (e.g., / or \)
    filepath = [filepath filesep]; 
end

if ~isempty(ext) % --- It is a file ---
    
    % The pattern to match existing backup files for the original file
    backup_pattern = [filepath name '_bak??' ext];
    
    % --- Step 1: Optional Removal of Previous Backups ---
    if rmpreviousbak
        all_backup_files = dir(backup_pattern);
        
        if ~isempty(all_backup_files)
            mdisp(['Removing ' num2str(length(all_backup_files)) ' previous backup(s) for ' name ext '...']);
            for i = 1:length(all_backup_files)
                % Delete the actual backup file
                delete([filepath all_backup_files(i).name]); 
            end
        end
        % After removal, we re-run dir to get the starting backup index (which will be 0)
        allfile = dir(backup_pattern); 
    else
        % If not removing, find the current number of backups to determine the new suffix
        allfile = dir(backup_pattern);
    end

    % --- Step 2: Determine New Suffix and Perform Backup ---
    
    % length(allfile) gives the number of existing backups (e.g., if 01 exists, length=1).
    % The new suffix index will be length(allfile) + 1.
    new_suffix_index = length(allfile) + 1; 

    % The target backup filename
    new_filename = [name '_bak' num2str(new_suffix_index,'%.2d') ext];
    
    % Construct the move command
    cmd = ['mv ' filepath name ext ' ' filepath new_filename];
    
    % Execute the command
    [status,result] = mysystem(cmd);

    if status == 0 % Check status for success (mysystem returns 0 for success in typical MATLAB implementations)
        mdisp([name ext ' has been backed up as ' mypath(filepath) new_filename '!']);
    else
        % Display error if the move failed
        mdisp(['Error backing up ' name ext ': ' result], 'e');
    end

else % --- It is a directory (folder) ---
    
    % The rmpreviousbak flag is ignored for folders, as per the original structure
    % (where the folder backup calls a separate function, backupfolder).
    backupfolder([filepath name])
end


