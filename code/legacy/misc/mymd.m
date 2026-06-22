% mymd() mkdir
%
% Arthur C. Tsai arthur@stat.sinica.edu.tw
% 2014-03-14
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function mymd(directory);
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

if isfolder(directory)
if islink(directory) == -1 % it is a link directory, but the target folder is missing 2024-11-7 arthur
  myrm(directory);
  mdisp('I am afraid Matlab may not able to remove it!! Here, keyboard to check it out.')
  keyboard;
end
end

if islink(directory) == 1 % it is a link directory, remove it and create a real one 2024-11-7 arthur
  myrm(directory);
end

if ~isfolder(directory)
  mkdir(directory); 
end
