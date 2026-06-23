% gparser() check s.
%
% varargin parser for neat defaultsetting processing in most of my emsica functions
% note.
% after gparser, recompute becomes 1 or 0 instead of 'on', 'off'
% 2023-05-25 arthur
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [g, s] = gparser(s, varargin, defaultsetting)
if ~isempty(s), s=get_info(s); end
if mod(length(varargin),2)
    mdisp('red','Error! varargin should be pairs!');
    keyboard
end

  % check varargin, if eg. 'recompute', reducemesh' == 1, change it to 'on'
  for i=1:length(varargin)
      if strcmpi(varargin(i),'recompute') % | strcmpi(varargin(i),'reducemesh')
          tmp = varargin{i+1};
          if ~ischar(tmp)
              if tmp
                  varargin{i+1} = 'on';
              else
                  varargin{i+1} = 'off';
              end
          end
      end
  end
 
g = finputcheck(varargin, defaultsetting);
%% ============================ (1) Define quote =============================
  % g.quote=char(39); % '

if ischar(g)
  if contains(g, 'error') && ...
     ~(contains(g, '''recompute''') || contains(g, '''reducemesh''') || contains(g, '''onavgbrain'''))
    g
    keyboard
  end
end



% 
% 
%   if ischar(g)
%     if contains(g,'error')
%       g
%       keyboard
%     end
%   end
  
% check varargin, if eg. 'reducemesh', 'onavgbrain', == 'on', change it to 1
for i=1:length(varargin)
     if strcmpi(varargin(i), 'reducemesh') | strcmpi(varargin(i), 'onavgbrain') | strcmpi(varargin(i), 'recompute')
        tmp = varargin{i+1};
        if ischar(tmp)
            if strcmpi(tmp, 'on')
                varargin{i+1} = 1;
            else
                varargin{i+1} = 0;
            end
        end
    end
end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  % then you can use something like this in your matlab code
  % mdisp('yellow',['You can use label_activations(' quote sss.subject quote '); to generate label of each component.\n']);
  % % this will show "You can use label_activations('7raicar'); to generate label of each component."

  % check whether variables exists in matlab or not
  tmp = fieldnames(g);
  for i = 1:length(tmp)
      if exist(tmp{i},'builtin')
          error([mymfilenames() ' The variable ' tmp{i} ' exists in matlab, please change your defaultsetting!']);
      end
  end

  % if there is parameter recompute, change it to boolean 0/1
  % so instead of write
  % if strcmpi(recompute, 'on')
  % you can write a cleaner code
  % if commpute
  if isfield(g, 'recompute')
      if contains(g.recompute,'on')
          g.recompute = 1;
      else
          g.recompute = 0;
      end
  end

%% ========= (2) For eg. get_similarity() and no parameter s asigned =========
if isempty(s), return; end % for eg. get_similarity which does not have parameter 's'

%% ============= (3) Assign workingdir according to emsicafolder =============
% step 1. validate emsicafolder
% emsicafolder = 3ica/ICsR101/
if isfield(g,'emsicafolder') % emsicafolder = '3ica/ICsR101/' 
  emsicafolder = g.emsicafolder;
  if contains(emsicafolder,'/')
    if ~isdigit(emsicafolder(1))
      mdisp(['emsicafolder should be a string something like 3ica/ICsR101/, 6emsica/B0/, etc.']);
      error(['check your emsicafolder']);
    end
  end
end

% The following parses the emsicafolder path and extracts the project folder (s)
% if present. For example:
%   - If emsicafolder = '7raicar2/6emsica/ICsR01-lhrh/' 
%     → subject = '7raicar2', emsicafolder = '6emsica/ICsR01-lhrh/'
%   - If emsicafolder = '6emsica/ICsR01-lhrh'
%     → emsicafolder = '6emsica/ICsR01-lhrh/', s is not assigned.

% Remove trailing slash if it exists
if isfield(g,'emsicafolder')
  emsicafolder = regexprep(emsicafolder, '/$', '');

  % Split by '/'
  parts = strsplit(emsicafolder, '/');

  if contains(emsicafolder,'7raicar') % eg. emsicafolder == 7raicar/6emsica/ICsR01/
    % clusterstxt = ~/1_zen/7riacar2/6emsica/ICsR01-lhrh/clusters.txt
    if ~contains(g.clusterstxt, '/') 
      clusterstxt = [s.studydir emsicafolder g.clusterstxt];
    end

    subject = parts{1}; % 7raicar
    emsicafolder = fullfile(parts{2}, parts{3}, '/');
  else
    emsicafolder = [emsicafolder '/'];
  end
