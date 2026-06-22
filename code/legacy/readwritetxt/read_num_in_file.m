% read_num_in_file() Description:
%
% Description:
%
%    To get channel or component list in the txt file.
%    "#" is the comment mark.
%    MxN numerical array is allowed in the txt file. (Comment is allowed.)
%    If there are english characters in the numerical array as prefix, they will be ignored.
%    details please refer to http://emsica.art/產生idx.txt_and_idx_selected.txt
%
% % Example: load data from idx.txt
% idx.txt content:
%   # this is a header line1
%   # this is header line2
%   1 2 # ddd
%   2 3 # qqq
%
% [list, text, headers] = read_num_in_file('idx.txt');
%
% list = % double array
%      1     2
%      2     3
%
% text = % cell array
%     {' ddd'}
%     {' qqq'}
%
% headers =
%     {'# this is a header line1'}
%     {'# this is header line2'}   
% 
%           
% 20110712 Vincent          
% 2022-07-8 rkffabcd. allowing headerline
% 2025-09-27 arthur. add an output headers
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [list, text, headers] = read_num_in_file(varargin)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  list = []; text = []; headers = {};

  filename = varargin{1};

  if ~isfile(filename)
    mdisp(['Cannot find ' filename '!']);
    return;
  end

  % Check if the file is empty
  fileInfo = dir(filename);
  if fileInfo.bytes == 0
    mdisp([filename ' is an empty file!']);
    return;
    % Handle empty file case here
  end

  if nargin>1    
    subjlist = varargin{2};
  else
    subjlist = [];
  end

  if nargin>2
    verbose = varargin{3};
  else
    verbose = 1;
  end

  headerline = 0; % use headerlines to allow header eg.
  % # flag, s, component, comments
  % in the .txt file  2022-07-8 rkffabcd

  flag = true;
  if verbose
    mdisp(['reading ' filename ' ...']);
  end

if verbose
    mdisp(['reading ' filename ' ...']);
end

% Read and collect header lines
fid = fopen(filename, 'r');                                              % <---
lines = {};                                                              % <---
while ~feof(fid)                                                         % <---
    line = fgetl(fid);                                                   % <---
    if ischar(line)                                                      % <---
        lines{end+1} = line; %#ok<AGROW>                                  % <---
        if startsWith(strtrim(line), '#')                                % <---
            headerline = headerline + 1;                                 % <---
            headers{end+1} = line; %#ok<AGROW>                            % <---
        else                                                             % <---
            break;                                                       % <---
        end                                                              % <---
    end                                                                  % <---
end                                                                      % <---
fclose(fid);                                                             % <---

while(flag)
  fid = fopen(filename,'r');
  in = textscan(fid, '%[^#\n] %[^\n]', 'HeaderLines', headerline);     % <---
  in2 = in;
  %in = textscan(fid, '%d %d %*[abcdefghijklmnopqrstuvwxyz] %d %d %[^\n]');
  %in = textscan(fid, '%s %[^\n]');
  fclose(fid);
  if isempty(in{1})
    headerline=headerline+1;
  else
    flag = false;
  end
end

list=[];
for i=1:length(in{1}) % remove [a-z] in in{1}
  if ~isempty(str2num(in{1}{i})) % for eg. '8.20e-02'
    tmp = in{1}{i};
  else % for eg. 'zm01'
    idx=regexp(in{1}{i},'[a-z]');
    in{1}{i}(idx)=[];
    tmp = in{1}{i};
  end
  list=[list;str2num(tmp)];
end

%% for reading clusters.txt, you will have subjlist
if ~isempty(subjlist)    
  for i=1:length(in2{1})
    temp = split(in2{1}{i},' ');
    list(i,3)=find(~cellfun(@isempty,strfind(subjlist,temp{3})));
  end
end

if nargout>=2
  for i=1:length(in{2}) 
    in{2}{i} = strrep(in{2}{i}, '#', '');
  end
  text = in{2};
end

% % Return header lines (including '#')                                   % <---
% if nargout >= 3 && isempty(header)                                       % <---
%     header = {};                                                         % <---
% end
