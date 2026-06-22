% sortcomps() Sorts EEG components according to specified criteria.
%
% sortcomps()
% SORTCOMPS Sorts EEG components according to specified criteria.
% ref. http://emsica.art/emsica/sortcomps
%
% This function is designed to sort EEG components, specifically tailored
% for use in EMSICA analysis workflows. It supports various sorting methods
% and allows for customization through multiple optional parameters.
%
% Usage:
%   sortcomps(s, EEG, 'ParameterName', ParameterValue, ...)
%
% Example 1: sort 6emsica/gradient-I/ components based on 3ica/ICs components.
% s= 'zm01';
% sortcomps(s,[], 'emsicafolder','6emsica/gradient-I/', 'features', {'topo67x67'})
% sortcomps()>get_similarity()>get_topo():105: ~/1_zen/zm01/3ica/ICs/EEG_topo67x67.mat is loaded.
% sortcomps()>get_similarity()>get_topo():100: ~/1_zen/zm01/6emsica/gradient-I/EEG_topo67x67.mat saved.
% ~/1_zen/zm01/6emsica/gradient-I/sortcomps-aligning_with_3ica_ICs_components_by_topo67x67.png is printed.
%
% sortcomps():186: ~/1_zen/zm01/6emsica/gradient-I/B.mat is saved for plot_b() to plot B.
% sortcomps():219: ~/1_zen/zm01/6emsica/gradient-I/zm01.set is saved.
%
% Other Examples:
%   s = 'zm03'
%   sortcomps(s, [], 'emsicafolder', '6emsica/ICsR01/', 'features', {'topomi'}, 'method', '3ica/ICs/');
%     % Outputs: ~/1_zen/zm03/6emsica/ICsR01/sortcomps-aligning_with_3ica_ICs_components_by_topomi.png
%
%   sortcomps('zm03', [], 'emsicafolder', '6emsica/ICsR01/', 'features', {'topo67x67'}, 'method', '3ica/ICs');
%     % Outputs: ~/1_zen/zm03/6emsica/ICsR01/sortcomps-aligning_with_3ica_ICs_components_by_topo67x67.png
%
%   sortcomps(s, [], 'emsicafolder', 'B0');
%
% Inputs:
%   s - A string specifying the subject or session identifier.
%   EEG - An EEG structure as defined in the EEGLAB toolbox. If empty,
%         the function attempts to load an EEG dataset based on 's' and
%         other parameters.
%
% Parameter-Value pairs:
%   'features' - A cell array of strings specifying features to be used
%                for sorting. Supported features include 'topomi',
%                'topo67x67', 'spec', and 'topo11'.
%   'weightings' - A vector of real numbers representing the weighting
%                  applied to each feature during sorting. Defaults to
%                  [.5 .4 .1 .0].
%   'emsicafolder' - A string indicating the analysis emsicafolder, such as 'ica' or
%             'emsica'. Default is 'emsica'.
%   'method' - A string specifying the sorting method.
%              'compvar': for component variance and 
%              '3ica/ICs/': for sorting based on 3ica/ICs components alignment.
%              '6emsica/ICsR01-I/': for sorting based on 6emsica/ICsR01-I/ components alignment.
%
% Outputs:
%   The function does not return values but
%   load EEG dataset and sort components and save them back to EEG datasets.
%   Also, generate a PNG file for visualizing the sorted components.
%
% Notes:
%   - The function was originally part of `runemsica_by_sphx.m` and is
%     now called in emsica_(). See, `emsica_()>sortcomps()`.
%
% History:
%   2023-05-22 - Created by Arthur & Rkffabcd.
%   2024-03-14 - Major revised
%
% See also EEGLAB, POP_LOADSET