end

% Finally, assign the workingdir
if isfield(g,'emsicafolder') % emsicafolder = '3ica/ICsR101/'
  g.emsicafolder = emsicafolder;
  if isfield(s, 'emsica') && isstruct(s.emsica) && ...
      isfield(s.emsica, 'output_folder') && ~isempty(s.emsica.output_folder) && ...
      startsWith(emsicafolder, '6emsica/ICs-synth-')
    workingdir = char(string(s.emsica.output_folder));
    if ~endsWith(workingdir, filesep), workingdir = [workingdir filesep]; end
  else
    workingdir = [s.subjectdir emsicafolder];
  end
  g.workingdir = workingdir;
  s.workingdir = workingdir;
end % if isfield(g,'emsicafolder')

if isfield(s, 'workingdir')
  g.workingdir = s.workingdir;
end

% keyboard
%% ===== (4) For eg. plot_b_7raicar, pairing3, mmi_7raicar_, get_comps,… =====
if isfield(g,'emsicafolder') && isfield(g, 'clusterstxt') 
  if ~isempty(g.clusterstxt) % sometimes clusterstxt =='' eg. in mmi_7raicar_() then leave it alone
    % for the case clusterstxt = 'clusters.txt' return full path eg. ~/1_zen/7riacar/6emsica/ICsR01-I/clusters.txt
    if ~contains(g.clusterstxt, '/') 
      if contains(s.subject, '7raicar')
        ssbj = strtok(s.subject, '_'); % for '7raicar1_medit', it returns '7raicar1'.
      elseif exist('subject','var')
          ssbj = subject;
      else
        ssbj = '7raicar'; % default
      end
      % ~/1_zen/7raicar/6emsica/ICsR01-I/clsuters.txt
      g.clusterstxt = [s.studydir ssbj '/' g.emsicafolder g.clusterstxt]; 
      % we use default study folder '7raicar', if not you have to asign your full path of clusters.txt
    end

%% ============ (5) For 1_zen add _paired.txt for the clusterstxt ============
    if contains(s.studydir, '1_zen') && ~endsWith(g.clusterstxt, '_paired.txt')
      if ~isempty(regexp(s.subject, '\d{2}8$', 'once')) || contains(s.subject, 'post')  
        % check whether s.subject ends with three digits, and the last digit is 8
        % or contain with post eg. '7raicar_meditpost'

        % replace the string from clustertxt = '7raicar/6emsica/ICsR01-I/clusters.txt';
        % to '7raicar/6emsica/ICsR01-I/clusters_paired.txt';
        g.clusterstxt = strrep(g.clusterstxt, '.txt', '_paired.txt');
        mdisp('yellow', ['clusterstxt is switched to ' g.clusterstxt ' since ' s.subject ' is a post-test subject(s).']);
        if ~isfile(g.clusterstxt)
          mdisp('red', ['Cannot find ' g.clusterstxt]);
          mdisp('red', ['You need to run pairing3() >> clusterspaired()']);
          keyboard
        end
      end

    end % 1_zen

%% ==== (6) To display the path stored in g.clusterstxt and the date it… =====
    if isfile(g.clusterstxt)
      fileInfo = dir(g.clusterstxt);
      mdisp('yellow', ['clusterstxt = ' g.clusterstxt ' was created on ', fileInfo.date]);

      % check clusters.txt
      if ~isfile(g.clusterstxt)
        mdisp(['Cannot find ' g.clusterstxt]);
        keyboard;
      end
    end
  end % if isfield 'clusterstxt'
end % if isfield(g,'emsicafolder') && isfield(g, 'clusterstxt') 


%% ======== (7) For eg. emsica_, emsica_4raicar_, assign emsicatype… =========
if isfield(g,'emsicafolder') && isfield(g, 'emsicatype') % so emsica_() will enter this segment
  if isempty(g.emsicatype) % which is the default of emsica_()
    switch true
      case contains(g.emsicafolder, 'B0')
        g.emsicatype = 'B0';
      case contains(g.emsicafolder, 'gradient')
        g.emsicatype = 'gradient';
      case contains(g.emsicafolder, 'fastemsica')
        g.emsicatype = 'fastemsica';
      otherwise % default
        g.emsicatype = 'gradient';
    end
