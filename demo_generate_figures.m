function files = demo_generate_figures(result_tag)
% demo_generate_figures() Generate source-recovery and broadband-PAC figures.
%
% demo_generate_figures('reference') uses the included validated result.
% demo_generate_figures('demo') uses output from demo_run_emsica().
%
% Author: Arthur C. Tsai
% Email: arthur@stat.sinica.edu.tw; arthurctsai@gmail.com
% Copyright (c) Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

if nargin < 1 || isempty(result_tag), result_tag = 'reference'; end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

cfg = setup_emsica_pac();

result_dir = fullfile(cfg.subject_dir, '6emsica', ...
  ['ICs-synth-infomax-extended-' result_tag '-full']);
if ~isfolder(result_dir)
  error('demo_generate_figures:MissingResult', ...
    'Missing %s. Run demo_run_emsica() or use result_tag="reference".', result_dir);
end

source_reference = fullfile(cfg.root, 'reference', 'source_recovery_zm09.png');
source_output = fullfile(cfg.output_dir, 'source_recovery_zm09.png');
plot_source_panel_a_local(source_reference, source_output);
demo_plot_pac_maps(result_tag);

files = {source_output, ...
  fullfile(cfg.output_dir, 'pac_recovery_zm09.png')};
for k = 1:numel(files)
  if ~isfile(files{k})
    error('demo_generate_figures:MissingOutput', 'Expected figure was not created: %s', files{k});
  end
  fprintf('Created %s\n', files{k});
end

function plot_source_panel_a_local(source_reference, source_output)
% Plot only the marked Panel A region while leaving the reference untouched.
img = imread(source_reference);
[height, width, ~] = size(img);

% Normalized bounds of the requested region in the validated composite:
% [left, top, right, bottom]. These omit the overall panel letter/title and
% the lower spatial/time-course summary panels B and C.
bounds = [0.030 0.069 0.996 0.663];
x_limits = [1 + bounds(1) * (width - 1), 1 + bounds(3) * (width - 1)];
y_limits = [1 + bounds(2) * (height - 1), 1 + bounds(4) * (height - 1)];

fig = figure('Visible', 'off', 'Color', 'w', 'InvertHardCopy', 'off');
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
set(fig, 'Position', [100 100 1800 560]);
ax = axes('Parent', fig, 'Position', [0 0 1 1]);
image(ax, img);
axis(ax, 'image');
set(ax, 'XLim', x_limits, 'YLim', y_limits, 'YDir', 'reverse');
axis(ax, 'off');
exportgraphics(ax, source_output, 'Resolution', 150, 'BackgroundColor', 'white');
end
end
