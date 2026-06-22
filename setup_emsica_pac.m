function config = setup_emsica_pac()
% setup_emsica_pac() Configure the standalone EMSICA-PAC demonstration.
%
% Author: Arthur C. Tsai
% Email: arthur@stat.sinica.edu.tw; arthurctsai@gmail.com
% Copyright (c) Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

% 123456789012345678901234567890123456789012345678901234567890123456789012345678

rootdir = fileparts(mfilename('fullpath'));
study_root = fullfile(rootdir, 'demodata');
output_dir = fullfile(rootdir, 'outputs');
log_dir = fullfile(output_dir, 'logs');
if ~isfolder(output_dir), mkdir(output_dir); end
if ~isfolder(log_dir), mkdir(log_dir); end

setenv('EMSICA_PAC_ROOT', rootdir);
setenv('EMSICA_PAC_STUDY_ROOT', study_root);
setenv('EMSICA_PAC_OUTPUT_DIR', output_dir);
setenv('SUBJECTS_DIR', study_root);

legacy_root = fullfile(rootdir, 'code', 'legacy');
addpath(genpath(legacy_root), '-begin');
addpath(fullfile(rootdir, 'code', 'portable'), '-begin');
addpath(fullfile(rootdir, 'tests'), '-begin');
addpath(rootdir, '-begin');
clear get_info

eeglab_root = getenv('EEGLAB_ROOT');
if isempty(which('pop_loadset')) && ~isempty(eeglab_root) && isfolder(eeglab_root)
  addpath(genpath(eeglab_root), '-end');
end
if isempty(which('pop_loadset'))
  error('setup_emsica_pac:MissingEEGLAB', ...
    ['EEGLAB is required. Add EEGLAB to the MATLAB path or set ' ...
     'the EEGLAB_ROOT environment variable before running setup_emsica_pac.']);
end

config = struct('root', rootdir, 'study_root', study_root, ...
  'subject_dir', fullfile(study_root, 'zm09'), ...
  'output_dir', output_dir, 'eeglab', fileparts(which('eeglab')));
fprintf('EMSICA-PAC root: %s\n', rootdir);
fprintf('Demo subject:    %s\n', config.subject_dir);
fprintf('Outputs:         %s\n', output_dir);
end
