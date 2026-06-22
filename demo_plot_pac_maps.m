function pngfile = demo_plot_pac_maps(result_tag)
% demo_plot_pac_maps() Render cached 4-by-4 broadband PAC comodulograms.
%
% Author: Arthur C. Tsai
% Email: arthur@stat.sinica.edu.tw; arthurctsai@gmail.com
% Copyright (c) Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

if nargin < 1 || isempty(result_tag), result_tag = 'reference'; end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

cfg = setup_emsica_pac();
subject_dir = cfg.subject_dir;
folders = { ...
  fullfile(subject_dir, '2epochs', 'EPs-synth'), ...
  fullfile(subject_dir, '3ica', 'ICs-synth-infomax'), ...
  fullfile(subject_dir, '6emsica', ...
    ['ICs-synth-infomax-extended-' result_tag '-full'])};
titles = {'Ground truth', 'Infomax ICA + sLORETA', 'Extended EMSICA'};
colors = {[0.3 0.3 0.3], [217 182 0]/255, [19 0 130]/255};
tensors = cell(1, 3);
all_values = [];
for g = 1:3
  mmifile = fullfile(folders{g}, 'mmitmp.mat');
  if ~isfile(mmifile)
    error('demo_plot_pac_maps:MissingMMI', 'Missing PAC cache: %s', mmifile);
  end
  tmp = load(mmifile);
  tensors{g} = tmp.EEGmmi;
  for n = 1:numel(tensors{g})
    value = tensors{g}{n};
    all_values = [all_values; value(isfinite(value))]; %#ok<AGROW>
  end
end

all_values = sort(all_values);
cmax = all_values(max(1, round(0.995 * numel(all_values))));
if ~isfinite(cmax) || cmax <= 0, cmax = max(all_values); end
phasefreq = logspace(log10(2), log10(15), 48);
ampfreq = logspace(log10(25), log10(150), 24);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [50 50 1680 620]);
left0 = [0.035 0.355 0.675];
groupw = 0.285;
top = 0.84;
bottom = 0.10;
gap = 0.004;
tilew = (groupw - 3*gap) / 4;
tileh = (top - bottom - 3*gap) / 4;

for g = 1:3
  annotation(fig, 'textbox', [left0(g) 0.91 groupw 0.05], ...
    'String', titles{g}, 'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none', 'FontWeight', 'bold', 'FontSize', 13, ...
    'Color', colors{g}, 'Interpreter', 'none');
  annotation(fig, 'textbox', [left0(g) 0.865 groupw 0.035], ...
    'String', 'Phase source', 'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none', 'FontWeight', 'bold', 'FontSize', 9);
  for row = 1:4
    for col = 1:4
      xpos = left0(g) + (col-1)*(tilew+gap);
      ypos = top - row*tileh - (row-1)*gap;
      ax = axes('Parent', fig, 'Position', [xpos ypos tilew tileh]);
      % EEGmmi{phase_source, amplitude_source}; the visual grid uses
      % amplitude sources as rows and phase sources as columns.
      map = tensors{g}{col,row};
      if isequal(size(map), [48 24]), map = map'; end
      imagesc(ax, phasefreq, ampfreq, map);
      axis(ax, 'xy'); caxis(ax, [0 cmax]);
      set(ax, 'XScale', 'log', 'YScale', 'log', 'FontSize', 6, ...
        'TickLength', [0.02 0.02], 'Box', 'on');
      if row == 4
        set(ax, 'XTick', [2 5 10], 'XTickLabel', {'2','5','10'});
      else
        set(ax, 'XTickLabel', {});
      end
      if col == 1
        set(ax, 'YTick', [25 50 100 150], 'YTickLabel', {'25','50','100','150'});
      else
        set(ax, 'YTickLabel', {});
      end
      if row == 1, title(ax, sprintf('k%d', col), 'FontSize', 8); end
      if col == 1
        ylabel(ax, sprintf('k%d', row), 'FontWeight', 'bold', 'Rotation', 0, ...
          'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
      end
      if (row == 3 && col == 1) || (row == 4 && col == 2)
        set(ax, 'LineWidth', 1.5, 'XColor', [0.9 0.15 0.1], 'YColor', [0.9 0.15 0.1]);
      end
    end
  end
end
colormap(fig, parula(256));
annotation(fig, 'textbox', [0.004 0.34 0.02 0.30], 'String', 'Amplitude source', ...
  'Rotation', 90, 'HorizontalAlignment', 'center', 'EdgeColor', 'none', ...
  'FontWeight', 'bold', 'FontSize', 9);
cbax = axes('Parent', fig, 'Position', [0.975 bottom 0.008 top-bottom], 'Visible', 'off');
caxis(cbax, [0 cmax]);
cb = colorbar(cbax, 'Position', [0.978 bottom 0.008 top-bottom]);
cb.Label.String = 'Modulation index';
cb.FontSize = 7;

pngfile = fullfile(cfg.output_dir, 'pac_recovery_zm09.png');
print(fig, '-dpng', '-r180', pngfile);
close(fig);
fprintf('Created %s\n', pngfile);
end