%     mdisp('yellow', ['emsicatype = ' g.emsicatype '\n']);
     mdisp('yellow', ['emsicatype = ' g.emsicatype]);
  end
end

%% ======= (8) Extract lapmethod from emsicafolder, for eg. emsica_,… ========
% lapmethod: ''|'cyto' | 'lhrh' | 'I';
 % 'cyto': use cytoarchitecture invented by arthur in 2021
 % 'lhrh': as in NI2014 emsica paper by arthur 
 %      I: as in NI2006 emsica paper by arthur
 %     '': then lapmethod will be determinated by name in emsicafolder or see gparser()
% eg. if there is some string like 'cyto' in the emsicafolder string, then lapmethod==cyto
% The default is 'lhrh' which is asigned here.
if ~isfield(g,'lapmethod')
  g.lapmethod='';
end
% keyboard
% if g.lapmethod is not set
if isempty(g.lapmethod) % lapmethod=='' is the default in most of the functions eg. emsica_(), get_LB0A0_by_sphx(), etc.
  if isfield(g,'emsicafolder') % && isfield(g,'lapmethod') % note, graicar_, emsica_() and get_LB0A0_by_sphx() will enter this segment
    switch true
      case contains(g.emsicafolder, 'cyto')
        g.lapmethod = 'cyto';
      case contains(g.emsicafolder, 'Ilhrh')
        g.lapmethod = 'Ilhrh'; % ref. get_LB0A0_by_sphx()
      case contains(g.emsicafolder, 'lhrh')
        g.lapmethod = 'lhrh';
      case contains(g.emsicafolder, 'I')
        g.lapmethod = 'I';
      otherwise % default
        g.lapmethod = 'lhrh'; % 2024-11-4 set default as lhrh as in NI14 arthur
    end
    % mdisp('yellow', ['lapmethod = ' g.lapmethod]);
  end
end

%% ======== (9) For fmri study, asign single subject main folder as… =========
% Note,
% case 1. if when calling plot_b() eg. by ica_4raicar_plot_a_b_only() > plot_b() s.workingdir has been asigned as eg. ICsR01, ICsR02,...
%         then we don't need to asign again here.
% case 2. if when calling plot_b() eg. by raicar_() > plot_b() s.workingdir has been asigned to plot average brain on 3ica/ICs/ 
%         then we don't need to asign again here.
if strcmpi(s.datatype, 'fmri') % for fmri study
  if ~isfield(s, 'workingdir') && ~contains(s.subject, '7raicar')
    s.icaDir = [s.subjectdir '3ica/ICsR01/']; % default working dir
    s.workingdir = s.icaDir;
    g.workingdir = s.icaDir;
  end
end

%% ====== (10) For EEG/MEG study, asign single subject main folder as… =======
if strcmpi(s.datatype, 'eeg') || strcmpi(s.datatype, 'meg')   % for EEG/MEG study
  if ~isfield(s, 'workingdir') && ~contains(s.subject, '7raicar')
    s.emsicaDir = [s.subjectdir '3ica/ICsR01/']; % default working dir
    s.workingdir = s.emsicaDir;
    g.workingdir = s.emsicaDir;
  end
end

%% ======= (11) In the final case asign working dir by g.emsicafolder ========
% Note, if you are passing s.workingdir, keep it. It will not enter the following.
% 2013-06-19 Seattle, arhtur
if ~isfield(s, 'workingdir') && isfield(g,'emsicafolder')
    switch lower(g.emsicafolder)
        case 'channel'
            STAGE_DIR = '1channels/CHs/'; s.emsicafolder = '1channels';
        case 'epoch'
            STAGE_DIR = '2epochs/EPs/';   s.emsicafolder = '2epochs';
        case 'ica'
            STAGE_DIR = '3ica/ICs/';      s.emsicafolder = '3ica';
        case 'clean'
            STAGE_DIR = '4clean/ICs/';    s.emsicafolder = '4clean';
        case 'lfm'
            STAGE_DIR = '5lfm/L/';        s.emsicafolder = '5lfm';
        case 'emsica'
            STAGE_DIR = '6emsica/ICs/';   s.emsicafolder = '6emsica';
        case 'b0'
            STAGE_DIR = '6emsica/B0/';   s.emsicafolder = '6emsica';
        otherwise
            STAGE_DIR = '6emsica/ICs/';   s.emsicafolder = '6emsica';
    end

    s.workingdir = [s.subjectDir STAGE_DIR]; %default
    g.workingdir = s.workingdir;
end


end
