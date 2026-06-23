% isdigit() True for digit characters.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function y = isdigit(x)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

y = (x >= '0') & (x <= '9');
end