% History: 
% 2023-05-22 arthur & rkffabcd
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [EEG, alignedcompcorr] = sortcomps(s, EEG, varargin)
defaultsetting = {...
  % name          type       range     default
  'features',     'cell',    '',       {'topomi','topo67x67','spec','topo11'} ;...%topo67x67,topo11,spec
  'weightings',   'real',    '',       [.5 .4 .1 .0]  ;...
  'emsicafolder', 'string',  [],       '6emsica/ICsR01-I';... % ica | emsica
  'method',       'string',  [],       '3ica/ICs/';... % 3ica/ICs/ | '6emsica/ICsR01-I' | meanvar | off
  };

[g, s] = gparser(s, varargin, defaultsetting); ff = fieldnames(g);
for i = 1:length(ff), eval([ff{i} '=getfield(g,''' ff{i}  ''');']); end % flatten parameters

allowed_features = {'topomi','topo67x67','spec','topo11','b','bmat'};
if any(~ismember(features, allowed_features))
  mdisp('red', ['sortcomps(): unsupported feature(s): ' mat2str(features)]);
  keyboard
end

cd(workingdir);
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

% ==== put log ====
% logfid = fopen([workingdir 'log.txt'],'w');
% logprintf(logfid,'-------------------------------\n %s %s\n------------------------------\n\n',['::' mfilename() ':'], datestr(now, 'mmm dd, yyyy | HH:MM:SS'));
% logprintf(logfid,'s.emsica.icatype=%s\n',s.emsica.icatype);
% % logprintf(logfid,'s.emsica.lrate=%g\n',s.emsica.lrate);
% % logprintf(logfid,'s.emsica.stop=%g\n',s.emsica.stop);
% logprintf(logfid,'s.emsica.maxsteps=%s\n',num2str(s.emsica.maxsteps));
% % logprintf(logfid,'s.emsica.annealstep=%f\n',s.emsica.annealstep);
% logprintf(logfid,'s.emsica.annealdeg=%s\n',num2str(s.emsica.annealdeg));
% % logprintf(logfid,'s.emsica.mybeta=%f\n',s.emsica.mybeta);
% % logprintf(logfid,'s.emsica.myalpha=%f\n',s.emsica.myalpha);
% logprintf(logfid,'s.emsica.run_likelihood=%s\n',num2str(s.emsica.run_likelihood));
% % keyboard;

%% =============================
%% load EEG
%% =============================
if isempty(EEG)
    setfile=[s.workingdir s.dataset];
    mdisp(['loading ' setfile ' by pop_loadset()...']);
    EEG = pop_loadset(setfile);
end

% note you have saved:
% EEG.data = reshape(x_clean, I, EEG.pnts, EEG.trials); % x_clean
% in get_LB0A0_by_sphx.m
% x_clean = double(reshape(EEG.data, [EEG.nbchan EEG.trials * EEG.pnts]));
% sph = EEG.icasphere;
% Xtilde=sph*x_clean;

file_B_mat=[workingdir 'B.mat'];
if exist(file_B_mat, 'file')
  disp(' ');
  mdisp(['loading ' file_B_mat ' so B.mat columns can be sorted with EEG components ...']);
  load(file_B_mat,'B');
elseif contains(features, 'b') || contains(features,'bmat')
  disp(' ');
  mdisp('red', ['sortcomps(): requested B feature but cannot find ' file_B_mat]);
end

A = EEG.icawinv;
sph = EEG.icasphere;
w = EEG.icaweights; % KxK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% sorting emsica components method 1: mean varance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
K=size(A,2);
windex = 1:K;
EEG = eeg_checkicaact(EEG);
S = EEG.icaact;
S = reshape(S, K, []);
if strcmp(method, 'meanvar')
  meanvar = sum(A .^ 2) .* sum(S' .^ 2) / (K-1)^2;
  [~, windex] = sort(meanvar, 'descend');
  %logprintf(logfid,'EMSICA components are sorted.\n');

  w = w(windex,:);
  A = A(:,windex);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% sorting emsica components method 2: align with 3ica/ICs components           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if contains(method,'ica') || contains(method,'synth') % eg. 2epochs/EPs-synth, 3ica/ICs/, 6emsica/ICsR01-I/
    if ~strcmp(method(end),'/'), method = [method, '/']; end % make sure method, eg. 3ica/ICs/ end with '/'

    % Use get_similarity() to sort emsica components according to 3ica/ICs/ components.
    mdisp('yellow',['Use get_similarity() to sort emsica components according to ' method ' components.']);

    setfile=[s.subjectdir method s.dataset];
    mdisp(['loading ' setfile ' ...']);
    ALLEEG(1) = pop_loadset(setfile);


    ALLEEG(1).subject=s.subject;
    ALLEEG(2).subject=s.subject;

    ALLEEG(2)=ALLEEG(1);
    ALLEEG(2).filepath = workingdir;
    ALLEEG(2).icaweights = w; % KxK
    ALLEEG(2).icawinv = A; % == AB*a; % IxK
    ALLEEG(2).icasphere = sph;
    ALLEEG(2).chanlocs = EEG.chanlocs;
    if isfield(EEG, 'chaninfo')
      ALLEEG(2).chaninfo = EEG.chaninfo;
    end
    ALLEEG(2).icachansind = EEG.icachansind;
    % Note: shp == WB in WB x_clean = uB = WB LBs
    %       shp == sph in sph x_clean = sph LBs

    % EEG.icaact     = reshape(S, K, EEG.pnts, EEG.trials); % S
    ALLEEG(2).K=K; % number of EMSICA components

    for i=1:2
      if length(ALLEEG(i).icachansind) ~= size(ALLEEG(i).icawinv,1)
        mdisp('red','Error! length(EEG.icachansind) ~= size(EEG.icawinv,1)');
        keyboard;
      end
    end

    disp(' ');
    % waiting for repair 2021-10-17
    %features = {'topo11','topo67x67','spec'};
    %features = {'topo67x67','spec'};
    %features = {'topo67x67'};
    %features = {'topomi'}; %, 'topo67x67'};
    [similarity, index]=get_similarity([], 'EEG', ALLEEG, 'features',features, 'recompute','on', 'emsicafolder',emsicafolder);

    % keyboard
    % kkk = sum(index(:,1)==2); % ==K
    % windex = zeros(1,kkk);
    windex = zeros(1,K);
    m = similarity(index(:,1)==1,:);
    m = m(:,index(:,1)==2);
    m = abs(m);
    m0 = m;
    alignedcompcorr = zeros(1,K);
    used_cols = false(1, size(m,2));

    % Greedy one-to-one assignment by row order. If a row has no remaining
    % positive match, fall back to the best unused column globally.
    for idx = 1:size(m,1)
      scores = m(idx,:);
      scores(used_cols) = -inf;
      [best_score, best_col] = max(scores);

      if ~isfinite(best_score) || best_score <= 0
        remaining_cols = find(~used_cols);
        if isempty(remaining_cols)
          break
        end
        [~, rem_idx] = max(max(m0(:, remaining_cols), [], 1));
        best_col = remaining_cols(rem_idx);
        best_score = m0(idx, best_col);
      end

      windex(idx) = best_col;
      alignedcompcorr(idx) = best_score;
      used_cols(best_col) = true;
    end

    %     % sort by similarity
    %     for idx = 1:sum(index(:,1)==2)
    %         [x,y]=find(m==max(m(:)));
    %         windex(x) = y;
    %         m(:,y) = 0;
    %     end

    %     % sort by similarity
    %     %for idx = 1:sum(index(:,1)==2)
    %     [x, y] = find(m == max(m(:)));
    %     for idx = 1:K
    %       windex(x(1)) = y(1);  % Update the first occurrence of x with the corresponding y
    %       m(x(1), :) = 0;  % Set the row to 0 to avoid reselecting it in the next iteration
    %     end


    % Fill any still-unassigned positions with unused valid indices.
    valid_indices = 1:size(w, 1);
    missing_index = setdiff(valid_indices, windex(windex >= 1));
    invalid_index_loc = find(windex < 1 | windex > size(w,1));
    if ~isempty(invalid_index_loc)
      nfill = min(numel(invalid_index_loc), numel(missing_index));
      windex(invalid_index_loc(1:nfill)) = missing_index(1:nfill);
    end

mdisp('yellow', ['sortcomps(): windex = ' mat2str(windex)]);
mdisp('yellow', ['sortcomps(): unique(windex) = ' mat2str(unique(windex))]);
mdisp('yellow', ['sortcomps(): numel(unique(windex)) = ' num2str(numel(unique(windex))) ', K = ' num2str(K)]);



    % BACKUP 2026-03-11
    % % keyboard;
    % w = w(windex, :);
    % A = A(:,windex);
    % mdisp('yellow', ['w and A are sorted and will be saved in ' s.subject '.set']);
    % figure;
    % kkk = min(size(A,2),15); % plot only <=15 components to see whether the sortcomps() works or not
    % for k=1:size(ALLEEG(1).icawinv,2)
    %   subplot(2,kkk,k);
    %   topoplot(ALLEEG(1).icawinv(:,k), ALLEEG(1).chanlocs(ALLEEG(1).icachansind),'electrodes','off');
    %   title(num2str(k));
    %   subplot(2,kkk,kkk+k);
    %   topoplot(A(:,k), ALLEEG(2).chanlocs(ALLEEG(2).icachansind),'electrodes','off');
    %   % title(['orig ' num2str(windex(k))]);
    %   title(num2str(windex(k)));
    % end
    % filename = [workingdir 'sortcomps-aligning_with_3ica_ICs_components_by_' features{1} '.png'];
    % print('-dpng',filename);
    % mdisp('yellow',[filename ' is printed.']);






    % keyboard;
    w = w(windex, :);
    A = A(:,windex);
    mdisp('yellow', ['w and A are sorted and will be saved in ' s.subject '.set']);
    fig_sort = figure('visible','on');
    set(fig_sort, 'Color', [0.92 0.96 1.00], 'InvertHardCopy', 'off');
    set(fig_sort, 'Position', [100 100 1000 700]);
    kkk = min(length(windex),15); % plot only <=15 components to see whether the sortcomps() works or not
    method_label = strrep(method, '\', '/');
    emsicafolder_label = strrep(emsicafolder, '\', '/');
    if ~isempty(method_label) && method_label(end) ~= '/', method_label = [method_label '/']; end
    if ~isempty(emsicafolder_label) && emsicafolder_label(end) ~= '/', emsicafolder_label = [emsicafolder_label '/']; end
    label_color = [0.18 0.18 0.18];
    label_font_size = 14;
    if length(emsicafolder_label) > 48
      label_font_size = 12;
    end
    annotation(fig_sort, 'textbox', [0.000 0.945 1.000 0.040], 'String', s.subject, ...
      'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'EdgeColor', 'none', ...
      'Interpreter', 'none', 'Color', label_color, 'FontWeight', 'bold', 'FontSize', 16);
    annotation(fig_sort, 'textbox', [0.080 0.842 0.840 0.035], 'String', method_label, ...
      'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'EdgeColor', 'none', ...
      'Interpreter', 'none', 'Color', label_color, 'FontWeight', 'bold', 'FontSize', label_font_size);
    annotation(fig_sort, 'textbox', [0.080 0.432 0.840 0.035], 'String', emsicafolder_label, ...
      'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'EdgeColor', 'none', ...
      'Interpreter', 'none', 'Color', label_color, 'FontWeight', 'bold', 'FontSize', label_font_size);
    left_margin = 0.080;
    total_w = 0.840;
    col_w = total_w / max(kkk, 1);
    ax_w = min(0.145, col_w * 0.74);
    ax_h = 0.220;
    top_y = 0.600;
    bottom_y = 0.190;
    for k=1:kkk
        ax_x = left_margin + (k - 1) * col_w + 0.5 * (col_w - ax_w);
        if size(ALLEEG(1).icawinv,2)>=k
      ax_top = axes('Parent', fig_sort, 'Position', [ax_x top_y ax_w ax_h]);
      topoplot(ALLEEG(1).icawinv(:,k), ALLEEG(1).chanlocs(ALLEEG(1).icachansind),'electrodes','off');
      title(ax_top, num2str(k), 'FontSize', 9, 'FontWeight', 'bold');
        end
        if  size(ALLEEG(2).icawinv,2)>=k
      ax_bottom = axes('Parent', fig_sort, 'Position', [ax_x bottom_y ax_w ax_h]);
      topoplot(A(:,k), EEG.chanlocs(EEG.icachansind),'electrodes','off');
      % title(['orig ' num2str(windex(k))]);
      title(ax_bottom, num2str(windex(k)), 'FontSize', 9, 'FontWeight', 'bold');
        end
    end
    filename = [workingdir 'sortcomps-aligning_with_3ica_ICs_components_by_' features{1} '.png'];
    print(fig_sort, '-dpng', '-r300', filename);
    mdisp('yellow',[filename ' is printed.']);
    % keyboard
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save B
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('B','var')
  if isnumeric(B) || islogical(B)
    B = B(:,windex);
  elseif isstruct(B)
    b_fields = fieldnames(B);
    for bb = 1:numel(b_fields)
      fname = b_fields{bb};
      if isnumeric(B.(fname)) || islogical(B.(fname))
        if ndims(B.(fname)) == 2 && size(B.(fname), 2) >= max(windex)
          B.(fname) = B.(fname)(:,windex);
        end
      end
    end
  else
    mdisp('red', ['sortcomps(): unsupported B.mat variable class ' class(B) '; B was not sorted.']);
  end
  mdisp('yellow', ['B is sorted.']);
  EEG.B = B;
  save(file_B_mat,'B','w');
  mdisp('yellow', [file_B_mat ' is saved for plot_b() to plot B.']);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save EEG for futhur plotting purpose
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2021-07-7 Note 
% 1. Since 
%    WB ~ sph in runemsica_by_sphx.m
%    AB ~ sphinv in runemsica_by_sphx.m 
%    Here we use sph from quasi-sphering
% 2. activation source, s, 
%    EEG.icaact = (EEG.icaweights*EEG.icasphere)*EEG.data;
%
%    s should be the same as what it really working in EMSICA
%                 s = w * Xtilde
%    the activation source:  
%                 s = Wx 
%            icaact = (icaweights * icasphere) * data
%                 s = (w *           sph       ) * x_clean;
%     where w is returned by gradientemsica() w == pinv(a); a=Ltilde*Btilde;
%EEG=EEG(2);
if contains(workingdir,'6emsica') && isfield(EEG,'A0') % when calling sortcomps from emsica_(s, 'emsicatype',B0) > sortcomps() 2025-01-29 arthur
  A0=EEG.A0;
  A0 = A0(:,windex);
  EEG.A0 = A0;
end
if isfield(EEG,'A0_from_infomax') && ~isempty(EEG.A0_from_infomax) && ...
    size(EEG.A0_from_infomax, 2) >= max(windex)
  EEG.A0_from_infomax = EEG.A0_from_infomax(:,windex);
end

EEG.icaweights = w; % KxK
EEG.icawinv = A; % == AB*a; % IxK
EEG.icasphere = sph; 
% Note: shp == WB in WB x_clean = uB = WB LBs 
%       shp == sph in sph x_clean = sph LBs

% EEG.icaact     = reshape(S, K, EEG.pnts, EEG.trials); % S
EEG.K=K; % number of EMSICA components

cd(workingdir);
pop_saveset(EEG, 'filename', s.dataset, 'filepath', workingdir);
mdisp('yellow', [workingdir s.dataset ' is saved.']);

EEG = eeg_checkicaact(EEG, 1); % recompute =1 to recompute EEG icaact since icaweights has beeen sorted
