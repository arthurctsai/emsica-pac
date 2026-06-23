function config = setup_emsica_pac()
% setup_emsica_pac() Configure the standalone EEGLAB EMSICA-PAC demo.
%
% Copyright (c) Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

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

addpath(genpath(fullfile(rootdir, 'code', 'legacy')), '-begin');
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
     'EEGLAB_ROOT before running setup_emsica_pac.']);
end

config = struct('root', rootdir, 'study_root', study_root, ...
  'subject_dir', fullfile(study_root, 'zm09'), ...
  'output_dir', output_dir, ...
  'run_dir', fullfile(output_dir, 'zm09'), ...
  'result_root', fullfile(output_dir, 'zm09', '6emsica'), ...
  'eeglab', fileparts(which('eeglab')));
fprintf('EMSICA-PAC root: %s\n', rootdir);
fprintf('Immutable data: %s\n', config.subject_dir);
fprintf('Generated runs: %s\n', config.run_dir);
end
