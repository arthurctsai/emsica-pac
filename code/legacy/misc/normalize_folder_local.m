% normalize_folder_local() Normalize folder local.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function folder = normalize_folder_local(folder)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

folder = strrep(strtrim(char(folder)), '\', '/');
if isempty(folder)
  folder = '2epochs/EPs-synth/';
end
if ~endsWith(folder, '/')
  folder = [folder '/'];
end
end
