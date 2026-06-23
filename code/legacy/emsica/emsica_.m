% emsica_() setting
%
% emsica_()e
%  Usages:
%  eg.
%  emsica_('o30', 'emsicatype', 'B0', 'emsicafolder', '3ica/1channels_sphinv/'); <-- old stuff think about what is this?!
%  emsica_('o30', 'emsicatype', 'B0', 'emsicafolder', '6emsica/B0_partialplot/');
%
% Example 1
%  emsica_('tb16', 'emsicatype', 'gradient'); % it will work on 6emsica/gradient/

% Example 2
%  emsica_('tb16', 'emsicafolder', '6emsica/gradient-test1/'); % it will work on 6emsica/gradient-test1/ and assume your emsicatype == 'gradient'
% s='zm01';
% emsica_(s, 'emsicatype', 'bypass', 'emsicafolder', '6emsica/gradient-cyto/'); % to plot all figures again in 6emsica/gradient/

% emsica_(s, 'emsicatype', 'bypass', 'emsicafolder', '6emsica/gradient-cyto/'); % to plot all figures again in 6emsica/gradient/
% emsica_(s, 'emsicatype', 'bypass', 'emsicafolder', '6emsica/gradient-cyto/'); % to plot all figures again in 6emsica/gradient/

% Example 3
% s='zm01';
% emsica_(s, 'emsicatype', 'bypass', 'emsicafolder', '6emsica/gradient-cyto/'); % to plot all figures again in 6emsica/gradient/

% emsica_(s, 'emsicatype', 'bypass', 'emsicafolder', '6emsica/gradient-cyto/'); % to plot all figures again in 6emsica/gradient/
% emsica_(s, 'emsicatype', 'bypass', 'emsicafolder', '6emsica/gradient-cyto/'); % to plot all figures again in 6emsica/gradient/

% note that:
% you can just asign  'emsicafolder', '6emsica/gradient-cyto/'
% this program will help you asign emsicatype as gradient and lapmethod as cyto

% emsicatype:
%    'gradient':run gradient emsica and save results in gradient directory
%    'fastemsica': default emsicafolder
%    'bypass': if 'bypass', skip running emsica.  2013-06-18 in Seattle, -arthur
%    'B0': show emsica initial conditions B0 in B0 directory

%  emsica_('tb16', 'mrrpd', onoff);
% mrrpd:
%   'off': default
%   'on': run multi-realization reproducibility emsica and save results in ICsR01, ICsR02, ...
% This will also run emsica_('tb16') at first in case you didn't have ICs directory
%
% Author:
% Arthur 2011 arthur@stat.sinica.edu.tw
%
% 2004 arthur initiate emsica matlab algorithm
% 2011-10-10 arthur complete the fastemsica
% 2010-10-18 arthur, multi-realization 
% 2023-05-23 major revision by arthur, 
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function emsica_(s, varargin)
  defaultsetting = {...
    ... % name       type       range  default
    'emsicafolder',  'string',  [],    '';... % '6emsica/gradient-cyto'
    'emsicatype',    'string',  [],    '';... % '' | gradient (recommanded) | fastemsica | bypass | B0
    'B0method',      'string',  [],    'Source-space_ICA';... % 'psudo-inv' | 'minimum-norm' | 'sLORETA' | 'Source-space_ICA' | 'infomax' | 'fastica'
    'lapmethod',     'string',  [],    '';... % '' | 'cyto' | 'lhrh' | 'I'; % see gparser() for more detail
    'mrrpd',         'string',  [],    'off';...
    'nRealizations', 'real',    [],    25;...
    'visible',       'string',  [],    'off';...
    'plots',         'string',  [],    'on';...
    'recompute',     'string',  [],    'off';...
    'K',             'real',    [],    0;... % default: 0 
    'ith',                 'real',   [],   1;... % ith block. this parameter is for get_LB0A0_by_sphx_source_space()
    'synth_truth_folder', 'string', [], '2epochs/EPs-synth/';...
    % K here ==0 means the number of components will be calculated according to idx_manually.txt later
    };

