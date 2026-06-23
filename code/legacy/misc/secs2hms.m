% secs2hms() Secs2hms.
%
% SECS2HMS Format a duration in seconds as hours, minutes, and seconds.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function hms = secs2hms(secs)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

secs = max(0, round(secs));
hours = floor(secs / 3600);
minutes = floor(mod(secs, 3600) / 60);
seconds = mod(secs, 60);
hms = sprintf('%02d:%02d:%02d', hours, minutes, seconds);
end
