function output_folder = demo_run_emsica(maxsteps, output_tag)
% demo_run_emsica() Run Extended EMSICA from the cached EEGLAB initializer.
%
% demo_run_emsica()                  % manuscript configuration, 100 steps
% demo_run_emsica(2, 'smoke')        % short installation test
%
% Copyright (c) Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

if nargin < 1 || isempty(maxsteps), maxsteps = 200; end
if nargin < 2 || isempty(output_tag), output_tag = 'demo'; end
validateattributes(maxsteps, {'numeric'}, ...
  {'scalar','real','finite','integer','nonnegative'});
output_tag = sanitize_output_tag_local(output_tag);
cfg = setup_emsica_pac();
rng(0, 'twister');

s = get_info('zm09');
s.emsica.myalpha = 0.0125;
s.emsica.mybeta = 27.7;
s.emsica.b_update_lrate_scale = 1;
s.emsica.spatiotemporal_mix_ramp_steps = 200;
s.emsica.spatiotemporal_mix_exp_k = 1;
s.emsica.spatiotemporal_mix_r_begin = 0;
s.emsica.spatiotemporal_mix_r_end = 1;
s.emsica.runemsica_log_suffix = output_tag;
s.emsica.enable_diagnostics = 0;
s.emsica.diagnostics_stride = 1;
s.emsica.maxsteps = maxsteps;
s.emsica.b0folder = '6emsica/B0-synth-infomax/';
s.emsica.ica_input_folder = '3ica/ICs-synth-infomax/';

result_name = sprintf('ICs-synth-infomax-extended-%s-full', output_tag);
output_folder = fullfile(cfg.result_root, result_name);
if ~isfolder(output_folder), mkdir(output_folder); end
s.emsica.output_folder = [output_folder filesep];
s.diaryfile = fullfile(output_folder, ...
  'log-runemsica_by_sphx-gradient.txt');
if isfile(s.diaryfile), delete(s.diaryfile); end
diary(s.diaryfile);
diaryCleanup = onCleanup(@() diary('off')); %#ok<NASGU>

% Keep the historical semantic folder token for the legacy synth branches;
% gparser redirects only the physical output directory.
emsica_(s, 'emsicatype', 'gradient', 'K', 4, ...
  'emsicafolder', '6emsica/ICs-synth-infomax-extended-demo-full/', ...
  'lapmethod', 'synth', 'recompute', 'on', 'plots', 'off', ...
  'synth_truth_folder', '2epochs/EPs-synth/');
fprintf('Extended EMSICA result: %s\n', output_folder);
end

function tag = sanitize_output_tag_local(tag)
tag = regexprep(strtrim(char(string(tag))), '[^A-Za-z0-9_-]', '-');
tag = regexprep(tag, '-+', '-');
tag = regexprep(tag, '^-|-$', '');
if isempty(tag)
  error('demo_run_emsica:InvalidOutputTag', 'Invalid output tag.');
end
end