[g, s] = gparser(s, varargin, defaultsetting); ff = fieldnames(g);
for i = 1:length(ff), eval([ff{i} '=getfield(g,''' ff{i}  ''');']); end % flatten parameters
synth_truth_folder = normalize_folder_local(synth_truth_folder);
s.synth_truth_folder = synth_truth_folder;

% note you can just asign emsicafolder, lapmethod is not necessary 
% gparser will extract lapmethod from emsicafolder

if ~strcmp(emsicatype,'bypass') && exist(workingdir, 'dir')
  % backup previous EMSICA results
  % backupfolder(workingdir);
  % myrm(workingdir); % just remove it to save space 2024-11-5 arthur
  % Change to the working directory
  cd(workingdir);

  % Check if B.mat and comp_001b.png exist
  if isfile('B.mat') && isfile('comp_001b.png') && ~recompute
    % keyboard
    mdisp(['B.mat and comp_001b.png are found in: ' workingdir ' skip.']);
    return; % Skip to the next iteration
  end
end

mymd(workingdir); cd(workingdir); 
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

% ==== put log ====
if exist([s.cleanDir 'log.txt'],'file')
  copyfile([s.cleanDir 'log.txt'],[s.icaDir 'log.txt']);
end

s.logfid = fopen([s.emsicaDir 'log.txt'],'a');
[~, username] = system('whoami'); username=strtrim(username); % to erase newline character from string
logprintf(s.logfid,'------------------------------------------------------\n %s %s run by %s\n------------------------------------------------------\n\n','emsica_()',datestr(now,'mmmm dd, yyyy HH:MM:SS'),username);

%s.emsica.lrate=1e-3; % h01 use 1e-3, h02 use 1e-4;
%s.emsica.stop=1e-9; % default: 1.0e-7
%s.emsica.myalpha = 10; % default: 20
% s.emsica.maxsteps=4; % for debugging; 480
% s.emsica.maxsteps=2; %just for debugging purpose!!

if strcmp(emsicatype,'B0') 

  if contains(emsicafolder, 'synth') % 2025-11-18 for simulation study
    if strcmpi(B0method, 'infomax') || strcmpi(B0method, 'fastica')
      ica_input_folder = '';
      if isfield(s, 'emsica') && isstruct(s.emsica) && ...
          isfield(s.emsica, 'ica_input_folder') && ~isempty(s.emsica.ica_input_folder)
        ica_input_folder = s.emsica.ica_input_folder;
      end
      EEG = get_LB0A0_by_ica(s, 'emsicafolder',emsicafolder, ...
        'lapmethod',lapmethod, 'B0method',B0method, 'K',K, ...
        'ica_input_folder',ica_input_folder);
    else
      EEG = get_LB0A0_by_sphx_source_space(s, 'emsicafolder',emsicafolder, 'lapmethod',lapmethod, 'B0method',B0method, 'K',K); % new, use source space ICA to estimate B0
    end
  else % old use A0=I as initial condition
    EEG = get_LB0A0_by_sphx(s, 'emsicafolder',emsicafolder, 'lapmethod',lapmethod, 'B0method',B0method, 'K',K);
  end

end % if emsicatype='B0'

if ismember(emsicatype, {'gradient', 'fastemsica', 'bypass'})
  % Load the EEG dataset in B0 folder
  % ~/1_zen/zm01/6emsica/B0-lhrh/zm01.set
  % old to be deleted... B0set = [s.subjectdir '6emsica/B0-' lapmethod '/' s.dataset];

  % The following is to find B0set filepath
  % It works whether you have:
  % emsicafolder   B0set
  % -------------  -----------------------
  % 'ICs-synth/' → 'B0-synth/zm01.set'
  % 'ICsR01-synth/' → 'B0-synth/zm01.set'
  % 'ICs-lhrh/' → 'B0-lhrh/zm01.set'

  % Prefer an explicitly requested B0 folder when provided by the caller.
  if isfield(s, 'emsica') && isstruct(s.emsica) && ...
      isfield(s.emsica, 'b0folder') && ~isempty(s.emsica.b0folder)
    explicitB0folder = char(string(s.emsica.b0folder));
    if ~endsWith(explicitB0folder, '/')
      explicitB0folder = [explicitB0folder '/'];
    end
    if startsWith(explicitB0folder, s.subjectdir)
      B0set = [explicitB0folder s.dataset];
    else
      B0set = [s.subjectdir explicitB0folder s.dataset];
    end
  else
    % Extract folder name only (e.g., 'ICs-synth') from emsicafolder (eg. 6emsica/ICs-synth/)
    [folderpath, foldername] = fileparts(emsicafolder(1:end-1)); % remove trailing '/'

    % Replace prefix before '-' with 'B0'.
    % For simulation folders like:
    %   ICs-synth-infomax-extended
    %   ICs-synth-infomax-conventional
    % we must keep the B0 initializer folder unsuffixed:
    %   B0-synth-infomax
    if startsWith(foldername, 'ICs-synth-')
      newfoldername = regexprep(foldername, '-(extended|conventional)$', '');
      newfoldername = regexprep(newfoldername, '^ICs', 'B0');
    else
      newfoldername = regexprep(foldername, '^[^-/]+', 'B0');
    end

    % Construct B0set path
    B0set = [s.subjectdir folderpath '/' newfoldername '/' s.dataset];
  end

  mdisp('yellow', ['loading ' B0set]);

  EEG0 = pop_loadset(B0set);

  if strcmp(lapmethod, 'I')
    EEG0.invC = speye(size(EEG0.invC)); % If you just use eye() rahter than speye, emsica_() learning takes time because memory demenanded hugely.
  end
  EEG = runemsica_by_sphx(s, EEG0, 'emsicatype',emsicatype, 'emsicafolder',emsicafolder);
end
% if emsicatype=='bypass', skip running emsica but 
% read 6emsica/gradient/Btilde.mat the do the following steps to plot a lot of figures
% 2013-06-18 in Seattle, arthur: 

% The public package has one fixed four-source synthetic comparison. Align
% directly by B.mat rather than the generic topology/clustering stack.
if contains(emsicafolder, 'synth')
  [EEG, alignedcompcorr] = align_synth_components(s, EEG, synth_truth_folder);
  msg = [':: ' s.subject ' :: In the ' emsicatype ...
    ' stage, aligned spatial correlations == ' ...
    num2str(alignedcompcorr) ', \nand sum(corr)==' ...
    num2str(sum(alignedcompcorr)) newline newline];
  mdisp('yellow', msg);
end
% keyboard
if strcmp(plots,'off')
  return
end

%% =========================================================
%% run lfmsens2chanlocs() and check A0=sphinv before and after
%% =========================================================
% to plot something like get_LB0A0_sphx_clean(): ~/1_zen/zm01/6emsica/B0-cyto/lfmsens2chanlocs_051a.png is printed.
% See wiki- http://emsica.art/emsica/lfmsens2chanlocs

%% check A0=sphinv before and after lfmsens2chanlocs()
if strcmp(emsicatype,'B0')
  % 2025-01-30 before, this code segment is in get_LB0A0_by_sphx()
  % now, I move it here. it runs after sortcomps()

  A0 = EEG.A0; % saved in get_LB0A0_by_sphx() A0 == sphinv initial for ICA, also initial for EMSICA to calculate B0
  A  = EEG.icawinv; % saved in get_LB0A0_by_sphx(), after calculated B0, A is obtained by A = LB0
  K = size(A0,2);

  % Note: this code segment has been moved to emsica_()
  % Note the column order of A0 in emsica_() is different, because of emsica_()>sortcomps()

  % Before lfmsens2chanlocs()
  chanlocs1 = EEG.chanlocs(EEG.icachansind);

  % Use lfm.sens which is obtained from coregister_(s);
  [EEG, ~]=lfmsens2chanlocs(s, EEG);

  % After lfmsens2chanlocs()
  chanlocs2 = EEG.chanlocs(EEG.icachansind);

  mdisp(['EEG.chanlocs is transforming by lfmsens2chanlocs()...']);
  EEG.chanlocs = chanlocs2;

  h=figure('name','A0-lfmsens2chanlocs()-@emsica_()'); 
  for k=1:K
    title(['A0(:,' num2str(k) ') = sphinv(:,' num2str(k) ')']); axis off;
    sbplot(1,3,1); title('before lfmsens2chanlocs()');
    topoplot(A0(:,k), chanlocs1); % for sph x_clean = sph LBs

    % check before and after lfmsens2chanlocs()
    sbplot(1,3,2); title('after lfmsens2chanlocs()');
    topoplot(A0(:,k), chanlocs2); % for sph x_clean = sph LBs

    sbplot(1,3,3); %title(['backprojected after ' B0method]);
    title(['A(:,' num2str(k) ')']); axis off;
    % axis off except xlabel
    ax=gca;
    axis(ax,'off');
    xlabel(ax, ['backprojected A0=LB0 after ' B0method]);
    ax.XLabel.Visible = 'on';

    topoplot(A(:,k), chanlocs2);
    filelfmsens2chanlocspng=[workingdir 'lfmsens2chanlocs_' num2str(k,'%.3d') 'a.png'];
    print('-dpng',filelfmsens2chanlocspng);

    % emsica_(): ~/1_zen/zm01/6emsica/B0-cyto/lfmsens2chanlocs_051a.png is printed.
    % 2...3...4...5...6...7...8...9...10...11...12...13...14...15...
      if k==1, mdisp([s.subject '-- print ' filelfmsens2chanlocspng  ' 1/' num2str(K)]); end; 
      printing(k);
    clf;
  end % for k for plot
  % keyboard
  pop_saveset(EEG, 'filename', s.dataset, 'filepath', workingdir);
  % the EEG is the same as the output of get_LB0A0_by_sphx() but EEG.chanlocs  is replaced by 
  mdisp([workingdir s.dataset ' is saved.']);
end

%% splitset for further plotting
splitset(s, 'emsicafolder', emsicafolder);
%get_bfeatures(s); % to generate (h01).emsicab

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% make subject-ongoingeeg.set
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if s.ongoingeeg % && ~contains(emsicafolder, 'synth') % skip this step for simulation study 2025-10-18
    % replace EEG.icaact and EEG.data with data in 1channels/CHs/xxx-ongoingeeg.set
    % EEG = pop_loadset([workingdir, s.dataset]);
    if contains(emsicafolder, 'synth') % there is a similar code in ica_.m
        EEGtmp = EEG;
        EEGtmp.data = EEGtmp.data(EEG.icachansind,:);
        EEGtmp.trials = 1;
        EEGtmp = rmfield(EEGtmp,'epoch');
        EEGtmp.icaact = [];
        EEGtmp.pnts = length(EEGtmp.data);
    else
        EEGtmp = channels_ongoingeeg(s);%% ongoing eeg
        EEGtmp.data = EEGtmp.data(EEG.icachansind_orig,:); % note previous get_LB0A0_by_sphx() or runemsica_by_sphx() has done EEG.data(EEG.icachansind_orig,:);
        % 2025-11-28 todo: check maybe EEG.icachansind_orig == EEG.icachansind
    end
    EEGtmp.chanlocs = EEG.chanlocs;
    EEGtmp.nbchan = EEG.nbchan;
    EEGtmp.icawinv=EEG.icawinv;
    EEGtmp.icasphere=EEG.icasphere;
    EEGtmp.icaweights=EEG.icaweights;
    EEGtmp.icachansind=EEG.icachansind;
    EEGtmp.chans=EEG.chans;
    EEG2=eeg_checkset(EEGtmp);
    %logprintf(logfid,'\n[Save set]\n');
    pop_saveset(EEG2, 'filename',[s.subject, '-ongoingeeg.set'], 'filepath',workingdir);
    % logprintf(logfid,'Dataset saved as %s\n\n', [s.workingdir, s.subject, '-ongoingeeg.set']);
    % keyboard
end
%return %% tentative do this for debugging

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot figures
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if 1 % disable it tentatively for testing 2025-03-9
if strcmp(emsicatype,'B0')
  %plot_asersp(s,'scalpmaponly','on', 'index', []);
elseif s.ongoingeeg
  plot_ersp_ongoingeeg3(s, 'emsicafolder',emsicafolder);
else
  % plot_a_enlarge(s, 'emsicafolder','emsica'); % good! to generate /ICs-a/
  plot_ersp(s, 'emsicafolder',emsicafolder); % plot_asersp('o08','index',[1],'freqscale','log') % use log scale
  deartifacts(s, 'emsicafolder', emsicafoleder, 'visible', visible); % artifact removal
end
end

% the most quickest plotting setting:
onavgbrain = 0; % plot on individual brain
reducemesh = 1; % use reducemesh mesh to save time
plot_b(s,'emsicafolder',emsicafolder, 'onavgbrain', onavgbrain,'reducemesh', reducemesh); 

%% as, ersp
if ~contains(emsicafolder, 'synth') % skip since we have only 2 trials
plot_as(s, 'emsicafolder',emsicafolder); % todo: the scalp is strange
%plot_electrodeatlas(s); % not necessary now, because this has been done in plot_as() to get a precisely conrrespond position for comp_*as.png and comp_electrodes?.png
end

% sort components to align with 3ica/ICs/ 
if contains(emsicafolder, 'synth') % skip this step for simulation study 2025-10-18
  % mdisp('yellow', [s.subject ': In the ' emsicatype ' stage, after sortcomps(), the aligned comps corr = ' num2str(alignedcompcorr) ', and sum(corr)=' num2str(sum(alignedcompcorr))]);
  logfid = fopen('performance.txt', 'w');
  % Build message with timestamp
  timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
  msg = [timestamp ' | ' s.subject ': In the ' emsicatype ...
    ' stage, after sortcomps(), the aligned comps corr = ' ...
    num2str(alignedcompcorr) ', and sum(corr)=' ...
    num2str(sum(alignedcompcorr)) newline newline];

  % msg = [s.subject ': In the ' emsicatype ' stage, after sortcomps(), the aligned comps corr = ' num2str(alignedcompcorr) ', and sum(corr)=' num2str(sum(alignedcompcorr))];
  logprintf(logfid, msg);
  % alignedcompcorr % will disp alignedcompcorr finally
  fclose(logfid);
  % keyboard
  mdisp('yellow', ['less ' mypwd 'performance.txt']);
  mdisp('yellow', ['gv ' mypwd 'comp_00*b.png&']);
  newline; newline; newline;
  return
end

% createthumb('~/1_zen/zm12/6emsica/B0-I/*');
createthumb([s.subjectdir emsicafolder '*']);
mdisp('yellow', ['gv ' mypwd 'comp_00*b.png&']);

return % return here 2025-03-9 for testing

if ismember(emsicatype, {'gradient', 'fastemsica', 'bypass'})
  % label_activations(s,'emsicafolder',emsicafolder, 'onavgbrain', onavgbrain, 'reducemesh', reducemesh);
  % plot_b2sphere(s); % todo: 2021-10-13 it cannot run now, so i disable it tentatively. 
  plot_brainatlas(s, 'emsicafolder',emsicafolder, 'onavgbrain', onavgbrain, 'reducemesh', reducemesh);
end
