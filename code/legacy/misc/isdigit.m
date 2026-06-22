% isdigit() True for digit characters.
%
% y = isdigit(x)
%    Given a string x, return a value y the same shape as x with 1's where x
%    has digit characters and 0's elsewhere.  Digits are simply '0' to '9'.
%    x need not be a string, merely have values in the right range.
%
% See also ISLETTER, ISSPACE, ISSTR, IS2POWER, ISEMPTY, 
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function y = isdigit(x)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

y = (x >= '0') & (x <= '9');
