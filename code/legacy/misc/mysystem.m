% mysystem() else.
%
% Output:
% Success (status = 0): A status of 0 confirms that the command was executed correctly.
% Example 1 in review_sphinv_plot()
% for k=1:K
%   % ln -s blank.gif comp_001ersp.png
%   pngfile = ['comp_' num2str(k, '%03d') 'ersp.png'];
%   if i==1
%     verbose = 1;
%   else
%     verbose = 0;
%     fprintf([' ' num2str(k)]);
%   end
%   mysystem(['ln -s blank.gif ' pngfile], verbose); %
% end
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [status, result, cmdexists] = mysystem(cmd, verbose)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  status=0; result=0;

  if nargin < 2
    verbose=1;
  end

  % Extract the first part of the command as the program name
  % Assuming commands are space-separated and the first part is the program
  tcmdexistsens = strsplit(cmd);
  programName = tcmdexistsens{1};

  % Check if the program exists on the system
  if isunix || ismac
    % For Unix/Linux/Mac, using 'which' command
    [status, ~] = system(['which ' programName]);
    cmdExists = (status == 0);
  elseif ispc
    % For Windows, using 'where' command
    [status, ~] = system(['where ' programName]);
    cmdExists = (status == 0);
  else
    disp('Unknown operating system. Cannot check if command exists.');
    return;
  end

  % Execute the command if it exists, otherwise display a warning
  if cmdExists
    if verbose
      % mdisp('nonewline', cmd);
      mdisp('nonewline', '');
      fprintf(cmd);
    end
    [status, result] = system(cmd);

    if verbose && (status == 0) % A status of 0 confirms that the command was executed correctly. 
      disp(' ... done!');
    end
    if status ~=0
      disp(' ');
      mdisp('red', ' ... something wrong!');
      disp('--- system error while running ---');
      disp(cmd);
      disp(result);
      keyboard
    end

    cmdexists =1;
  else
    disp(cmd); % display the command
    cdisp('red',['Command ' programName ' is not found on this system.']);
    keyboard;
    cmdexists =0;
  end
end

