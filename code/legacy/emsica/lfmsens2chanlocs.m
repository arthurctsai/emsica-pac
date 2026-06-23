% lfmsens2chanlocs() transfer lfm.sens (after coregister_() ) to EEG.chanlocs.
%
% Note:
%   get_LB0A0_by_sphx() > lfmsens2chanlocs()
%
% Example:
%   s=get_info('zm02');
%   EEG = pop_loadset([s.cleanDir s.dataset]); % pop_loadset(): loading file ~/1_zen/zm02/4clean/ICs/zm02.set …
%   [EEG, ~]=lfmsens2chanlocs(s, EEG);
%
% Wiki:
%   http://emsica.art/emsica/lfmsens2chanlocs
%
% See also:
%   readneurolocs, convertlocs
%
% History:
% 2014-07-14 rkffabcd
% 2021-0714 adjust the code for nonicachans removal from EEG.chanlocs.
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [EEG sens_flag] = lfmsens2chanlocs(s,EEG)
s = get_info(s);
sens_flag = 1; % default
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

if ~isfile([s.lfmDir 'lfm.sens'])
  sens_flag = 0;
  mdisp('red',['Cannot find ' s.lfmDir 'lfm.sens']);
  mdisp('red','Before running lfmsens2chanlocs(), you must run coregister_() to generate lfm.sens.');
  EEG.lfmsens2chanlocs = 'off';
  return;
end
% 
% % remove all EOG, HEOG, VEOG, MEG, EKG, etc. channels in EEG 
% % since they are not in lfm.sens -arthur 2021-07-15
% nonicachans = s.nonicachans; % {'REF','EKG','EMG','HEO','VEO','VEO1','VEO2','VEOG','HEOG','HEOL','HEOR'};
% 
% for i = 1:EEG.nbchan
%   label = EEG.chanlocs(i).labels; 
%   urchan{i} = label; % urchan: 1x118
% end
% 
% idxx=[];
% for j = 1:length(nonicachans)
%   idx = strcmpi(nonicachans{j},urchan);
%   %template(:,i) = [EEG.chanlocs(idx).X;EEG.chanlocs(idx).Y;EEG.chanlocs(idx).Z];
%   %temp(:,i) = tmp(:,idx);
%   if any(idx)
%     if isfield(s,'logfid')
%       logprintf(s.logfid,[EEG.chanlocs(idx).labels ' ']);
%     end
%     %idxx =  idx | idxx;
%     if any(idxx)
%       idxx=or(idxx, idx);
%     else % idxx==[] for the first time
%       idxx=idx;
%     end;
%     %keyboard;
%   end
% end
% keyboard
% EEG.chanlocs(idxx) = [];
% EEG.data(idx,:) = [];
% 
[pos, label] = read_num_in_file([s.lfmDir 'lfm.sens']); 
% !less ~/1_zen/zm01/5lfm/lfm.sens
% -0.076473 0.013956 -0.018662 # 1
% -0.078031 0.015013 0.000735 # 2
% -0.083354 0.004727 0.016324 # 3
% -0.084658 -0.010127 0.022762 # 4
% -0.080469 -0.030980 0.010174 # 5

% 2025-3-4 add label for no mri
if ~hasmri(s) % for those subject without mri, skip this step
    label = {EEG.chanlocs.labels};
    ii =cellfun(@str2double, label);
    ii = ii(~isnan(ii));
    pos = pos(ii,:);
end

if any(isnan(label{1})) || isempty(label{1})
  mdisp('red', ['check your ' s.lfmDir 'lfm.sens, the last column is empty!!!']);
  keyboard
  % Experience 1:
  % I got label =Nan, that is because lfm.sens has no column of # channel
end

% % check icachansind 2025.1.2
% if ~isempty(setdiff(EEG.icachansind, str2double(label)))
%   mdisp('red', ['Need to add ' urchan{setdiff(EEG.icachansind,str2double(label))}  ' to s.nonicachans in studyinfo.m. and also rerun ica_(s) > loadset_prune_channels() to get correct EEG.icachansind' ]);
%   keyboard
% end

mdisp(['Now length(EEG.chanlocs)=' num2str(length(EEG.chanlocs))]);
mdisp(['and length(lfm.sens)=' num2str(length(label))]);


%% ========== (1) Transfer lfm.sens channlocation onto EEG.chanlocs ==========
chanlocs_from_sens = struct('labels', label, 'type', 69*ones(length(label),1), 'X', pos(:,2)*100, 'Y', -pos(:,1)*100, 'Z', pos(:,3)*100);
% x y z -> y -x z
chanlocs_from_sens = convertlocs( chanlocs_from_sens, 'cart2all');

%% ====== (2) Iterate through EEG.chanlocs (1:118), compare the labels… ======
% and replace each channel’s entire struct if the labels match.

% 2025-01-30 added by Arthur with ChatGPT help
unmatched_labels = {}; % Store unmatched labels
for i = 1:length(EEG.chanlocs)
    % Find corresponding index in chanlocs_from_sens
    j = find(strcmp(strtrim({chanlocs_from_sens.labels}), strtrim(EEG.chanlocs(i).labels)));

    if ~isempty(j)
        j = j(1); % Take the first match if multiple

        % Replace only the specified fields
        EEG.chanlocs(i).type = chanlocs_from_sens(j).type;
        EEG.chanlocs(i).X = chanlocs_from_sens(j).X;
        EEG.chanlocs(i).Y = chanlocs_from_sens(j).Y;
        EEG.chanlocs(i).Z = chanlocs_from_sens(j).Z;
        EEG.chanlocs(i).sph_phi = chanlocs_from_sens(j).sph_phi;
        EEG.chanlocs(i).sph_radius = chanlocs_from_sens(j).sph_radius;
        EEG.chanlocs(i).theta = chanlocs_from_sens(j).theta;
        EEG.chanlocs(i).radius = chanlocs_from_sens(j).radius;
    else
        % Store unmatched labels
        unmatched_labels{end+1} = EEG.chanlocs(i).labels;
    end
end
% Display unmatched labels
if ~isempty(unmatched_labels)
    mdisp(['Total unmatched labels: ', num2str(length(unmatched_labels))]);
    mdisp('Unmatched labels:');
    mdisp(unmatched_labels);
else
    mdisp('All channel positions were successfully replaced with lfm.sens.');
end

EEG.lfmsens2chanlocs = 'on'; % arthur
