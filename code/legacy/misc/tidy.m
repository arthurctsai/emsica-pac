% tidy() 2 Preview or delete numbered backup result folders for one subject.
%
% This helper scans a subject directory and looks for backup folders whose
% names end with 2-3 digits, such as `ICs05`, `EPs12`, or
% `ICs-synth-fastica03`. It is useful for cleaning old backup folders that
% were created automatically by `backupfolder()`.
%
% Usage
%   tidy2('zc03')
%   tidy2('zc03', 1)
%
% Inputs
%   s
%     Subject name or input accepted by `get_info()`, for example `'zc03'`.
%
%   dopurge
%     `0` = preview only. Show matched folders without deleting them.
%     `1` = delete matched folders recursively using `rmdir(...,'s')`.
%     Default: `0`.
%
% Cleanup targets
%   The function checks these subject subfolders:
%     `1channels/`
%     `2epochs/`
%     `3ica/`
%     `4clean/`
%     `6emsica/`
%
%   It removes only numbered backup-style folders that match the internal
%   regular-expression rules, for example:
%     `CHs05`
%     `EPs12`
%     `ICs03`
%     `ICs-a07`
%     `sphinv11`
%     `ICs-synth-fastica02`
%     `ICs-synth-infomax04`
%
% Examples
%   tidy2('zc03')        % preview only
%   tidy2('zc03', 1)     % delete matched folders
%
%   for i = 1:numel(s.simulation)
%     tidy2(s.simulation{i});
%   end
%
% Notes
%   This function does not remove the current main folders such as
%   `ICs/`, `EPs/`, or `ICs-synth-fastica/`. It only targets numbered
%   backup folders like `ICs01`, `ICs02`, ...
%
%   Folders starting with `ICsR` are protected and will not be removed,
%   for example:
%     `ICsR01`
%     `ICsR12`
%     `ICsR01-I`
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function tidy(s, dopurge)
if nargin < 2 || isempty(dopurge)
  dopurge = 0;
end

s = get_info(s);
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

if ~isfolder(s.subjectdir)
  error('The subject directory "%s" does not exist.', s.subjectdir);
end

targets = {
  struct('reldir', '1channels/', ...
         'patterns', {{'^CHs\d{2,3}$'}})
  struct('reldir', '2epochs/', ...
         'patterns', {{'^EPs\d{2,3}$'}})
  struct('reldir', '3ica/', ...
         'patterns', {{...
           '^ICs\d{2,3}$', ...
           '^ICs-a\d{2,3}$', ...
           '^sphinv\d{2,3}$', ...
           '^ICs-synth-fastica\d{2,3}$', ...
           '^ICs-synth-infomax\d{2,3}$', ...
           '^ICs-synth-fastica-a\d{2,3}$', ...
           '^ICs-synth-infomax-a\d{2,3}$'}})
  struct('reldir', '4clean/', ...
         'patterns', {{...
           '^ICs\d{2,3}$', ...
           '^ICs-synth-infomax\d{2,3}$'}})
  struct('reldir', '6emsica/', ...
         'patterns', {{'^ICs\d{2,3}$'}})
  };

folders_to_remove = {};

%% ======================= (1) Collect matching folders ========================
for tt = 1:numel(targets)
  basedir = [s.subjectdir targets{tt}.reldir];
  if ~isfolder(basedir)
    mdisp(['Skip missing directory: ' basedir]);
    continue;
  end

  items = dir(basedir);
  items = items([items.isdir]);
  items = items(~ismember({items.name}, {'.', '..'}));

  for ii = 1:numel(items)
    folder_name = items(ii).name;
    if is_protected_folder(folder_name)
      continue;
    end
    if matches_any_pattern(folder_name, targets{tt}.patterns)
      folders_to_remove{end+1} = [basedir folder_name]; %#ok<AGROW>
    end
  end
end

%% ============================= (2) Show preview ==============================
if isempty(folders_to_remove)
  mdisp(['No matching folders found for subject ' s.subject '.']);
  return
end

mdisp(['Matched folders for subject ' s.subject ':']);
for ii = 1:numel(folders_to_remove)
  mdisp(['  ' folders_to_remove{ii}]);
end
mdisp(['Total matched folders: ' num2str(numel(folders_to_remove))]);

if ~dopurge
  mdisp('green',['Preview only. Run tidy2(''' s.subject ''', 1) to delete them.']);
  return
end

%% ======================== (3) Delete matched folders =========================
for ii = 1:numel(folders_to_remove)
  folder_path = folders_to_remove{ii};
  try
    rmdir(folder_path, 's');
    mdisp(['Removed: ' folder_path]);
  catch ME
    warning('Failed to delete folder: %s\nError: %s', folder_path, ME.message);
  end
end

mdisp(['Folder cleanup completed for subject ' s.subject '.']);

end

%% ========== Helper: (1) check folder name against cleanup patterns ===========
function tf = matches_any_pattern(folder_name, patterns)
tf = false;
for ii = 1:numel(patterns)
  if ~isempty(regexp(folder_name, patterns{ii}, 'once'))
    tf = true;
    return
  end
end
end

%% ================== Helper: (2) protect folders from cleanup =================
function tf = is_protected_folder(folder_name)
tf = ~isempty(regexp(folder_name, '^ICsR\d{2,3}.*$', 'once'));
end
