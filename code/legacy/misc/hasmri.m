% hasmri() Retrieve directory information from input structure
%
% I have a mri directory, sometimes it is linked to other place
% mri -> ../.colin27/mri
% This function checks if the directory exists and is not a symbolic link.
%
% If it does not exist or is linked to other place return 0
%
% Author:
% 2014-12-14 arthur
% 2024-04-27 arthur rewrite it thoroughly
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function subjecthasmri = hasmri(s,verbose)
  s = get_info(s);
  if nargin <2
    verbose =0; % default donot show message.
  end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  %% step 0. check if this is a fmri study
  if contains(s.studydir,'fmri') | contains(s.subject,'7raicar')
    subjecthasmri = 1;
    return;
  end

  %% step 1. check hasmri field asign by studyinfo()
  if isfield(s,'hasmris')
    [subjecthasmri, index] = ismember(s.subject, s.hasmri);

    if verbose
      if subjecthasmri
        mdisp(['The subject ' s.subject ' has mri according to s.hasmri']);
      else
        mdisp(['The subject ' s.subject ' has no mri according to s.hasmri']);
      end
      return;
    end
  end;

  %% step 2. check whether you have symbolic link
  % Doing symbolic link for subject without mir is not a good idea
  % now we don't do that, instead, most of the function they needs to read template brain, 
  % they will read from colin27 eg. subcorticalmeshes = get_subcorticalmeshes('.colin27')
  % so the folloing code maybe useless. 2024-08-22 arthur
  % Initialize output to false (0)
  subjecthasmri = 0;

  % Check if the directory exists
  mridir = s.mriDir;
  %   if exist(mridir, 'dir') == 7  % The argument 'dir' ensures we're checking for a directory
  %     subjecthasmri = 1;  % The directory exists
  %   end

  if isfield(s,'hasmri') | isfield(s,'hasnomri')
    if isfield(s,'hasmri')
      subjecthasmri = any(ismember(s.hasmri,s.subject));
    end
   % if isfield(s,'hasnomri')
   %   subjecthasmri = ~any(ismember(s.hasnomri,s.subject));
   % end

  else
    % Check if the directory is a symbolic link
    [isLink, result] = islink(mridir);
    if isLink
      % The subject zm10 has no mri. It links to -> ~/1_zen/.colin27/mri/.
      if verbose
        mdisp(['The subject ''' s.subject ''' has no mri. It links to -> ' result '.']);
      end
      subjecthasmri = 0;  % It's a symlink, set return to false
    else
      % The subject zm01 has mri with real mri directory ~/1_zen/zm01/mri/
      if verbose
        mdisp(['The subject ''' s.subject ''' has mri with real mri directory ' mridir]);
      end
      subjecthasmri =1;
    end
  end
end

