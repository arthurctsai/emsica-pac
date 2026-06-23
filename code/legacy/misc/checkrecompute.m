% checkrecompute() Check if a file needs to be recomputed based on timestamps.
%
% checkrecompute - Check if a file needs to be recomputed based on timestamps
%
% Usage:
%   recompute = checkrecompute(recompute, derivative, ref_file);
%       - `derivative` should be derived after `ref_file`, or, needs to recompute.
%         Also, derivative will be and `recompute` is set to 1 (true).
%
%   checkrecompute(0, idxmanuallytxt, idxtxt);
%       - If `idxmanuallytxt` exists but is older than `idxtxt`, it will be
%         deleted. This is useful to ensure the index file inherits the most
%         recent changes from its reference file.
%
% Syntax:
%   yes = checkrecompute(recompute, derivative, ref_file)
%
% Inputs:
%   recompute   - Boolean (1 or 0). If set to 1, it forces the function to delete
%                 the `derivative` file and return `yes = 1`, indicating
%                 recomputation is needed.
%   derivative  - Filepath to the derivative file that you want to check.
%   ref_file    - Filepath to the reference file against which the derivative's
%                 timestamp is compared.
%
% Outputs:
%   yes         - Boolean indicating whether the `derivative` file needs to be
%                 recomputed:
%                   * yes = 1: The file needs to be recomputed.
%                   * yes = 0: The file is up-to-date.
%                   * yes = -1: The reference file does not exist.
%
% History:
%   Created by Arthur on 2024-02-24.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function yes = checkrecompute(recompute, derivative, ref_file, verbose)
  if nargin<4
    verbose =0; % default
  end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  % Check if derivative exists
  if ~exist(ref_file, 'file')
    mdisp('red', [ref_file ' does not exist. It needs to be computed.\n']);
    yes = -1;
    return
  end

% Extract filenames for ref_file if both ref_file and derivative are in the same directory
[derivative_path, derivative_name, derivative_ext] = fileparts(derivative);
[ref_file_path, ref_file_name, ref_file_ext] = fileparts(ref_file);

% if strcmp(derivative_path, ref_file_path)
%     ref_file = [ref_file_name ref_file_ext];
% end

% keyboard

  % if you have force recompute, then return.
  if recompute
    yes =1;
    % Check if derivative exists
    if exist(derivative, 'file')
      mdisp('yellow', [derivative ' exists but since you force recompute=1, it is removed now for recomputing.']);
      myrm(derivative);
    end

    return;
  end

  % Check if derivative exists
  if ~isfile(derivative) && verbose
    mdisp('yellow', [derivative ' does not exist.\n']);
  end

  if exist(derivative, 'file')
    % Get file data for derivative and ref_file
    derivative_info = dir(derivative);
    ref_file_info = dir(ref_file);
    
    % Check if derivative is older than ref_file
    if derivative_info.datenum < ref_file_info.datenum
      yes = 1; % derivative is older than ref_file

      if ~contains(derivative,'/')
        derivative = [mypwd derivative];
      end

      % if ~contains(ref_file,'/')
      %  derivative = [mypwd ref_file];
      % end

      if strcmp(derivative_path, ref_file_path)
          ref_file = [ref_file_name ref_file_ext];
      end
      mdisp('yellow', [derivative ' is out of date, comparing with ' ref_file '. Remove it and recompute later.']);
      if strcmpi(derivative,'B.mat')
        keyboard; % set a keyboard for you to make sure whether to delete B.mat or not
      end
      myrm(derivative);
    else
      yes = 0; % derivative is newer than ref_file, so ok recompute=0

      if strcmp(derivative_path, ref_file_path)
          ref_file = [ref_file_name ref_file_ext];
      end
      mdisp('white', [derivative ' is newer than ' ref_file ', good! recompute = 0'], verbose);
    end
    
  else
    yes = 1; % derivative does not exist
    mdisp('red', [derivative ' does not exist. It needs to be computed.']);
  end
end

