% logprintf() Print to screen.
%
% LOGPRINTF Print a message to screen and optionally to a log file.
%   logprintf(fid, msg1, msg2, ...) prints the message(s) to screen using `mdisp`,
%   and if the file identifier `fid` is valid and open, also prints to the log file.
%
%   Inputs:
%     varargin{1} : file ID (optional; pass [] to skip logging)
%     varargin{2:end} : message arguments (as in fprintf)
%
% Usage example:
% logfid = fopen([s.subjectDir 'log.txt'], 'a');
% msg = 'print this';
% logprintf(logfid, msg)
%
% mdisp('yellow', varargin{2:end});  % <--- screen output
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function logprintf(varargin)
    fprintf(varargin{2:end});  % <--- screen output
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

    % Get list of open file identifiers
    open_fids = openedFiles();

    % Log to file only if valid fid is provided and open
    if ismember(varargin{1}, open_fids)
        fprintf(varargin{:});  % <--- file output
    end
end



