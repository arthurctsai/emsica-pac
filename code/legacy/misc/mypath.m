% mypath() Shorten an absolute path for display.
%
% 2020-12-20 arthur
%
% return ~/clouds/data/1_iaps_test/im98/1channels/CHs
% returnpath = strrep(thepath,'/Users/arthur','~');
%
% 2021-01-10 -arthur the following is better
% /Volumes/WD4T/data/3_Li_grouping/grouping01/3ica -->
% ~/data/3_Li_grouping/grouping01/3ica
%
% this function seems useless 2024-11-14
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function thepath = mypath(thepath)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

return 

temp = regexp(thepath, '/data/','split');

if length(temp)>1 % return sucessfully revised thepath, else return input thepath
  thepath = ['~/' temp{2}];
end;
