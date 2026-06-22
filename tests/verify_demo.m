% verify_demo() Validate required files, cached figures, and optional training.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function verify_demo(level)
if nargin < 1 || isempty(level), level = 'figures'; end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

cfg = setup_emsica_pac();
required = { ...
  fullfile(cfg.subject_dir, '2epochs', 'EPs-synth', 'zm09.set'), ...
  fullfile(cfg.subject_dir, '2epochs', 'EPs-synth', 'zm09.fdt'), ...
  fullfile(cfg.subject_dir, '3ica', 'ICs-synth-infomax', 'zm09.set'), ...
  fullfile(cfg.subject_dir, '6emsica', 'B0-synth-infomax', 'zm09.set'), ...
  fullfile(cfg.subject_dir, '6emsica', 'ICs-synth-infomax-extended-reference-full', 'B.mat'), ...
  fullfile(cfg.subject_dir, '6emsica', 'ICs-synth-infomax-extended-reference-full', 'mmitmp.mat')};
missing = required(~cellfun(@isfile, required));
assert(isempty(missing), 'Missing required demo file: %s', strjoin(missing, ', '));

switch lower(string(level))
  case "data"
    fprintf('Data validation passed.\n');
  case "figures"
    files = demo_generate_figures('reference');
    assert(all(cellfun(@isfile, files)), 'Figure validation failed.');
    source_info = imfinfo(files{1});
    assert(source_info.Width / source_info.Height > 2.8, ...
      'Source-recovery output should contain only the wide Panel A region.');
    fprintf('Figure validation passed.\n');
  case "smoke"
    demo_run_emsica(2, 'smoke');
    fprintf('EMSICA smoke validation passed.\n');
  otherwise
    error('verify_demo:UnknownLevel', 'Level must be data, figures, or smoke.');
end
end
