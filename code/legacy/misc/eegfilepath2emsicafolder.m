% eegfilepath2emsicafolder() Extract the subject and analysis-relative folder.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [subject, emsicafolder] = eegfilepath2emsicafolder(eegfilepath)
if nargin < 1 || isempty(eegfilepath)
    error('Usage: [subject, emsicafolder] = eegfilepath2emsicafolder(eegfilepath)');
end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

parts = split(string(eegfilepath), '/');
parts(parts == "") = [];
idx = find(contains(parts, {'2epochs', '3ica', '6emsica'}), 1, 'last');
if isempty(idx) || idx < 2
    error('Path must contain 2epochs, 3ica, or 6emsica after a subject folder.');
end

subject = char(parts(idx - 1));
emsicafolder = char(join(parts(idx:end), '/'));
if ~endsWith(emsicafolder, '/')
    emsicafolder = [emsicafolder '/'];
end
end
