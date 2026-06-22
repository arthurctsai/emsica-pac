% get_topo() setting
%
% to debug this function
% s='zm03'; EEG=[]; emsicafolder = '6emsica/ICsR01/';
% sortcomps(s, EEG,  'emsicafolder', emsicafolder);
% 
% History:
% rkffab 2014-08-4
% rkffabcd 2016-11-29 keep nan value!
% return compidx correspond to topo, topo11
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function topo = get_topo(s,EEG,varargin)
  defaultsetting = {...
    %  name         type      range     default
    'emsicafolder', 'string', '',       'ica';...
    'K',            'real',   [],       55 ;... % number of components to calculate EEG_topo67x67.mat
    'ffeature',     'string', '',       'topo11';... % 'topo11' | 'topo67x67'
    'rmartifact',   'string', '',       'on';...
    'recompute',    'string', '',       'off';...
    'msg',          'string', '',       'on';... % messenge {'on'} | 'off'
    };

[g, s] = gparser(s, varargin, defaultsetting); ff = fieldnames(g);
for i = 1:length(ff), eval([ff{i} '=getfield(g,''' ff{i}  ''');']); end % flatten parameters
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

setfile=[s.workingdir s.dataset];
matfile=[s.workingdir 'EEG_' ffeature '.mat']; % EEG_topo11.mat, or EEG_topo67x67
recompute = checkrecompute(recompute, matfile, setfile); % if matfile is older than setfile, recompute!

if recompute
  myrm(matfile);
  mdisp(['recomputing ' matfile]);
else
  load(matfile);
  mdisp([matfile ' is loaded.']);

% the following two if is for workaround, for saved older eg. ~/1_zen/zc038/3ica/ICs/EEG_topo67x67.mat  2024-11-18 arthur
  if exist('topo11','var') 
    topo = topo11;
  end
% keyboard
  if size(topo,1) ~= K
    recompute =1;
  else
    return;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read idx.txt / idx_manually.txt
if exist([s.workingdir 'idx_manually.txt'],'file')
  txtfile = [s.workingdir 'idx_manually.txt'];
elseif exist([s.workingdir 'idx.txt'],'file')
  txtfile = [s.workingdir 'idx.txt'];           
else
  mdisp(['There is no idx.txt , or idx_manually.txt in ' s.workingdir]);
  mdisp(['So setting remove artifact as off!']);
  rmartifact = 'off';
  txtfile = gen_dummy_idx(s,K,workingdir);
end

%% it woould be better always to save arti_num in you matfile, such that you can know which comps are artifacts
% if strcmp(rmartifact,'on')
  if strcmp(msg,'on')
    mdisp(['Loading ' txtfile]);
  end
  [list, ~] = read_num_in_file(txtfile);
  list = sortrows(list,2);
  % artifact number
  arti_num = list(:,1)==0;
% else
%   arti_num = zeros( K ,1);
% end

%% ==== topo67x67 ====
if recompute && strcmpi(ffeature,'topo67x67')
  if ~isfield(EEG,'icawinv')
    EEG=pop_loadset(setfile);
    % keyboard
  end
  EEG = lfmsens2chanlocs(s,EEG);

  topo = zeros(K,67,67);
  mdisp(['Calculating ' s.subject ' ' matfile]);
% 
%   if exist(matfile,'file')
%     arti_num_new = arti_num;
%     load(matfile);        
%     mdisp([matfile ' is loaded.']);
%   else
     arti_num_new = arti_num;
     arti_num = ones( K ,1);
%   end

  for k=1:K            
    if ~arti_num_new(k) && arti_num(k)
      h=figure('visible','off');
      [~,tmp]=topoplot(EEG.icawinv(:,k),...
        EEG.chanlocs(EEG.icachansind),'electrodes','off');
      close(h);

      %                 tmp(isnan(tmp))=0;                    
      topo(k,:,:)=tmp;
      %             elseif ~arti_num_new(k) && ~arti_num(k)
      %             else
      %                 a = clock;
      %                 rand(1,a(5));
      %                 topo(k,:,:)=rand(67);
    end
  end

  arti_num = arti_num_new;

  save(matfile,'topo','arti_num');
  if strcmp(msg,'on')
    mdisp([matfile ' saved.']);
  end
% 
% else      
%   load(matfile,'topo');
%   mdisp([matfile ' is loaded.']);
%   if size(topo,1) < K % recalculate EEG_topo67x67.mat
%     mdisp(['size(topo,1)<K! it need to be recomputed!']);
%     myrm(matfile);
%     [topo]=get_topo(s,EEG,varargin{:});
%   end
end % topo67x67
% keyboard

%% ==== topo11 ====
if recompute && strcmpi(ffeature,'topo11')
  %% EEG_topo11.mat
  if recompute 
    if ~isfield(EEG,'icawinv')
      EEG=pop_loadset(setfile);
    end
    KK=size(EEG.icawinv,2);
    EEG_topo11 = nan(KK,11);
    for k = 1:KK
      mat = nan(132,1);
      mat(EEG.icachansind) = EEG.icawinv(:,k);
      for a = 1:11
        reg_idx = a == s.eeg132chanregions.index(:,1);
        EEG_topo11(k,a) = nanmean(mat(reg_idx));
      end
    end

    %% for dubuging purpose   
    %[EEG.icawinv(:,2)' ; EEG.icachansind]
    %for a = 1:132,
    %  if s.eeg132chanregions.index(a)
    %     EEG.chanlocs(a).labels=s.eeg132chanregions.regionname2{s.eeg132chanregions.index(a)};
    %  end
    %end
    %topoplot(EEG.icawinv(:,9), EEG.chanlocs(EEG.icachansind),'electrodes', 'labels', 'chaninfo', EEG.chaninfo);
    %
    %keyboard


    %    for j = 1:11
    %        topo11(:,j) = abs(2*EEG_topo11(:,j)-nansum(EEG_topo11,2))./sumsqrt(EEG_topo11);
    %    end;
    topo=EEG_topo11; % topo11
    save([s.workingdir 'EEG_topo11.mat'],'topo');
    if strcmp(msg,'on')
      mdisp([s.workingdir 'EEG_topo11.mat saved.']);
    end
    %    topo11 = topo11(EEG.icachansind(1:K),1:11); % arthur disable it 2014-08-18
    %   else
    %     load([s.workingdir 'EEG_topo11.mat'],'topo11');
    %     if strcmp(msg,'on')
    %       mdisp([s.workingdir 'EEG_topo11.mat loaded.']);
    %     end
  end

  % centers and normalizes the data in topo11 to by subtracting the mean of each column 
  % and dividing each column by its standard deviation
  topo = standardize(topo')';

end % topo11

end


%% ==== functions ====
function a=sumsqrt(mat)
  mat=mat.*mat;
  a=sqrt(sum(mat,2));
end
